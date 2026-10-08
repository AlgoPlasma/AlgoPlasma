// SPDX-License-Identifier: Apache-2.0
// Table interpolation, domain policy and majorant audit.
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <cmath>
#include <filesystem>
#include <vector>

using namespace algoplasma::mcc;
namespace fs = std::filesystem;

namespace {

Table make_table(std::vector<Real> x, std::vector<Real> y, const Interpolation interpolation) {
    Table table;
    table.dataset_id = "audit";
    table.x_axis = "energy";
    table.x_unit = "eV";
    table.y_unit = "m2";
    table.interpolation = interpolation;
    table.below = DomainPolicy::Error;
    table.above = DomainPolicy::Error;
    table.x = std::move(x);
    table.y = std::move(y);
    return table;
}

} // namespace

int main() {
    bool outside = false;

    // ---- linear -----------------------------------------------------------
    {
        Table table = make_table({0.0, 1.0, 2.0}, {0.0, 10.0, 20.0}, Interpolation::Linear);
        table.validate("linear");
        G02_CHECK_NEAR(table.sample(0.5, outside), 5.0, 1.0e-12);
        G02_CHECK(!outside);
        G02_CHECK_NEAR(table.sample(0.0, outside), 0.0, 1.0e-12);
        G02_CHECK_NEAR(table.sample(2.0, outside), 20.0, 1.0e-12);
    }

    // ---- log-linear -------------------------------------------------------
    {
        Table table = make_table({1.0, 10.0}, {1.0, 100.0}, Interpolation::LogLinear);
        table.validate("log-linear");
        G02_CHECK_NEAR(table.sample(5.5, outside), 10.0, 1.0e-9);
        G02_CHECK_NEAR(table.sample(1.0, outside), 1.0, 1.0e-12);
        G02_CHECK_NEAR(table.sample(10.0, outside), 100.0, 1.0e-9);
    }

    // ---- log-log ----------------------------------------------------------
    {
        Table table = make_table({1.0, 100.0}, {1.0, 10000.0}, Interpolation::LogLog);
        table.validate("log-log");
        G02_CHECK_NEAR(table.sample(10.0, outside), 100.0, 1.0e-6);
        G02_CHECK_NEAR(table.sample(1.0, outside), 1.0, 1.0e-12);
        G02_CHECK_NEAR(table.sample(100.0, outside), 10000.0, 1.0e-6);
    }

    // ---- domain policy ----------------------------------------------------
    {
        Table table = make_table({0.0, 1.0}, {1.0, 2.0}, Interpolation::Linear);
        table.validate("domain");
        G02_CHECK_THROWS(table.sample(-0.5, outside));
        G02_CHECK_THROWS(table.sample(1.5, outside));
        table.below = DomainPolicy::Zero;
        table.above = DomainPolicy::Zero;
        outside = false;
        G02_CHECK_NEAR(table.sample(-0.5, outside), 0.0, 1.0e-15);
        G02_CHECK(outside);
        outside = false;
        G02_CHECK_NEAR(table.sample(1.5, outside), 0.0, 1.0e-15);
        G02_CHECK(outside);
        table.below = DomainPolicy::Clamp;
        table.above = DomainPolicy::Clamp;
        outside = false;
        G02_CHECK_NEAR(table.sample(-0.5, outside), 1.0, 1.0e-15);
        G02_CHECK(outside);
        outside = false;
        G02_CHECK_NEAR(table.sample(1.5, outside), 2.0, 1.0e-15);
        G02_CHECK(outside);
    }

    // ---- validation -------------------------------------------------------
    {
        Table table = make_table({0.0, 1.0}, {1.0}, Interpolation::Linear);
        G02_CHECK_THROWS(table.validate("size"));
        table = make_table({0.0}, {1.0}, Interpolation::Linear);
        G02_CHECK_THROWS(table.validate("short"));
        table = make_table({0.0, 0.0}, {1.0, 2.0}, Interpolation::Linear);
        G02_CHECK_THROWS(table.validate("non-increasing"));
        table = make_table({0.0, 1.0}, {1.0, -2.0}, Interpolation::Linear);
        G02_CHECK_THROWS(table.validate("negative"));
        table = make_table({0.0, 1.0}, {1.0, std::nan("")}, Interpolation::Linear);
        G02_CHECK_THROWS(table.validate("nan"));
        table = make_table({0.0, 1.0}, {0.0, 2.0}, Interpolation::LogLinear);
        G02_CHECK_THROWS(table.validate("log zero"));
        table = make_table({0.0, 1.0}, {1.0, 2.0}, Interpolation::LogLog);
        G02_CHECK_THROWS(table.validate("loglog zero x"));
    }

    // ---- dense independent majorant audit over every segment -------------
    {
        const std::vector<Interpolation> modes = {Interpolation::Linear, Interpolation::LogLinear,
                                                  Interpolation::LogLog};
        for (const Interpolation mode : modes) {
            Table table = make_table({1.0, 2.0, 5.0, 9.0, 20.0},
                                     {1.0, 4.0, 3.0, 8.0, 2.0}, mode);
            table.validate("bounds");
            const std::vector<Real> bounds = table.segment_upper_bounds();
            G02_CHECK(bounds.size() == table.x.size() - 1U);
            for (std::size_t i = 0; i + 1U < table.x.size(); ++i) {
                for (int step = 0; step <= 200; ++step) {
                    const Real fraction = static_cast<Real>(step) / 200.0;
                    const Real x = table.x[i] + fraction * (table.x[i + 1U] - table.x[i]);
                    bool outside_value = false;
                    const Real y = table.sample(x, outside_value);
                    if (!(y <= bounds[i] * (1.0 + 1.0e-12) + 1.0e-300)) {
                        G02_CHECK(false);
                    }
                }
            }
            G02_CHECK(table.upper_bound() >= bounds.back());
        }
    }

    // ---- compiled cross-section majorant audit ----------------------------
    {
        const fs::path root = g02test::temp_package_root("interp");
        const fs::path dir = root / "audit";
        auto files = g02test::single_channel_package(2.0e-20);
        files["tables/t1.csv"] =
            "x,y\n"
            "0.0,0.0\n"
            "1.0,1.0e-20\n"
            "2.0,3.0e-20\n"
            "5.0,1.0e-20\n"
            "9.0,5.0e-21\n"
            "20.0,2.0e-21\n";
        g02test::write_package(dir, files);
        const MccEngine engine = MccEngine::load(dir);
        const CompiledReaction& reaction = engine.model().reactions.at(0);
        const Species& projectile = engine.model().species.at(reaction.projectile);
        SpeciesId background = invalid_species;
        for (const ReactantTerm& term : reaction.reactants) {
            if (term.role == ReactantRole::Background) background = term.species;
        }
        const Species& target = engine.model().species.at(background);
        const Real reduced = projectile.mass_kg * target.mass_kg /
                             (projectile.mass_kg + target.mass_kg);
        for (std::size_t i = 0; i + 1U < reaction.table.x.size(); ++i) {
            for (int step = 0; step <= 400; ++step) {
                const Real fraction = static_cast<Real>(step) / 400.0;
                const Real energy = reaction.table.x[i] +
                                    fraction * (reaction.table.x[i + 1U] - reaction.table.x[i]);
                bool outside_value = false;
                const Real sigma = reaction.table.sample(energy, outside_value);
                const Real speed = std::sqrt(2.0 * energy * elementary_charge_c / reduced);
                const Real rate_shape = sigma * speed;
                G02_CHECK(rate_shape <= reaction.majorant_shape * (1.0 + 1.0e-12));
                if (i < reaction.segment_shape_bounds.size()) {
                    G02_CHECK(rate_shape <=
                              reaction.segment_shape_bounds[i] * (1.0 + 1.0e-12) + 1.0e-300);
                }
            }
        }
        std::filesystem::remove_all(root);
    }

    return g02test::summary("test_interpolation");
}
