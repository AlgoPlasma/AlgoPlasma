// SPDX-License-Identifier: Apache-2.0
#include "mpi.hpp"

#include <mpi.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <stdexcept>
#include <vector>

namespace mcc = algoplasma::mcc;

int main(int argc, char** argv) {
    int provided = MPI_THREAD_SINGLE;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    int rank = 0, ranks = 1;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &ranks);
    try {
        if (provided < MPI_THREAD_FUNNELED || argc != 5) {
            throw std::runtime_error(
                "usage: mpirun -n R mpi_collision_box MODEL TOTAL_PARTICLES REPEATS THREADS");
        }
        const auto total_particles = std::stoull(argv[2]);
        const auto repeats = std::stoi(argv[3]);
        const auto threads = static_cast<unsigned>(std::stoul(argv[4]));
        if (total_particles == 0 || repeats < 2 || threads == 0) {
            throw std::runtime_error("particle count, repeats or threads is invalid");
        }
        const mcc::MccEngine engine = mcc::MccEngine::load(std::filesystem::path(argv[1]));
        const auto species = engine.species_id("A");
        const auto state = engine.state_id(species, "ground");
        const auto gas_species = engine.species_id("B");
        const auto gas_state = engine.state_id(gas_species, "ground");
        const std::vector<mcc::CellBackground> background{{UINT32_MAX,
            {gas_species, 1e20, 300, {}, gas_state}}};
        std::vector<mcc::ParticleState> initial;
        initial.reserve(static_cast<std::size_t>(total_particles /
            static_cast<unsigned long long>(ranks) + 1));
        for (std::uint64_t id = static_cast<std::uint64_t>(rank) + 1;
             id <= total_particles; id += static_cast<std::uint64_t>(ranks)) {
            mcc::ParticleState particle;
            particle.species = species;
            particle.state = state;
            particle.id = id;
            particle.velocity = {1000, 0, 0};
            initial.push_back(particle);
        }
        mcc::StepOptions options;
        options.backend = threads == 1 ? mcc::CpuBackend::Serial : mcc::CpuBackend::OpenMp;
        options.threads = threads;
        mcc::MccStepper local(engine, options);
        mcc::MccWorkspace local_workspace;
        mcc::DistributedMccStepper distributed(engine, MPI_COMM_WORLD, options);
        std::vector<double> local_times, distributed_times;
        std::uint64_t candidates = 0, real_events = 0;
        for (int trial = -2; trial < repeats; ++trial) {
            std::vector<mcc::ParticleState> local_particles = initial;
            std::vector<mcc::ParticleState> mpi_particles = initial;
            mcc::VectorParticleAdapter local_adapter(local_particles);
            mcc::VectorParticleAdapter mpi_adapter(mpi_particles);
            MPI_Barrier(MPI_COMM_WORLD);
            const double local_start = MPI_Wtime();
            const auto local_report = local.step(local_adapter, background, 1e-7, 1, 42,
                                                 local_workspace);
            const double local_elapsed = MPI_Wtime() - local_start;
            MPI_Barrier(MPI_COMM_WORLD);
            const double mpi_start = MPI_Wtime();
            const auto mpi_report = distributed.step(mpi_adapter, background, 1e-7, 1, 42);
            const double mpi_elapsed = MPI_Wtime() - mpi_start;
            if (local_report.candidates != mpi_report.candidates ||
                local_particles.size() != mpi_particles.size()) {
                throw std::runtime_error("local and MPI outcomes differ");
            }
            for (std::size_t i = 0; i < local_particles.size(); ++i) {
                if (local_particles[i].velocity.x != mpi_particles[i].velocity.x ||
                    local_particles[i].velocity.y != mpi_particles[i].velocity.y ||
                    local_particles[i].velocity.z != mpi_particles[i].velocity.z) {
                    throw std::runtime_error("local and MPI velocities differ");
                }
            }
            double slowest_local = 0, slowest_mpi = 0;
            MPI_Reduce(&local_elapsed, &slowest_local, 1, MPI_DOUBLE, MPI_MAX, 0,
                       MPI_COMM_WORLD);
            MPI_Reduce(&mpi_elapsed, &slowest_mpi, 1, MPI_DOUBLE, MPI_MAX, 0,
                       MPI_COMM_WORLD);
            if (trial >= 0 && rank == 0) {
                local_times.push_back(slowest_local);
                distributed_times.push_back(slowest_mpi);
            }
            if (trial == 0) {
                candidates = mpi_report.candidates;
                real_events = mpi_report.real_events;
            }
        }
        std::uint64_t global_candidates = 0, global_real = 0;
        MPI_Reduce(&candidates, &global_candidates, 1, MPI_UINT64_T, MPI_SUM, 0,
                   MPI_COMM_WORLD);
        MPI_Reduce(&real_events, &global_real, 1, MPI_UINT64_T, MPI_SUM, 0,
                   MPI_COMM_WORLD);
        if (rank == 0) {
            std::sort(local_times.begin(), local_times.end());
            std::sort(distributed_times.begin(), distributed_times.end());
            const auto middle = static_cast<std::size_t>(repeats / 2);
            std::printf("ranks,threads,total_particles,local_step_s,distributed_step_s,"
                        "mpi_overhead_s,candidates,real_events\n");
            std::printf("%d,%u,%llu,%.9g,%.9g,%.9g,%llu,%llu\n", ranks, threads,
                total_particles, local_times[middle], distributed_times[middle],
                distributed_times[middle] - local_times[middle],
                static_cast<unsigned long long>(global_candidates),
                static_cast<unsigned long long>(global_real));
        }
    } catch (const std::exception& error) {
        std::fprintf(stderr, "rank %d: %s\n", rank, error.what());
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    MPI_Finalize();
    return 0;
}
