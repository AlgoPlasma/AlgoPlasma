// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：load_model_package 是主入口，按依赖顺序把多张 CSV 拼成模型。
// 先建立物种/能级，再加载数据表和反应项，最后按 reaction_id 连接各表。
// 这里检查格式和引用；守恒、反应阶数等物理约束交给 compile_model。

#include "model.hpp"

#include <algorithm>
#include <cmath>
#include <set>
#include <sstream>
#include <utility>

namespace algoplasma {
namespace mcc {
namespace {

[[nodiscard]] std::string row_context(const CsvTable& table, const CsvRow& row) {
    return table.path.string() + ":" + std::to_string(row.line);
}

[[nodiscard]] std::string normalize_key(std::string value) {
    value = to_lower(trim(std::move(value)));
    for (char& c : value) {
        if (c == '-' || c == ' ' || c == '/') c = '_';
    }
    return value;
}

[[nodiscard]] SpeciesId parse_species_id(const CsvTable& table, const CsvRow& row,
                                         const std::string_view column) {
    const long long value = csv_int(table, row, column);
    if (value < 0 || value > static_cast<long long>(invalid_species) - 1) {
        throw Error(row_context(table, row) + ": column '" + std::string(column) +
                    "' must fit in an unsigned 16-bit species id");
    }
    return static_cast<SpeciesId>(value);
}

[[nodiscard]] StateId parse_state_id(const CsvTable& table, const CsvRow& row,
                                     const std::string_view column) {
    const long long value = csv_int(table, row, column);
    if (value < 0 || value > static_cast<long long>(invalid_state) - 1) {
        throw Error(row_context(table, row) + ": column '" + std::string(column) +
                    "' must fit in an unsigned 16-bit state id");
    }
    return static_cast<StateId>(value);
}

[[nodiscard]] ReactionId parse_reaction_id(const CsvTable& table, const CsvRow& row,
                                           const std::string_view column) {
    const long long value = csv_int(table, row, column);
    if (value <= 0 || value > static_cast<long long>(invalid_reaction) - 1) {
        throw Error(row_context(table, row) + ": column '" + std::string(column) +
                    "' must be a positive reaction id");
    }
    return static_cast<ReactionId>(value);
}

[[nodiscard]] unsigned parse_count(const CsvTable& table, const CsvRow& row,
                                   const std::string_view column) {
    const long long value = csv_int(table, row, column);
    if (value <= 0 || value > 1'000'000) {
        throw Error(row_context(table, row) + ": column '" + std::string(column) +
                    "' must be a positive stoichiometric count");
    }
    return static_cast<unsigned>(value);
}

// 这里只规范单位拼写，不进行 keV->eV 等数值换算；不支持的单位直接报错。
void require_unit_pair(Table& table, const std::string& context) {
    const std::string axis = normalize_key(table.x_axis);
    const std::string xunit = normalize_key(table.x_unit);
    if (axis == "energy" && xunit != "ev") {
        throw Error(context + ": x_axis 'energy' requires x_unit 'eV'");
    }
    if (axis == "temperature" && xunit != "k") {
        throw Error(context + ": x_axis 'temperature' requires x_unit 'K'");
    }
    if (axis != "energy" && axis != "temperature") {
        throw Error(context + ": x_axis must be 'energy' or 'temperature'");
    }
    const std::string yunit = normalize_key(table.y_unit);
    if (yunit != "m2" && yunit != "m3_s" && yunit != "m6_s") {
        throw Error(context + ": y_unit must be 'm2', 'm3/s' or 'm6/s'");
    }
    // Canonicalize accepted spellings so downstream checks compare one form.
    table.x_axis = axis;
    table.x_unit = axis == "energy" ? "eV" : "K";
    table.y_unit = yunit == "m2" ? "m2" : (yunit == "m3_s" ? "m3/s" : "m6/s");
}

[[nodiscard]] std::string manifest_value(
    const std::map<std::string, std::string>& manifest, const std::string& key) {
    const auto found = manifest.find(key);
    if (found == manifest.end() || found->second.empty()) {
        throw Error("manifest.csv: missing required key '" + key + "'");
    }
    return found->second;
}

} // namespace

// ---------------------------------------------------------------------------
// 1. 配置文字与枚举：接受指定别名，但未知算法/模型不能自动猜测。
// ---------------------------------------------------------------------------

CollisionAlgorithm collision_algorithm_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key == "c02" || key == "c02_elastic" || key == "elastic") {
        return CollisionAlgorithm::C02Elastic;
    }
    if (key == "c03" || key == "c03_discrete_transition" || key == "discrete_transition" ||
        key == "excitation" || key == "superelastic") {
        return CollisionAlgorithm::C03DiscreteTransition;
    }
    if (key == "c04" || key == "c04_dissociation" || key == "dissociation") {
        return CollisionAlgorithm::C04Dissociation;
    }
    if (key == "c05" || key == "c05_ionization" || key == "ionization") {
        return CollisionAlgorithm::C05Ionization;
    }
    if (key == "c06" || key == "c06_attachment_detachment" || key == "attachment" ||
        key == "detachment") {
        return CollisionAlgorithm::C06AttachmentDetachment;
    }
    if (key == "c07" || key == "c07_charge_exchange" || key == "charge_exchange") {
        return CollisionAlgorithm::C07ChargeExchange;
    }
    if (key == "c08" || key == "c08_recombination" || key == "recombination" ||
        key == "mutual_neutralization") {
        return CollisionAlgorithm::C08Recombination;
    }
    throw Error("unknown collision algorithm '" + value + "'");
}

