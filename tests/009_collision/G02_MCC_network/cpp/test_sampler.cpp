// SPDX-License-Identifier: Apache-2.0
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <cmath>
#include <cstdint>
#include <filesystem>
#include <vector>

using namespace algoplasma::mcc;

int main() {
    const auto root = g02test::temp_package_root("sampler");
    g02test::write_package(root, g02test::two_channel_package(2.0e-20, 1.0e-20));
    const MccEngine engine = MccEngine::load(root);
    std::vector<ParticleState> initial(20000);
    const SpeciesId electron = engine.species_id("e-");
    const StateId ground = engine.state_id(electron, "ground");
    for (std::size_t i = 0; i < initial.size(); ++i) {
        initial[i].species = electron;
        initial[i].state = ground;
        initial[i].velocity = {2.0e5, 0.0, 0.0};
        initial[i].id = i + 1;
    }
    BackgroundComponent gas;
    gas.species = engine.species_id("M");
    gas.state = engine.state_id(gas.species, "ground");
    gas.density_m3 = 2.0e20;
    gas.temperature_k = 0.0;
    std::vector<CellBackground> background{{UINT32_MAX, gas}};

    StepOptions options;
    options.backend = CpuBackend::Serial;
    options.sampler = ChannelSampler::Alias;
    MccStepper serial(engine, options);
    MccWorkspace workspace;
    std::vector<ParticleState> particles = initial;
    VectorParticleAdapter adapter(particles);
    const StepReport report = serial.step(adapter, background, 1.0e-6, 1, 42, workspace);
    G02_CHECK(report.real_events > 10000);
    G02_REQUIRE(report.by_reaction.size() == 2);
    const auto first = report.by_reaction[0].second;
    const auto second = report.by_reaction[1].second;
    G02_CHECK(first + second == report.real_events);
    G02_CHECK(std::abs(static_cast<double>(first) /
                       static_cast<double>(report.real_events) - 2.0 / 3.0) < 0.03);

#ifdef _OPENMP
    options.backend = CpuBackend::OpenMp;
    options.threads = 4;
    MccStepper parallel(engine, options);
    std::vector<ParticleState> parallel_particles = initial;
    VectorParticleAdapter parallel_adapter(parallel_particles);
    MccWorkspace parallel_workspace;
    const StepReport parallel_report = parallel.step(parallel_adapter, background, 1.0e-6,
                                                     1, 42, parallel_workspace);
    G02_CHECK(parallel_report.candidates == report.candidates);
    G02_CHECK(parallel_report.by_reaction == report.by_reaction);
    for (std::size_t i = 0; i < particles.size(); ++i) {
        G02_CHECK(parallel_particles[i].velocity.x == particles[i].velocity.x);
        G02_CHECK(parallel_particles[i].velocity.y == particles[i].velocity.y);
        G02_CHECK(parallel_particles[i].velocity.z == particles[i].velocity.z);
    }
#endif

    background[0].component.density_m3 = 0;
    const StepReport no_gas = serial.step(adapter, background, 1.0e-6, 2, 42, workspace);
    G02_CHECK(no_gas.candidates == 0);
    G02_CHECK(no_gas.real_events == 0);
    G02_CHECK(no_gas.created_particles == 0);
    background[0].component.density_m3 = gas.density_m3;
    const StepReport restored = serial.step(adapter, background, 1.0e-6, 3, 42, workspace);
    G02_CHECK(restored.real_events > 0);

    options.backend = CpuBackend::Serial;
    options.sampler = ChannelSampler::Prefix;
    MccStepper prefix(engine, options);
    particles = initial;
    const StepReport prefix_report = prefix.step(adapter, background, 1.0e-6, 1, 42, workspace);
    G02_CHECK(prefix_report.real_events > 10000);
    G02_CHECK(prefix_report.by_reaction.size() == 2);
    std::filesystem::remove_all(root);
    return g02test::summary("test_sampler");
}
