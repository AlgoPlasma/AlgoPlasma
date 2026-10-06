// SPDX-License-Identifier: Apache-2.0
#include "mpi.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <vector>

using namespace algoplasma::mcc;

namespace {

void require(bool condition, const char* message) {
    if (condition) return;
    std::fprintf(stderr, "MPI MCC test failure: %s\n", message);
    MPI_Abort(MPI_COMM_WORLD, 1);
}

std::vector<ParticleState> gather_particles(const std::vector<ParticleState>& local,
                                            int ranks) {
    const auto bytes = static_cast<int>(local.size() * sizeof(ParticleState));
    std::vector<int> counts(static_cast<std::size_t>(ranks));
    MPI_Allgather(&bytes, 1, MPI_INT, counts.data(), 1, MPI_INT, MPI_COMM_WORLD);
    std::vector<int> offsets(static_cast<std::size_t>(ranks));
    int total = 0;
    for (int i = 0; i < ranks; ++i) {
        offsets[static_cast<std::size_t>(i)] = total;
        total += counts[static_cast<std::size_t>(i)];
    }
    require(total % static_cast<int>(sizeof(ParticleState)) == 0, "particle bytes misaligned");
    std::vector<ParticleState> gathered(
        static_cast<std::size_t>(total / static_cast<int>(sizeof(ParticleState))));
    MPI_Allgatherv(local.data(), bytes, MPI_BYTE, gathered.data(), counts.data(),
                   offsets.data(), MPI_BYTE, MPI_COMM_WORLD);
    std::sort(gathered.begin(), gathered.end(),
              [](const auto& a, const auto& b) { return a.id < b.id; });
    return gathered;
}

void same_particles(const std::vector<ParticleState>& actual,
                    const std::vector<ParticleState>& expected) {
    require(actual.size() == expected.size(), "particle population mismatch");
    for (std::size_t i = 0; i < actual.size(); ++i) {
        require(actual[i].id == expected[i].id, "global particle ID mismatch");
        require(actual[i].species == expected[i].species, "particle species mismatch");
        require(actual[i].state == expected[i].state, "particle state mismatch");
        require(actual[i].velocity.x == expected[i].velocity.x &&
                actual[i].velocity.y == expected[i].velocity.y &&
                actual[i].velocity.z == expected[i].velocity.z,
                "particle velocity mismatch");
    }
}

} // namespace

int main(int argc, char** argv) {
    int provided = MPI_THREAD_SINGLE;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    require(provided >= MPI_THREAD_FUNNELED, "MPI thread support is insufficient");
    int rank = 0, ranks = 1;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &ranks);
    require(argc == 2, "expected model path");

    {
    const MccEngine engine = MccEngine::load(std::filesystem::path(argv[1]));
    std::vector<CellBackground> background;
    for (const char* name : {"M", "M2", "M2+"}) {
        BackgroundComponent gas;
        gas.species = engine.species_id(name);
        gas.state = engine.state_id(gas.species, "ground");
        gas.density_m3 = std::string(name) == "M" ? 2e20 : 0;
        gas.temperature_k = 300;
        background.push_back({UINT32_MAX, gas});
    }
    const SpeciesId electron = engine.species_id("e-");
    const StateId ground = engine.state_id(electron, "ground");
    const Real speed = std::sqrt(2 * 40 * elementary_charge_c /
                                 engine.model().species.at(electron).mass_kg);
    std::vector<ParticleState> initial(512);
    for (std::size_t i = 0; i < initial.size(); ++i) {
        initial[i].species = electron;
        initial[i].state = ground;
        initial[i].id = i + 1;
        initial[i].velocity = {speed, 0, 0};
    }
    std::vector<ParticleState> local;
    for (const auto& p : initial) {
        if (static_cast<int>(p.id % static_cast<std::uint64_t>(ranks)) == rank) {
            local.push_back(p);
        }
    }
    std::vector<ParticleState> serial = initial;
    VectorParticleAdapter serial_adapter(serial, 513);
    StepOptions options;
    options.backend = CpuBackend::Serial;
    const MccStepper serial_stepper(engine, options);
    MccWorkspace serial_workspace;
    DistributedMccStepper distributed(engine, MPI_COMM_WORLD, options);
    for (std::uint64_t step = 1; step <= 2; ++step) {
        VectorParticleAdapter adapter(local);
        const StepReport local_report = distributed.step(adapter, background, 1e-7, step, 157);
        const StepReport serial_report = serial_stepper.step(
            serial_adapter, background, 1e-7, step, 157, serial_workspace);
        require(local_report.particles_visited <= local.size(), "invalid local visit count");
        require(serial_report.created_particles > 0, "test did not exercise births");
        const auto global = gather_particles(local, ranks);
        same_particles(global, serial);
        local.clear();
        for (const auto& particle : global) {
            const auto owner = static_cast<int>(
                (particle.id + step) % static_cast<std::uint64_t>(ranks));
            if (owner == rank) local.push_back(particle);
        }
    }

    const std::vector<ParticleState> before_failure = local;
    std::vector<CellBackground> invalid = background;
    if (rank == 0) invalid.front().component.density_m3 = -1;
    VectorParticleAdapter adapter(local);
    bool failed = false;
    try {
        (void)distributed.step(adapter, invalid, 1e-7, 3, 157);
    } catch (const Error&) { failed = true; }
    require(failed, "one-rank invalid background did not fail collectively");
    same_particles(gather_particles(local, ranks), gather_particles(before_failure, ranks));
    (void)distributed.step(adapter, background, 1e-7, 3, 157);
    (void)serial_stepper.step(serial_adapter, background, 1e-7, 3, 157, serial_workspace);
    same_particles(gather_particles(local, ranks), serial);

    std::vector<ParticleState> tiny;
    if (rank == 0) tiny.push_back(initial.front());
    VectorParticleAdapter tiny_adapter(tiny);
    DistributedMccStepper empty_ranks(engine, MPI_COMM_WORLD, options);
    const StepReport zero = empty_ranks.step(tiny_adapter, background, 0, 4, 157);
    require(zero.particles_visited == (rank == 0 ? 1U : 0U), "empty rank accounting");
    }
    MPI_Finalize();
    return 0;
}