AngularModel angular_model_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key.empty() || key == "isotropic") return AngularModel::Isotropic;
    if (key == "cone" || key == "cosine_range") return AngularModel::Cone;
    if (key == "identity_exchange" || key == "identity") return AngularModel::IdentityExchange;
    if (key == "opal" || key == "opal_like") {
        throw Error("angular model '" + value + "' is not implemented by G02_MCC_network v1");
    }
    throw Error("unknown angular model '" + value + "'");
}

EnergyModel energy_model_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key.empty() || key == "n_body_phase_space" || key == "phase_space" ||
        key == "nbody_phase_space") {
        return EnergyModel::NBodyPhaseSpace;
    }
    if (key == "equal_share" || key == "equal") return EnergyModel::EqualShare;
    if (key == "opal" || key == "opal_like") {
        throw Error("energy model '" + value + "' is not implemented by G02_MCC_network v1");
    }
    throw Error("unknown energy model '" + value + "'");
}

Representation representation_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key == "kinetic") return Representation::Kinetic;
    if (key == "background" || key == "reservoir") return Representation::Background;
    throw Error("unknown species representation '" + value + "'");
}

RateKind rate_kind_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key == "cross_section" || key == "crosssection") return RateKind::CrossSection;
    if (key == "rate_coefficient" || key == "ratecoefficient") return RateKind::RateCoefficient;
    throw Error("unknown rate law kind '" + value + "'");
}

ReactantRole reactant_role_from_string(const std::string& value) {
    const std::string key = normalize_key(value);
    if (key == "projectile" || key == "kinetic") return ReactantRole::Projectile;
    if (key == "background" || key == "reservoir" || key == "target") {
        return ReactantRole::Background;
    }
    throw Error("unknown reactant role '" + value + "'");
}

const char* to_string(const CollisionAlgorithm value) noexcept {
    switch (value) {
    case CollisionAlgorithm::C02Elastic: return "C02_elastic";
    case CollisionAlgorithm::C03DiscreteTransition: return "C03_discrete_transition";
    case CollisionAlgorithm::C04Dissociation: return "C04_dissociation";
    case CollisionAlgorithm::C05Ionization: return "C05_ionization";
    case CollisionAlgorithm::C06AttachmentDetachment: return "C06_attachment_detachment";
    case CollisionAlgorithm::C07ChargeExchange: return "C07_charge_exchange";
    case CollisionAlgorithm::C08Recombination: return "C08_recombination";
    }
    return "unknown";
}

