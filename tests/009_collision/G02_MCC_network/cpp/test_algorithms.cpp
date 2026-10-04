// SPDX-License-Identifier: Apache-2.0
// C02-C08 single-event verification, three-body density scaling, replay and
// background-order independence, using the two shipped demo packages.
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <algorithm>

#include <cmath>
#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>

using namespace algoplasma::mcc;
namespace fs = std::filesystem;

namespace {

struct TriggerResult {
    bool found{false};
    StepOutcome outcome{};
};

CollisionRequest make_request(const MccEngine& engine, const std::string& projectile,
                              const double energy_ev, const std::uint64_t seed,
                              const double dt_s) {
    CollisionRequest request;
    request.projectile.species = engine.species_id(projectile);
    request.projectile.state = engine.state_id(request.projectile.species, "ground");
    const Real mass = engine.model().species.at(request.projectile.species).mass_kg;
    const Real speed = std::sqrt(2.0 * energy_ev * elementary_charge_c / mass);
    request.projectile.velocity = {speed, 0.0, 0.0};
    request.projectile.id = 1234;
    request.projectile.weight = 1.0;
    request.dt_s = dt_s;
    request.global_step = 7;
    request.seed = seed;
    request.max_events_per_step = 1;
    return request;
}

void add_background(CollisionRequest& request, const MccEngine& engine, const std::string& name,
                    const double density, const double temperature = 300.0) {
    BackgroundComponent component;
    component.species = engine.species_id(name);
    component.density_m3 = density;
    component.temperature_k = temperature;
    request.background.push_back(component);
}

TriggerResult trigger(const MccEngine& engine, CollisionRequest request, const ReactionId id,
                      const int trials) {
    for (int attempt = 0; attempt < trials; ++attempt) {
        request.seed = 100000U + static_cast<std::uint64_t>(attempt);
        const StepOutcome outcome = engine.collide(request);
        for (const EventRecord& event : outcome.events) {
            if (event.real_event && event.reaction == id) {
                return TriggerResult{true, outcome};
            }
        }
    }
    return TriggerResult{};
}

void check_conservation(const StepOutcome& outcome) {
    G02_CHECK_NEAR(outcome.ledger.charge_before_c, outcome.ledger.charge_after_c, 1.0e-30);
    const Real before = norm(outcome.ledger.momentum_before_kg_m_per_s);
    const Real after = norm(outcome.ledger.momentum_after_kg_m_per_s);
    const Real error = norm(outcome.ledger.momentum_after_kg_m_per_s -
                            outcome.ledger.momentum_before_kg_m_per_s);
    G02_CHECK(error <= 1.0e-9 * (before + after + 1.0e-30));
    G02_CHECK(std::fabs(outcome.ledger.energy_residual_j) <= outcome.ledger.tolerance_j);
}

bool same_outcome(const StepOutcome& a, const StepOutcome& b) {
    if (a.primary_action != b.primary_action) return false;
    if (a.primary_after.species != b.primary_after.species) return false;
    if (a.primary_after.state != b.primary_after.state) return false;
    if (std::fabs(a.primary_after.velocity.x - b.primary_after.velocity.x) > 1.0e-9) return false;
    if (a.real_events != b.real_events || a.null_events != b.null_events) return false;
    if (a.created.size() != b.created.size()) return false;
    for (std::size_t i = 0; i < a.created.size(); ++i) {
        if (a.created[i].species != b.created[i].species) return false;
        if (a.created[i].product_ordinal != b.created[i].product_ordinal) return false;
    }
    if (a.events.size() != b.events.size()) return false;
    for (std::size_t i = 0; i < a.events.size(); ++i) {
        if (a.events[i].reaction != b.events[i].reaction) return false;
        if (a.events[i].real_event != b.events[i].real_event) return false;
    }
    return true;
}

const ChannelDiagnostics& channel(const std::vector<ChannelDiagnostics>& diagnostics,
                                  const ReactionId id) {
    for (const ChannelDiagnostics& entry : diagnostics) {
        if (entry.reaction == id) return entry;
    }
    static const ChannelDiagnostics missing{};
    return missing;
}

} // namespace

