// SPDX-License-Identifier: Apache-2.0
// MPI C 接口先协调参数检查，再调用 C++ 分布式推进器。
// 容量不足需全体重试本次 step；这里没有普通 C session 的 resume 接口。
#include "mpi_c_api.h"

#include "mpi.hpp"
#include "c_api_internal.hpp"

#include <algorithm>
#include <cstring>
#include <exception>
#include <limits>
#include <memory>
#include <string_view>
#include <type_traits>
#include <vector>

namespace mcc = algoplasma::mcc;
static_assert(std::is_nothrow_move_assignable_v<mcc::StepReport>);

struct ap_g02_mcc_mpi_session {
    mcc::DistributedMccStepper stepper;
    std::uint64_t next_id{0};
    ap_g02_mcc_mpi_session(const ap_g02_mcc_engine& engine, const MPI_Comm comm,
                           const mcc::StepOptions options)
        : stepper(engine.engine, comm, options), next_id(engine.next_batch_id) {}
};

namespace {

void write_error(char* buffer, const std::size_t size, const std::string_view message) {
    if (buffer == nullptr || size == 0) return;
    const auto count = std::min(size - 1, message.size());
    std::memcpy(buffer, message.data(), count);
    buffer[count] = '\0';
}

mcc::ParticleState to_particle(const ap_g02_mcc_particle& source) {
    mcc::ParticleState result;
    result.species = source.species;
    result.state = source.state;
    result.position = {source.position[0], source.position[1], source.position[2]};
    result.velocity = {source.velocity[0], source.velocity[1], source.velocity[2]};
    result.weight = source.weight;
    result.id = source.id;
    result.birth_step = source.birth_step;
    result.cell = source.cell;
    return result;
}

void from_particle(const mcc::ParticleState& source, ap_g02_mcc_particle& target) noexcept {
    target.species = source.species;
    target.state = source.state;
    target.position[0] = source.position.x;
    target.position[1] = source.position.y;
    target.position[2] = source.position.z;
    target.velocity[0] = source.velocity.x;
    target.velocity[1] = source.velocity.y;
    target.velocity[2] = source.velocity.z;
    target.weight = source.weight;
    target.id = source.id;
    target.birth_step = source.birth_step;
    target.cell = source.cell;
}

// prepare_commit 核对容量并借用结果；commit 才修改数组和粒子数。
class CParticleAdapter final : public mcc::ParticleAdapter {
public:
    CParticleAdapter(ap_g02_mcc_particle* particles, std::size_t& count,
                     const std::size_t capacity, std::size_t& required,
                     std::uint64_t& next_id)
        : particles_(particles), count_(count), capacity_(capacity),
          required_(required), next_id_(next_id) {}
    std::size_t size() const override { return count_; }
    bool alive(const std::size_t index) const override { return index < count_; }
    mcc::ParticleState particle(const std::size_t index) const override {
        return to_particle(particles_[index]);
    }
    std::uint64_t next_id_hint() const noexcept override { return next_id_; }
    void prepare_commit(const std::vector<mcc::ParticleChange>& changes,
                        const std::vector<mcc::ParticleState>& created,
                        const std::uint64_t next_id) override {
        std::size_t removed = 0;
        for (const auto& change : changes) {
            if (change.action == mcc::PrimaryAction::Remove) ++removed;
        }
        if (removed > count_ || created.size() >
            std::numeric_limits<std::size_t>::max() - (count_ - removed)) {
            throw mcc::Error("particle buffer size overflow");
        }
        required_ = count_ - removed + created.size();
        if (required_ > capacity_) {
            throw mcc::Error("particle buffer is too small for products");
        }
        changes_ = &changes;
        created_ = &created;
        staged_next_id_ = next_id;
    }
    void commit() noexcept override {
        std::size_t write = 0, change_index = 0;
        for (std::size_t read = 0; read < count_; ++read) {
            if (change_index < changes_->size() && (*changes_)[change_index].index == read) {
                const auto& change = (*changes_)[change_index++];
                if (change.action != mcc::PrimaryAction::Remove) {
                    from_particle(change.after, particles_[write++]);
                }
            } else {
                if (write != read) particles_[write] = particles_[read];
                ++write;
            }
        }
        for (const auto& created : *created_) from_particle(created, particles_[write++]);
        count_ = write;
        next_id_ = staged_next_id_;
        changes_ = nullptr;
        created_ = nullptr;
    }

private:
    ap_g02_mcc_particle* particles_;
    std::size_t& count_;
    std::size_t capacity_;
    std::size_t& required_;
    std::uint64_t& next_id_;
    std::uint64_t staged_next_id_{0};
    const std::vector<mcc::ParticleChange>* changes_{nullptr};
    const std::vector<mcc::ParticleState>* created_{nullptr};
};

std::vector<mcc::CellBackground> cell_backgrounds(
    const ap_g02_mcc_cell_background* input, const std::size_t count) {
    std::vector<mcc::CellBackground> result;
    result.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        mcc::BackgroundComponent component;
        component.species = input[i].species;
        component.state = input[i].state;
        component.density_m3 = input[i].density_m3;
        component.temperature_k = input[i].temperature_k;
        component.drift_m_per_s = {input[i].drift_m_per_s[0], input[i].drift_m_per_s[1],
                                   input[i].drift_m_per_s[2]};
        result.push_back({input[i].cell, component});
    }
    return result;
}

} // namespace

