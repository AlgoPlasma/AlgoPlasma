// SPDX-License-Identifier: Apache-2.0
#include "mcc.hpp"
#include "package_builder.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <numbers>
#include <numeric>
#include <optional>
#include <random>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {

namespace fs = std::filesystem;
namespace mcc = algoplasma::mcc;
using mcc::Real;
using mcc::Vec3;

struct Config {
    fs::path model;
    bool model_supplied{false};
    fs::path output;
    std::size_t particles{50000};
    std::uint64_t seed{20260924};
    std::uint64_t steps{200};
    Real dt_s{1e-7};
    Real density_m3{1e20};
    Real gas_temperature_k{300};
    Real initial_temperature_k{3000};
    Real drift_x_m_s{1000};
    mcc::CpuBackend backend{mcc::CpuBackend::Serial};
    mcc::ChannelSampler sampler{mcc::ChannelSampler::Prefix};
    unsigned threads{0};
    bool compare_backends{false};
};

struct Moments {
    Vec3 mean{};
    Vec3 variance{};
    Real mean_v2{};
    Real variance_v2{};
    Real temperature_k{};
    Real energy_j{};
};

struct Reference {
    Vec3 mean{};
    Real mean_v2{};
    Real temperature_k{};
};

struct Row {
    std::uint64_t step{};
    Real time_s{};
    Real nu_t{};
    Moments measured{};
    Reference expected{};
    std::uint64_t candidates{};
    std::uint64_t real_events{};
    std::uint64_t null_events{};
    std::uint64_t cumulative_real{};
    Real energy_balance_j{};
    Real momentum_balance_kg_m_s{};
};

struct Check {
    std::string name;
    Real observed{};
    Real expected{};
    Real tolerance{};
    bool pass{};
};

struct Result {
    std::vector<Row> history;
    std::vector<Vec3> initial_velocities;
    std::vector<mcc::ParticleState> final_particles;
    std::vector<std::uint32_t> collision_counts;
    std::vector<Check> checks;
    Real mass_kg{};
    Real rate_coefficient_m3_s{};
    Real rate_s_inv{};
    Real majorant_s_inv{};
    Real mcc_seconds{};
    mcc::CpuBackend backend{mcc::CpuBackend::Serial};
    std::uint64_t total_candidates{};
    std::uint64_t total_real{};
    std::uint64_t total_null{};
};

[[noreturn]] void usage() {
    std::cout
        << "collision_box [--model DIR] [--output DIR] [--particles N] [--steps N]\n"
        << "  [--dt SECONDS] [--seed N] [--density M^-3] [--gas-temperature K]\n"
        << "  [--initial-temperature K] [--drift-x M/S] [--backend serial|openmp]\n"
        << "  [--threads N] [--sampler prefix|alias] [--compare-backends]\n";
    std::exit(0);
}

std::uint64_t parse_uint(const std::string& text, const std::string& flag) {
    if (text.empty() || text[0] == '-' || text[0] == '+') {
        throw std::runtime_error(flag + " requires an unsigned integer");
    }
    std::size_t end = 0;
    const auto value = std::stoull(text, &end);
    if (end != text.size()) throw std::runtime_error(flag + " requires an unsigned integer");
    return value;
}

Real parse_real(const std::string& text, const std::string& flag) {
    std::size_t end = 0;
    const Real value = std::stod(text, &end);
    if (end != text.size() || !std::isfinite(value)) {
        throw std::runtime_error(flag + " requires a finite number");
    }
    return value;
}