int main(int argc, char** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: test_algorithms <demo_binary_dir> <demo_three_body_dir>\n");
        return 1;
    }
    const fs::path binary_dir = argv[1];
    const fs::path three_dir = argv[2];
    const MccEngine engine = MccEngine::load(binary_dir);
    G02_REQUIRE(engine.model().reactions.size() == 7U);

    // ---- C02 elastic ------------------------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 20.0, 0, 1.0e-6);
        add_background(request, engine, "M", 2.0e20);
        add_background(request, engine, "M2", 0.0);
        add_background(request, engine, "M2+", 0.0);
        const TriggerResult result = trigger(engine, request, 1U, 3000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Update);
        G02_CHECK(result.outcome.primary_after.species == engine.species_id("e-"));
        G02_CHECK(result.outcome.primary_after.state == engine.state_id(
                       engine.species_id("e-"), "ground"));
        G02_CHECK(result.outcome.created.empty());
        check_conservation(result.outcome);
    }

    // ---- C03 discrete transition -----------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 20.0, 0, 1.0e-6);
        add_background(request, engine, "M", 2.0e20);
        add_background(request, engine, "M2", 0.0);
        add_background(request, engine, "M2+", 0.0);
        const TriggerResult result = trigger(engine, request, 2U, 3000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Update);
        G02_CHECK(result.outcome.primary_after.species == engine.species_id("e-"));
        G02_CHECK(result.outcome.ledger.internal_after_j > result.outcome.ledger.internal_before_j);
        {
            bool excited_feed = false;
            for (const ReservoirDelta& delta : result.outcome.reservoir) {
                if (delta.species == engine.species_id("M") && delta.internal_energy_j > 0.0) {
                    excited_feed = true;
                }
            }
            G02_CHECK(excited_feed);
        }
        check_conservation(result.outcome);
    }

    // ---- C04 dissociation -------------------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 20.0, 0, 1.0e-6);
        add_background(request, engine, "M", 0.0);
        add_background(request, engine, "M2", 2.0e20);
        add_background(request, engine, "M2+", 0.0);
        const TriggerResult result = trigger(engine, request, 3U, 3000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Update);
        bool has_m = false;
        bool has_m2 = false;
        for (const ReservoirDelta& delta : result.outcome.reservoir) {
            if (delta.species == engine.species_id("M")) has_m = true;
            if (delta.species == engine.species_id("M2")) has_m2 = true;
        }
        G02_CHECK(has_m);
        G02_CHECK(has_m2);
        check_conservation(result.outcome);
    }

    // ---- C05 ionization ---------------------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 40.0, 0, 1.0e-6);
        add_background(request, engine, "M", 2.0e20);
        add_background(request, engine, "M2", 0.0);
        add_background(request, engine, "M2+", 0.0);
        const TriggerResult result = trigger(engine, request, 4U, 4000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Update);
        G02_CHECK(result.outcome.created.size() == 2U);
        G02_CHECK(result.outcome.created[0].species == engine.species_id("e-"));
        G02_CHECK(result.outcome.created[0].product_ordinal == 1U);
        G02_CHECK(result.outcome.created[1].species == engine.species_id("M+"));
        G02_CHECK(result.outcome.created[1].product_ordinal == 2U);
        for (const CreatedProduct& product : result.outcome.created) {
            G02_CHECK(product.parent_id == request.projectile.id);
            G02_CHECK(product.birth_step == request.global_step + 1U);
        }
        check_conservation(result.outcome);
    }

    // ---- C06 attachment ---------------------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 1.0, 0, 1.0e-6);
        add_background(request, engine, "M", 0.0);
        add_background(request, engine, "M2", 2.0e20);
        add_background(request, engine, "M2+", 0.0);
        const TriggerResult result = trigger(engine, request, 5U, 3000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::MoveSpecies);
        G02_CHECK(result.outcome.primary_after.species == engine.species_id("M-"));
        G02_CHECK(result.outcome.primary_destination == engine.species_id("M-"));
        check_conservation(result.outcome);
    }

    // ---- C07 charge exchange (resonant identity exchange) -----------------
    {
        CollisionRequest request = make_request(engine, "M+", 10.0, 0, 1.0e-5);
        add_background(request, engine, "M", 2.0e20);
        const TriggerResult result = trigger(engine, request, 6U, 3000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Update);
        G02_CHECK(result.outcome.primary_after.species == engine.species_id("M+"));
        // The projectile must have picked up the sampled neutral velocity.
        const Real speed = norm(result.outcome.primary_after.velocity);
        G02_CHECK(speed < 2.0e4);
        check_conservation(result.outcome);
    }

    // ---- C08 recombination ------------------------------------------------
    {
        CollisionRequest request = make_request(engine, "e-", 5.0, 0, 1.0e-6);
        add_background(request, engine, "M", 0.0);
        add_background(request, engine, "M2", 0.0);
        add_background(request, engine, "M2+", 2.0e20);
        const TriggerResult result = trigger(engine, request, 7U, 2000);
        G02_REQUIRE(result.found);
        G02_CHECK(result.outcome.primary_action == PrimaryAction::Remove);
        bool has_m = false;
        bool has_ion = false;
        for (const ReservoirDelta& delta : result.outcome.reservoir) {
            if (delta.species == engine.species_id("M")) has_m = true;
            if (delta.species == engine.species_id("M2+")) has_ion = true;
        }
        G02_CHECK(has_m);
        G02_CHECK(has_ion);
        G02_CHECK(result.outcome.ledger.radiated_or_unresolved_j > 0.0);
        check_conservation(result.outcome);
    }

    // ---- RNG replay and background order independence ---------------------
    {
        CollisionRequest request = make_request(engine, "e-", 30.0, 987654321ULL, 1.0e-6);
        add_background(request, engine, "M", 2.0e20);
        add_background(request, engine, "M2", 5.0e19);
        add_background(request, engine, "M2+", 1.0e19);
        const StepOutcome first = engine.collide(request);
        const StepOutcome second = engine.collide(request);
        G02_CHECK(same_outcome(first, second));

        CollisionRequest reversed = request;
        std::reverse(reversed.background.begin(), reversed.background.end());
        const StepOutcome third = engine.collide(reversed);
        G02_CHECK(same_outcome(first, third));
    }

    // ---- product ordinal stability across background order ----------------
    {
        CollisionRequest request = make_request(engine, "e-", 40.0, 24680ULL, 1.0e-6);
        add_background(request, engine, "M", 2.0e20);
        add_background(request, engine, "M2", 0.0);
        add_background(request, engine, "M2+", 0.0);
        // Find an ionization event, then replay with reversed background order.
        bool found = false;
        StepOutcome reference;
        for (int attempt = 0; attempt < 4000 && !found; ++attempt) {
            request.seed = 700000U + static_cast<std::uint64_t>(attempt);
            const StepOutcome outcome = engine.collide(request);
            for (const EventRecord& event : outcome.events) {
                if (event.real_event && event.reaction == 4U) {
                    found = true;
                    reference = outcome;
                }
            }
        }
        G02_REQUIRE(found);
        G02_REQUIRE(reference.created.size() == 2U);
        CollisionRequest reversed = request;
        std::reverse(reversed.background.begin(), reversed.background.end());
        const StepOutcome replayed = engine.collide(reversed);
        G02_REQUIRE(replayed.created.size() == 2U);
        for (std::size_t i = 0; i < reference.created.size(); ++i) {
            G02_CHECK(reference.created[i].species == replayed.created[i].species);
            G02_CHECK(reference.created[i].product_ordinal == replayed.created[i].product_ordinal);
            G02_CHECK(reference.created[i].event_index == replayed.created[i].event_index);
        }
    }

    // ---- three-body density scaling --------------------------------------
    {
        const MccEngine three = MccEngine::load(three_dir);
        G02_REQUIRE(three.model().reactions.size() == 3U);
        const auto rates = [&](const double n_m, const double n_m2, const double n_ion) {
            CollisionRequest request = make_request(three, "e-", 1.0, 0, 1.0e-9);
            add_background(request, three, "M", n_m);
            add_background(request, three, "M2", n_m2);
            add_background(request, three, "M+", n_ion);
            return three.evaluate_channels(request);
        };

        const auto base = rates(1.0e22, 1.0e22, 1.0e22);
        const auto doubled_m = rates(2.0e22, 1.0e22, 1.0e22);
        const auto doubled_m2 = rates(1.0e22, 2.0e22, 1.0e22);

        G02_CHECK(channel(base, 1U).rate_defined);
        G02_CHECK(channel(base, 2U).rate_defined);
        G02_CHECK(channel(base, 3U).rate_defined);

        // n_M^2 channel: doubling n_M multiplies the rate by four.
        G02_CHECK_NEAR(channel(doubled_m, 1U).rate_s_inv,
                       4.0 * channel(base, 1U).rate_s_inv,
                       1.0e-9 * channel(doubled_m, 1U).rate_s_inv);
        // mixed n_M * n_M2 channel: doubling either density doubles the rate.
        G02_CHECK_NEAR(channel(doubled_m, 2U).rate_s_inv,
                       2.0 * channel(base, 2U).rate_s_inv,
                       1.0e-9 * channel(doubled_m, 2U).rate_s_inv);
        G02_CHECK_NEAR(channel(doubled_m2, 2U).rate_s_inv,
                       2.0 * channel(base, 2U).rate_s_inv,
                       1.0e-9 * channel(doubled_m2, 2U).rate_s_inv);
        // mixed n_M+ * n_M channel.
        G02_CHECK_NEAR(channel(doubled_m, 3U).rate_s_inv,
                       2.0 * channel(base, 3U).rate_s_inv,
                       1.0e-9 * channel(doubled_m, 3U).rate_s_inv);

        // Any zero density gives a zero rate and no candidates.
        const auto zero_m = rates(0.0, 1.0e22, 1.0e22);
        G02_CHECK(channel(zero_m, 1U).rate_s_inv == 0.0);
        G02_CHECK(channel(zero_m, 2U).rate_s_inv == 0.0);
        G02_CHECK(channel(zero_m, 3U).rate_s_inv == 0.0);
        CollisionRequest zero_request = make_request(three, "e-", 1.0, 0, 1.0e-6);
        add_background(zero_request, three, "M", 0.0);
        add_background(zero_request, three, "M2", 1.0e22);
        add_background(zero_request, three, "M+", 1.0e22);
        G02_CHECK(three.collide(zero_request).candidates == 0U);

        // Statistical sanity for the n^2 channel.
        const auto count = [&](const double n_m) {
            CollisionRequest request = make_request(three, "e-", 1.0, 0, 1.0e-3);
            request.max_events_per_step = 1000;
            add_background(request, three, "M", n_m);
            add_background(request, three, "M2", 0.0);
            add_background(request, three, "M+", 0.0);
            std::size_t real = 0;
            for (int attempt = 0; attempt < 300; ++attempt) {
                request.seed = 300000U + static_cast<std::uint64_t>(attempt);
                const StepOutcome outcome = three.collide(request);
                for (const EventRecord& event : outcome.events) {
                    if (event.real_event && event.reaction == 1U) ++real;
                }
            }
            return real;
        };
        const std::size_t low = count(1.0e23);
        const std::size_t high = count(2.0e23);
        G02_CHECK(low > 0U);
        // The n^2 channel must scale roughly fourfold.
        G02_CHECK_NEAR(static_cast<double>(high) / static_cast<double>(low), 4.0, 0.4);
    }

    // ---- projectile state selects the active channel set ------------------
    {
        const fs::path root = g02test::temp_package_root("algo_state");
        const fs::path dir = root / "two_state";
        g02test::write_package(dir, g02test::two_state_kinetic_package(1.0e-18, 1.0e-22));
        const MccEngine states = MccEngine::load(dir);
        const SpeciesId a = states.species_id("A");
        const StateId ground = states.state_id(a, "ground");
        const StateId excited = states.state_id(a, "excited");
        const StateId metastable = states.state_id(a, "metastable");

        const auto state_request = [&](const StateId state, const double dt) {
            CollisionRequest request;
            request.projectile.species = a;
            request.projectile.state = state;
            const Real mass = states.model().species.at(a).mass_kg;
            const Real speed = std::sqrt(2.0 * 40.0 * elementary_charge_c / mass);
            request.projectile.velocity = {speed, 0.0, 0.0};
            request.projectile.id = 77;
            request.projectile.weight = 1.0;
            request.dt_s = dt;
            request.global_step = 1;
            request.seed = 1;
            request.max_events_per_step = 4;
            BackgroundComponent background;
            background.species = states.species_id("B");
            background.density_m3 = 1.0e24;
            background.temperature_k = 0.0;
            request.background.push_back(background);
            return request;
        };

        // A ground projectile sees only the ground-only channel.
        {
            const std::vector<ChannelDiagnostics> diag =
                states.evaluate_channels(state_request(ground, 1.0e-6));
            bool has1 = false;
            bool has2 = false;
            for (const ChannelDiagnostics& entry : diag) {
                if (entry.reaction == 1U) has1 = true;
                if (entry.reaction == 2U) has2 = true;
            }
            G02_CHECK(has1);
            G02_CHECK(!has2);
            G02_CHECK(diag.size() == 1U);
        }
        // An excited projectile must not see the ground-only channel.
        {
            const std::vector<ChannelDiagnostics> diag =
                states.evaluate_channels(state_request(excited, 1.0e-6));
            bool has1 = false;
            bool has2 = false;
            for (const ChannelDiagnostics& entry : diag) {
                if (entry.reaction == 1U) has1 = true;
                if (entry.reaction == 2U) has2 = true;
            }
            G02_CHECK(!has1);
            G02_CHECK(has2);
            G02_CHECK(diag.size() == 1U);
        }
        // A state with no eligible channel produces zero candidates/events.
        {
            const StepOutcome outcome = states.collide(state_request(metastable, 1.0e-3));
            G02_CHECK(outcome.candidates == 0U);
            G02_CHECK(outcome.events.empty());
            G02_CHECK(outcome.primary_action == PrimaryAction::None);
        }
        // Only the backgrounds of active channels are required: the excited
        // channel uses background C, so a ground request supplying only B must
        // succeed while an excited request supplying only B must fail.
        {
            auto files = g02test::two_state_kinetic_package(1.0e-18, 1.0e-22);
            files["species.csv"] += "2,C,6.0e-26,0,background\n";
            files["states.csv"] += "4,C,ground,0.0,1,true\n";
            files["composition.csv"] += "C,X,1\n";
            files["reactants.csv"] =
                "reaction_id,role,species,state,stoichiometry\n"
                "1,projectile,A,ground,1\n"
                "1,background,B,ground,1\n"
                "2,projectile,A,excited,1\n"
                "2,background,C,ground,1\n";
            files["products.csv"] =
                "reaction_id,species,state,stoichiometry\n"
                "1,A,excited,1\n"
                "1,B,ground,1\n"
                "2,A,excited,1\n"
                "2,C,ground,1\n";
            const fs::path split_dir = root / "split_background";
            g02test::write_package(split_dir, files);
            const MccEngine split = MccEngine::load(split_dir);
            const SpeciesId sa = split.species_id("A");
            const auto request_for = [&](const StateId state) {
                CollisionRequest request;
                request.projectile.species = sa;
                request.projectile.state = state;
                request.projectile.velocity = {1.0e4, 0.0, 0.0};
                request.projectile.id = 9;
                request.projectile.weight = 1.0;
                request.dt_s = 1.0e-6;
                request.seed = 3;
                BackgroundComponent b;
                b.species = split.species_id("B");
                b.density_m3 = 1.0e24;
                b.temperature_k = 0.0;
                request.background.push_back(b);
                return request;
            };
            const StateId sground = split.state_id(sa, "ground");
            const StateId sexcited = split.state_id(sa, "excited");
            // Ground uses B only: fine.
            bool ground_ok = true;
            try {
                const std::vector<ChannelDiagnostics> diag =
                    split.evaluate_channels(request_for(sground));
                ground_ok = diag.size() == 1U && diag.front().reaction == 1U;
            } catch (const std::exception&) {
                ground_ok = false;
            }
            G02_CHECK(ground_ok);
            // Excited needs C, which was not supplied.
            G02_CHECK_MESSAGE_CONTAINS(split.evaluate_channels(request_for(sexcited)),
                                       "missing from the request");
        }
        // A real ground -> excited Update must rebuild channels before the
        // remaining dt, so the second real event can only be channel 2.
        {
            const CollisionRequest base = state_request(ground, 1.0e-6);
            int observed = 0;
            bool wrong_second = false;
            for (int attempt = 0; attempt < 400 && observed < 40; ++attempt) {
                CollisionRequest request = base;
                request.seed = 400000U + static_cast<std::uint64_t>(attempt);
                const StepOutcome outcome = states.collide(request);
                if (outcome.real_events < 2U) continue;
                ++observed;
                // events also contains rejected null candidates. Check the
                // first two real collisions, independently of their positions.
                std::vector<ReactionId> real_reactions;
                for (const EventRecord& event : outcome.events) {
                    if (event.real_event) real_reactions.push_back(event.reaction);
                }
                if (real_reactions.size() < 2U || real_reactions[0] != 1U ||
                    real_reactions[1] != 2U) {
                    wrong_second = true;
                }
            }
            G02_CHECK(observed >= 20);
            G02_CHECK(!wrong_second);
        }
        std::filesystem::remove_all(root);
    }

    // ---- strict resonant identity exchange --------------------------------
    {
        const fs::path root = g02test::temp_package_root("algo_identity");
        const fs::path dir = root / "resonant";
        const Vec3 drift{1.0e1, -5.0, 2.0};

        const auto run = [&drift](const fs::path& package) {
            const MccEngine engine = MccEngine::load(package);
            CollisionRequest request;
            request.projectile.species = engine.species_id("Iplus");
            request.projectile.state = engine.state_id(request.projectile.species, "ground");
            request.projectile.velocity = {1.0e3, -5.0e2, 2.0e2};
            request.projectile.id = 5;
            request.projectile.weight = 1.0;
            request.dt_s = 1.0e-5;
            request.global_step = 0;
            request.max_events_per_step = 1;
            BackgroundComponent background;
            background.species = engine.species_id("I");
            background.density_m3 = 5.0e23;
            background.temperature_k = 0.0;
            background.drift_m_per_s = drift;
            request.background.push_back(background);
            bool found = false;
            StepOutcome reference;
            for (int attempt = 0; attempt < 5000 && !found; ++attempt) {
                request.seed = 600000U + static_cast<std::uint64_t>(attempt);
                const StepOutcome outcome = engine.collide(request);
                for (const EventRecord& event : outcome.events) {
                    if (event.real_event && event.reaction == 1U) {
                        found = true;
                        reference = outcome;
                    }
                }
            }
            G02_CHECK(found);
            if (!found) return;
            G02_CHECK(reference.primary_action == PrimaryAction::Update);
            G02_CHECK(reference.primary_after.species == engine.species_id("Iplus"));
            // T=0: the sampled background velocity is exactly the drift and the
            // projectile-species product takes it.
            G02_CHECK(reference.primary_after.velocity.x == drift.x);
            G02_CHECK(reference.primary_after.velocity.y == drift.y);
            G02_CHECK(reference.primary_after.velocity.z == drift.z);
            G02_CHECK(reference.created.empty());
            check_conservation(reference);
        };

        g02test::write_package(dir, g02test::identity_exchange_package(4.0e-26, 4.0e-26));
        run(dir);

        // Product row order must not change the species-based mapping.
        const fs::path reversed = root / "reversed";
        auto files = g02test::identity_exchange_package(4.0e-26, 4.0e-26);
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,Iplus,ground,1\n"
            "1,I,ground,1\n";
        g02test::write_package(reversed, files);
        run(reversed);

        std::filesystem::remove_all(root);
    }

    // ---- ker_min is enforced for a plain two-body channel -----------------
    {
        const fs::path root = g02test::temp_package_root("algo_ker");
        const fs::path dir = root / "ker_min";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,elastic,C02,0.0,0.0,1.0,0.0,isotropic,,,n_body_phase_space,true\n";
        g02test::write_package(dir, files);
        const MccEngine ker = MccEngine::load(dir);
        CollisionRequest request = make_request(ker, "e-", 0.5, 0, 1.0e-6);
        add_background(request, ker, "M", 2.0e20, 0.0); // cold: relative energy is 0.5 eV
        bool saw_ker_min = false;
        for (int attempt = 0; attempt < 4000 && !saw_ker_min; ++attempt) {
            request.seed = 810000U + static_cast<std::uint64_t>(attempt);
            try {
                (void)ker.collide(request);
            } catch (const Error& error) {
                if (std::string(error.what()).find("ker_min") != std::string::npos) {
                    saw_ker_min = true;
                }
            }
        }
        G02_CHECK(saw_ker_min);
        std::filesystem::remove_all(root);
    }

    // ---- finite-input overflow is a hard failure --------------------------
    {
        const MccEngine three = MccEngine::load(three_dir);
        CollisionRequest request = make_request(three, "e-", 1.0, 0, 1.0e-9);
        add_background(request, three, "M", 1.0e200); // n^2 overflows to infinity
        add_background(request, three, "M2", 0.0);
        add_background(request, three, "M+", 0.0);
        G02_CHECK_MESSAGE_CONTAINS(three.evaluate_channels(request), "overflow");
        G02_CHECK_MESSAGE_CONTAINS(three.collide(request), "overflow");
    }

    return g02test::summary("test_algorithms");
}
