// SPDX-License-Identifier: Apache-2.0
// Schema, parser and cross-reference validation tests.
#include "package_builder.hpp"
#include "test_util.hpp"

#include "mcc.hpp"

#include <filesystem>
#include <limits>
#include <string>

using namespace algoplasma::mcc;
namespace fs = std::filesystem;

namespace {

ModelDefinition load_package(const fs::path& dir) { return load_model_package(dir); }

CompiledModel load_compiled(const fs::path& dir) {
    return compile_model(load_model_package(dir));
}

} // namespace

int main() {
    const fs::path root = g02test::temp_package_root("schema");

    // ---- valid fixtures ---------------------------------------------------
    {
        const fs::path dir = root / "valid_single";
        g02test::write_package(dir, g02test::single_channel_package(2.0e-20));
        const CompiledModel model = load_compiled(dir);
        G02_CHECK(model.reactions.size() == 1);
        G02_CHECK(model.reactions[0].majorant_shape > 0.0);
    }
    {
        const fs::path dir = root / "valid_two";
        g02test::write_package(dir, g02test::two_channel_package(2.0e-20, 1.0e-20));
        const CompiledModel model = load_compiled(dir);
        G02_CHECK(model.reactions.size() == 2);
    }
    {
        // Completion criterion: a new background species plus a new supported
        // two-body channel must load and compile from CSV alone.
        const fs::path dir = root / "valid_extension";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic\n"
            "1,M,6.633521463e-26,0,background\n"
            "2,N,4.0e-26,0,background\n";
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,true\n"
            "2,N,ground,0.0,1,true\n";
        files["composition.csv"] =
            "species,element,count\n"
            "M,X,1\n"
            "N,Y,1\n";
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,elastic_M,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n"
            "2,elastic_N,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n";
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n"
            "1,background,M,ground,1\n"
            "2,projectile,e-,ground,1\n"
            "2,background,N,ground,1\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n"
            "1,M,ground,1\n"
            "2,e-,ground,1\n"
            "2,N,ground,1\n";
        files["rate_laws.csv"] =
            "reaction_id,kind,dataset_id,x_source,x_species\n"
            "1,cross_section,ds1,relative_energy_ev,\n"
            "2,cross_section,ds2,relative_energy_ev,\n";
        files["datasets.csv"] =
            "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
            "above_max_policy,source,version,license,notes\n"
            "ds1,tables/t1.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test\n"
            "ds2,tables/t2.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test\n";
        files["tables/t2.csv"] =
            "x,y\n"
            "0.0,1.0e-20\n"
            "1.0,1.0e-20\n";
        g02test::write_package(dir, files);
        const MccEngine engine = MccEngine::load(dir);
        G02_CHECK(engine.model().reactions.size() == 2);
        G02_CHECK(engine.species_id("N") != invalid_species);
    }

    // ---- CSV quoting and column count ------------------------------------
    {
        const fs::path dir = root / "unterminated_quote";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,\"e-,9.1093837139e-31,-1,kinetic\n"
            "1,M,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "unterminated quote");
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "species.csv:2");
    }
    {
        const fs::path dir = root / "mid_quote";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e\"-,9.1093837139e-31,-1,kinetic\n"
            "1,M,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "unexpected quote");
    }
    {
        const fs::path dir = root / "too_few_columns";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1\n"
            "1,M,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "species.csv:2");
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "fields");
    }
    {
        const fs::path dir = root / "too_many_columns";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic,extra\n"
            "1,M,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_THROWS(load_package(dir));
    }

    // ---- duplicates and unknown references -------------------------------
    {
        const fs::path dir = root / "duplicate_species_id";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic\n"
            "0,M,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "duplicate species id");
    }
    {
        const fs::path dir = root / "duplicate_species_name";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic\n"
            "1,e-,6.633521463e-26,0,background\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "duplicate species name");
    }
    {
        const fs::path dir = root / "duplicate_state";
        auto files = g02test::single_channel_package(2.0e-20);
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,true\n"
            "2,M,ground,1.0,1,false\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "duplicate state label");
    }
    {
        const fs::path dir = root / "unknown_species";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n"
            "1,background,Q,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "unknown species name 'Q'");
    }
    {
        const fs::path dir = root / "unknown_state";
        auto files = g02test::single_channel_package(2.0e-20);
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n"
            "1,M,excited,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "unknown state 'excited'");
    }

    // ---- units, order and rate-law agreement -----------------------------
    {
        const fs::path dir = root / "wrong_y_unit";
        auto files = g02test::single_channel_package(2.0e-20);
        files["datasets.csv"] =
            "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
            "above_max_policy,source,version,license,notes\n"
            "ds1,tables/t1.csv,energy,eV,m3/s,linear,zero,error,fixture,1,CC0-1.0,test\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "y_unit=m2");
    }
    {
        const fs::path dir = root / "cross_section_three_body";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n"
            "1,background,M,ground,2\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n"
            "1,M,ground,2\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "only defined for two-body");
    }
    {
        const fs::path dir = root / "bad_order";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n"
            "1,background,M,ground,1\n"
            "1,background,M,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "same background species is listed more than once");
    }
    {
        const fs::path dir = root / "bad_x_unit";
        auto files = g02test::single_channel_package(2.0e-20);
        files["datasets.csv"] =
            "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
            "above_max_policy,source,version,license,notes\n"
            "ds1,tables/t1.csv,energy,K,m2,linear,zero,error,fixture,1,CC0-1.0,test\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "requires x_unit 'eV'");
    }

    // ---- table validation -------------------------------------------------
    {
        const fs::path dir = root / "non_increasing";
        auto files = g02test::single_channel_package(2.0e-20);
        files["tables/t1.csv"] =
            "x,y\n"
            "1.0,2.0e-20\n"
            "0.0,2.0e-20\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "strictly increasing");
    }
    {
        const fs::path dir = root / "negative_value";
        auto files = g02test::single_channel_package(2.0e-20);
        files["tables/t1.csv"] =
            "x,y\n"
            "0.0,-1.0e-20\n"
            "1.0,2.0e-20\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "negative");
    }
    {
        const fs::path dir = root / "nan_value";
        auto files = g02test::single_channel_package(2.0e-20);
        files["tables/t1.csv"] =
            "x,y\n"
            "0.0,nan\n"
            "1.0,2.0e-20\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "NaN or infinite");
    }
    {
        const fs::path dir = root / "log_zero";
        auto files = g02test::single_channel_package(2.0e-20);
        files["datasets.csv"] =
            "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
            "above_max_policy,source,version,license,notes\n"
            "ds1,tables/t1.csv,energy,eV,m2,log-linear,zero,error,fixture,1,CC0-1.0,test\n";
        files["tables/t1.csv"] =
            "x,y\n"
            "0.0,0.0\n"
            "1.0,2.0e-20\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "strictly positive y");
    }

    // ---- checksum ---------------------------------------------------------
    {
        const fs::path dir = root / "bad_checksum";
        auto files = g02test::single_channel_package(2.0e-20);
        files["manifest.csv"] += "checksum.species.csv,0000000000000000\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "checksum mismatch");
    }
    {
        const fs::path dir = root / "good_checksum";
        auto files = g02test::single_channel_package(2.0e-20);
        g02test::write_package(dir, files);
        const std::string digest = fnv1a64_hex(dir / "species.csv");
        files["manifest.csv"] += "checksum.species.csv," + digest + "\n";
        g02test::write_package(dir, files);
        // A matching checksum must load without throwing.
        bool ok = true;
        try {
            (void)load_package(dir);
        } catch (const std::exception&) {
            ok = false;
        }
        G02_CHECK(ok);
    }

    // ---- conservation at compile time ------------------------------------
    {
        const fs::path dir = root / "element_imbalance";
        auto files = g02test::single_channel_package(2.0e-20);
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "not conserved");
    }
    {
        const fs::path dir = root / "charge_imbalance";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic\n"
            "1,M,6.633521463e-26,0,background\n"
            "2,M+,6.633430369e-26,1,kinetic\n";
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,true\n"
            "2,M+,ground,0.0,1,true\n";
        files["composition.csv"] =
            "species,element,count\n"
            "M,X,1\n"
            "M+,X,1\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,e-,ground,1\n"
            "1,M+,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "charge is not conserved");
    }
    {
        const fs::path dir = root / "unsupported_model";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,elastic,C02,0.0,0.0,0.0,0.0,opal_like,,,n_body_phase_space,true\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "not implemented");
    }

    // ---- runtime domain policy -------------------------------------------
    {
        const fs::path dir = root / "domain_error";
        g02test::write_package(dir, g02test::single_channel_package(2.0e-20));
        MccEngine engine = MccEngine::load(dir);
        CollisionRequest request;
        request.projectile.species = engine.species_id("e-");
        request.projectile.state = engine.state_id(request.projectile.species, "ground");
        // 5 eV electron against a table that ends at 1 eV.
        request.projectile.velocity = {1.325e6, 0.0, 0.0};
        request.projectile.id = 1;
        request.dt_s = 1.0e-3;
        request.seed = 7;
        BackgroundComponent component;
        component.species = engine.species_id("M");
        component.density_m3 = 1.0e20;
        component.temperature_k = 300.0;
        request.background.push_back(component);
        G02_CHECK_MESSAGE_CONTAINS(engine.collide(request), "declared domain");
    }

    // ---- strict schema: names, orphans, ground states, temperature grid ---
    {
        const fs::path dir = root / "duplicate_reaction_name";
        auto files = g02test::two_channel_package(2.0e-20, 1.0e-20);
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,same_name,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n"
            "2,same_name,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "duplicate reaction name");
    }
    {
        const fs::path dir = root / "orphan_reactant";
        auto files = g02test::single_channel_package(2.0e-20);
        files["reactants.csv"] += "99,projectile,e-,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir),
                                   "reactants.csv references unknown reaction id 99");
    }
    {
        const fs::path dir = root / "orphan_product";
        auto files = g02test::single_channel_package(2.0e-20);
        files["products.csv"] += "99,e-,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir),
                                   "products.csv references unknown reaction id 99");
    }
    {
        const fs::path dir = root / "multiple_ground";
        auto files = g02test::single_channel_package(2.0e-20);
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,true\n"
            "2,M,other,1.0,1,true\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "exactly one ground state");
    }
    {
        const fs::path dir = root / "missing_ground";
        auto files = g02test::single_channel_package(2.0e-20);
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,false\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "exactly one ground state (found 0)");
    }
    {
        const fs::path dir = root / "negative_temperature";
        auto files = g02test::single_channel_package(2.0e-20);
        files["rate_laws.csv"] =
            "reaction_id,kind,dataset_id,x_source,x_species\n"
            "1,rate_coefficient,ds1,temperature_k,M\n";
        files["datasets.csv"] =
            "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
            "above_max_policy,source,version,license,notes\n"
            "ds1,tables/t1.csv,temperature,K,m3/s,linear,error,error,fixture,1,CC0-1.0,test\n";
        files["tables/t1.csv"] =
            "x,y\n"
            "-1.0,1.0e-20\n"
            "300.0,1.0e-20\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_package(dir), "non-negative");
    }
    {
        // Missing composition entries are allowed and mean "no atomic-nucleus
        // element inventory"; element balance then trivially holds.
        const fs::path dir = root / "no_composition";
        auto files = g02test::single_channel_package(2.0e-20);
        files["composition.csv"] = "species,element,count\n";
        g02test::write_package(dir, files);
        const CompiledModel model = load_compiled(dir);
        G02_CHECK(model.composition.empty());
        G02_CHECK(model.reactions.size() == 1U);
    }
    {
        // The manifest composition key and the file are entirely optional.
        const fs::path dir = root / "absent_composition";
        auto files = g02test::single_channel_package(2.0e-20);
        const std::string line = "composition,composition.csv\n";
        const auto position = files["manifest.csv"].find(line);
        G02_REQUIRE(position != std::string::npos);
        files["manifest.csv"].erase(position, line.size());
        files.erase("composition.csv");
        g02test::write_package(dir, files);
        const CompiledModel model = load_compiled(dir);
        G02_CHECK(model.composition.empty());
        G02_CHECK(model.reactions.size() == 1U);
    }

    // ---- identity_exchange strict definition -----------------------------
    {
        const fs::path dir = root / "identity_unequal_mass";
        g02test::write_package(dir, g02test::identity_exchange_package(4.0e-26, 4.1e-26));
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "masses to be equal");
    }
    {
        const fs::path dir = root / "identity_ker_min";
        auto files = g02test::identity_exchange_package(4.0e-26, 4.0e-26);
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,resonant,C07,0.0,0.0,1.0,0.0,identity_exchange,,,n_body_phase_space,true\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "ker_min_ev=0");
    }

    // ---- single product cannot request a final relative kinetic energy ---
    {
        const fs::path dir = root / "single_product_ker_min";
        auto files = g02test::single_channel_package(2.0e-20);
        files["species.csv"] =
            "id,name,mass_kg,charge_state,representation\n"
            "0,e-,9.1093837139e-31,-1,kinetic\n"
            "1,M,4.0e-26,0,background\n"
            "2,M+,4.0e-26,1,background\n";
        files["states.csv"] =
            "id,species,label,energy_ev,degeneracy,is_ground\n"
            "0,e-,ground,0.0,1,true\n"
            "1,M,ground,0.0,1,true\n"
            "2,M+,ground,0.0,1,true\n";
        files["composition.csv"] =
            "species,element,count\n"
            "M,X,1\n"
            "M+,X,1\n";
        files["reactions.csv"] =
            "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
            "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
            "1,recomb,C08,0.0,0.0,1.0,0.0,isotropic,,,n_body_phase_space,true\n";
        files["reactants.csv"] =
            "reaction_id,role,species,state,stoichiometry\n"
            "1,projectile,e-,ground,1\n"
            "1,background,M+,ground,1\n";
        files["products.csv"] =
            "reaction_id,species,state,stoichiometry\n"
            "1,M,ground,1\n";
        g02test::write_package(dir, files);
        G02_CHECK_MESSAGE_CONTAINS(load_compiled(dir), "ker_min_ev>0");
    }

    // ---- non-finite compile options are rejected -------------------------
    {
        const fs::path dir = root / "infinite_tolerance";
        g02test::write_package(dir, g02test::single_channel_package(2.0e-20));
        CompileOptions options;
        options.relative_tolerance = std::numeric_limits<Real>::infinity();
        G02_CHECK_MESSAGE_CONTAINS(compile_model(load_package(dir), options), "finite");
    }
    {
        const fs::path dir = root / "overflowing_majorant_scale";
        g02test::write_package(dir, g02test::single_channel_package(2.0e-20));
        CompileOptions options;
        options.majorant_safety_factor = 1.0e308;
        options.diagnostic_majorant_scale = 1.0e308;
        G02_CHECK_MESSAGE_CONTAINS(compile_model(load_package(dir), options), "finite");
    }

    std::filesystem::remove_all(root);
    return g02test::summary("test_schema");
}