Config parse_args(int argc, char** argv) {
    Config config;
    for (int index = 1; index < argc; ++index) {
        const std::string key = argv[index];
        if (key == "--help" || key == "-h") usage();
        if (key == "--compare-backends") {
            config.compare_backends = true;
            continue;
        }
        if (index + 1 >= argc) throw std::runtime_error("missing value for " + key);
        const std::string value = argv[++index];
        if (key == "--model") {
            config.model = value;
            config.model_supplied = true;
        }
        else if (key == "--output") config.output = value;
        else if (key == "--particles") config.particles = parse_uint(value, key);
        else if (key == "--steps") config.steps = parse_uint(value, key);
        else if (key == "--dt") config.dt_s = parse_real(value, key);
        else if (key == "--seed") config.seed = parse_uint(value, key);
        else if (key == "--density") config.density_m3 = parse_real(value, key);
        else if (key == "--gas-temperature") config.gas_temperature_k = parse_real(value, key);
        else if (key == "--initial-temperature") {
            config.initial_temperature_k = parse_real(value, key);
        } else if (key == "--drift-x") config.drift_x_m_s = parse_real(value, key);
        else if (key == "--threads") {
            const auto parsed = parse_uint(value, key);
            if (parsed > std::numeric_limits<unsigned>::max()) {
                throw std::runtime_error("--threads is too large");
            }
            config.threads = static_cast<unsigned>(parsed);
        } else if (key == "--backend") {
            if (value == "serial") config.backend = mcc::CpuBackend::Serial;
            else if (value == "openmp") config.backend = mcc::CpuBackend::OpenMp;
            else throw std::runtime_error("--backend must be serial or openmp");
        } else if (key == "--sampler") {
            if (value == "prefix") config.sampler = mcc::ChannelSampler::Prefix;
            else if (value == "alias") config.sampler = mcc::ChannelSampler::Alias;
            else throw std::runtime_error("--sampler must be prefix or alias");
        } else throw std::runtime_error("unknown option: " + key);
    }
    if (config.model_supplied) {
        if (config.model.empty()) throw std::runtime_error("--model requires a nonempty directory");
        config.model = fs::absolute(config.model).lexically_normal();
    }
    if (config.particles == 0 || config.particles > UINT32_MAX || config.steps == 0) {
        throw std::runtime_error("particles must be in [1, 2^32-1] and steps must be positive");
    }
    if (config.dt_s < 0 || config.density_m3 < 0 || config.gas_temperature_k <= 0 ||
        config.initial_temperature_k < 0) {
        throw std::runtime_error("dt/density/initial temperature must be nonnegative; gas temperature must be positive");
    }
    if (!std::isfinite(config.dt_s * static_cast<Real>(config.steps)) ||
        !std::isfinite(config.density_m3 * config.dt_s)) {
        throw std::runtime_error("time or collision rate overflows");
    }
    return config;
}

Real validate_model(const mcc::MccEngine& engine, const Config& config) {
    const auto& model = engine.model();
    const auto a = engine.species_id("A");
    const auto b = engine.species_id("B");
    const auto a0 = engine.state_id(a, "ground");
    const auto b0 = engine.state_id(b, "ground");
    const auto& sa = model.species.at(a);
    const auto& sb = model.species.at(b);
    const auto fail = [] { throw std::runtime_error(
        "analytic collision_box requires exactly one equal-mass A+B -> A+B "
        "isotropic C02 channel with a constant temperature-based rate coefficient"); };
    if (model.species.size() != 2 || model.states.size() != 2 ||
        sa.representation != mcc::Representation::Kinetic ||
        sb.representation != mcc::Representation::Background ||
        std::abs(sa.mass_kg - sb.mass_kg) > 1e-12 * sa.mass_kg ||
        model.reactions.size() != 1) fail();
    const auto& reaction = model.reactions.front();
    if (reaction.algorithm != mcc::CollisionAlgorithm::C02Elastic ||
        reaction.projectile != a || reaction.projectile_state != a0 ||
        reaction.order != 2 || reaction.background_count != 1 ||
        reaction.reactant_bodies.size() != 2 || reaction.product_bodies.size() != 2 ||
        reaction.reactant_bodies[0] != std::make_pair(a, a0) ||
        reaction.reactant_bodies[1] != std::make_pair(b, b0) ||
        reaction.product_bodies[0] != std::make_pair(a, a0) ||
        reaction.product_bodies[1] != std::make_pair(b, b0) ||
        reaction.angular_model != mcc::AngularModel::Isotropic ||
        reaction.energy_model != mcc::EnergyModel::NBodyPhaseSpace ||
        reaction.rate_kind != mcc::RateKind::RateCoefficient ||
        reaction.x_source != "temperature_k" || reaction.x_species != b ||
        reaction.threshold_ev != 0 || reaction.q_value_ev != 0 ||
        reaction.ker_min_ev != 0 || reaction.radiated_energy_ev != 0) fail();
    const auto& table = reaction.table;
    if (table.x.empty() || table.y.empty() || table.x_unit != "K" ||
        table.y_unit != "m3/s" || config.gas_temperature_k < table.x_min() ||
        config.gas_temperature_k > table.x_max() || table.y.front() <= 0) fail();
    for (const Real value : table.y) {
        if (value != table.y.front()) fail();
    }
    return table.y.front();
}

