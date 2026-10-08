// SPDX-License-Identifier: Apache-2.0
// C01 continuous-time exponential candidate clock: Poisson statistics,
// multi-channel ratios, null fraction, majorant violation and the event cap.
// Analytical basis: exponential competing-event clocks (Gillespie 1977,
// doi:10.1021/j100540a008) with null-collision thinning (Skullerud 1968).
// These are synthetic probability checks, not a published gas benchmark.
// See docs/source/rst_files/G_Collision/G02_MCC_network/references.rst.
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"
#include "rng.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <utility>

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

// Constant k(T) makes nu = density * k independent of the velocity changes
// after elastic events. Constant cross sections alone would not give this.
g02test::FileMap constant_rate_package() {
    g02test::FileMap files = g02test::two_channel_package(2.0e-15, 1.0e-15);
    files["rate_laws.csv"] =
        "reaction_id,kind,dataset_id,x_source,x_species\n"
        "1,rate_coefficient,ds1,temperature_k,M\n"
        "2,rate_coefficient,ds2,temperature_k,M\n";
    files["datasets.csv"] =
        "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
        "above_max_policy,source,version,license,notes\n"
        "ds1,tables/t1.csv,temperature,K,m3/s,linear,error,error,fixture,1,CC0-1.0,test only\n"
        "ds2,tables/t2.csv,temperature,K,m3/s,linear,error,error,fixture,1,CC0-1.0,test only\n";
    files["tables/t1.csv"] = "x,y\n0,2e-15\n1000,2e-15\n";
    files["tables/t2.csv"] = "x,y\n0,1e-15\n1000,1e-15\n";
    return files;
}

struct PoissonCounts {
    std::size_t trials{0};
    std::uint64_t total{0};
    std::uint64_t squared{0};
    std::array<std::size_t, 3> bins{}; // zero, one, at least two events

    void add(const std::uint32_t count) {
        ++trials;
        total += count;
        squared += static_cast<std::uint64_t>(count) * count;
        ++bins[count < 2U ? count : 2U];
    }
};

