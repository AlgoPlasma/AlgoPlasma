// SPDX-License-Identifier: Apache-2.0
// Single-thread G02 electron-swarm benchmark; see PERFORMANCE.md for the run protocol.
#include "mcc.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include <sys/resource.h>
using namespace algoplasma::mcc;
using Clock = std::chrono::steady_clock;
double seconds(Clock::time_point a) {
    return std::chrono::duration<double>(Clock::now() - a).count();
}
int main(int argc, char **argv) {
    try {
        if (argc != 10)
            throw std::runtime_error("model initial out EN dt warmup measured seed interval");
        auto engine = MccEngine::load(argv[1]);
        std::ifstream initial(argv[2]);
        std::vector<ParticleState> p;
        double vx, vy, vz;
        auto electron = engine.species_id("e-"), ground = engine.state_id(electron, "ground");
        while (initial >> vx >> vy >> vz) {
            ParticleState q;
            q.species = electron;
            q.state = ground;
            q.id = p.size() + 1;
            q.velocity = {vx, vy, vz};
            p.push_back(q);
        }
        size_t n = p.size();
        if (!initial.eof() || n != 4000)
            throw std::runtime_error("expected 4000 electron velocities");
        double en = std::stod(argv[4]), dt = std::stod(argv[5]), ng = 1e23;
        int warm = std::stoi(argv[6]), measured = std::stoi(argv[7]), interval = std::stoi(argv[9]);
        uint64_t seed = std::stoull(argv[8]);
        if (!std::isfinite(dt) || !std::isfinite(en) || dt <= 0 || warm < 0 || measured <= 0 ||
            interval <= 0 || warm % interval || measured % interval)
            throw std::runtime_error("bad settings");
        std::vector<CellBackground> bg;
        for (auto const &s : engine.model().species.all())
            if (s.representation == Representation::Background) {
                BackgroundComponent b;
                b.species = s.id;
                b.state = engine.state_id(s.id, "ground");
                b.density_m3 = s.name == "M" ? ng : 0;
                b.temperature_k = 0;
                bg.push_back({UINT32_MAX, b});
            }
        StepOptions options;
        options.backend = CpuBackend::Serial;
        options.threads = 1;
        MccStepper stepper(engine, options);
        MccWorkspace workspace;
        VectorParticleAdapter adapter(p);
        std::mt19937_64 rng(seed + 9173);
        double acc = elementary_charge_c * en * 1e-21 * ng / electron_mass_kg;
        std::ofstream f(argv[3]);
        if (!f)
            throw std::runtime_error("cannot open output");
        f << std::setprecision(16)
          << "step,time_s,phase,n_before_control,n_after_control,births,energy_eV,drift_m_s,z_mean_"
             "m,z_var_m2,ND_projection_flux,max_energy_eV\n";
        uint64_t events = 0, candidates = 0, births = 0, visited = 0, totalbirths = 0;
        size_t maxn = n;
        double maxenergy = 0;
        double motion_s = 0;
        double advance_s = 0, control_s = 0, diagnostic_s = 0, prep_s = 0, sampling_s = 0,
               reduction_s = 0, commit_s = 0;
        // Accelerate along +z; apply a half step on each side of the MCC update.
        auto half = [&]() {
            for (auto &q : p) {
                q.position.z += q.velocity.z * dt * .5 + acc * dt * dt * .125;
                q.velocity.z += acc * dt * .5;
            }
        };
        auto all_start = Clock::now(), timed_start = all_start;
        double warm_s = 0;
        for (int block = 0; block < (warm + measured) / interval; block++) {
            int start_step = block * interval;
            bool timed = start_step >= warm;
            if (start_step == warm) {
                warm_s = seconds(all_start);
                timed_start = Clock::now();
            }
            auto t = Clock::now();
            auto before = p.size();
            for (int k = 0; k < interval; k++) {
                auto mt = Clock::now();
                half();
                if (timed)
                    motion_s += seconds(mt);
                auto rep = stepper.step(adapter, bg, dt, start_step + k, seed, workspace);
                mt = Clock::now();
                half();
                if (timed)
                    motion_s += seconds(mt);
                if (timed) {
                    events += rep.real_events;
                    candidates += rep.candidates;
                    visited += rep.particles_visited;
                    prep_s += rep.preparation_seconds;
                    sampling_s += rep.sampling_seconds;
                    reduction_s += rep.reduction_seconds;
                    commit_s += rep.commit_seconds;
                }
            }
            if (timed) {
                advance_s += seconds(t);
            }
            t = Clock::now();
            size_t npre = p.size();
            if (npre < n)
                throw std::runtime_error("unexpected particle loss");
            uint64_t born = npre - before;
            totalbirths += born;
            if (timed) {
                births += born;
                maxn = std::max(maxn, npre);
            }
            // Uniformly thin the swarm back to its initial size after each block.
            for (size_t count = p.size(); count > n; --count) {
                std::uniform_int_distribution<size_t> pick(0, count - 1);
                p[pick(rng)] = p[count - 1];
            }
            p.resize(n);
            if (timed) {
                control_s += seconds(t);
            }
            t = Clock::now();
            double energy = 0, drift = 0, zmean = 0, zvar = 0, nd = 0, emax = 0;
            for (auto &q : p) {
                double e =
                    .5 * electron_mass_kg * dot(q.velocity, q.velocity) / elementary_charge_c;
                energy += e;
                emax = std::max(emax, e);
                drift += q.velocity.z;
                zmean += q.position.z;
            }
            energy /= n;
            drift /= n;
            zmean /= n;
            for (auto &q : p) {
                double z = q.position.z - zmean;
                zvar += z * z;
                nd += z * (q.velocity.z - drift);
                if (!std::isfinite(q.position.z) || std::abs(q.position.z) >= 90)
                    throw std::runtime_error("invalid position");
            }
            zvar /= n;
            nd *= ng / n;
            if (!std::isfinite(energy) || !std::isfinite(nd))
                throw std::runtime_error("invalid diagnostic");
            if (timed)
                maxenergy = std::max(maxenergy, emax);
            int step = start_step + interval;
            f << step << ',' << step * dt << ',' << (timed ? "measured" : "warmup") << ',' << npre
              << ',' << p.size() << ',' << born << ',' << energy << ',' << drift << ',' << zmean
              << ',' << zvar << ',' << nd << ',' << emax << '\n';
            f.flush();
            if (timed)
                diagnostic_s += seconds(t);
        }
        double wall = seconds(timed_start);
        f.close();
        if (!f)
            throw std::runtime_error("failed to write diagnostics");
        struct rusage usage{};
        getrusage(RUSAGE_SELF, &usage);
        std::ofstream m(std::string(argv[3]) + ".json");
        m << std::setprecision(16) << "{\"engine\":\"G02\",\"EN_Td\":" << en << ",\"n0\":" << n
          << ",\"dt_s\":" << dt << ",\"warmup_steps\":" << warm
          << ",\"measured_steps\":" << measured << ",\"seed\":" << seed
          << ",\"interval\":" << interval << ",\"wall_s\":" << wall
          << ",\"warmup_wall_s\":" << warm_s << ",\"steps_per_s\":" << measured / wall
          << ",\"advance_s\":" << advance_s << ",\"population_control_s\":" << control_s
          << ",\"diagnostic_io_s\":" << diagnostic_s << ",\"real_events\":" << events
          << ",\"candidates\":" << candidates << ",\"particles_visited\":" << visited
          << ",\"births_measured\":" << births << ",\"births_total\":" << totalbirths
          << ",\"max_n_before_control\":" << maxn << ",\"max_energy_eV\":" << maxenergy
          << ",\"peak_rss_self_kib\":" << usage.ru_maxrss << ",\"preparation_s\":" << prep_s
          << ",\"sampling_s\":" << sampling_s << ",\"reduction_s\":" << reduction_s
          << ",\"commit_s\":" << commit_s << "}\n";
        m.close();
        if (!m)
            throw std::runtime_error("failed to write timing metadata");
        std::ofstream final(std::string(argv[3]) + ".state", std::ios::binary);
        auto field = [&](const auto &value) {
            final.write(reinterpret_cast<const char *>(&value), sizeof(value));
        };
        for (const auto &q : p) {
            field(q.species);
            field(q.state);
            field(q.position.x);
            field(q.position.y);
            field(q.position.z);
            field(q.velocity.x);
            field(q.velocity.y);
            field(q.velocity.z);
            field(q.weight);
            field(q.id);
            field(q.birth_step);
            field(q.cell);
        }
        final.close();
        if (!final)
            throw std::runtime_error("failed to write final particle state");
        std::cout << "BENCHMARK_FINISHED " << measured << " " << wall << std::endl;
    } catch (std::exception const &e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }
}
