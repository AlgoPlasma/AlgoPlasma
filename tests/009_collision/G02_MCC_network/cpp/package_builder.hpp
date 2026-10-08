// SPDX-License-Identifier: Apache-2.0
// Builds small, self-contained G02_MCC_network model packages in a temporary
// directory so that schema, parser and C01 tests can mutate one file at a time
// without shipping dozens of fixture directories.
#pragma once

#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <system_error>
#include <vector>

namespace g02test {

[[nodiscard]] inline std::string number(const double value) {
    std::ostringstream output;
    output << std::setprecision(17) << value;
    return output.str();
}

using FileMap = std::map<std::string, std::string>;

[[nodiscard]] inline std::uint64_t process_id() noexcept {
#if defined(_WIN32)
    return static_cast<std::uint64_t>(::_getpid());
#else
    return static_cast<std::uint64_t>(::getpid());
#endif
}

inline std::filesystem::path temp_package_root(const std::string& tag) {
    const auto base = std::filesystem::temp_directory_path() /
                      ("g02_mcc_test_" + tag + "_" + std::to_string(process_id()));
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
// package; the generated demo uses exactly equal masses. The products are listed
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


// Own only a newly created temporary directory. Explicit user model paths never
// pass through this class, so its destructor cannot remove external data.
class TemporaryPackage {
public:
    TemporaryPackage(const FileMap& files, const std::string& tag) {
        // Atomically claim a fresh directory with standard filesystem calls.
        // The process/time/counter names keep parallel examples independent;
        // none of these values is a physical or simulation random parameter.
        static std::atomic<std::uint64_t> sequence{0};
        const auto stamp = static_cast<std::uint64_t>(
            std::chrono::steady_clock::now().time_since_epoch().count());
        const auto prefix = "g02_mcc_" + tag + "_" + std::to_string(process_id()) +
                            "_" + std::to_string(stamp) + "_";
        const auto temporary_root = std::filesystem::temp_directory_path();
        for (unsigned attempt = 0; attempt < 128U; ++attempt) {
            const auto candidate = temporary_root / (prefix + std::to_string(
                sequence.fetch_add(1, std::memory_order_relaxed)));
            std::error_code error;
            if (std::filesystem::create_directory(candidate, error)) {
                directory_ = candidate; // Only this successfully claimed path is owned.
                break;
            }
            if (error && error != std::errc::file_exists) {
                throw std::runtime_error("cannot create temporary model package: " +
                                         error.message());
            }
        }
        if (directory_.empty()) {
            throw std::runtime_error("cannot claim a unique temporary model directory");
        }
        try {
            write_package(directory_, files);
        } catch (...) {
            std::error_code ignored;
            std::filesystem::remove_all(directory_, ignored);
            throw;
        }
    }

    ~TemporaryPackage() {
        std::error_code ignored;
        std::filesystem::remove_all(directory_, ignored);
    }
    TemporaryPackage(const TemporaryPackage&) = delete;
    TemporaryPackage& operator=(const TemporaryPackage&) = delete;
    [[nodiscard]] const std::filesystem::path& path() const noexcept { return directory_; }

private:
    std::filesystem::path directory_;
};

// Synthetic demo_binary fixture; generated at test time, not physical data.
inline FileMap demo_binary_package() {
    FileMap files;
    files["composition.csv"] = R"G02CSV(species,element,count
M,X,1
M2,X,2
M+,X,1
M-,X,1
M2+,X,2
)G02CSV";
    files["datasets.csv"] = R"G02CSV(dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,above_max_policy,source,version,license,notes
ds_e_M_elastic,tables/e_M_elastic.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_M_excitation,tables/e_M_excitation.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_M2_dissociation,tables/e_M2_dissociation.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_M_ionization,tables/e_M_ionization.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_M2_attachment,tables/e_M2_attachment.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_Mplus_M_charge_exchange,tables/Mplus_M_charge_exchange.csv,energy,eV,m2,linear,zero,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_Mplus_recombination,tables/e_Mplus_recombination.csv,temperature,K,m3/s,log-log,error,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
)G02CSV";
    files["manifest.csv"] = R"G02CSV(key,value
format,g02-mcc-model-package
format_version,1
name,demo_binary
version,1.0.0
description,Synthetic software-demonstration package for G02_MCC_network. NOT FOR RESEARCH USE.
species,species.csv
states,states.csv
composition,composition.csv
reactions,reactions.csv
reactants,reactants.csv
products,products.csv
rate_laws,rate_laws.csv
datasets,datasets.csv
)G02CSV";
    files["products.csv"] = R"G02CSV(reaction_id,species,state,stoichiometry