void check_poisson(const PoissonCounts& counts, const char* label, const double mean) {
    const double n = static_cast<double>(counts.trials);
    const double observed_mean = static_cast<double>(counts.total) / n;
    const double observed_variance = (static_cast<double>(counts.squared) -
        n * observed_mean * observed_mean) / (n - 1.0);
    G02_CHECK_NEAR(observed_mean, mean, 6.0 * std::sqrt(mean / n));
    // For Poisson samples the fourth central moment is mean + 3*mean^2.
    G02_CHECK_NEAR(observed_variance, mean,
                   6.0 * std::sqrt((mean + 2.0 * mean * mean) / n));
    const double p_zero = std::exp(-mean);
    const std::array<double, 3> expected{p_zero, mean * p_zero,
                                        1.0 - (1.0 + mean) * p_zero};
    for (std::size_t bin = 0; bin < expected.size(); ++bin) {
        const double probability = expected[bin];
        const double observed = static_cast<double>(counts.bins[bin]) / n;
        G02_CHECK_NEAR(observed, probability,
                       6.0 * std::sqrt(probability * (1.0 - probability) / n) + 1.0 / n);
    }
    std::printf("Poisson %s: mean=%.6f variance=%.6f P0=%.6f P1=%.6f P>=2=%.6f\n",
        label, observed_mean, observed_variance,
        static_cast<double>(counts.bins[0]) / n,
        static_cast<double>(counts.bins[1]) / n,
        static_cast<double>(counts.bins[2]) / n);
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

    // ---- tuple domains: swapping any two positions must not reuse a stream
    {
        const std::array<std::uint64_t, 5> keys{17, 3, 11, 1, 4};
        const auto stream = [](const std::array<std::uint64_t, 5>& tuple) {
            return CounterRng(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4]);
        };
        CounterRng first = stream(keys);
        CounterRng replay = stream(keys);
        for (unsigned draw = 0; draw < 8U; ++draw) {
            G02_CHECK(first.next_u64() == replay.next_u64());
        }
        for (std::size_t a = 0; a < keys.size(); ++a) {
            for (std::size_t b = a + 1; b < keys.size(); ++b) {
                auto swapped = keys;
                std::swap(swapped[a], swapped[b]);
                CounterRng original = stream(keys);
                CounterRng changed = stream(swapped);
                bool different = false;
                for (unsigned draw = 0; draw < 4U; ++draw) {
                    different |= original.next_u64() != changed.next_u64();
                }
                G02_CHECK(different);
            }
        }
        // Engine slots 1/2/3/4 mean clock/selection/acceptance/final state.
        // Previously all addresses with event_index == slot collapsed together.
        CounterRng clock(42, 1, 11, 1, 1);
        CounterRng select(42, 1, 11, 2, 2);
        CounterRng accept(42, 1, 11, 3, 3);
        CounterRng final_state(42, 1, 11, 4, 4);
        const auto clock_draw = clock.next_u64();
        const auto select_draw = select.next_u64();
        const auto accept_draw = accept.next_u64();
        const auto final_draw = final_state.next_u64();
        G02_CHECK(clock_draw != select_draw);
        G02_CHECK(clock_draw != accept_draw);
        G02_CHECK(clock_draw != final_draw);
        G02_CHECK(select_draw != accept_draw);
        G02_CHECK(select_draw != final_draw);
        G02_CHECK(accept_draw != final_draw);
    }

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

    // ---- multi-event Poisson clock and independent thinning ---------------
    {
        const fs::path rate_dir = root / "constant_rates";
        g02test::write_package(rate_dir, constant_rate_package());
        CompileOptions options;
        options.majorant_safety_factor = 2.0;
        const MccEngine rate_engine = MccEngine::load(rate_dir, options);
        constexpr double density = 1.0e20;
        constexpr double physical_rate = density * (2.0e-15 + 1.0e-15);
        CollisionRequest request = make_request(rate_engine, 424242, density,
                                                1.0 / physical_rate);
        const auto channels = rate_engine.evaluate_channels(request);
        G02_REQUIRE(channels.size() == 2U);
        G02_CHECK_NEAR(channels[0].rate_s_inv + channels[1].rate_s_inv,
                       physical_rate, physical_rate * 1.0e-12);
        G02_CHECK_NEAR(channels[0].majorant_s_inv + channels[1].majorant_s_inv,
                       2.0 * physical_rate, physical_rate * 1.0e-12);

        constexpr std::size_t trials = 100000;
        PoissonCounts candidates, real_events;
        std::uint64_t real_a = 0, real_b = 0;
        bool consistent = true;
        for (std::size_t i = 0; i < trials; ++i) {
            request.projectile.id = i + 1;
            const StepOutcome outcome = rate_engine.collide_full(request, 1000, true);
            candidates.add(outcome.candidates);
            real_events.add(outcome.real_events);
            consistent &= !outcome.event_limit_reached &&
                outcome.candidates == outcome.real_events + outcome.null_events;
            for (const EventRecord& event : outcome.events) {
                if (!event.real_event) continue;
                if (event.reaction == 1U) ++real_a;
                if (event.reaction == 2U) ++real_b;
            }
        }
        G02_CHECK(consistent);
        G02_REQUIRE(real_a + real_b == real_events.total);
        G02_REQUIRE(real_events.total > 0U);
        // nu*dt=1 and the majorant is 2*nu. Both the clock and the thinned
        // real-event counts must have the complete Poisson distribution.
        check_poisson(candidates, "candidates (expected 2)", 2.0);
        check_poisson(real_events, "real events (expected 1)", 1.0);
        const double fraction_a = static_cast<double>(real_a) /
                                  static_cast<double>(real_events.total);
        G02_CHECK_NEAR(fraction_a, 2.0 / 3.0,
            6.0 * std::sqrt((2.0 / 3.0) * (1.0 / 3.0) /
                            static_cast<double>(real_events.total)));
        std::printf("Multi-event channel 1 fraction: %.6f (expected %.6f)\n",
                    fraction_a, 2.0 / 3.0);
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