const char* to_string(const AngularModel value) noexcept {
    switch (value) {
    case AngularModel::Isotropic: return "isotropic";
    case AngularModel::Cone: return "cone";
    case AngularModel::IdentityExchange: return "identity_exchange";
    }
    return "unknown";
}

const char* to_string(const EnergyModel value) noexcept {
    switch (value) {
    case EnergyModel::NBodyPhaseSpace: return "n_body_phase_space";
    case EnergyModel::EqualShare: return "equal_share";
    }
    return "unknown";
}

const char* to_string(const Representation value) noexcept {
    switch (value) {
    case Representation::Kinetic: return "kinetic";
    case Representation::Background: return "background";
    }
    return "unknown";
}

const char* to_string(const RateKind value) noexcept {
    switch (value) {
    case RateKind::CrossSection: return "cross_section";
    case RateKind::RateCoefficient: return "rate_coefficient";
    }
    return "unknown";
}

const char* to_string(const ReactantRole value) noexcept {
    switch (value) {
    case ReactantRole::Projectile: return "projectile";
    case ReactantRole::Background: return "background";
    }
    return "unknown";
}

// ---------------------------------------------------------------------------
// 2. 注册表：统一管理 ID、名称和能级归属，避免重复定义或查错对象。
// ---------------------------------------------------------------------------

void SpeciesRegistry::add(Species species) {
    if (species.id == invalid_species) throw Error("species id is invalid");
    if (species.name.empty()) throw Error("species name is empty");
    if (by_id_.count(species.id) != 0U) {
        throw Error("duplicate species id " + std::to_string(species.id));
    }
    if (by_name_.count(species.name) != 0U) {
        throw Error("duplicate species name '" + species.name + "'");
    }
    if (!(species.mass_kg > 0.0) || !is_finite(species.mass_kg)) {
        throw Error("species '" + species.name + "' has a non-positive or non-finite mass");
    }
    by_id_.emplace(species.id, species_.size());
    by_name_.emplace(species.name, species.id);
    species_.push_back(std::move(species));
}

bool SpeciesRegistry::contains(const SpeciesId id) const noexcept {
    return by_id_.count(id) != 0U;
}

const Species& SpeciesRegistry::at(const SpeciesId id) const {
    const auto found = by_id_.find(id);
    if (found == by_id_.end()) {
        throw Error("unknown species id " + std::to_string(id));
    }
    return species_[found->second];
}

SpeciesId SpeciesRegistry::id_of(const std::string& name) const {
    const auto found = by_name_.find(name);
    if (found == by_name_.end()) throw Error("unknown species name '" + name + "'");
    return found->second;
}

void StateRegistry::add(State state) {
    if (state.id == invalid_state) throw Error("state id is invalid");
    if (state.label.empty()) throw Error("state label is empty");
    if (by_id_.count(state.id) != 0U) {
        throw Error("duplicate state id " + std::to_string(state.id));
    }
    const std::string key = std::to_string(state.species) + "/" + state.label;
    if (by_label_.count(key) != 0U) {
        throw Error("duplicate state label '" + state.label + "' for the same species");
    }
    if (!is_finite(state.energy_ev)) throw Error("state '" + state.label + "' has a non-finite energy");
    if (state.degeneracy == 0U) throw Error("state '" + state.label + "' has zero degeneracy");
    by_id_.emplace(state.id, states_.size());
    by_label_.emplace(key, state.id);
    states_.push_back(std::move(state));
}

bool StateRegistry::contains(const StateId id) const noexcept {
    return by_id_.count(id) != 0U;
}