1,e-,ground,1
1,M,ground,1
2,e-,ground,1
2,M,excited_1,1
3,e-,ground,1
3,M,ground,2
4,e-,ground,2
4,M+,ground,1
5,M-,ground,1
5,M,ground,1
6,M,ground,1
6,M+,ground,1
7,M,ground,2
)G02CSV";
    files["rate_laws.csv"] = R"G02CSV(reaction_id,kind,dataset_id,x_source,x_species
1,cross_section,ds_e_M_elastic,relative_energy_ev,
2,cross_section,ds_e_M_excitation,relative_energy_ev,
3,cross_section,ds_e_M2_dissociation,relative_energy_ev,
4,cross_section,ds_e_M_ionization,relative_energy_ev,
5,cross_section,ds_e_M2_attachment,relative_energy_ev,
6,cross_section,ds_Mplus_M_charge_exchange,relative_energy_ev,
7,rate_coefficient,ds_e_Mplus_recombination,temperature_k,M2+
)G02CSV";
    files["reactants.csv"] = R"G02CSV(reaction_id,role,species,state,stoichiometry
1,projectile,e-,ground,1
1,background,M,ground,1
2,projectile,e-,ground,1
2,background,M,ground,1
3,projectile,e-,ground,1
3,background,M2,ground,1
4,projectile,e-,ground,1
4,background,M,ground,1
5,projectile,e-,ground,1
5,background,M2,ground,1
6,projectile,M+,ground,1
6,background,M,ground,1
7,projectile,e-,ground,1
7,background,M2+,ground,1
)G02CSV";
    files["reactions.csv"] = R"G02CSV(id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,angular_model,angular_cos_min,angular_cos_max,energy_model,enabled
1,e_M_elastic,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true
2,e_M_excitation,C03,11.5,-11.5,0.0,0.0,isotropic,,,n_body_phase_space,true
3,e_M2_dissociation,C04,8.0,-8.0,0.0,0.0,isotropic,,,n_body_phase_space,true
4,e_M_ionization,C05,15.8,-15.8,0.0,0.0,isotropic,,,n_body_phase_space,true
5,e_M2_attachment,C06,0.0,0.2,0.0,0.0,isotropic,,,n_body_phase_space,true
6,Mplus_M_charge_exchange,C07,0.0,0.0,0.0,0.0,identity_exchange,,,n_body_phase_space,true
7,e_Mplus_recombination,C08,0.0,15.8,0.0,15.8,isotropic,,,n_body_phase_space,true
)G02CSV";
    files["species.csv"] = R"G02CSV(id,name,mass_kg,charge_state,representation
0,e-,9.1093837139e-31,-1,kinetic
1,M,6.633521463e-26,0,background
2,M2,1.326704293e-25,0,background
3,M+,6.633521463e-26,1,kinetic
4,M-,6.633612557e-26,-1,kinetic
5,M2+,1.3266941219e-25,1,background
)G02CSV";
    files["states.csv"] = R"G02CSV(id,species,label,energy_ev,degeneracy,is_ground
