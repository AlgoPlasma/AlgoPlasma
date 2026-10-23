// SPDX-License-Identifier: Apache-2.0
#include "dsmc.hpp"
#include <algorithm>
#include <charconv>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <string_view>
#include <vector>

using namespace algoplasma::dsmc;

namespace {
std::uint64_t integer(std::string_view text) {
    std::uint64_t value{};
    const auto result = std::from_chars(text.data(), text.data()+text.size(), value);
    if (result.ec != std::errc{} || result.ptr != text.data()+text.size()) {
        throw Error("invalid integer argument");
    }
    return value;
}

struct State {
    long double temperature{}, fraction_x{}, fraction_y{}, fraction_z{}, kurtosis{};
    Vec3 mean{};
};

State observe(const std::vector<CylindricalParticleState>& particles, Real mass) {
    long double ux = 0, uy = 0, uz = 0;
    for (const auto& particle : particles) {
        const auto v = to_cartesian_velocity(particle.velocity_mps, particle.position.theta_rad);
        ux += v.x;
        uy += v.y;
        uz += v.z;
    }
    ux /= particles.size();
    uy /= particles.size();
    uz /= particles.size();
    long double xx = 0, yy = 0, zz = 0, xxxx = 0;
    for (const auto& particle : particles) {
        const auto v = to_cartesian_velocity(particle.velocity_mps, particle.position.theta_rad);
        const auto x = v.x-ux, y = v.y-uy, z = v.z-uz;
        xx += x*x;
        yy += y*y;
        zz += z*z;
        xxxx += x*x*x*x;
    }
    const auto sum = xx+yy+zz;
    return {mass*sum/(3*boltzmann*particles.size()), xx/sum, yy/sum, zz/sum,
            particles.size()*xxxx/(xx*xx),
            {static_cast<Real>(ux), static_cast<Real>(uy), static_cast<Real>(uz)}};
}
} // namespace

