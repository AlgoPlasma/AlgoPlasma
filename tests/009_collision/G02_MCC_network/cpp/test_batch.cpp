// SPDX-License-Identifier: Apache-2.0
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <vector>

using namespace algoplasma::mcc;

namespace {

std::vector<CellBackground> field(const MccEngine& engine, const bool spatial) {
    std::vector<CellBackground> result;
    for (const std::uint32_t cell : {0U, 1U}) {
        if (!spatial && cell == 1U) break;
        for (const auto& name : {"M", "M2", "M2+"}) {
            BackgroundComponent component;
            component.species = engine.species_id(name);
            component.state = engine.state_id(component.species, "ground");
            component.temperature_k = 300.0;
            component.density_m3 = cell == 0U && std::string(name) == "M" ? 2.0e20 : 0.0;
            result.push_back({spatial ? cell : UINT32_MAX, component});
        }
    }
    return result;
}

std::vector<BackgroundComponent> for_cell(const std::vector<CellBackground>& field,
                                          const std::uint32_t cell) {
    std::vector<BackgroundComponent> result;
    for (const auto& entry : field) {
        if (entry.cell == cell) result.push_back(entry.component);
    }
    return result;
}

} // namespace

int main(int argc, char** argv) {
    G02_REQUIRE(argc == 2);
    const MccEngine engine = MccEngine::load(std::filesystem::path(argv[1]));
    const auto background = field(engine, true);
    std::vector<ParticleState> input;
    for (std::uint64_t i = 0; i < 1024; ++i) {
        ParticleState particle;
        particle.species = engine.species_id("e-");
        particle.state = engine.state_id(particle.species, "ground");
        particle.velocity = {1.0e6, 0.0, 0.0};
        particle.id = i + 1000;
        particle.cell = static_cast<std::uint32_t>(i % 2U);
        input.push_back(particle);
    }
    input.back().birth_step = 2;

    std::vector<ParticleState> expected = input;
    std::uint64_t candidates = 0;
    std::uint64_t real_events = 0;
    for (std::size_t i = 0; i < expected.size() - 1U; ++i) {
        CollisionRequest request;
        request.projectile = input[i];
        request.background = for_cell(background, input[i].cell);
        request.dt_s = 1.0e-7;
        request.global_step = 1;
        request.seed = 42;
        const StepOutcome outcome = engine.collide_full(request, 1000000, false);
        candidates += outcome.candidates;
        real_events += outcome.real_events;
        expected[i] = outcome.primary_after;
    }

    std::vector<ParticleState> actual = input;
    VectorParticleAdapter adapter(actual);
    StepOptions options;
    options.backend = CpuBackend::Serial;
    const MccStepper stepper(engine, options);
    const StepReport report = stepper.step(adapter, background, 1.0e-7, 1, 42);
    G02_CHECK(report.particles_visited == input.size() - 1U);
    G02_CHECK(report.candidates == candidates);
    G02_CHECK(report.real_events == real_events);
    G02_CHECK(actual.size() == expected.size());
    for (std::size_t i = 0; i < expected.size(); ++i) {
        G02_CHECK(actual[i].id == expected[i].id);
        G02_CHECK(actual[i].species == expected[i].species);
        G02_CHECK(actual[i].velocity.x == expected[i].velocity.x);
        G02_CHECK(actual[i].velocity.y == expected[i].velocity.y);
        G02_CHECK(actual[i].velocity.z == expected[i].velocity.z);
    }

    ParticleBank bank(engine.model());
    for (const ParticleState& particle : input) bank.push(particle);
    SoaParticleAdapter soa(bank);
    const StepReport soa_report = stepper.step(soa, background, 1.0e-7, 1, 42);
    G02_CHECK(soa_report.candidates == report.candidates);
    G02_CHECK(soa.size() == actual.size());
    for (std::size_t i = 0; i < actual.size(); ++i) {
        G02_CHECK(soa.particle(i).id == actual[i].id);
        G02_CHECK(soa.particle(i).velocity.x == actual[i].velocity.x);
    }
    const StepReport soa_second = stepper.step(soa, background, 1.0e-7, 2, 43);
    const StepReport vector_second = stepper.step(adapter, background, 1.0e-7, 2, 43);
    G02_CHECK(soa_second.candidates == vector_second.candidates);
    G02_CHECK(soa.size() == actual.size());
    for (std::size_t i = 0; i < actual.size(); ++i) {
        G02_CHECK(soa.particle(i).velocity.x == actual[i].velocity.x);
    }
    ParticleBank externally_updated(engine.model());
    externally_updated.push(input[0]);
    SoaParticleAdapter refreshed(externally_updated);
    G02_CHECK(stepper.step(refreshed, background, 0.0, 1, 42).particles_visited == 1U);
    externally_updated.push(input[1]);
    G02_CHECK(stepper.step(refreshed, background, 0.0, 1, 42).particles_visited == 2U);
    G02_CHECK(refreshed.size() == 2U);

    std::vector<ParticleState> guarded = input;
    VectorParticleAdapter guarded_adapter(guarded);
    StepOptions low_cap;
    low_cap.max_candidates_per_particle = 1;
    low_cap.backend = CpuBackend::Serial;
    const MccStepper guarded_stepper(engine, low_cap);
    G02_CHECK_MESSAGE_CONTAINS(
        guarded_stepper.step(guarded_adapter, background, 1.0e-4, 1, 42),
        "max_candidates");
    G02_CHECK(guarded.size() == input.size());
    for (std::size_t i = 0; i < input.size(); ++i) {
        G02_CHECK(guarded[i].velocity.x == input[i].velocity.x);
    }

    guarded[1].id = guarded[0].id;
    G02_CHECK_MESSAGE_CONTAINS(
        stepper.step(guarded_adapter, background, 1.0e-7, 1, 42), "duplicate");

    std::vector<ParticleState> shuffled = input;
    std::reverse(shuffled.begin(), shuffled.end());
    VectorParticleAdapter shuffled_adapter(shuffled);
    const StepReport shuffled_report = stepper.step(
        shuffled_adapter, background, 1.0e-7, 1, 42);
    G02_CHECK(shuffled_report.candidates == report.candidates);
    G02_CHECK(shuffled_report.real_events == report.real_events);
    G02_CHECK(shuffled_report.ledger.energy_residual_j == report.ledger.energy_residual_j);
    G02_CHECK(shuffled_report.reservoir.size() == report.reservoir.size());
    std::reverse(shuffled.begin(), shuffled.end());
    for (std::size_t i = 0; i < expected.size(); ++i) {
        G02_CHECK(shuffled[i].id == expected[i].id);
        G02_CHECK(shuffled[i].velocity.x == expected[i].velocity.x);
        G02_CHECK(shuffled[i].velocity.y == expected[i].velocity.y);
        G02_CHECK(shuffled[i].velocity.z == expected[i].velocity.z);
    }

#ifdef _OPENMP
    std::vector<ParticleState> parallel = input;
    VectorParticleAdapter parallel_adapter(parallel);
    StepOptions parallel_options;
    parallel_options.backend = CpuBackend::OpenMp;
    parallel_options.threads = 4;
    const StepReport parallel_report = MccStepper(engine, parallel_options).step(
        parallel_adapter, background, 1.0e-7, 1, 42);
    G02_CHECK(parallel_report.candidates == report.candidates);
    G02_CHECK(parallel_report.real_events == report.real_events);
    G02_CHECK(parallel_report.ledger.energy_residual_j == report.ledger.energy_residual_j);
    G02_REQUIRE(parallel_report.reservoir.size() == report.reservoir.size());
    for (std::size_t i = 0; i < report.reservoir.size(); ++i) {
        G02_CHECK(parallel_report.reservoir[i].delta.kinetic_energy_j ==
                  report.reservoir[i].delta.kinetic_energy_j);
    }
    for (std::size_t i = 0; i < expected.size(); ++i) {
        G02_CHECK(parallel[i].velocity.x == expected[i].velocity.x);
        G02_CHECK(parallel[i].velocity.y == expected[i].velocity.y);
        G02_CHECK(parallel[i].velocity.z == expected[i].velocity.z);
    }
    for (const unsigned worker_count : {2U, 8U}) {
        std::vector<ParticleState> replay = input;
        VectorParticleAdapter replay_adapter(replay);
        parallel_options.threads = worker_count;
        const StepReport replay_report = MccStepper(engine, parallel_options).step(
            replay_adapter, background, 1.0e-7, 1, 42);
        G02_CHECK(replay_report.ledger.energy_residual_j == report.ledger.energy_residual_j);
        G02_CHECK(replay_report.reservoir.size() == report.reservoir.size());
        for (std::size_t i = 0; i < expected.size(); ++i) {
            G02_CHECK(replay[i].velocity.x == expected[i].velocity.x);
        }
    }
    parallel_options.threads = 4;
    std::vector<ParticleState> ionizing(512);
    const Real mass = engine.model().species.at(engine.species_id("e-")).mass_kg;
    const Real speed = std::sqrt(2.0 * 40.0 * elementary_charge_c / mass);
    for (std::size_t i = 0; i < ionizing.size(); ++i) {
        ionizing[i].species = engine.species_id("e-");
        ionizing[i].state = engine.state_id(ionizing[i].species, "ground");
        ionizing[i].velocity = {speed, 0.0, 0.0};
        ionizing[i].id = 10000U + i;
    }
    std::vector<ParticleState> ionizing_parallel = ionizing;
    VectorParticleAdapter ionizing_serial_adapter(ionizing);
    VectorParticleAdapter ionizing_parallel_adapter(ionizing_parallel);
    const auto uniform_field = field(engine, false);
    const StepReport ionizing_serial_report = stepper.step(
        ionizing_serial_adapter, uniform_field, 1.0e-7, 1, 157);
    const StepReport ionizing_parallel_report = MccStepper(engine, parallel_options).step(
        ionizing_parallel_adapter, uniform_field, 1.0e-7, 1, 157);
    G02_CHECK(ionizing_serial_report.created_particles > 0U);
    G02_CHECK(ionizing_parallel_report.created_particles == ionizing_serial_report.created_particles);
    G02_CHECK(ionizing_parallel_report.ledger.energy_residual_j ==
              ionizing_serial_report.ledger.energy_residual_j);
    G02_CHECK(ionizing_parallel.size() == ionizing.size());
    for (std::size_t i = 0; i < ionizing.size(); ++i) {
        G02_CHECK(ionizing_parallel[i].id == ionizing[i].id);
        G02_CHECK(ionizing_parallel[i].birth_step == ionizing[i].birth_step);
        G02_CHECK(ionizing_parallel[i].species == ionizing[i].species);
        G02_CHECK(ionizing_parallel[i].velocity.x == ionizing[i].velocity.x);
        G02_CHECK(ionizing_parallel[i].velocity.y == ionizing[i].velocity.y);
        G02_CHECK(ionizing_parallel[i].velocity.z == ionizing[i].velocity.z);
    }
#endif
    {
        auto files = g02test::single_channel_package(1.0e-18);
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0,1,true\n1,M,ground,0,1,true\n"
            "2,M,excited,1,1,false\n";
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n1,background,M,excited,1\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n1,M,excited,1\n";
        const auto temp = g02test::temp_package_root("batch_background_state");
        g02test::write_package(temp, files);
        const MccEngine split = MccEngine::load(temp);
        const SpeciesId m = split.species_id("M");
        const StateId m_ground = split.state_id(m, "ground");
        const StateId m_excited = split.state_id(m, "excited");
        ParticleState electron;
        electron.species = split.species_id("e-");
        electron.state = split.state_id(electron.species, "ground");
        electron.velocity = {2.0e5, 0.0, 0.0};
        electron.id = 11;
        electron.cell = 7;
        BackgroundComponent ground_gas{m, 0.0, 0.0, {}, m_ground};
        BackgroundComponent excited_gas{m, 2.0e20, 0.0, {}, m_excited};
        std::vector<ParticleState> one{electron};
        VectorParticleAdapter one_adapter(one);
        const StepReport state_report = MccStepper(split).step(
            one_adapter, {{7, ground_gas}, {7, excited_gas}}, 1.0e-7, 1, 53);
        G02_CHECK(state_report.candidates > 0U);
        G02_CHECK(state_report.real_events > 0U);
        G02_REQUIRE(state_report.reservoir.size() == 1U);
        G02_CHECK(state_report.reservoir[0].cell == 7U);
        G02_CHECK(state_report.reservoir[0].delta.state == m_excited);
        CollisionRequest long_request;
        long_request.projectile = electron;
        long_request.background = {ground_gas, excited_gas};
        long_request.dt_s = 1.0e-6;
        long_request.global_step = 1;
        long_request.seed = 53;
        const StepOutcome full = split.collide_full(long_request);
        const StepOutcome legacy = split.collide(long_request);
        G02_CHECK(full.candidates > 64U);
        G02_CHECK(legacy.candidates == 64U);
        G02_CHECK(legacy.event_limit_reached);
        std::vector<ParticleState> zero{electron};
        VectorParticleAdapter zero_adapter(zero);
        excited_gas.density_m3 = 0.0;
        const StepReport pruned = MccStepper(split).step(
            zero_adapter, {{7, ground_gas}, {7, excited_gas}}, 1.0e-7, 1, 53);
        G02_CHECK(pruned.candidates == 0U);
        std::filesystem::remove_all(temp);
    }
    {
        auto files = g02test::single_channel_package(1.0e-18);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,A,4.0e-26,0,kinetic\n1,B,4.0e-26,0,background\n"
            "2,C,4.0e-26,0,kinetic\n";
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,A,ground,0,1,true\n1,B,ground,0,1,true\n2,C,ground,0,1,true\n";
        files["composition.csv"] =
            "species,element,count\nA,X,1\nB,Y,1\nC,X,1\n";
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,conversion,C04,0,0,0,0,isotropic,,,n_body_phase_space,true\n"
            "2,converted_elastic,C02,0,0,0,0,isotropic,,,n_body_phase_space,true\n";
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,A,ground,1\n1,background,B,ground,1\n"
            "2,projectile,C,ground,1\n2,background,B,ground,1\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,C,ground,1\n1,B,ground,1\n"
            "2,C,ground,1\n2,B,ground,1\n";
        files["rate_laws.csv"] =
            "reaction_id,kind,dataset_id,x_source,x_species\n"
            "1,cross_section,ds1,relative_energy_ev,\n"
            "2,cross_section,ds1,relative_energy_ev,\n";
        files["tables/t1.csv"] = "x,y\n0,1.0e-18\n20,1.0e-18\n";
        const auto temp = g02test::temp_package_root("batch_transmutation");
        g02test::write_package(temp, files);
        const MccEngine transmuting = MccEngine::load(temp);
        CollisionRequest request;
        request.projectile.species = transmuting.species_id("A");
        request.projectile.state = transmuting.state_id(request.projectile.species, "ground");
        request.projectile.velocity = {1.0e4, 0.0, 0.0};
        request.projectile.id = 700;
        request.background.push_back({transmuting.species_id("B"), 1.0e22, 0.0,
                                      {}, transmuting.state_id(transmuting.species_id("B"),
                                                               "ground")});
        request.dt_s = 1.0e-7;
        bool crossed = false;
        for (std::uint64_t seed = 1; seed < 100 && !crossed; ++seed) {
            request.seed = seed;
            const StepOutcome full = transmuting.collide_full(request, 1000000, true);
            if (full.primary_after.species != transmuting.species_id("C")) continue;
            bool second_channel = false;
            for (const auto& event : full.events) {
                if (event.real_event && event.reaction == 2U) second_channel = true;
            }
            if (!second_channel) continue;
            const StepOutcome legacy = transmuting.collide(request);
            G02_CHECK(legacy.primary_action == PrimaryAction::MoveSpecies);
            G02_CHECK(full.primary_action == PrimaryAction::MoveSpecies);
            G02_CHECK(full.primary_after.id == request.projectile.id);
            G02_CHECK(full.real_events > legacy.real_events);
            ParticleBank moved_bank(transmuting.model());
            moved_bank.push(request.projectile);
            SoaParticleAdapter moved_adapter(moved_bank);
            const StepReport moved_report = MccStepper(transmuting).step(
                moved_adapter, {{0U, request.background[0]}},
                request.dt_s, request.global_step, request.seed);
            G02_CHECK(moved_report.candidates == full.candidates);
            G02_CHECK(moved_bank.at(request.projectile.species).size() == 0U);
            G02_CHECK(moved_bank.at(transmuting.species_id("C")).size() == 1U);
            G02_CHECK(moved_adapter.particle(0).species == transmuting.species_id("C"));
            G02_CHECK(moved_adapter.particle(0).id == request.projectile.id);
            G02_CHECK(moved_adapter.particle(0).velocity.x == full.primary_after.velocity.x);
            crossed = true;
        }
        G02_CHECK(crossed);
        std::filesystem::remove_all(temp);
    }
    return g02test::summary("test_batch");
}
