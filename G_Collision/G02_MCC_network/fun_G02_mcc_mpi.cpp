// SPDX-License-Identifier: Apache-2.0
// 多进程推进：本地准备碰撞 → 协商新粒子编号 → 全体成功后提交。
// 这里只交换编号等元数据，不替主程序迁移粒子。
// 初读先看文件末尾 step，再看 agree 和 allocate_child_ids。
#include "mpi.hpp"

#include <algorithm>
#include <climits>
#include <cstdint>
#include <exception>
#include <limits>
#include <numeric>
#include <stdexcept>
#include <tuple>
#include <vector>

namespace algoplasma::mcc {
namespace {

void check_mpi(const int status, const char* operation) {
    if (status == MPI_SUCCESS) return;
    char detail[MPI_MAX_ERROR_STRING]{};
    int length = 0;
    MPI_Error_string(status, detail, &length);
    throw Error(std::string(operation) + ": " + std::string(detail,
        static_cast<std::size_t>(length)));
}

struct RoutedBirth {
    std::uint64_t parent_id{0};
    std::uint64_t event_and_ordinal{0};
    std::uint64_t origin_index{0};
    int origin_rank{0};
};

int route_for(const std::uint64_t parent, const std::uint64_t minimum,
              const std::uint64_t maximum, const int ranks) noexcept {
    if (minimum == maximum || ranks == 1) return 0;
    const long double offset = static_cast<long double>(parent - minimum);
    const long double span = static_cast<long double>(maximum - minimum) + 1.0L;
    const auto chosen = static_cast<int>(offset * ranks / span);
    return std::clamp(chosen, 0, ranks - 1);
}

std::vector<int> displacements(const std::vector<int>& counts) {
    std::vector<int> offsets(counts.size());
    int next = 0;
    for (std::size_t i = 0; i < counts.size(); ++i) {
        offsets[i] = next;
        if (counts[i] < 0 || counts[i] > INT_MAX - next) {
            throw Error("MPI birth metadata exceeds the MPI int count limit");
        }
        next += counts[i];
    }
    return offsets;
}

} // namespace

DistributedMccStepper::DistributedMccStepper(MccEngine engine,
                                             const MPI_Comm communicator,
                                             const StepOptions options)
    : local_(std::move(engine), options) {
    int initialized = 0, finalized = 0, provided = MPI_THREAD_SINGLE;
    check_mpi(MPI_Initialized(&initialized), "MPI_Initialized");
    if (initialized == 0) throw Error("host must initialize MPI before MCC");
    check_mpi(MPI_Finalized(&finalized), "MPI_Finalized");
    if (finalized != 0) throw Error("MPI was already finalized");
    check_mpi(MPI_Query_thread(&provided), "MPI_Query_thread");
    if (provided < MPI_THREAD_FUNNELED) {
        throw Error("distributed MCC needs at least MPI_THREAD_FUNNELED");
    }
    check_mpi(MPI_Comm_dup(communicator, &communicator_), "MPI_Comm_dup");
    try {
        check_mpi(MPI_Comm_set_errhandler(communicator_, MPI_ERRORS_RETURN),
                  "MPI_Comm_set_errhandler");
        check_mpi(MPI_Comm_rank(communicator_, &rank_), "MPI_Comm_rank");
        check_mpi(MPI_Comm_size(communicator_, &ranks_), "MPI_Comm_size");
    } catch (...) {
        MPI_Comm_free(&communicator_);
        throw;
    }
}

DistributedMccStepper::~DistributedMccStepper() {
    if (communicator_ == MPI_COMM_NULL) return;
    int finalized = 0;
    if (MPI_Finalized(&finalized) == MPI_SUCCESS && finalized == 0) {
        MPI_Comm_free(&communicator_);
    }
}

// Allreduce 汇总失败标志；任一进程失败，全体停止本阶段。
void DistributedMccStepper::agree(const bool failed, const std::string& message) const {
    int local_flag = failed ? 1 : 0, any_failure = 0;
    check_mpi(MPI_Allreduce(&local_flag, &any_failure, 1, MPI_INT, MPI_MAX, communicator_),
              "MPI_Allreduce(step status)");
    if (any_failure != 0) {
        throw Error(failed ? message : "another MPI rank could not prepare the MCC step");
    }
}

std::vector<std::uint64_t> DistributedMccStepper::allocate_child_ids(
    const std::vector<BirthKey>& keys, const std::uint64_t global_max,
    const std::uint64_t global_births) const {
    std::uint64_t local_min = UINT64_MAX, local_max = 0;
    for (const BirthKey& key : keys) {
        local_min = std::min(local_min, key.parent_id);
        local_max = std::max(local_max, key.parent_id);
    }
    std::uint64_t minimum = 0, maximum = 0;
    check_mpi(MPI_Allreduce(&local_min, &minimum, 1, MPI_UINT64_T, MPI_MIN, communicator_),
              "MPI_Allreduce(minimum parent ID)");
    check_mpi(MPI_Allreduce(&local_max, &maximum, 1, MPI_UINT64_T, MPI_MAX, communicator_),
              "MPI_Allreduce(maximum parent ID)");

    std::vector<int> send_counts(static_cast<std::size_t>(ranks_));
    bool failed = keys.size() > static_cast<std::size_t>(INT_MAX / 3);
    if (!failed) {
        for (const BirthKey& key : keys) {
            const int owner = route_for(key.parent_id, minimum, maximum, ranks_);
            if (send_counts[static_cast<std::size_t>(owner)] == INT_MAX / 3) {
                failed = true;
                break;
            }
            ++send_counts[static_cast<std::size_t>(owner)];
        }
    }
    agree(failed, "local MPI birth metadata exceeds the MPI int count limit");

    std::vector<int> receive_counts(static_cast<std::size_t>(ranks_));
    check_mpi(MPI_Alltoall(send_counts.data(), 1, MPI_INT,
                           receive_counts.data(), 1, MPI_INT, communicator_),
              "MPI_Alltoall(birth counts)");
    std::vector<int> send_offsets, receive_offsets;
    std::string error;
    try {
        send_offsets = displacements(send_counts);
        receive_offsets = displacements(receive_counts);
        const int total_received = receive_offsets.back() + receive_counts.back();
        if (total_received > INT_MAX / 3) {
            throw Error("received MPI birth metadata exceeds the MPI int count limit");
        }
    } catch (const std::exception& caught) { error = caught.what(); }
    agree(!error.empty(), error);

    std::vector<std::uint64_t> outbound, inbound;
    std::vector<int> send_words, receive_words, send_word_offsets, receive_word_offsets;
    std::size_t total_received = 0;
    error.clear();
    try {
        outbound.resize(std::max<std::size_t>(1, 3 * keys.size()));
        total_received = static_cast<std::size_t>(
            receive_offsets.back() + receive_counts.back());
        inbound.resize(std::max<std::size_t>(1, 3 * total_received));
        std::vector<int> cursor = send_offsets;
        for (std::size_t i = 0; i < keys.size(); ++i) {
            const int owner = route_for(keys[i].parent_id, minimum, maximum, ranks_);
            const std::size_t slot = static_cast<std::size_t>(
                cursor[static_cast<std::size_t>(owner)]++);
            outbound[3 * slot] = keys[i].parent_id;
            outbound[3 * slot + 1] =
                (static_cast<std::uint64_t>(keys[i].event_index) << 32U) |
                keys[i].product_ordinal;
            outbound[3 * slot + 2] = i;
        }
        for (int i = 0; i < ranks_; ++i) {
            send_words.push_back(3 * send_counts[static_cast<std::size_t>(i)]);
            receive_words.push_back(3 * receive_counts[static_cast<std::size_t>(i)]);
            send_word_offsets.push_back(3 * send_offsets[static_cast<std::size_t>(i)]);
            receive_word_offsets.push_back(3 * receive_offsets[static_cast<std::size_t>(i)]);
        }
    } catch (const std::exception& caught) { error = caught.what(); }
    agree(!error.empty(), error);
    check_mpi(MPI_Alltoallv(outbound.data(), send_words.data(), send_word_offsets.data(),
                            MPI_UINT64_T, inbound.data(), receive_words.data(),
                            receive_word_offsets.data(), MPI_UINT64_T, communicator_),
              "MPI_Alltoallv(birth keys)");

    const std::size_t local_count = total_received;
    std::vector<RoutedBirth> routed;
    error.clear();
    try {
        routed.reserve(local_count);
        for (int source = 0; source < ranks_; ++source) {
            const std::size_t start = static_cast<std::size_t>(
                receive_offsets[static_cast<std::size_t>(source)]);
            const std::size_t end = start + static_cast<std::size_t>(
                receive_counts[static_cast<std::size_t>(source)]);
            for (std::size_t i = start; i < end; ++i) {
                routed.push_back({inbound[3 * i], inbound[3 * i + 1],
                                  inbound[3 * i + 2], source});
            }
        }
        std::sort(routed.begin(), routed.end(), [](const auto& a, const auto& b) {
            return std::tie(a.parent_id, a.event_and_ordinal) <
                   std::tie(b.parent_id, b.event_and_ordinal);
        });
        for (std::size_t i = 1; i < routed.size(); ++i) {
            if (routed[i].parent_id == routed[i - 1].parent_id &&
                routed[i].event_and_ordinal == routed[i - 1].event_and_ordinal) {
                throw Error("duplicate MPI birth key; particle IDs must be globally unique");
            }
        }
    } catch (const std::exception& caught) { error = caught.what(); }
    agree(!error.empty(), error);

    const std::uint64_t owned = static_cast<std::uint64_t>(routed.size());
    std::uint64_t preceding = 0;
    check_mpi(MPI_Exscan(&owned, &preceding, 1, MPI_UINT64_T, MPI_SUM, communicator_),
              "MPI_Exscan(birth offsets)");
    if (rank_ == 0) preceding = 0;
    agree(global_max > UINT64_MAX - global_births ||
          preceding > global_births || owned > global_births - preceding,
          "global MCC child ID overflow or inconsistent birth counts");

    std::vector<int> return_send_counts(static_cast<std::size_t>(ranks_));
    std::vector<int> return_receive_counts(static_cast<std::size_t>(ranks_));
    std::vector<int> return_send_offsets(static_cast<std::size_t>(ranks_));
    std::vector<int> return_receive_offsets(static_cast<std::size_t>(ranks_));
    std::vector<std::uint64_t> assigned, returned, ids;
    error.clear();
    try {
        for (int i = 0; i < ranks_; ++i) {
            const std::size_t slot = static_cast<std::size_t>(i);
            return_send_counts[slot] = 2 * receive_counts[slot];
            return_receive_counts[slot] = 2 * send_counts[slot];
            return_send_offsets[slot] = 2 * receive_offsets[slot];
            return_receive_offsets[slot] = 2 * send_offsets[slot];
        }
        assigned.resize(std::max<std::size_t>(1, 2 * routed.size()));
        returned.resize(std::max<std::size_t>(1, 2 * keys.size()));
        ids.resize(keys.size());
        std::vector<int> cursor = receive_offsets;
        for (std::size_t i = 0; i < routed.size(); ++i) {
            const int origin = routed[i].origin_rank;
            const std::size_t slot = static_cast<std::size_t>(
                cursor[static_cast<std::size_t>(origin)]++);
            assigned[2 * slot] = routed[i].origin_index;
            assigned[2 * slot + 1] = global_max + preceding +
                static_cast<std::uint64_t>(i) + 1U;
        }
    } catch (const std::exception& caught) { error = caught.what(); }
    agree(!error.empty(), error);
    check_mpi(MPI_Alltoallv(assigned.data(), return_send_counts.data(),
                            return_send_offsets.data(), MPI_UINT64_T,
                            returned.data(), return_receive_counts.data(),
                            return_receive_offsets.data(), MPI_UINT64_T, communicator_),
              "MPI_Alltoallv(child IDs)");
    for (std::size_t i = 0; i < keys.size(); ++i) {
        const std::uint64_t index = returned[2 * i];
        if (index >= ids.size() || ids[static_cast<std::size_t>(index)] != 0U) {
            error = "invalid or repeated MPI child ID assignment";
            break;
        }
        ids[static_cast<std::size_t>(index)] = returned[2 * i + 1];
    }
    if (error.empty() && std::find(ids.begin(), ids.end(), 0U) != ids.end()) {
        error = "missing MPI child ID assignment";
    }
    agree(!error.empty(), error);
    return ids;
}

// 全体须以相同顺序调用，包括本地没有粒子的进程。
StepReport DistributedMccStepper::step(ParticleAdapter& particles,
                                        const std::vector<CellBackground>& background,
                                        const Real dt_s,
                                        const std::uint64_t global_step,
                                        const std::uint64_t seed) {
    // 1. 本地准备后协调错误，保证全体都能进入后续编号通信。
    PreparedMccStep pending;
    std::vector<BirthKey> keys;
    std::string error;
    try {
        pending = local_.prepare_step(particles, background, dt_s, global_step,
                                      seed, workspace_);
        keys = pending.birth_keys();
    } catch (const std::exception& caught) { error = caught.what(); }
    catch (...) { error = "unknown MCC preparation error"; }
    agree(!error.empty(), error);

    // 2. 求全局已用编号上界和新生粒子数，防止编号重复或溢出。
    const std::uint64_t local_max = std::max(high_watermark_, pending.largest_id());
    const std::uint64_t local_births = static_cast<std::uint64_t>(keys.size());
    std::uint64_t global_max = 0, global_births = 0;
    check_mpi(MPI_Allreduce(&local_max, &global_max, 1, MPI_UINT64_T, MPI_MAX, communicator_),
              "MPI_Allreduce(global particle ID)");
    check_mpi(MPI_Allreduce(&local_births, &global_births, 1, MPI_UINT64_T, MPI_SUM,
                            communicator_), "MPI_Allreduce(global births)");
    if (global_births > UINT64_MAX - global_max) {
        throw Error("global MCC child IDs would overflow UINT64_MAX");
    }

    // 3. 按出生键分配编号，使编号不依赖粒子所在的进程。
    std::vector<std::uint64_t> ids;
    if (global_births != 0U) ids = allocate_child_ids(keys, global_max, global_births);
    const std::uint64_t newest_id = global_max + global_births;
    const std::uint64_t next_id = newest_id == UINT64_MAX ? UINT64_MAX : newest_id + 1U;
    error.clear();
    try { pending.prepare_commit(particles, ids, next_id); }
    catch (const std::exception& caught) { error = caught.what(); }
    catch (...) { error = "unknown MCC commit preparation error"; }
    agree(!error.empty(), error);
    // 4. 全体通过内存和容量检查后写回。返回本地报告，全局统计由主程序汇总。
    pending.commit(particles);
    high_watermark_ = newest_id;
    return pending.take_report();
}

} // namespace algoplasma::mcc
