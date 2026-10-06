// SPDX-License-Identifier: Apache-2.0
#include "mcc.hpp"

#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <vector>

using namespace algoplasma::mcc;

int main(int argc, char** argv) {
    if (argc != 2) throw std::runtime_error("usage: g02_mcc_host_pic MODEL_DIR");
    const MccEngine engine = MccEngine::load(argv[1]);
    StepOptions options;
    options.backend = CpuBackend::Auto;
    const MccStepper stepper(engine, options);
    MccWorkspace workspace;

    std::vector<ParticleState> particles(1);
    particles[0].species = engine.species_id("e-");
    particles[0].state = engine.state_id(particles[0].species, "ground");
    particles[0].velocity = {2.0e6, 0.0, 0.0};
    particles[0].id = 1;
    VectorParticleAdapter adapter(particles);

    std::vector<CellBackground> background;
    for (const Species& species : engine.model().species.all()) {
        if (species.representation != Representation::Background) continue;
        BackgroundComponent component;
        component.species = species.id;
        component.state = engine.state_id(species.id, "ground");
        component.density_m3 = species.name == "M" ? 2.0e20 : 0.0;
        component.temperature_k = 300.0;
        background.push_back({UINT32_MAX, component});
    }

    for (std::uint64_t step = 0; step < 3; ++step) {
        const StepReport result = stepper.step(adapter, background, 1.0e-8, step, 1234,
                                               workspace);
        std::cout << "step=" << step << " particles=" << particles.size()
                  << " candidates=" << result.candidates
                  << " real=" << result.real_events << '\n';
        // The host applies result.reservoir to its fluid/background solver here.
    }
}