Moments measure(const std::vector<mcc::ParticleState>& particles, Real mass) {
    long double sx = 0, sy = 0, sz = 0, sx2 = 0, sy2 = 0, sz2 = 0;
    long double sq = 0, sq2 = 0;
    for (const auto& particle : particles) {
        const auto v = particle.velocity;
        const long double q = static_cast<long double>(v.x) * v.x +
            static_cast<long double>(v.y) * v.y + static_cast<long double>(v.z) * v.z;
        sx += v.x; sy += v.y; sz += v.z;
        sx2 += static_cast<long double>(v.x) * v.x;
        sy2 += static_cast<long double>(v.y) * v.y;
        sz2 += static_cast<long double>(v.z) * v.z;
        sq += q; sq2 += q * q;
    }
    const long double n = static_cast<long double>(particles.size());
    Moments m;
    m.mean = {static_cast<Real>(sx / n), static_cast<Real>(sy / n),
              static_cast<Real>(sz / n)};
    m.mean_v2 = static_cast<Real>(sq / n);
    m.variance = {static_cast<Real>(std::max(0.L, sx2 / n - (sx / n) * (sx / n))),
                  static_cast<Real>(std::max(0.L, sy2 / n - (sy / n) * (sy / n))),
                  static_cast<Real>(std::max(0.L, sz2 / n - (sz / n) * (sz / n)))};
    m.variance_v2 = static_cast<Real>(std::max(0.L, sq2 / n - (sq / n) * (sq / n)));
    m.temperature_k = mass * (m.mean_v2 - mcc::dot(m.mean, m.mean)) /
        (3 * mcc::boltzmann_j_per_k);
    m.energy_j = static_cast<Real>(0.5L * mass * sq);
    return m;
}

// Equal-mass, isotropic, constant-rate test: one event halves the mean drift
// and the excess second moment; E[2^(-N)] = exp(-nu*t/2) for Poisson N.
// This local derivation and its method references are documented in
// docs/source/rst_files/G_Collision/G02_MCC_network/references.rst.
Reference reference(const Moments& initial, Real tau, Real gas_t, Real mass) {
    const Real decay = std::exp(-0.5 * tau);
    const Real equilibrium_v2 = 3 * mcc::boltzmann_j_per_k * gas_t / mass;
    Reference r;
    r.mean = initial.mean * decay;
    r.mean_v2 = equilibrium_v2 + (initial.mean_v2 - equilibrium_v2) * decay;
    r.temperature_k = mass * (r.mean_v2 - mcc::dot(r.mean, r.mean)) /
        (3 * mcc::boltzmann_j_per_k);
    return r;
}

void add_check(Result& result, const std::string& name, Real observed,
               Real expected, Real tolerance) {
    result.checks.push_back({name, observed, expected, tolerance,
                             std::abs(observed - expected) <= tolerance});
}

Real gaussian_cdf(Real value, Real sigma) {
    return 0.5 * (1 + std::erf(value / (std::sqrt(2.0) * sigma)));
}

Real maxwell_cdf(Real speed, Real sigma) {
    const Real z = speed / sigma;
    return std::erf(z / std::sqrt(2.0)) -
        std::sqrt(2.0 / std::numbers::pi) * z * std::exp(-0.5 * z * z);
}

