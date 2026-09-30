// SPDX-License-Identifier: Apache-2.0
#include "package_builder.hpp"

#include "mcc.hpp"

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <vector>

using namespace algoplasma::mcc;

int main(int argc, char** argv) {
    if (argc != 5 && argc != 6) {
        std::fprintf(stderr, "usage: bench_batch PARTICLES CHANNELS REPEATS THREADS [prefix|alias]\n");
        return 2;
    }
    const std::size_t particle_count = std::stoull(argv[1]);
    const std::size_t channel_count = std::stoull(argv[2]);
    const int repeats = std::stoi(argv[3]);
    const unsigned threads = static_cast<unsigned>(std::stoul(argv[4]));
    const std::string sampler = argc == 6 ? argv[5] : "prefix";
    if (particle_count == 0 || channel_count == 0 || repeats < 2 || threads == 0) return 2;
    if (sampler != "prefix" && sampler != "alias") return 2;

    const double channel_sigma = 2.0e-20 / static_cast<double>(channel_count);
    auto files = g02test::single_channel_package(channel_sigma);
    std::string reactions =
        "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
        "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n";
    std::string reactants = "reaction_id,role,species,state,stoichiometry\n";
    std::string products = "reaction_id,species,state,stoichiometry\n";
    std::string rate_laws = "reaction_id,kind,dataset_id,x_source,x_species\n";
    for (std::size_t i = 1; i <= channel_count; ++i) {
        const std::string id = std::to_string(i);
        reactions += id + ",elastic_" + id + ",C02,0,0,0,0,isotropic,,,"
                     "n_body_phase_space,true\n";
        reactants += id + ",projectile,e-,ground,1\n" + id + ",background,M,ground,1\n";
        products += id + ",e-,ground,1\n" + id + ",M,ground,1\n";
        rate_laws += id + ",cross_section,ds1,relative_energy_ev,\n";
    }
    files["reactions.csv"] = reactions;
    files["reactants.csv"] = reactants;
    files["products.csv"] = products;
    files["rate_laws.csv"] = rate_laws;
    const std::string sigma = g02test::number(channel_sigma);
    files["tables/t1.csv"] = "x,y\n0," + sigma + "\n5," + sigma + "\n";

    const auto root = g02test::temp_package_root("bench");
    const auto package = root / "model";
    g02test::write_package(package, files);
    const MccEngine engine = MccEngine::load(package);
    std::vector<ParticleState> initial(particle_count);
    const SpeciesId electron = engine.species_id("e-");
    const StateId ground = engine.state_id(electron, "ground");
    for (std::size_t i = 0; i < particle_count; ++i) {
        initial[i].species = electron;
        initial[i].state = ground;
        initial[i].velocity = {1.0e6, 0.0, 0.0};
        initial[i].id = static_cast<std::uint64_t>(i + 1U);
    }
    BackgroundComponent gas;
    gas.species = engine.species_id("M");
    gas.state = engine.state_id(gas.species, "ground");
    gas.density_m3 = 2.0e20;
    gas.temperature_k = 0.0;
    const std::vector<CellBackground> background{{UINT32_MAX, gas}};
    std::printf("particles,channels,threads,sampler,median_step_s,preparation_s,sampling_s,"
                "reduction_s,commit_s,candidates,real_events\n");
    for (const unsigned workers : {1U, threads}) {
        StepOptions options;
        options.backend = workers == 1U ? CpuBackend::Serial : CpuBackend::OpenMp;
        options.threads = workers;
        options.sampler = sampler == "alias" ? ChannelSampler::Alias : ChannelSampler::Prefix;
        MccStepper stepper(engine, options);
        MccWorkspace workspace;
        std::vector<StepReport> measured;
        for (int trial = -3; trial < repeats; ++trial) {
            std::vector<ParticleState> particles = initial;
            VectorParticleAdapter adapter(particles);
            StepReport report = stepper.step(adapter, background, 2.0e-7, 0, 42,
                                             workspace);
            if (trial >= 0) measured.push_back(std::move(report));
        }
        std::sort(measured.begin(), measured.end(), [](const auto& a, const auto& b) {
            return a.total_seconds < b.total_seconds;
        });
        const StepReport& middle = measured[measured.size() / 2U];
        std::printf("%zu,%zu,%u,%s,%.9g,%.9g,%.9g,%.9g,%.9g,%llu,%llu\n", particle_count,
                    channel_count, workers, sampler.c_str(), middle.total_seconds,
                    middle.preparation_seconds,
                    middle.sampling_seconds,
                    middle.reduction_seconds,
                    middle.commit_seconds,
                    static_cast<unsigned long long>(middle.candidates),
                    static_cast<unsigned long long>(middle.real_events));
    }
    std::filesystem::remove_all(root);
    return 0;
}
