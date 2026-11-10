// SPDX-License-Identifier: Apache-2.0
#include "mcc.hpp"
#include "package_builder.hpp"
#include "test_util.hpp"

#include <cstdlib>
#include <filesystem>
#include <new>
#include <vector>

// Isolated to this serial test executable. Fail one allocation while the
// workspace grows its per-slot live flags from 2 to 257 bytes.
namespace { bool fail_live_flags = false; }
void* operator new(std::size_t size) {
    if (fail_live_flags && size == 257) {
        fail_live_flags = false;
        throw std::bad_alloc{};
    }
    if (void* p = std::malloc(size ? size : 1)) return p;
    throw std::bad_alloc{};
}
void operator delete(void* p) noexcept { std::free(p); }
void operator delete(void* p, std::size_t) noexcept { std::free(p); }

int main() {
    using namespace algoplasma::mcc;
    const auto root = g02test::temp_package_root("batch_retry");
    g02test::write_package(root, g02test::two_channel_package(2.e-20, 1.e-20));
    const auto engine = MccEngine::load(root);
    StepOptions options;
    options.backend = CpuBackend::Serial;
    const MccStepper stepper(engine, options);
    MccWorkspace workspace;
    ParticleState electron;
    electron.species = engine.species_id("e-");
    electron.state = engine.state_id(electron.species, "ground");
    electron.velocity.x = 2.e5;
    std::vector<ParticleState> particles(2, electron);
    particles[0].id = 2;
    particles[1].id = 1;
    VectorParticleAdapter adapter(particles);
    BackgroundComponent gas;
    gas.species = engine.species_id("M");
    gas.state = engine.state_id(gas.species, "ground");
    gas.density_m3 = 2.e20;
    const std::vector<CellBackground> background{{UINT32_MAX, gas}};
    (void)stepper.step(adapter, background, 1.e-6, 1, 42, workspace);
    particles.assign(257, electron);
    // Keep the first two IDs identical so a stale cache would try slot 3.
    particles[0].id = 2;
    particles[1].id = 1;
    for (std::size_t i = 2; i < particles.size(); ++i) particles[i].id = 259 - i;
    auto reference = particles;
    fail_live_flags = true;
    bool failed = false;
    try { (void)stepper.step(adapter, background, 1.e-6, 2, 42, workspace); }
    catch (const std::bad_alloc&) { failed = true; }
    fail_live_flags = false;
    G02_REQUIRE(failed);
    VectorParticleAdapter reference_adapter(reference);
    const auto expected = stepper.step(reference_adapter, background, 1.e-6, 2, 42);
    const auto retry = stepper.step(adapter, background, 1.e-6, 2, 42, workspace);
    G02_CHECK(retry.particles_visited == 257);
    G02_CHECK(retry.candidates == expected.candidates);
    G02_CHECK(retry.by_reaction == expected.by_reaction);
    G02_REQUIRE(particles.size() == reference.size());
    for (std::size_t i = 0; i < particles.size(); ++i) {
        G02_CHECK(particles[i].id == reference[i].id);
        G02_CHECK(particles[i].velocity.x == reference[i].velocity.x);
        G02_CHECK(particles[i].velocity.y == reference[i].velocity.y);
        G02_CHECK(particles[i].velocity.z == reference[i].velocity.z);
    }
    std::filesystem::remove_all(root);
    return g02test::summary("test_batch_retry");
}