int main(int argc, char** argv) {
    const bool check = argc > 1 && std::string_view(argv[argc-1]) == "--check";
    const int arguments = argc-(check ? 1 : 0);
    if (arguments != 3 && arguments != 5 && arguments != 6) {
        std::cerr << "usage: relaxation HS|VHS|VSS ntc|clock [particles steps [seed]] [--check]\n";
        return 2;
    }
    try {
        const std::string_view type_name(argv[1]), clock_name(argv[2]);
        const auto type = type_name == "HS" ? ElasticModel::HS : type_name == "VHS" ? ElasticModel::VHS :
                          type_name == "VSS" ? ElasticModel::VSS : throw Error("unknown model");
        const auto clock = clock_name == "ntc" ? CandidateSchedule::RoundedNtc :
                           clock_name == "clock" ? CandidateSchedule::ContinuousClock :
                           throw Error("unknown candidate schedule");
        // 增加粒子数以减小后期时间均值的统计涨落，支持 1% 的相对误差检查。
        const auto count = arguments >= 5 ? integer(argv[3]) : 16384;
        const auto steps = arguments >= 5 ? integer(argv[4]) : 2000;
        const auto seed = arguments == 6 ? integer(argv[5]) : 42;
        if (count < 2 || count > 100000 || count % 2 || steps < 1 || steps > 100000) {
            throw Error("use an even particle count in [2,100000] and steps in [1,100000]");
        }
        const Species gas{0, "Ar", 6.6335209e-26, 0};
        constexpr Real density = 1e21, temperature = 300, dt = 1e-7;
        const Real speed = std::sqrt(3*boltzmann*temperature/gas.mass_kg);
        const CylindricalGrid grid({0, 1e-3}, {0, 2*pi}, {0, 1e-3}, AngularBoundary::periodic);
        const Real weight = density*grid.cells()[0].volume_m3/count;
        const ElasticModelParameters parameters{type, 4e-10, temperature,
            type == ElasticModel::HS ? 0.5 : 0.81, type == ElasticModel::VSS ? 1.4 : 1};
        StepOptions options;
        options.candidate_schedule = clock;
        options.conservation_tolerance = 1e-10;
        DsmcStepper stepper(DsmcModel(gas, weight, parameters), options);
        std::vector<CylindricalParticleState> particles;
        particles.reserve(count);
        for (std::uint64_t i = 0; i < count; ++i) {
            const Real theta = 2*pi*(i+0.5)/count;
            const Vec3 velocity{i % 2 ? speed : -speed, 0, 0};
            particles.push_back({i, gas.id, {0.5e-3, theta, 0.5e-3}, to_cylindrical_velocity(velocity, theta)});
        }
        // 均匀单元中的纯碰撞实验：位置固定，用于观察方向能量由各向异性趋向均分。
        DsmcWorkspace work;
        const auto initial = observe(particles, gas.mass_kg);
        auto final = initial;
        State late_sum{};
        std::uint64_t late_samples = 0;
        std::uint64_t candidates = 0, accepted = 0;
        // 保留长双精度诊断量；逐步输出，便于检查弛豫早期与守恒误差。
        std::cout << std::setprecision(std::numeric_limits<long double>::max_digits10)
                  << "step,time_s,temperature_k,energy_x_fraction,energy_y_fraction,energy_z_fraction,kurtosis_x,candidates,accepted,particle_count,seed,temperature_relative_change,mean_velocity_change_over_v0\n";
        const auto write = [&](std::uint64_t step, const State& state) {
            std::cout << step << ',' << step*dt << ',' << state.temperature << ',' << state.fraction_x
                      << ',' << state.fraction_y << ',' << state.fraction_z << ',' << state.kurtosis
                      << ',' << candidates << ',' << accepted << ',' << count << ',' << seed
                      << ',' << state.temperature/initial.temperature-1
                      << ',' << norm(state.mean-initial.mean)/speed << '\n';
        };
        write(0, initial);
        for (std::uint64_t step = 1; step <= steps; ++step) {
            const auto report = stepper.step(particles, grid, {dt, step-1, seed, 0}, work);
            candidates += report.candidates;
            accepted += report.accepted;
            final = observe(particles, gas.mass_kg);
            write(step, final);
            // 对后半程等间隔采样取时间均值；默认区间为 (100,200] us。
            if (step > steps/2) {
                late_sum.fraction_x += final.fraction_x;
                late_sum.fraction_y += final.fraction_y;
                late_sum.fraction_z += final.fraction_z;
                late_sum.kurtosis += final.kurtosis;
                ++late_samples;
            }
            if (check) {
                const auto energy_error = std::abs(final.temperature/initial.temperature-1);
                const auto momentum_error = norm(final.mean-initial.mean)/speed;
                if (!std::isfinite(energy_error) || !std::isfinite(momentum_error) ||
                    energy_error > options.conservation_tolerance ||
                    momentum_error > options.conservation_tolerance) {
                    throw Error("conservation check failed at step " + std::to_string(step));
                }
            }
        }
        if (check) {
            const auto fx = late_sum.fraction_x/late_samples;
            const auto fy = late_sum.fraction_y/late_samples;
            const auto fz = late_sum.fraction_z/late_samples;
            const auto kappa = late_sum.kurtosis/late_samples;
            const auto fraction_error = std::max({std::abs(3*fx-1), std::abs(3*fy-1), std::abs(3*fz-1)});
            const auto kurtosis_error = std::abs(kappa/3-1);
            constexpr long double tolerance = 1e-2L;
            std::cerr << std::setprecision(8) << "Relaxation: " << type_name << ' ' << clock_name
                      << " mean_F=(" << fx << ',' << fy << ',' << fz << ") mean_kappa=" << kappa
                      << " epsilon_F=" << fraction_error << " epsilon_kappa=" << kurtosis_error
                      << " limit=" << tolerance << '\n';
            if (!std::isfinite(fraction_error) || !std::isfinite(kurtosis_error) ||
                fraction_error > tolerance || kurtosis_error > tolerance) {
                throw Error("late-time relative equilibrium error exceeds tolerance");
            }
            std::cerr << "PASS: relaxation " << type_name << ' ' << clock_name << '\n';
        }
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
