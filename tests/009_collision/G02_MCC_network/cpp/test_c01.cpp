// SPDX-License-Identifier: Apache-2.0
// C01 continuous-time exponential candidate clock: Poisson statistics,
// multi-channel ratios, null fraction, majorant violation and the event cap.
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <cmath>
#include <cstdint>
#include <filesystem>

using namespace algoplasma::mcc;
namespace fs = std::filesystem;

namespace {

constexpr double kEnergyEv = 0.9;
constexpr double kSigmaA = 2.0e-20;
constexpr double kSigmaB = 1.0e-20;

CollisionRequest make_request(const MccEngine& engine, const std::uint64_t seed,
                              const double density, const double dt) {
    CollisionRequest request;
    request.projectile.species = engine.species_id("e-");
    request.projectile.state = engine.state_id(request.projectile.species, "ground");
    const Real speed = std::sqrt(2.0 * kEnergyEv * elementary_charge_c / electron_mass_kg);
    request.projectile.velocity = {speed, 0.0, 0.0};
    request.projectile.id = 11;
    request.projectile.weight = 1.0;
    request.dt_s = dt;
    request.global_step = 0;
    request.seed = seed;
    BackgroundComponent component;
    component.species = engine.species_id("M");
    component.density_m3 = density;
    component.temperature_k = 300.0;
    request.background.push_back(component);
    return request;
}

double five_sigma(const double probability, const std::size_t trials) {
    return 5.0 * std::sqrt(probability * (1.0 - probability) / static_cast<double>(trials));
}

} // namespace

int main() {
    const fs::path root = g02test::temp_package_root("c01");
    const fs::path dir = root / "two_channel";
    g02test::write_package(dir, g02test::two_channel_package(kSigmaA, kSigmaB));
    const MccEngine engine = MccEngine::load(dir);

    const double v1 = std::sqrt(2.0 * 1.0 * elementary_charge_c / electron_mass_kg);
    const double lambda = 1.0e20 * 1.05 * v1 * (kSigmaA + kSigmaB);
    G02_CHECK(lambda > 0.0);

    // ---- deterministic replay --------------------------------------------
    {
        const CollisionRequest request = make_request(engine, 4242, 1.0e20, 1.0e-6);
        const StepOutcome first = engine.collide(request);
        const StepOutcome second = engine.collide(request);
        G02_CHECK(first.candidates == second.candidates);
        G02_CHECK(first.real_events == second.real_events);
        G02_CHECK(first.null_events == second.null_events);
        G02_CHECK(first.events.size() == second.events.size());
        for (std::size_t i = 0; i < first.events.size(); ++i) {
            G02_CHECK(first.events[i].reaction == second.events[i].reaction);
            G02_CHECK(first.events[i].real_event == second.events[i].real_event);
            G02_CHECK(first.events[i].null_event == second.events[i].null_event);
        }
    }

    // ---- Poisson no-event statistics -------------------------------------
    {
        // p = 1 - exp(-Lambda dt) with p = 0.01.
        const double dt = -std::log(0.99) / lambda;
        const std::size_t trials = 200000;
        std::size_t with_candidate = 0;
        for (std::size_t i = 0; i < trials; ++i) {
            const CollisionRequest request =
                make_request(engine, 900000 + i, 1.0e20, dt);
            const StepOutcome outcome = engine.collide(request);
            if (outcome.candidates > 0U) ++with_candidate;
        }
        const double observed = static_cast<double>(with_candidate) /
                                static_cast<double>(trials);
        const double error = five_sigma(0.01, trials);
        G02_CHECK(std::fabs(observed - 0.01) <= error);
    }

    // ---- multi-channel ratio and null fraction ---------------------------
    {
        const std::size_t trials = 40000;
        std::size_t real_a = 0;
        std::size_t real_b = 0;
        std::size_t nulls = 0;
        std::size_t total = 0;
        for (std::size_t i = 0; i < trials; ++i) {
            CollisionRequest request = make_request(engine, 500000 + i, 1.0e20, 1.0e-6);
            request.max_events_per_step = 1;
            const StepOutcome outcome = engine.collide(request);
            if (outcome.events.empty()) continue;
            ++total;
            const EventRecord& event = outcome.events.front();
            if (event.null_event) {
                ++nulls;
            } else if (event.reaction == 1U) {
                ++real_a;
            } else if (event.reaction == 2U) {
                ++real_b;
            }
        }
        G02_CHECK(total > 0);
        const double ratio = static_cast<double>(real_a) /
                             static_cast<double>(real_a + real_b);
        const double ratio_error = 5.0 * std::sqrt((2.0 / 3.0) * (1.0 / 3.0) /
                                                   static_cast<double>(real_a + real_b));
        G02_CHECK(std::fabs(ratio - 2.0 / 3.0) <= ratio_error);

        const double expected_null = 1.0 - (std::sqrt(kEnergyEv / 1.0) / 1.05);
        const double null_fraction = static_cast<double>(nulls) / static_cast<double>(total);
        G02_CHECK(std::fabs(null_fraction - expected_null) <=
                  5.0 * std::sqrt(expected_null * (1.0 - expected_null) /
                                  static_cast<double>(total)) + 0.01);
    }

    // ---- majorant violation is a hard error ------------------------------
    {
        CompileOptions options;
        options.diagnostic_majorant_scale = 0.5;
        const MccEngine broken = MccEngine::load(dir, options);
        const CollisionRequest request = make_request(broken, 17, 1.0e20, 1.0e-3);
        G02_CHECK_MESSAGE_CONTAINS(broken.collide(request), "majorant");
    }

    // ---- event cap --------------------------------------------------------
    {
        const CollisionRequest request = make_request(engine, 3, 1.0e22, 1.0e-3);
        const StepOutcome outcome = engine.collide(request);
        G02_CHECK(outcome.candidates == 64U);
        G02_CHECK(outcome.event_limit_reached);
    }
    {
        CollisionRequest request = make_request(engine, 3, 1.0e22, 1.0e-3);
        request.max_events_per_step = 5;
        const StepOutcome outcome = engine.collide(request);
        G02_CHECK(outcome.candidates == 5U);
        G02_CHECK(outcome.event_limit_reached);
    }

    // ---- degenerate cases -------------------------------------------------
    {
        const CollisionRequest request = make_request(engine, 3, 1.0e20, 0.0);
        const StepOutcome outcome = engine.collide(request);
        G02_CHECK(outcome.candidates == 0U);
        G02_CHECK(outcome.events.empty());
        G02_CHECK(outcome.primary_action == PrimaryAction::None);
    }
    {
        const CollisionRequest request = make_request(engine, 3, 0.0, 1.0e-3);
        const StepOutcome outcome = engine.collide(request);
        G02_CHECK(outcome.candidates == 0U);
    }

    std::filesystem::remove_all(root);
    return g02test::summary("test_c01");
}
