// SPDX-License-Identifier: Apache-2.0
// Builds small, self-contained G02_MCC_network model packages in a temporary
// directory so that schema, parser and C01 tests can mutate one file at a time
// without shipping dozens of fixture directories.
#pragma once

#include <unistd.h>

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>

namespace g02test {

[[nodiscard]] inline std::string number(const double value) {
    std::ostringstream output;
    output << std::setprecision(17) << value;
    return output.str();
}

using FileMap = std::map<std::string, std::string>;

inline std::filesystem::path temp_package_root(const std::string& tag) {
    const auto base = std::filesystem::temp_directory_path() /
                      ("g02_mcc_test_" + tag + "_" + std::to_string(::getpid()));
    std::filesystem::remove_all(base);
    std::filesystem::create_directories(base);
    return base;
}

inline void write_package(const std::filesystem::path& directory, const FileMap& files) {
    std::filesystem::create_directories(directory);
    for (const auto& [relative, content] : files) {
        const std::filesystem::path path = directory / relative;
        std::filesystem::create_directories(path.parent_path());
        std::ofstream output(path, std::ios::binary);
        if (!output) throw std::runtime_error("cannot write fixture file " + path.string());
        output << content;
        if (!output) throw std::runtime_error("cannot write fixture file " + path.string());
    }
}

inline FileMap single_channel_package(double sigma_m2) {
    const std::string sigma = number(sigma_m2);
    FileMap files;
    files["manifest.csv"] =
        "key,value\n"
        "format,g02-mcc-model-package\n"
        "format_version,1\n"
        "name,fixture_single\n"
        "version,1.0.0\n"
        "description,synthetic fixture\n"
        "species,species.csv\n"
        "states,states.csv\n"
        "composition,composition.csv\n"
        "reactions,reactions.csv\n"
        "reactants,reactants.csv\n"
        "products,products.csv\n"
        "rate_laws,rate_laws.csv\n"
        "datasets,datasets.csv\n";
    files["species.csv"] =
        "id,name,mass_kg,charge_state,representation\n"
        "0,e-,9.1093837139e-31,-1,kinetic\n"
        "1,M,6.633521463e-26,0,background\n";
    files["states.csv"] =
        "id,species,label,energy_ev,degeneracy,is_ground\n"
        "0,e-,ground,0.0,1,true\n"
        "1,M,ground,0.0,1,true\n";
    files["composition.csv"] =
        "species,element,count\n"
        "M,X,1\n";
    files["reactions.csv"] =
        "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
        "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
        "1,elastic,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n";
    files["reactants.csv"] =
        "reaction_id,role,species,state,stoichiometry\n"
        "1,projectile,e-,ground,1\n"
        "1,background,M,ground,1\n";
    files["products.csv"] =
        "reaction_id,species,state,stoichiometry\n"
        "1,e-,ground,1\n"
        "1,M,ground,1\n";
    files["rate_laws.csv"] =
        "reaction_id,kind,dataset_id,x_source,x_species\n"
        "1,cross_section,ds1,relative_energy_ev,\n";
    files["datasets.csv"] =
        "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
        "above_max_policy,source,version,license,notes\n"
        "ds1,tables/t1.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n";
    files["tables/t1.csv"] =
        "x,y\n"
        "0.0," + sigma + "\n"
        "1.0," + sigma + "\n";
    return files;
}

// Two two-body channels on the same background: channel 1 has twice the cross
// section of channel 2. Table domain is [0, 1] eV so the majorant is tight and
// the statistics are controllable.
inline FileMap two_channel_package(double sigma_a, double sigma_b) {
    FileMap files = single_channel_package(sigma_a);
    files["reactions.csv"] =
        "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
        "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
        "1,elastic_a,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n"
        "2,elastic_b,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n";
    files["reactants.csv"] =
        "reaction_id,role,species,state,stoichiometry\n"
        "1,projectile,e-,ground,1\n"
        "1,background,M,ground,1\n"
        "2,projectile,e-,ground,1\n"
        "2,background,M,ground,1\n";
    files["products.csv"] =
        "reaction_id,species,state,stoichiometry\n"
        "1,e-,ground,1\n"
        "1,M,ground,1\n"
        "2,e-,ground,1\n"
        "2,M,ground,1\n";
    files["rate_laws.csv"] =
        "reaction_id,kind,dataset_id,x_source,x_species\n"
        "1,cross_section,ds1,relative_energy_ev,\n"
        "2,cross_section,ds2,relative_energy_ev,\n";
    files["datasets.csv"] =
        "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
        "above_max_policy,source,version,license,notes\n"
        "ds1,tables/t1.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n"
        "ds2,tables/t2.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n";
    files["tables/t1.csv"] =
        "x,y\n"
        "0.0," + number(sigma_a) + "\n"
        "1.0," + number(sigma_a) + "\n";
    files["tables/t2.csv"] =
        "x,y\n"
        "0.0," + number(sigma_b) + "\n"
        "1.0," + number(sigma_b) + "\n";
    return files;
}

// A kinetic species A with ground / excited / metastable states and a
// background B. Channel 1 is ground-only (C03 ground -> excited); channel 2 is
// excited-only (C02 elastic). No channel matches the metastable state. The
// tables span [0, 20] eV so a 20 eV projectile samples close to the majorant
// and real events dominate.
inline FileMap two_state_kinetic_package(double sigma_ground, double sigma_excited) {
    FileMap files;
    files["manifest.csv"] =
        "key,value\n"
        "format,g02-mcc-model-package\n"
        "format_version,1\n"
        "name,fixture_two_state\n"
        "version,1.0.0\n"
        "description,synthetic fixture\n"
        "species,species.csv\n"
        "states,states.csv\n"
        "composition,composition.csv\n"
        "reactions,reactions.csv\n"
        "reactants,reactants.csv\n"
        "products,products.csv\n"
        "rate_laws,rate_laws.csv\n"
        "datasets,datasets.csv\n";
    files["species.csv"] =
        "id,name,mass_kg,charge_state,representation\n"
        "0,A,4.0e-26,0,kinetic\n"
        "1,B,4.0e-26,0,background\n";
    files["states.csv"] =
        "id,species,label,energy_ev,degeneracy,is_ground\n"
        "0,A,ground,0.0,1,true\n"
        "1,A,excited,1.0,1,false\n"
        "2,A,metastable,2.0,1,false\n"
        "3,B,ground,0.0,1,true\n";
    files["composition.csv"] =
        "species,element,count\n"
        "A,X,1\n"
        "B,X,1\n";
    files["reactions.csv"] =
        "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
        "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
        "1,A_ground_excite,C03,1.0,-1.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n"
        "2,A_excited_elastic,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true\n";
    files["reactants.csv"] =
        "reaction_id,role,species,state,stoichiometry\n"
        "1,projectile,A,ground,1\n"
        "1,background,B,ground,1\n"
        "2,projectile,A,excited,1\n"
        "2,background,B,ground,1\n";
    files["products.csv"] =
        "reaction_id,species,state,stoichiometry\n"
        "1,A,excited,1\n"
        "1,B,ground,1\n"
        "2,A,excited,1\n"
        "2,B,ground,1\n";
    files["rate_laws.csv"] =
        "reaction_id,kind,dataset_id,x_source,x_species\n"
        "1,cross_section,ds1,relative_energy_ev,\n"
        "2,cross_section,ds2,relative_energy_ev,\n";
    files["datasets.csv"] =
        "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
        "above_max_policy,source,version,license,notes\n"
        "ds1,tables/t1.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n"
        "ds2,tables/t2.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n";
    files["tables/t1.csv"] =
        "x,y\n"
        "0.0," + number(sigma_ground) + "\n"
        "20.0," + number(sigma_ground) + "\n";
    files["tables/t2.csv"] =
        "x,y\n"
        "0.0," + number(sigma_excited) + "\n"
        "20.0," + number(sigma_excited) + "\n";
    return files;
}

// Strict resonant charge exchange I+ + I -> I + I+ with identity_exchange.
// `mass_ion` and `mass_neutral` let a test build a non-resonant (rejected)
// package; the shipped demo uses exactly equal masses. The products are listed
// neutral-first on purpose.
inline FileMap identity_exchange_package(double mass_ion, double mass_neutral) {
    FileMap files;
    files["manifest.csv"] =
        "key,value\n"
        "format,g02-mcc-model-package\n"
        "format_version,1\n"
        "name,fixture_identity\n"
        "version,1.0.0\n"
        "description,synthetic fixture\n"
        "species,species.csv\n"
        "states,states.csv\n"
        "composition,composition.csv\n"
        "reactions,reactions.csv\n"
        "reactants,reactants.csv\n"
        "products,products.csv\n"
        "rate_laws,rate_laws.csv\n"
        "datasets,datasets.csv\n";
    files["species.csv"] =
        "id,name,mass_kg,charge_state,representation\n"
        "0,Iplus," + number(mass_ion) + ",1,kinetic\n"
        "1,I," + number(mass_neutral) + ",0,background\n";
    files["states.csv"] =
        "id,species,label,energy_ev,degeneracy,is_ground\n"
        "0,Iplus,ground,0.0,1,true\n"
        "1,I,ground,0.0,1,true\n";
    files["composition.csv"] =
        "species,element,count\n"
        "Iplus,X,1\n"
        "I,X,1\n";
    files["reactions.csv"] =
        "id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,"
        "angular_model,angular_cos_min,angular_cos_max,energy_model,enabled\n"
        "1,resonant_exchange,C07,0.0,0.0,0.0,0.0,identity_exchange,,,n_body_phase_space,true\n";
    files["reactants.csv"] =
        "reaction_id,role,species,state,stoichiometry\n"
        "1,projectile,Iplus,ground,1\n"
        "1,background,I,ground,1\n";
    files["products.csv"] =
        "reaction_id,species,state,stoichiometry\n"
        "1,I,ground,1\n"
        "1,Iplus,ground,1\n";
    files["rate_laws.csv"] =
        "reaction_id,kind,dataset_id,x_source,x_species\n"
        "1,cross_section,ds1,relative_energy_ev,\n";
    files["datasets.csv"] =
        "dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,"
        "above_max_policy,source,version,license,notes\n"
        "ds1,tables/t1.csv,energy,eV,m2,linear,zero,error,fixture,1,CC0-1.0,test only\n";
    files["tables/t1.csv"] =
        "x,y\n"
        "0.0,2.0e-19\n"
        "10.0,2.0e-19\n";
    return files;
}

} // namespace g02test