template <typename Transform, typename Cdf>
Real ks_distance(const std::vector<mcc::ParticleState>& particles,
                 Transform transform, Cdf cdf) {
    std::vector<Real> values;
    values.reserve(particles.size());
    for (const auto& p : particles) values.push_back(transform(p.velocity));
    std::sort(values.begin(), values.end());
    Real distance = 0;
    const Real n = static_cast<Real>(values.size());
    for (std::size_t i = 0; i < values.size(); ++i) {
        const Real target = cdf(values[i]);
        distance = std::max({distance, std::abs(target - static_cast<Real>(i) / n),
                             std::abs(static_cast<Real>(i + 1) / n - target)});
    }
    return distance;
}

void statistical_checks(Result& result, const Config& config) {
    const Real n = static_cast<Real>(config.particles);
    const Real tau = result.history.back().nu_t;
    const Real expected_count = tau;
    Real count_sum = 0, count_square_sum = 0;
    for (const auto count : result.collision_counts) {
        count_sum += count;
        count_square_sum += static_cast<Real>(count) * count;
    }
    const Real count_mean = count_sum / n;
    const Real count_variance = count_square_sum / n - count_mean * count_mean;
    add_check(result, "collision_count_mean", count_mean, expected_count,
              expected_count == 0 ? 0 : 6 * std::sqrt(expected_count / n) + 1 / n);
    add_check(result, "collision_count_variance", count_variance, expected_count,
              expected_count == 0 ? 0 :
              6 * std::sqrt((expected_count + 2 * expected_count * expected_count) / n) + 1 / n);
    add_check(result, "candidate_partition", static_cast<Real>(result.total_candidates),
              static_cast<Real>(result.total_real + result.total_null), 0);
    if (result.total_candidates > 0) {
        const Real expected_null = 1 - result.rate_s_inv / result.majorant_s_inv;
        const Real observed_null = static_cast<Real>(result.total_null) /
                                   static_cast<Real>(result.total_candidates);
        const Real tolerance = 6 * std::sqrt(expected_null * (1 - expected_null) /
                                                static_cast<Real>(result.total_candidates)) +
                               1 / static_cast<Real>(result.total_candidates);
        add_check(result, "null_fraction", observed_null, expected_null, tolerance);
    }

    for (const Real target_tau : {2.0, 10.0, 20.0}) {
        if (tau + 1e-12 < target_tau) continue;
        const auto it = std::find_if(result.history.begin(), result.history.end(),
            [&](const Row& row) { return row.nu_t + 1e-12 >= target_tau; });
        if (it == result.history.end()) continue;
        const std::string tag = "tau" + std::to_string(static_cast<int>(target_tau));
        const Real observed[] = {it->measured.mean.x, it->measured.mean.y,
                                 it->measured.mean.z, it->measured.mean_v2};
        const Real expected[] = {it->expected.mean.x, it->expected.mean.y,
                                 it->expected.mean.z, it->expected.mean_v2};
        const Real variances[] = {it->measured.variance.x, it->measured.variance.y,
                                  it->measured.variance.z, it->measured.variance_v2};
        const char* labels[] = {"vx", "vy", "vz", "v2"};
        for (int j = 0; j < 4; ++j) {
            const Real tolerance = 6 * std::sqrt(variances[j] / n) +
                1e-12 * std::max(1.0, std::abs(expected[j]));
            add_check(result, tag + "_" + labels[j], observed[j], expected[j], tolerance);
        }
    }

    const auto& final = result.history.back();
    const Real sigma = std::sqrt(mcc::boltzmann_j_per_k * config.gas_temperature_k /
                                 result.mass_kg);
    if (tau >= 18 && mcc::norm(final.expected.mean) < 0.002 * sigma &&
        std::abs(final.expected.temperature_k - config.gas_temperature_k) <
            0.002 * config.gas_temperature_k) {
        const Real limit = std::sqrt(std::log(4000.0) / (2 * n));
        add_check(result, "final_vx_maxwell_ks",
                  ks_distance(result.final_particles,
                      [](Vec3 v) { return v.x; },
                      [&](Real value) { return gaussian_cdf(value, sigma); }),
                  0, limit);
        add_check(result, "final_speed_maxwell_ks",
                  ks_distance(result.final_particles,
                      [](Vec3 v) { return mcc::norm(v); },
                      [&](Real value) { return maxwell_cdf(value, sigma); }),
                  0, limit);
    }
}