extern "C" {

ap_g02_mcc_status ap_g02_mcc_mpi_session_create(const ap_g02_mcc_engine* engine,
    const MPI_Comm communicator, const uint32_t max_candidates, const unsigned threads,
    const int backend, const int sampler, ap_g02_mcc_mpi_session** out_session,
    char* error_buffer, const size_t error_buffer_size) {
    int initialized = 0;
    MPI_Initialized(&initialized);
    if (initialized == 0 || communicator == MPI_COMM_NULL) {
        write_error(error_buffer, error_buffer_size, "MPI is not initialized or communicator is null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const int invalid = engine == nullptr || out_session == nullptr ||
        backend < 0 || backend > 2 || sampler < 0 || sampler > 1;
    int any_invalid = 0;
    MPI_Allreduce(&invalid, &any_invalid, 1, MPI_INT, MPI_MAX, communicator);
    if (any_invalid != 0) {
        write_error(error_buffer, error_buffer_size, "invalid MPI MCC session argument");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_session = nullptr;
    try {
        mcc::StepOptions options;
        options.backend = static_cast<mcc::CpuBackend>(backend);
        options.threads = threads;
        options.max_candidates_per_particle = max_candidates == 0U
            ? 1000000U : max_candidates;
        options.sampler = static_cast<mcc::ChannelSampler>(sampler);
        *out_session = new ap_g02_mcc_mpi_session(*engine, communicator, options);
        return AP_G02_MCC_OK;
    } catch (const std::exception& error) {
        write_error(error_buffer, error_buffer_size, error.what());
        return AP_G02_MCC_INTERNAL_ERROR;
    } catch (...) {
        write_error(error_buffer, error_buffer_size, "unknown MPI MCC session error");
        return AP_G02_MCC_INTERNAL_ERROR;
    }
}

ap_g02_mcc_status ap_g02_mcc_mpi_session_create_f(const ap_g02_mcc_engine* engine,
    const int communicator, const uint32_t max_candidates, const unsigned threads,
    const int backend, const int sampler, ap_g02_mcc_mpi_session** out_session,
    char* error_buffer, const size_t error_buffer_size) {
    int initialized = 0;
    MPI_Initialized(&initialized);
    if (initialized == 0) {
        write_error(error_buffer, error_buffer_size, "MPI is not initialized");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    return ap_g02_mcc_mpi_session_create(engine,
        MPI_Comm_f2c(static_cast<MPI_Fint>(communicator)),
        max_candidates, threads, backend, sampler, out_session,
        error_buffer, error_buffer_size);
}

ap_g02_mcc_status ap_g02_mcc_mpi_session_destroy(ap_g02_mcc_mpi_session* session) {
    delete session;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_mpi_session_step(ap_g02_mcc_mpi_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, const size_t capacity,
    size_t* required, const ap_g02_mcc_cell_background* background,
    const size_t background_count, const double dt_s, const uint64_t global_step,
    const uint64_t seed, ap_g02_mcc_step_report** out_report,
    char* error_buffer, const size_t error_buffer_size) {
    if (session == nullptr) {
        write_error(error_buffer, error_buffer_size, "MPI MCC session is null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const MPI_Comm comm = session->stepper.communicator();
    const int invalid = inout_count == nullptr || required == nullptr ||
        out_report == nullptr || (inout_count != nullptr && *inout_count > capacity) ||
        (inout_count != nullptr && *inout_count != 0U && particles == nullptr) ||
        (background_count != 0U && background == nullptr);
    std::vector<mcc::CellBackground> field;
    std::unique_ptr<ap_g02_mcc_step_report> report;
    int local_preflight_error = invalid ? AP_G02_MCC_INVALID_ARGUMENT : AP_G02_MCC_OK;
    if (invalid == 0) {
        *out_report = nullptr;
        *required = *inout_count;
        try {
            field = cell_backgrounds(background, background_count);
            report = std::make_unique<ap_g02_mcc_step_report>();
        } catch (const std::exception& error) {
            local_preflight_error = AP_G02_MCC_INTERNAL_ERROR;
            write_error(error_buffer, error_buffer_size, error.what());
        } catch (...) {
            local_preflight_error = AP_G02_MCC_INTERNAL_ERROR;
            write_error(error_buffer, error_buffer_size, "unknown MPI MCC input error");
        }
    }
    // 全体先检查参数和内存，避免部分进程提前返回、其余进入后续通信。
    int any_preflight_error = 0;
    MPI_Allreduce(&local_preflight_error, &any_preflight_error, 1, MPI_INT, MPI_MAX, comm);
    if (any_preflight_error != 0) {
        if (local_preflight_error == AP_G02_MCC_OK) {
            write_error(error_buffer, error_buffer_size,
                        "another rank could not prepare MPI MCC inputs");
        } else if (local_preflight_error == AP_G02_MCC_INVALID_ARGUMENT) {
            write_error(error_buffer, error_buffer_size, "invalid MPI MCC step argument");
        }
        return static_cast<ap_g02_mcc_status>(any_preflight_error);
    }
    // required 返回本进程所需容量，不是全体容量之和。
    CParticleAdapter adapter(particles, *inout_count, capacity, *required, session->next_id);
    try {
        report->report = session->stepper.step(adapter, field, dt_s, global_step, seed);
        *out_report = report.release();
        return AP_G02_MCC_OK;
    } catch (const std::exception& error) {
        const std::string_view message = error.what();
        write_error(error_buffer, error_buffer_size, message);
        int local_kind = *required > capacity ? 1 :
            message == "another MPI rank could not prepare the MCC step" ? 0 : 2;
        int global_kind = 0;
        MPI_Allreduce(&local_kind, &global_kind, 1, MPI_INT, MPI_MAX, comm);
        if (global_kind == 1) {
            return AP_G02_MCC_BUFFER_TOO_SMALL;
        }
        return AP_G02_MCC_PHYSICS_ERROR;
    } catch (...) {
        write_error(error_buffer, error_buffer_size, "unknown MPI MCC step error");
        int local_kind = 2, global_kind = 0;
        MPI_Allreduce(&local_kind, &global_kind, 1, MPI_INT, MPI_MAX, comm);
        return AP_G02_MCC_INTERNAL_ERROR;
    }
}

} // extern "C"