0,e-,ground,0.0,1,true
1,M,ground,0.0,1,true
2,M,excited_1,11.5,1,false
3,M2,ground,0.0,1,true
4,M+,ground,0.0,1,true
5,M-,ground,0.0,1,true
6,M2+,ground,0.0,1,true
)G02CSV";
    files["tables/Mplus_M_charge_exchange.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,4.0e-19
0.1,4.0e-19
1.0,3.0e-19
5.0,2.0e-19
10.0,1.5e-19
20.0,1.2e-19
50.0,8.0e-20
200.0,5.0e-20
)G02CSV";
    files["tables/e_M2_attachment.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,0.0
0.2,2.0e-21
1.0,8.0e-21
3.0,2.0e-21
10.0,2.0e-22
50.0,5.0e-23
200.0,1.0e-23
)G02CSV";
    files["tables/e_M2_dissociation.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,0.0
8.0,0.0
12.0,5.0e-21
20.0,9.0e-21
50.0,7.0e-21
100.0,4.0e-21
200.0,2.0e-21
)G02CSV";
    files["tables/e_M_elastic.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,2.0e-20
1.0,2.5e-20
5.0,3.0e-20
10.0,2.8e-20
20.0,2.4e-20
50.0,1.8e-20
100.0,1.2e-20
200.0,8.0e-21
)G02CSV";
    files["tables/e_M_excitation.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,0.0
11.5,0.0
15.0,7.0e-21
20.0,1.2e-20
50.0,8.0e-21
100.0,4.0e-21
200.0,2.0e-21
)G02CSV";
    files["tables/e_M_ionization.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid cross sections
x,y
0.0,0.0
15.8,0.0
20.0,3.0e-21
30.0,8.0e-21
50.0,1.1e-20
100.0,7.0e-21
200.0,4.0e-21
)G02CSV";
    files["tables/e_Mplus_recombination.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid rate coefficients
x,y
100.0,2.0e-13
300.0,1.6e-13
1000.0,1.0e-13
3000.0,6.0e-14
10000.0,3.0e-14
100000.0,5.0e-15
1000000.0,1.0e-15
10000000.0,2.0e-16
)G02CSV";
    return files;
}

// Synthetic demo_three_body fixture; generated at test time, not physical data.
inline FileMap demo_three_body_package() {
    FileMap files;
    files["composition.csv"] = R"G02CSV(species,element,count
M,X,1
M2,X,2
M+,X,1
M-,X,1
)G02CSV";
    files["datasets.csv"] = R"G02CSV(dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,above_max_policy,source,version,license,notes
ds_e_M_M_elastic,tables/e_M_M_elastic.csv,temperature,K,m6/s,log-log,error,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_M_M2_elastic,tables/e_M_M2_elastic.csv,temperature,K,m6/s,log-log,error,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
ds_e_Mplus_M_recombination,tables/e_Mplus_M_recombination.csv,temperature,K,m6/s,log-log,error,error,synthetic,1.0,CC0-1.0,SYNTHETIC demonstration values only
)G02CSV";
    files["manifest.csv"] = R"G02CSV(key,value
format,g02-mcc-model-package
format_version,1
name,demo_three_body
version,1.0.0
description,Synthetic three-body software-demonstration package. NOT FOR RESEARCH USE.
species,species.csv
states,states.csv
composition,composition.csv
reactions,reactions.csv
reactants,reactants.csv
products,products.csv
rate_laws,rate_laws.csv
datasets,datasets.csv
)G02CSV";
    files["products.csv"] = R"G02CSV(reaction_id,species,state,stoichiometry
1,e-,ground,1
1,M,ground,2
2,e-,ground,1
2,M,ground,1
2,M2,ground,1
3,M,ground,2
)G02CSV";
    files["rate_laws.csv"] = R"G02CSV(reaction_id,kind,dataset_id,x_source,x_species
1,rate_coefficient,ds_e_M_M_elastic,temperature_k,M
2,rate_coefficient,ds_e_M_M2_elastic,temperature_k,M
3,rate_coefficient,ds_e_Mplus_M_recombination,temperature_k,M
)G02CSV";
    files["reactants.csv"] = R"G02CSV(reaction_id,role,species,state,stoichiometry
1,projectile,e-,ground,1
1,background,M,ground,2
2,projectile,e-,ground,1
2,background,M,ground,1
2,background,M2,ground,1
3,projectile,e-,ground,1
3,background,M+,ground,1
3,background,M,ground,1
)G02CSV";
    files["reactions.csv"] = R"G02CSV(id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,angular_model,angular_cos_min,angular_cos_max,energy_model,enabled
1,e_M_M_elastic_3body,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true
2,e_M_M2_elastic_3body,C02,0.0,0.0,0.0,0.0,isotropic,,,n_body_phase_space,true
3,e_Mplus_M_recombination_3body,C08,0.0,15.8,0.0,0.0,isotropic,,,n_body_phase_space,true
)G02CSV";
    files["species.csv"] = R"G02CSV(id,name,mass_kg,charge_state,representation