Result simulate(const Config& config, const mcc::MccEngine& engine, Real coefficient,
                mcc::CpuBackend backend) {
    Result result;
    result.backend = backend;
    const auto a = engine.species_id("A");
    const auto b = engine.species_id("B");
    const auto a0 = engine.state_id(a, "ground");
    const auto b0 = engine.state_id(b, "ground");
    result.mass_kg = engine.model().species.at(a).mass_kg;
    result.rate_coefficient_m3_s = coefficient;
    result.rate_s_inv = coefficient * config.density_m3;
    result.majorant_s_inv = result.rate_s_inv *
        engine.model().reactions.front().applied_majorant_scale;
    if (!std::isfinite(result.rate_s_inv) ||
        !std::isfinite(result.majorant_s_inv * config.dt_s)) {
        throw std::runtime_error("collision rate overflows");
    }
    const Real sigma = std::sqrt(mcc::boltzmann_j_per_k * config.initial_temperature_k /
                                 result.mass_kg);
    std::mt19937_64 random(config.seed ^ 0x7c83a6d5241bef09ULL);
    std::normal_distribution<Real> normal(0, 1);
    std::vector<mcc::ParticleState> particles;
    particles.reserve(config.particles);
    result.initial_velocities.reserve(config.particles);
    for (std::size_t i = 0; i < config.particles; ++i) {
        mcc::ParticleState p;
        p.species = a;
        p.state = a0;
        p.id = static_cast<std::uint64_t>(i + 1);
        p.velocity = {config.drift_x_m_s + sigma * normal(random),
                      sigma * normal(random), sigma * normal(random)};
        particles.push_back(p);
        result.initial_velocities.push_back(p.velocity);
    }
    const Moments initial = measure(particles, result.mass_kg);
    const Vec3 initial_momentum = initial.mean *
        (result.mass_kg * static_cast<Real>(config.particles));
    const Real initial_energy = initial.energy_j;
    const std::vector<mcc::CellBackground> background{{0,
        {b, config.density_m3, config.gas_temperature_k, {}, b0}}};
    mcc::StepOptions options;
    options.backend = backend;
    options.threads = config.threads;
    options.record_events = true;
    options.exact_pruning = true;
    options.sampler = config.sampler;
    mcc::MccStepper stepper(engine, options);
    mcc::MccWorkspace workspace;
    mcc::VectorParticleAdapter adapter(particles, config.particles + 1);
    result.collision_counts.resize(config.particles);
    result.history.reserve(static_cast<std::size_t>(config.steps + 1));
    result.history.push_back({0, 0, 0, initial, reference(initial, 0,
        config.gas_temperature_k, result.mass_kg)});
    Vec3 reservoir_momentum{};
    Real reservoir_energy = 0;
    Real max_energy_residual = 0, max_momentum_residual = 0;
    for (std::uint64_t step = 1; step <= config.steps; ++step) {
        const mcc::StepReport report = stepper.step(adapter, background, config.dt_s,
                                                   step, config.seed, workspace);
        result.mcc_seconds += report.total_seconds;
        if (report.particles_visited != config.particles || report.created_particles != 0 ||
            particles.size() != config.particles ||
            report.events.size() != report.candidates ||
            report.candidates != report.real_events + report.null_events) {
            throw std::runtime_error("particle count or event accounting changed");
        }
        for (const auto& event : report.events) {
            if (event.particle_id == 0 || event.particle_id > config.particles ||
                event.cell != 0 || event.event.real_event == event.event.null_event) {
                throw std::runtime_error("invalid collision event record");
            }
            if (event.event.real_event) {
                ++result.collision_counts[static_cast<std::size_t>(event.particle_id - 1)];
            }
        }
        for (const auto& entry : report.reservoir) {
            if (entry.cell != 0 || entry.delta.species != b ||
                entry.delta.physical_particles != 0 || entry.delta.internal_energy_j != 0) {
                throw std::runtime_error("unexpected background reservoir change");
            }
            reservoir_momentum += entry.delta.momentum_kg_m_per_s;
            reservoir_energy += entry.delta.kinetic_energy_j;
        }
        for (std::size_t i = 0; i < particles.size(); ++i) {
            const auto& p = particles[i];
            if (p.id != i + 1 || p.species != a || p.state != a0 ||
                p.weight != 1 || p.position.x != 0 || p.position.y != 0 ||
                p.position.z != 0 || p.cell != 0 || p.birth_step != 0) {
                throw std::runtime_error("particle identity, weight, state or position changed");
            }
        }
        result.total_candidates += report.candidates;
        result.total_real += report.real_events;
        result.total_null += report.null_events;
        const Moments current = measure(particles, result.mass_kg);
        const Vec3 net_momentum = current.mean *
                                  (result.mass_kg * static_cast<Real>(config.particles)) +
                                  reservoir_momentum - initial_momentum;
        const Real energy_balance = current.energy_j + reservoir_energy - initial_energy;
        max_energy_residual = std::max(max_energy_residual, std::abs(energy_balance));
        max_momentum_residual = std::max(max_momentum_residual, mcc::norm(net_momentum));
        const Real elapsed = static_cast<Real>(step) * config.dt_s;
        const Real tau = result.rate_s_inv * elapsed;
        result.history.push_back({step, elapsed, tau, current,
            reference(initial, tau, config.gas_temperature_k, result.mass_kg),
            report.candidates, report.real_events, report.null_events,
            result.total_real, energy_balance, mcc::norm(net_momentum)});
    }
    const Real energy_scale = std::max(initial_energy,
        static_cast<Real>(config.particles) * mcc::boltzmann_j_per_k *
        config.gas_temperature_k);
    const Real momentum_scale = static_cast<Real>(config.particles) * result.mass_kg *
        std::max(std::sqrt(mcc::boltzmann_j_per_k * config.gas_temperature_k /
                           result.mass_kg), mcc::norm(initial.mean));
    add_check(result, "energy_conservation_max_j", max_energy_residual, 0,
              1e-9 * energy_scale);
    add_check(result, "momentum_conservation_max_kg_m_s", max_momentum_residual,
              0, 1e-9 * momentum_scale);
    result.final_particles = std::move(particles);
    statistical_checks(result, config);
    return result;
}

