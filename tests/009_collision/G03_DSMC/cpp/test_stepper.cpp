// SPDX-License-Identifier: Apache-2.0
#include "test_support.hpp"
#include <array>

namespace test {
namespace {
constexpr std::array types{ElasticModel::HS, ElasticModel::VHS, ElasticModel::VSS};
constexpr std::array clocks{CandidateSchedule::RoundedNtc, CandidateSchedule::ContinuousClock};

void report_checks(const StepReport& report, const CylindricalGrid& mesh,
                   CandidateSchedule clock, Real dt) {
    require(report.by_cell.size() == mesh.cells().size(), "empty cells retained in report");
    std::uint64_t candidates = 0, accepted = 0, rejected = 0;
    for (std::size_t i = 0; i < report.by_cell.size(); ++i) {
        const auto& cell = report.by_cell[i];
        require(cell.cell_id == mesh.cells()[i].global_id, "report cell order");
        require(cell.candidates == cell.accepted+cell.rejected, "cell event accounting");
        candidates += cell.candidates;
        accepted += cell.accepted;
        rejected += cell.rejected;
    }
    require(report.candidates == candidates && report.accepted == accepted &&
            report.rejected == rejected, "whole-step event accounting");
    for (std::size_t i = 0; i < report.events.size(); ++i) {
        const auto& event = report.events[i];
        require(event.first_id != event.second_id, "no self collisions");
        const auto p0 = event.before[0]+event.before[1], p1 = event.after[0]+event.after[1];
        const auto energy = dot(event.before[0], event.before[0])+dot(event.before[1], event.before[1]);
        close(norm(p1-p0), 0, 0, 2e-14*std::sqrt(energy), "event pair momentum");
        close(dot(event.after[0], event.after[0])+dot(event.after[1], event.after[1]),
              energy, 3e-14, 0, "event pair kinetic energy");
        if (clock == CandidateSchedule::ContinuousClock) {
            require(event.time_offset_s && *event.time_offset_s >= 0 && *event.time_offset_s <= dt,
                    "continuous event lies inside substep");
            if (i && report.events[i-1].cell_id == event.cell_id) {
                require(*event.time_offset_s >= *report.events[i-1].time_offset_s,
                        "cell event time ordering");
            }
        } else {
            require(!event.time_offset_s, "rounded NTC has no event timestamp");
        }
    }
}
} // namespace

void conservation() {
    const auto mesh = grid();
    for (const auto type : types) {
        for (const auto clock : clocks) {
            auto particles = cloud(128, 1e6);
            const auto initial = particles;
            const auto before = moments(particles, {1e6, 0, 0});
            StepOptions options;
            options.candidate_schedule = clock;
            options.record_events = true;
            DsmcStepper stepper(DsmcModel(argon, 1e10, parameters(type)), options);
            DsmcWorkspace work;
            std::uint64_t accepted = 0;
            for (std::uint64_t step = 0; step < 48; ++step) {
                const auto report = stepper.step(particles, mesh, {1e-5, step, 812, 0}, work);
                report_checks(report, mesh, clock, 1e-5);
                require(report.max_relative_energy_error <= options.conservation_tolerance &&
                        report.max_relative_momentum_error <= options.conservation_tolerance,
                        "reported thermal-scale conservation");
                accepted += report.accepted;
            }
            require(accepted > 100, "conservation run exercised collisions");
            conserved(before, moments(particles, {1e6, 0, 0}), particles.size(), 2e-8);
            for (std::size_t i = 0; i < particles.size(); ++i) {
                require(particles[i].id == initial[i].id && particles[i].species_id == initial[i].species_id &&
                        particles[i].position.r_m == initial[i].position.r_m &&
                        particles[i].position.theta_rad == initial[i].position.theta_rad &&
                        particles[i].position.z_m == initial[i].position.z_m,
                        "collision preserves IDs, positions and original array order");
            }
        }
    }
}

void schedules() {
    const auto mesh = single_cell();
    auto initial = cloud(8);
    for (auto& p : initial) {
        p.position = {0.5e-3, 0.3, 0.5e-3};
    }
    constexpr std::size_t trials = 20000;
    constexpr Real weight = 1e10;
    const ElasticModelParameters constant{ElasticModel::VHS, 4e-10, 300, 1, 1};
    DsmcModel reference(argon, weight, constant);
    const auto dt_for = [&](Real expectation) {
        return expectation*mesh.cells()[0].volume_m3/(28*weight*reference.rate().kernel(1));
    };
    for (const auto clock : clocks) {
        StepOptions options;
        options.candidate_schedule = clock;
        options.record_events = true;
        DsmcStepper stepper(DsmcModel(argon, weight, constant), options);
        DsmcWorkspace work;
        for (Real expectation : {0.2, 3.7}) {
            Statistics counts;
            std::array<std::size_t, 64> pairs{};
            std::size_t survived_half_step = 0, total_pairs = 0;
            for (std::size_t seed = 0; seed < trials; ++seed) {
                auto particles = initial;
                const auto report = stepper.step(particles, mesh, {dt_for(expectation), 0, seed, 0}, work);
                require(report.candidates == report.accepted && report.rejected == 0,
                        "constant kernel accepts every candidate");
                survived_half_step += report.events.empty() ||
                    (report.events.front().time_offset_s &&
                     *report.events.front().time_offset_s > dt_for(expectation)/2);
                for (const auto& event : report.events) {
                    require(event.first_id >= 100 && event.first_id < 108 &&
                            event.second_id >= 100 && event.second_id < 108 &&
                            event.first_id != event.second_id, "valid sampled particle pair");
                    const auto i = std::min(event.first_id, event.second_id)-100;
                    const auto j = std::max(event.first_id, event.second_id)-100;
                    ++pairs[i*8+j];
                    ++total_pairs;
                }
                if (clock == CandidateSchedule::RoundedNtc) {
                    require(report.candidates == static_cast<std::uint64_t>(std::floor(expectation)) ||
                            report.candidates == static_cast<std::uint64_t>(std::ceil(expectation)),
                            "NTC rounding support");
                }
                if (seed == 0) {
                    report_checks(report, mesh, clock, dt_for(expectation));
                }
                counts.add(report.candidates);
            }
            const long double fraction = expectation-std::floor(expectation);
            const long double variance = clock == CandidateSchedule::RoundedNtc ?
                                         fraction*(1-fraction) : expectation;
            const long double fourth_central = clock == CandidateSchedule::RoundedNtc ?
                variance*(1-3*variance) : expectation+3*expectation*expectation;
            close(counts.mean, expectation, 0, 6*std::sqrt(variance/trials), "candidate count mean");
            close(counts.variance(), variance, 0,
                  6*std::sqrt((fourth_central-variance*variance)/trials), "candidate count variance");
            if (clock == CandidateSchedule::ContinuousClock) {
                const auto probability = std::exp(-expectation/2);
                close(static_cast<Real>(survived_half_step)/trials, probability, 0,
                      6*std::sqrt(probability*(1-probability)/trials), "first-event survival probability");
            }
            for (std::size_t i = 0; i < 8; ++i) {
                for (std::size_t j = i+1; j < 8; ++j) {
                    close(pairs[i*8+j], static_cast<long double>(total_pairs)/28, 0,
                          6*std::sqrt(total_pairs/28.0L*27/28), "uniform unordered pair frequencies");
                }
            }
            std::cout << "  " << (clock == CandidateSchedule::RoundedNtc ? "NTC" : "clock")
                      << " A=" << expectation << " mean=" << static_cast<double>(counts.mean)
                      << " variance=" << static_cast<double>(counts.variance()) << '\n';
        }
    }
    // 最多一个候选时，接受事件期望可由初态各粒子对的核独立算出。
    for (const auto type : types) {
        DsmcModel model(argon, weight, parameters(type));
        auto particles0 = initial;
        particles0.resize(4);
        const std::array velocities{Vec3{500, 0, 0}, Vec3{-500, 0, 0}, Vec3{0, 500, 0}, Vec3{0, -500, 0}};
        long double sum = 0;
        for (std::size_t i = 0; i < 4; ++i) {
            particles0[i].velocity_mps = to_cylindrical_velocity(velocities[i], 0.3);
            for (std::size_t j = 0; j < i; ++j) {
                sum += model.rate().kernel(norm(velocities[i]-velocities[j]));
            }
        }
        const auto dt = 0.5*mesh.cells()[0].volume_m3/(6*weight*model.rate().majorant(2500));
        const auto expected = weight*dt/mesh.cells()[0].volume_m3*sum;
        DsmcStepper stepper(std::move(model));
        DsmcWorkspace work;
        std::size_t accepted = 0;
        for (std::size_t seed = 0; seed < trials; ++seed) {
            auto particles = particles0;
            const auto report = stepper.step(particles, mesh, {dt, 0, seed, 0}, work);
            require(report.candidates <= 1, "frozen-state frequency uses at most one candidate");
            accepted += report.accepted;
        }
        close(static_cast<long double>(accepted)/trials, expected, 0,
              6*std::sqrt(expected*(1-expected)/trials), "accepted collision frequency");
    }
}

void replay() {
    const auto mesh = grid();
    for (const auto type : types) {
        for (const auto clock : clocks) {
            const auto initial = cloud(96);
            auto first = initial, shuffled = initial, capped = initial;
            std::mt19937_64 generator(789);
            std::shuffle(shuffled.begin(), shuffled.end(), generator);
            StepOptions options;
            options.candidate_schedule = clock;
            options.record_events = true;
            DsmcStepper stepper(DsmcModel(argon, 1e11, parameters(type)), options);
            DsmcWorkspace work;
            const StepContext context{1e-5, 12, 42, 3};
            const auto report = stepper.step(first, mesh, context, work);
            const auto other = stepper.step(shuffled, mesh, context, work);
            std::sort(shuffled.begin(), shuffled.end(), [](const auto& a, const auto& b) { return a.id < b.id; });
            require(same(first, shuffled), "particle layout independent replay");
            require(report.accepted == other.accepted && report.candidates == other.candidates,
                    "replay report counters");
            require(report.accepted > 1, "replay run exercised collisions");
            options.max_event_records = 1;
            DsmcStepper limited(DsmcModel(argon, 1e11, parameters(type)), options);
            const auto truncated = limited.step(capped, mesh, context, work);
            require(same(first, capped) && truncated.events_truncated && truncated.events.size() == 1,
                    "event recording cap preserves physical result");
            auto zero = initial;
            stepper.step(zero, mesh, {0, 12, 42, 3}, work);
            require(same(zero, initial), "zero dt keeps local velocity bits");
            stepper.step(zero, mesh, {1e-100, 12, 42, 3}, work);
            require(same(zero, initial), "no candidates keeps local velocity bits");
            auto cold = initial;
            for (auto& particle : cold) {
                particle.velocity_mps = {0, -0.0, 0};
            }
            const auto cold_before = cold;
            require(stepper.step(cold, mesh, context, work).candidates == 0 && same(cold, cold_before),
                    "zero thermal speed keeps signed local zero components");
            std::vector<CylindricalParticleState> empty;
            require(stepper.step(empty, mesh, context, work).candidates == 0, "empty particle array");
            std::array<CylindricalParticleState, 3> subset{initial[0], initial[1], initial[2]};
            subset.front().position.r_m = -1;
            const auto guards = subset;
            stepper.step(std::span(subset).subspan(1, 1), mesh, context, work);
            require(same(std::span(subset), std::span(guards)), "single-particle subspan and excluded guard");
            auto wrapped = initial;
            wrapped.insert(wrapped.begin(), initial.front());
            wrapped.push_back(initial.back());
            const auto before = wrapped;
            stepper.step(std::span(wrapped).subspan(1, initial.size()), mesh, context, work);
            require(same(wrapped.front(), before.front()) && same(wrapped.back(), before.back()) &&
                    same(std::span(wrapped).subspan(1, initial.size()), first),
                    "subspan writes only selected original particles");
        }
    }
}

void errors() {
    const auto mesh = grid();
    const auto initial = cloud(16);
    DsmcStepper stepper(DsmcModel(argon, 1e10, parameters(ElasticModel::HS)));
    DsmcWorkspace work;
    const auto check_bad = [&](auto change) {
        auto bad = initial;
        change(bad);
        const auto before = bad;
        rejects([&] { stepper.step(bad, mesh, {1e-5, 0, 2, 0}, work); }, "invalid particle input");
        require(same(bad, before), "invalid input does not modify particles");
    };
    check_bad([](auto& p) { p[1].id = p[0].id; });
    check_bad([](auto& p) { p[0].species_id = 99; });
    check_bad([](auto& p) { p[0].position.r_m = 9; });
    check_bad([](auto& p) { p[0].velocity_mps.vr_mps = std::numeric_limits<Real>::quiet_NaN(); });
    for (Real dt : {-1.0, std::numeric_limits<Real>::infinity(), std::numeric_limits<Real>::quiet_NaN()}) {
        auto particles = initial;
        rejects([&] { stepper.step(particles, mesh, {dt, 0, 2, 0}, work); }, "invalid dt");
        require(same(particles, initial), "invalid dt preserves input");
    }
    StepOptions invalid;
    invalid.max_candidates_total = 0;
    rejects([&] { DsmcStepper bad(DsmcModel(argon, 1, parameters(ElasticModel::HS)), invalid); }, "zero budget");
    invalid = {};
    invalid.candidate_schedule = static_cast<CandidateSchedule>(99);
    rejects([&] { DsmcStepper bad(DsmcModel(argon, 1, parameters(ElasticModel::HS)), invalid); }, "invalid schedule");

    const CylindricalGrid two({0, 1e-3, std::sqrt(2.0)*1e-3}, {0, 2*pi}, {0, 1e-3},
                              AngularBoundary::periodic);
    auto base = cloud(10);
    for (std::size_t i = 0; i < base.size(); ++i) {
        base[i].position = {i < 2 ? 0.5e-3 : 1.2e-3, 0.3, 0.5e-3};
    }
    const ElasticModelParameters constant{ElasticModel::VHS, 4e-10, 300, 1, 1};
    DsmcModel reference(argon, 1e10, constant);
    const auto dt = 20*two.cells()[0].volume_m3/(1e10*reference.rate().kernel(1));
    for (const auto clock : clocks) {
        StepOptions options;
        options.candidate_schedule = clock;
        DsmcStepper unrestricted(DsmcModel(argon, 1e10, constant), options);
        auto completed = base;
        const auto report = unrestricted.step(completed, two, {dt, 0, 7, 0}, work);
        require(report.by_cell[0].accepted > 0 && report.by_cell[0].candidates < 50 && report.candidates > 50,
                "rollback fixture reaches a later-cell budget failure");
        for (bool total : {true, false}) {
            options.max_candidates_total = total ? 50 : 10000;
            options.max_candidates_per_cell = total ? 10000 : 50;
            DsmcStepper limited(DsmcModel(argon, 1e10, constant), options);
            auto particles = base;
            rejects([&] { limited.step(particles, two, {dt, 0, 7, 0}, work); }, "candidate budget failure");
            require(same(particles, base), "later-cell failure rolls back every particle");
            limited.step(particles, two, {0, 0, 7, 0}, work);
            require(same(particles, base), "workspace reusable after exception");
        }
    }
}
} // namespace test
