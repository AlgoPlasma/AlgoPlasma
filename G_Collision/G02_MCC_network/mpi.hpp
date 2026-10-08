// SPDX-License-Identifier: Apache-2.0
// MPI 把工作分给多个进程；rank 是进程在 communicator（通信组）中的编号。
// 每个进程推进自己持有的粒子，主程序负责空间划分、迁移和背景更新。
// MPI 并不替代 OpenMP：每个进程内部仍可用多个线程处理本地粒子。
#pragma once

#include "batch.hpp"

#include <mpi.h>
#include <string>

namespace algoplasma::mcc {

// Each rank owns its particles, cells and background. The host initializes MPI,
// preserves particle IDs during migration and calls step() on every rank.
class DistributedMccStepper {
public:
    DistributedMccStepper(MccEngine engine, MPI_Comm communicator,
                          StepOptions options = {});
    ~DistributedMccStepper();
    DistributedMccStepper(const DistributedMccStepper&) = delete;
    DistributedMccStepper& operator=(const DistributedMccStepper&) = delete;

    [[nodiscard]] StepReport step(ParticleAdapter& particles,
                                  const std::vector<CellBackground>& background,
                                  Real dt_s, std::uint64_t global_step,
                                  std::uint64_t seed);
    [[nodiscard]] MPI_Comm communicator() const noexcept { return communicator_; }

private:
    MccStepper local_;
    MccWorkspace workspace_;
    MPI_Comm communicator_{MPI_COMM_NULL};
    int rank_{0};
    int ranks_{1};
    std::uint64_t high_watermark_{0};

    void agree(bool failed, const std::string& message) const;
    [[nodiscard]] std::vector<std::uint64_t> allocate_child_ids(
        const std::vector<BirthKey>& keys, std::uint64_t global_max,
        std::uint64_t global_births) const;
};

} // namespace algoplasma::mcc