std::ofstream csv_file(const fs::path& path) {
    std::ofstream out(path);
    if (!out) throw std::runtime_error("cannot write " + path.string());
    out << std::setprecision(17);
    return out;
}

void write_history(const fs::path& path, const Result& result) {
    auto out = csv_file(path);
    out << "step,time_s,nu_t,mean_vx_m_s,mean_vy_m_s,mean_vz_m_s,mean_v2_m2_s2,"
           "temperature_k,kinetic_energy_j,reference_vx_m_s,reference_vy_m_s,"
           "reference_vz_m_s,reference_v2_m2_s2,reference_temperature_k,"
           "candidates,real_events,null_events,cumulative_real,"
           "energy_balance_j,momentum_balance_kg_m_s\n";
    for (const Row& row : result.history) {
        out << row.step << ',' << row.time_s << ',' << row.nu_t << ','
            << row.measured.mean.x << ',' << row.measured.mean.y << ','
            << row.measured.mean.z << ',' << row.measured.mean_v2 << ','
            << row.measured.temperature_k << ',' << row.measured.energy_j << ','
            << row.expected.mean.x << ',' << row.expected.mean.y << ','
            << row.expected.mean.z << ',' << row.expected.mean_v2 << ','
            << row.expected.temperature_k << ',' << row.candidates << ','
            << row.real_events << ',' << row.null_events << ','
            << row.cumulative_real << ',' << row.energy_balance_j << ','
            << row.momentum_balance_kg_m_s << '\n';
    }
}