const State& StateRegistry::at(const StateId id) const {
    const auto found = by_id_.find(id);
    if (found == by_id_.end()) throw Error("unknown state id " + std::to_string(id));
    return states_[found->second];
}

StateId StateRegistry::find(const SpeciesId species, const std::string& label) const {
    const std::string key = std::to_string(species) + "/" + label;
    const auto found = by_label_.find(key);
    if (found == by_label_.end()) {
        throw Error("unknown state '" + label + "' for the given species");
    }
    return found->second;
}

StateId StateRegistry::ground_state(const SpeciesId species) const {
    for (const State& state : states_) {
        if (state.species == species && state.ground) return state.id;
    }
    throw Error("species id " + std::to_string(species) + " has no ground state");
}

const std::map<std::string, unsigned>& ModelDefinition::composition_of(const SpeciesId id) const {
    const auto found = composition.find(id);
    if (found == composition.end()) {
        throw Error("no element composition declared for species id " + std::to_string(id));
    }
    return found->second;
}

// ---------------------------------------------------------------------------
// 3. 加载数据包：以下分段顺序也是新读者理解各张表依赖关系的顺序。
// ---------------------------------------------------------------------------

ModelDefinition load_model_package(const std::filesystem::path& package_dir) {
    if (!std::filesystem::is_directory(package_dir)) {
        throw Error("model package directory does not exist: " + package_dir.string());
    }
    ModelDefinition model;
    model.package_dir = package_dir.string();

    // ---- 3.1 清单：版本、模型名称以及各张表的路径 -------------------------
    // 路径相对于数据包目录解析，不依赖运行程序时的工作目录。
    const CsvTable manifest_table = read_csv_table(package_dir / "manifest.csv");
    std::map<std::string, std::string> manifest;
    for (const CsvRow& row : manifest_table.rows) {
        const std::string key = manifest_table.value(row, "key");
        const std::string value = manifest_table.value(row, "value");
        if (key.empty()) throw Error(row_context(manifest_table, row) + ": empty key");
        if (manifest.count(key) != 0U) {
            throw Error(row_context(manifest_table, row) + ": duplicate key '" + key + "'");
        }
        manifest.emplace(key, value);
    }
    const std::string format = manifest_value(manifest, "format");
    if (format != "g02-mcc-model-package") {
        throw Error("manifest.csv: unsupported format '" + format + "'");
    }
    model.format_version = static_cast<int>(std::stoi(manifest_value(manifest, "format_version")));
    if (model.format_version != 1) {
        throw Error("manifest.csv: unsupported format_version " +
                    std::to_string(model.format_version));
    }
    model.name = manifest_value(manifest, "name");
    model.version = manifest_value(manifest, "version");

    // Optional integrity entries: checksum.<relative path> = <16 hex digits>.
    for (const auto& [key, value] : manifest) {
        constexpr const char* prefix = "checksum.";
        if (key.rfind(prefix, 0) != 0U) continue;
        const std::string relative = key.substr(std::char_traits<char>::length(prefix));
        const std::string actual = fnv1a64_hex(package_dir / relative);
        if (to_lower(value) != actual) {
            throw Error("manifest.csv: checksum mismatch for '" + relative + "' (declared '" +
                        value + "', computed '" + actual + "')");
        }
    }

    const auto file_path = [&](const std::string& key) {
        return package_dir / manifest_value(manifest, key);
    };

    // ---- 3.2 物种：先建立名称到 ID 的映射，后面的表才能引用物种 ------------
    const CsvTable species_table = read_csv_table(file_path("species"));
    for (const CsvRow& row : species_table.rows) {
        Species species;
        species.id = parse_species_id(species_table, row, "id");
        species.name = species_table.value(row, "name");
        species.mass_kg = csv_real(species_table, row, "mass_kg");
        const long long charge = csv_int(species_table, row, "charge_state");
        if (charge < -1000 || charge > 1000) {
            throw Error(row_context(species_table, row) + ": implausible charge_state");
        }
        species.charge_state = static_cast<int>(charge);
        species.representation = representation_from_string(species_table.value(row, "representation"));
        model.species.add(std::move(species));
    }

    // ---- 3.3 能级：能量留空默认 0 eV，每个物种必须恰有一个基态 -------------
    const CsvTable states_table = read_csv_table(file_path("states"));
    for (const CsvRow& row : states_table.rows) {
        State state;
        state.id = parse_state_id(states_table, row, "id");
        const std::string species_name = states_table.value(row, "species");
        state.species = model.species.id_of(species_name);
        state.label = states_table.value(row, "label");
        state.energy_ev = csv_real_or(states_table, row, "energy_ev", 0.0);
        const long long degeneracy = csv_int(states_table, row, "degeneracy");
        if (degeneracy <= 0) {
            throw Error(row_context(states_table, row) + ": degeneracy must be positive");
        }
        state.degeneracy = static_cast<unsigned>(degeneracy);
        state.ground = csv_bool(states_table, row, "is_ground");
        model.states.add(std::move(state));
    }
    for (const Species& species : model.species.all()) {
        unsigned ground_count = 0U;
        for (const State& state : model.states.all()) {
            if (state.species == species.id && state.ground) ++ground_count;
        }
        if (ground_count != 1U) {
            throw Error("species '" + species.name +
                        "' must declare exactly one ground state (found " +
                        std::to_string(ground_count) + ")");
        }
    }

    // ---- 3.4 元素组成（可选）：供后续核对反应前后的原子数 ------------------
    // 不提供组成就无法检查被省略的元素；应为参与守恒检查的物种填全组成。
    // The manifest key and the file are optional. A species without a
    // composition row contributes no atomic-nucleus element inventory.
    const auto composition_entry = manifest.find("composition");
    if (composition_entry != manifest.end() && !composition_entry->second.empty()) {
        const CsvTable composition_table =
            read_csv_table(package_dir / composition_entry->second);
        for (const CsvRow& row : composition_table.rows) {
            const SpeciesId species = model.species.id_of(composition_table.value(row, "species"));
            const std::string element = composition_table.value(row, "element");
            if (element.empty()) {
                throw Error(row_context(composition_table, row) + ": empty element");
            }
            const unsigned count = parse_count(composition_table, row, "count");
            auto& elements = model.composition[species];
            if (elements.count(element) != 0U) {
                throw Error(row_context(composition_table, row) + ": duplicate element '" +
                            element + "'");
            }
            elements.emplace(element, count);
        }
    }

    // ---- 3.5 数据表：元信息定义单位/插值，x,y 文件保存数值 -----------------
    // 在加载时验证全部节点，避免第一次碰撞才暴露坏数据。
    const CsvTable datasets_table = read_csv_table(file_path("datasets"));
    std::map<std::string, Table> datasets;
    for (const CsvRow& row : datasets_table.rows) {
        Table table;
        table.dataset_id = datasets_table.value(row, "dataset_id");
        if (table.dataset_id.empty()) {
            throw Error(row_context(datasets_table, row) + ": empty dataset_id");
        }
        if (datasets.count(table.dataset_id) != 0U) {
            throw Error(row_context(datasets_table, row) + ": duplicate dataset_id '" +
                        table.dataset_id + "'");
        }
        table.path = datasets_table.value(row, "path");
        table.x_axis = datasets_table.value(row, "x_axis");
        table.x_unit = datasets_table.value(row, "x_unit");
        table.y_unit = datasets_table.value(row, "y_unit");
        table.interpolation = interpolation_from_string(datasets_table.value(row, "interpolation"));
        table.below = domain_policy_from_string(datasets_table.value(row, "below_min_policy"));
        table.above = domain_policy_from_string(datasets_table.value(row, "above_max_policy"));
        table.source = datasets_table.value_or(row, "source", "");
        table.version = datasets_table.value_or(row, "version", "");
        table.license = datasets_table.value_or(row, "license", "");
        table.notes = datasets_table.value_or(row, "notes", "");
        require_unit_pair(table, row_context(datasets_table, row));

        const std::filesystem::path table_path = package_dir / table.path;
        const CsvTable values = read_csv_table(table_path);
        for (const CsvRow& value_row : values.rows) {
            table.x.push_back(csv_real(values, value_row, "x"));
            table.y.push_back(csv_real(values, value_row, "y"));
        }
        table.validate(table_path.string());
        datasets.emplace(table.dataset_id, std::move(table));
    }

    // ---- 3.6 速率定律：把反应编号连接到数据集，并指明查表的横坐标来源 -------
    const CsvTable rate_table = read_csv_table(file_path("rate_laws"));
    struct RateLawRow {
        RateKind kind{RateKind::CrossSection};
        std::string dataset_id;
        std::string x_source;
        std::string x_species;
    };
    std::map<ReactionId, RateLawRow> rate_laws;
    for (const CsvRow& row : rate_table.rows) {
        const ReactionId id = parse_reaction_id(rate_table, row, "reaction_id");
        if (rate_laws.count(id) != 0U) {
            throw Error(row_context(rate_table, row) + ": duplicate rate law for reaction " +
                        std::to_string(id));
        }
        RateLawRow law;
        law.kind = rate_kind_from_string(rate_table.value(row, "kind"));
        law.dataset_id = rate_table.value(row, "dataset_id");
        law.x_source = normalize_key(rate_table.value(row, "x_source"));
        law.x_species = rate_table.value_or(row, "x_species", "");
        if (datasets.count(law.dataset_id) == 0U) {
            throw Error(row_context(rate_table, row) + ": unknown dataset_id '" + law.dataset_id +
                        "'");
        }
        rate_laws.emplace(id, std::move(law));
    }

    // ---- 3.7 反应物：state 留空时查询该物种的基态，不使用 invalid_state -----
    std::map<ReactionId, std::vector<ReactantTerm>> reactants;
    const CsvTable reactants_table = read_csv_table(file_path("reactants"));
    for (const CsvRow& row : reactants_table.rows) {
        const ReactionId id = parse_reaction_id(reactants_table, row, "reaction_id");
        ReactantTerm term;
        term.role = reactant_role_from_string(reactants_table.value(row, "role"));
        term.species = model.species.id_of(reactants_table.value(row, "species"));
        const std::string state_label = reactants_table.value_or(row, "state", "");
        term.state = state_label.empty()
            ? model.states.ground_state(term.species)
            : model.states.find(term.species, state_label);
        term.stoichiometry = parse_count(reactants_table, row, "stoichiometry");
        reactants[id].push_back(term);
    }

    // ---- 3.8 产物：同样解析物种、能级和计量系数，按反应编号分组 ------------
    std::map<ReactionId, std::vector<ProductTerm>> products;
    const CsvTable products_table = read_csv_table(file_path("products"));
    for (const CsvRow& row : products_table.rows) {
        const ReactionId id = parse_reaction_id(products_table, row, "reaction_id");
        ProductTerm term;
        term.species = model.species.id_of(products_table.value(row, "species"));
        const std::string state_label = products_table.value_or(row, "state", "");
        term.state = state_label.empty()
            ? model.states.ground_state(term.species)
            : model.states.find(term.species, state_label);
        term.stoichiometry = parse_count(products_table, row, "stoichiometry");
        products[id].push_back(term);
    }

    // ---- 3.9 组装反应：连接反应物、产物和速率定律 --------------------------
    // _or 明确列出可选字段及其默认值；普通读取函数所需的列不能省略。
    const CsvTable reactions_table = read_csv_table(file_path("reactions"));
    std::set<ReactionId> reaction_ids;
    std::set<std::string> reaction_names;
    for (const CsvRow& row : reactions_table.rows) {
        ReactionDefinition reaction;
        reaction.id = parse_reaction_id(reactions_table, row, "id");
        if (!reaction_ids.insert(reaction.id).second) {
            throw Error(row_context(reactions_table, row) + ": duplicate reaction id " +
                        std::to_string(reaction.id));
        }
        reaction.name = reactions_table.value(row, "name");
        if (!reaction_names.insert(reaction.name).second) {
            throw Error(row_context(reactions_table, row) + ": duplicate reaction name '" +
                        reaction.name + "'");
        }
        reaction.algorithm = collision_algorithm_from_string(reactions_table.value(row, "algorithm"));
        reaction.threshold_ev = csv_real(reactions_table, row, "threshold_ev");
        reaction.q_value_ev = csv_real(reactions_table, row, "q_value_ev");
        reaction.ker_min_ev = csv_real_or(reactions_table, row, "ker_min_ev", 0.0);
        reaction.radiated_energy_ev = csv_real_or(reactions_table, row, "radiated_energy_ev", 0.0);
        reaction.angular_model = angular_model_from_string(
            reactions_table.value_or(row, "angular_model", "isotropic"));
        reaction.energy_model = energy_model_from_string(
            reactions_table.value_or(row, "energy_model", "n_body_phase_space"));
        reaction.angular_cos_min = csv_real_or(reactions_table, row, "angular_cos_min", 0.0);
        reaction.angular_cos_max = csv_real_or(reactions_table, row, "angular_cos_max", 0.0);
        reaction.enabled = csv_bool(reactions_table, row, "enabled");
        reaction.source_file = reactions_table.path.string();
        reaction.source_line = row.line;

        const auto reactant_found = reactants.find(reaction.id);
        if (reactant_found == reactants.end() || reactant_found->second.empty()) {
            throw Error(row_context(reactions_table, row) + ": reaction has no reactants");
        }
        reaction.reactants = reactant_found->second;
        const auto product_found = products.find(reaction.id);
        if (product_found == products.end() || product_found->second.empty()) {
            throw Error(row_context(reactions_table, row) + ": reaction has no products");
        }
        reaction.products = product_found->second;

        const auto law_found = rate_laws.find(reaction.id);
        if (law_found == rate_laws.end()) {
            throw Error(row_context(reactions_table, row) + ": reaction has no rate law");
        }
        reaction.rate_kind = law_found->second.kind;
        reaction.dataset_id = law_found->second.dataset_id;
        reaction.x_source = law_found->second.x_source;
        reaction.table = datasets.at(law_found->second.dataset_id);
        if (!law_found->second.x_species.empty()) {
            reaction.x_species = model.species.id_of(law_found->second.x_species);
        }
        model.reactions.push_back(std::move(reaction));
    }
    if (model.reactions.empty()) throw Error("model package declares no reactions");

    // ---- 3.10 反向检查：拒绝没有对应反应的孤立行 ---------------------------
    // 只检查“反应能找到配表”还不够，配表中多写的编号也必须被发现。
    // Every rate law must belong to a declared reaction.
    for (const auto& [id, law] : rate_laws) {
        (void)law;
        if (reaction_ids.count(id) == 0U) {
            throw Error("rate_laws.csv references unknown reaction id " + std::to_string(id));
        }
    }
    // Reactant and product rows may not reference a reaction that reactions.csv
    // never declares (orphan rows used to be dropped silently).
    for (const auto& [id, terms] : reactants) {
        (void)terms;
        if (reaction_ids.count(id) == 0U) {
            throw Error("reactants.csv references unknown reaction id " + std::to_string(id));
        }
    }
    for (const auto& [id, terms] : products) {
        (void)terms;
        if (reaction_ids.count(id) == 0U) {
            throw Error("products.csv references unknown reaction id " + std::to_string(id));
        }
    }
    return model;
}

} // namespace mcc
} // namespace algoplasma
