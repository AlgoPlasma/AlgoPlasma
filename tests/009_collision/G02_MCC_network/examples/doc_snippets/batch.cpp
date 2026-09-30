// SPDX-License-Identifier: Apache-2.0
#include "mcc.hpp"
#include <iostream>
using namespace algoplasma::mcc;

int main(int argc, char** argv) {
    if (argc != 2) return 2; // argv[1]: model directory
    try {
        MccEngine engine = MccEngine::load(argv[1]);
        StepOptions options;
        options.backend = CpuBackend::Serial;
        MccStepper stepper(engine, options);
        std::vector<ParticleState> particles(1);
        particles[0].species = engine.species_id("A");
        particles[0].state = engine.state_id(particles[0].species, "ground");
        particles[0].id = 1;
        particles[0].cell = 0;
        particles[0].velocity = {1000.0, 0.0, 0.0};
        std::vector<CellBackground> background(1);
        background[0].cell = 0; // local cell; UINT32_MAX means uniform fallback
        auto& gas = background[0].component;
        gas.species = engine.species_id("B");
        gas.state = engine.state_id(gas.species, "ground");
        gas.density_m3 = 1.0e20;
        gas.temperature_k = 300.0;
        VectorParticleAdapter adapter(particles); // preserve across steps
        MccWorkspace workspace;                  // preserve across steps
        const Real dt_s = 1.0e-7;
        const std::uint64_t seed = 1234;
        // Two overloads, shown on different steps; never advance one step twice.
        auto first = stepper.step(adapter, background, dt_s, 0, seed, workspace);
        auto second = stepper.step(adapter, background, dt_s, 1, seed);
        std::cout << "PASS " << first.real_events + second.real_events << '\n';
    } catch (const std::exception& e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}