void write_distribution(const fs::path& path, const Result& result,
                        const Config& config) {
    auto out = csv_file(path);
    out << "snapshot,variable,bin_center,observed_density,expected_density\n";
    const Real sigma_initial = std::sqrt(mcc::boltzmann_j_per_k *
        config.initial_temperature_k / result.mass_kg);
    const Real sigma_final = std::sqrt(mcc::boltzmann_j_per_k *
        config.gas_temperature_k / result.mass_kg);
    const Real v_max = std::max(std::abs(config.drift_x_m_s) + 6 * sigma_initial,
                                6 * sigma_final);
    const auto emit = [&](const std::string& snapshot, const std::string& variable,
                          const std::vector<Vec3>& velocities, Real start, Real stop,
                          Real mean, Real sigma, bool expectation) {
        constexpr std::size_t bins = 100;
        const Real width = (stop - start) / bins;
        std::vector<std::size_t> counts(bins);
        for (const Vec3 v : velocities) {
            const Real value = variable == "vx" ? v.x : mcc::norm(v);
            if (value >= start && value < stop) {
                ++counts[std::min(bins - 1, static_cast<std::size_t>((value - start) / width))];
            }
        }
        for (std::size_t i = 0; i < bins; ++i) {
            const Real center = start + (static_cast<Real>(i) + 0.5) * width;
            out << snapshot << ',' << variable << ',' << center << ','
                << static_cast<Real>(counts[i]) /
                   (static_cast<Real>(velocities.size()) * width) << ',';
            if (expectation && sigma > 0) {
                if (variable == "vx") {
                    const Real z = (center - mean) / sigma;
                    out << std::exp(-0.5 * z * z) /
                        (std::sqrt(2.0 * std::numbers::pi) * sigma);
                } else {
                    const Real z = center / sigma;
                    out << std::sqrt(2.0 / std::numbers::pi) * z * z *
                        std::exp(-0.5 * z * z) / sigma;
                }
            }
            out << '\n';
        }
    };
    std::vector<Vec3> final_velocities;
    final_velocities.reserve(result.final_particles.size());
    for (const auto& p : result.final_particles) final_velocities.push_back(p.velocity);
    emit("initial", "vx", result.initial_velocities, -v_max, v_max,
         config.drift_x_m_s, sigma_initial, true);
    emit("final", "vx", final_velocities, -v_max, v_max, 0,
         sigma_final, true);
    emit("initial", "speed", result.initial_velocities, 0, v_max, 0, 0, false);
    emit("final", "speed", final_velocities, 0, v_max, 0,
         sigma_final, true);
}

void write_counts(const fs::path& path, const Result& result) {
    auto out = csv_file(path);
    out << "collisions,observed_particles,poisson_expected_particles\n";
    const Real lambda = result.history.back().nu_t;
    const auto max_it = std::max_element(result.collision_counts.begin(),
                                         result.collision_counts.end());
    const std::size_t max_count = std::max<std::size_t>(*max_it,
        static_cast<std::size_t>(std::ceil(lambda + 6 * std::sqrt(lambda))));
    std::vector<std::size_t> frequency(max_count + 1);
    for (const auto count : result.collision_counts) ++frequency[count];
    for (std::size_t count = 0; count <= max_count; ++count) {
        const Real probability = lambda == 0 ? (count == 0 ? 1.0 : 0.0) :
            std::exp(-lambda + static_cast<Real>(count) * std::log(lambda) -
                     std::lgamma(static_cast<Real>(count) + 1));
        out << count << ',' << frequency[count] << ','
            << probability * static_cast<Real>(result.collision_counts.size()) << '\n';
    }
}

std::string csv_text(const std::string& value) {
    if (value.find_first_of(",\"\r\n") == std::string::npos) return value;
    std::string quoted = "\"";
    for (const char c : value) {
        if (c == '"') quoted += '"';
        quoted += c;
    }
    return quoted + '"';
}