0,e-,9.1093837139e-31,-1,kinetic
1,M,6.633521463e-26,0,background
2,M2,1.326704293e-25,0,background
3,M+,6.633430369e-26,1,background
4,M-,6.633612557e-26,-1,kinetic
)G02CSV";
    files["states.csv"] = R"G02CSV(id,species,label,energy_ev,degeneracy,is_ground
0,e-,ground,0.0,1,true
1,M,ground,0.0,1,true
2,M2,ground,0.0,1,true
3,M+,ground,0.0,1,true
4,M-,ground,0.0,1,true
)G02CSV";
    files["tables/e_M_M2_elastic.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid rate coefficients
x,y
100.0,3.0e-42
300.0,2.0e-42
1000.0,1.2e-42
3000.0,6.0e-43
10000.0,2.5e-43
100000.0,6.0e-44
1000000.0,1.2e-44
10000000.0,2.5e-45
)G02CSV";
    files["tables/e_M_M_elastic.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid rate coefficients
x,y
100.0,2.0e-42
300.0,1.5e-42
1000.0,1.0e-42
3000.0,5.0e-43
10000.0,2.0e-43
100000.0,5.0e-44
1000000.0,1.0e-44
10000000.0,2.0e-45
)G02CSV";
    files["tables/e_Mplus_M_recombination.csv"] = R"G02CSV(# SYNTHETIC demonstration values only - not valid rate coefficients
x,y
100.0,5.0e-39
300.0,4.0e-39
1000.0,3.0e-39
3000.0,2.0e-39
10000.0,1.0e-39
100000.0,2.0e-40
1000000.0,4.0e-41
10000000.0,8.0e-42
)G02CSV";
    return files;
}

// Synthetic collision_box_elastic fixture; generated at test time, not physical data.
inline FileMap collision_box_package() {
    FileMap files;
    files["composition.csv"] = R"G02CSV(species,element,count
A,X,1
B,Y,1
)G02CSV";
    files["datasets.csv"] = R"G02CSV(dataset_id,path,x_axis,x_unit,y_unit,interpolation,below_min_policy,above_max_policy,source,version,license,notes
ds_elastic,tables/elastic.csv,temperature,K,m3/s,linear,error,error,synthetic,1.0,CC0-1.0,SYNTHETIC constant coefficient for code validation only
)G02CSV";
    files["manifest.csv"] = R"G02CSV(key,value
format,g02-mcc-model-package
format_version,1
name,collision_box_elastic
version,1.0.0
description,Synthetic constant-rate equal-mass elastic thermalization test. NOT FOR RESEARCH USE.
species,species.csv
states,states.csv
composition,composition.csv
reactions,reactions.csv
reactants,reactants.csv
products,products.csv
rate_laws,rate_laws.csv
datasets,datasets.csv
)G02CSV";
    files["products.csv"] = R"G02CSV(reaction_id,species,state,stoichiometry
1,A,ground,1
1,B,ground,1
)G02CSV";
    files["rate_laws.csv"] = R"G02CSV(reaction_id,kind,dataset_id,x_source,x_species
1,rate_coefficient,ds_elastic,temperature_k,B
)G02CSV";
    files["reactants.csv"] = R"G02CSV(reaction_id,role,species,state,stoichiometry
1,projectile,A,ground,1
1,background,B,ground,1
)G02CSV";
    files["reactions.csv"] = R"G02CSV(id,name,algorithm,threshold_ev,q_value_ev,ker_min_ev,radiated_energy_ev,angular_model,angular_cos_min,angular_cos_max,energy_model,enabled
1,A_B_elastic,C02,0,0,0,0,isotropic,,,n_body_phase_space,true
)G02CSV";
    files["species.csv"] = R"G02CSV(id,name,mass_kg,charge_state,representation
0,A,4e-26,0,kinetic
1,B,4e-26,0,background
)G02CSV";
    files["states.csv"] = R"G02CSV(id,species,label,energy_ev,degeneracy,is_ground
0,A,ground,0,1,true
1,B,ground,0,1,true
)G02CSV";
    files["tables/elastic.csv"] = R"G02CSV(x,y
100,1e-14
10000,1e-14
)G02CSV";
    return files;
}

} // namespace g02test