void write_outputs(const fs::path& directory, const Result& result,
                   const Config& config) {
    fs::create_directories(directory);
    write_history(directory / "history.csv", result);
    write_distribution(directory / "distribution.csv", result, config);
    write_counts(directory / "collision_counts.csv", result);
    {
        auto out = csv_file(directory / "checks.csv");
        out << "check,observed,expected,tolerance,pass\n";
        for (const auto& check : result.checks) {
            out << check.name << ',' << check.observed << ',' << check.expected << ','
                << check.tolerance << ',' << (check.pass ? "true" : "false") << '\n';
        }
    }
    {
        auto out = csv_file(directory / "parameters.csv");
        out << "model,particles,seed,steps,dt_s,density_m3,gas_temperature_k,"
               "initial_temperature_k,drift_x_m_s,mass_kg,rate_coefficient_m3_s,"
               "collision_rate_s_inv,majorant_s_inv,backend,threads,mcc_seconds,"
               "particle_steps_per_mcc_second\n";
        out << csv_text(config.model.string()) << ',' << config.particles << ',' << config.seed << ','
            << config.steps << ',' << config.dt_s << ',' << config.density_m3 << ','
            << config.gas_temperature_k << ',' << config.initial_temperature_k << ','
            << config.drift_x_m_s << ',' << result.mass_kg << ','
            << result.rate_coefficient_m3_s << ',' << result.rate_s_inv << ','
            << result.majorant_s_inv << ','
            << (result.backend == mcc::CpuBackend::Serial ? "serial" : "openmp") << ','
            << config.threads << ',' << result.mcc_seconds << ','
            << (result.mcc_seconds > 0 ?
                static_cast<Real>(config.particles) * static_cast<Real>(config.steps) /
                    result.mcc_seconds : 0) << '\n';
    }
}

void compare_backends(const Config& config, const mcc::MccEngine& engine,
                      Real coefficient, const Result& serial) {
    const Result parallel = simulate(config, engine, coefficient, mcc::CpuBackend::OpenMp);
    if (serial.final_particles.size() != parallel.final_particles.size() ||
        serial.collision_counts != parallel.collision_counts ||
        serial.total_candidates != parallel.total_candidates ||
        serial.total_real != parallel.total_real ||
        serial.total_null != parallel.total_null) {
        throw std::runtime_error("serial/OpenMP event counts differ");
    }
    for (std::size_t i = 0; i < serial.final_particles.size(); ++i) {
        const auto a = serial.final_particles[i].velocity;
        const auto b = parallel.final_particles[i].velocity;
        if (a.x != b.x || a.y != b.y || a.z != b.z) {
            throw std::runtime_error("serial/OpenMP final particle velocities differ");
        }
    }
    for (const auto& check : parallel.checks) {
        if (!check.pass) throw std::runtime_error("OpenMP check failed: " + check.name);
    }
    std::cout << "serial/OpenMP particle states and collision counts: identical\n";
}

} // namespace

int main(int argc, char** argv) {
    try {
        Config config = parse_args(argc, argv);
        std::optional<g02test::TemporaryPackage> default_model;
        if (!config.model_supplied) {
            default_model.emplace(g02test::collision_box_package(), "collision_box");
            config.model = default_model->path();
        }
        const mcc::MccEngine engine = mcc::MccEngine::load(config.model);
        const Real coefficient = validate_model(engine, config);
        const auto backend = config.compare_backends ? mcc::CpuBackend::Serial : config.backend;
        const Result result = simulate(config, engine, coefficient, backend);
        if (config.compare_backends) compare_backends(config, engine, coefficient, result);
        if (!config.output.empty()) write_outputs(config.output, result, config);
        std::size_t failed = 0;
        for (const auto& check : result.checks) {
            if (!check.pass) {
                ++failed;
                std::cerr << "FAIL " << check.name << ": observed " << check.observed
                          << ", expected " << check.expected << " +/- "
                          << check.tolerance << '\n';
            }
        }
        const auto& last = result.history.back();
        std::cout << "collision_box: " << (failed == 0 ? "PASS" : "FAIL")
                  << ", N=" << config.particles << ", nu*t=" << last.nu_t
                  << ", real=" << result.total_real << ", null=" << result.total_null
                  << ", T=" << last.measured.temperature_k << " K"
                  << ", reference=" << last.expected.temperature_k << " K"
                  << ", MCC time=" << result.mcc_seconds << " s\n";
        if (!config.output.empty()) std::cout << "output: " << config.output.string() << '\n';
        return failed == 0 ? 0 : 1;
    } catch (const std::exception& error) {
        std::cerr << "collision_box: " << error.what() << '\n';
        return 2;
    }
}
