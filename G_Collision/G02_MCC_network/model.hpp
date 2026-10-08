// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：这里描述“输入模型长什么样”，尚未进行粒子碰撞。
// CSV -> ModelDefinition -> compile_model -> CompiledModel 是数据进入计算的顺序。

//
// G02_MCC_network model package: species, states, element composition,
// reactions, reactants, products and versioned rate-law datasets.
//
// load_model_package() performs strict schema and cross-reference validation
// and resolves every table. compile_model() then applies the physics-level
// checks (stoichiometry, order/unit agreement, charge and element balance,
// supported angular/energy models) and computes conservative majorants.
#pragma once

#include "csv.hpp"
#include "table.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

namespace algoplasma {
namespace mcc {

// kinetic 物种由程序逐粒子跟踪；background 物种由密度、温度等统计量描述。
enum class Representation : std::uint8_t { Kinetic = 0, Background = 1 };

// 以下是 G02 算法编号，与 C_Gather 模块的同名编号无关。
enum class CollisionAlgorithm : std::uint8_t {
    C02Elastic = 2,
    C03DiscreteTransition = 3,
    C04Dissociation = 4,
    C05Ionization = 5,
    C06AttachmentDetachment = 6,
    C07ChargeExchange = 7,
    C08Recombination = 8
};

enum class AngularModel : std::uint8_t { Isotropic = 0, Cone = 1, IdentityExchange = 2 };
enum class EnergyModel : std::uint8_t { NBodyPhaseSpace = 0, EqualShare = 1 };
enum class RateKind : std::uint8_t { CrossSection = 0, RateCoefficient = 1 };
enum class ReactantRole : std::uint8_t { Projectile = 0, Background = 1 };

[[nodiscard]] CollisionAlgorithm collision_algorithm_from_string(const std::string& value);
[[nodiscard]] AngularModel angular_model_from_string(const std::string& value);
[[nodiscard]] EnergyModel energy_model_from_string(const std::string& value);
[[nodiscard]] Representation representation_from_string(const std::string& value);
[[nodiscard]] RateKind rate_kind_from_string(const std::string& value);
[[nodiscard]] ReactantRole reactant_role_from_string(const std::string& value);
[[nodiscard]] const char* to_string(CollisionAlgorithm value) noexcept;
[[nodiscard]] const char* to_string(AngularModel value) noexcept;
[[nodiscard]] const char* to_string(EnergyModel value) noexcept;
[[nodiscard]] const char* to_string(Representation value) noexcept;
[[nodiscard]] const char* to_string(RateKind value) noexcept;
[[nodiscard]] const char* to_string(ReactantRole value) noexcept;

// 物种记录质量和电荷；charge_state 是电荷量除以元电荷 e 后的整数。
struct Species {
    SpeciesId id{invalid_species};
    std::string name;
    Real mass_kg{};
    int charge_state{};
    Representation representation{Representation::Kinetic};
};

// 能级属于某一物种，energy_ev 是内部能量（eV）；同一物种须有唯一基态。
struct State {
    StateId id{invalid_state};
    SpeciesId species{invalid_species};
    std::string label;
    Real energy_ev{};
    unsigned degeneracy{1};
    bool ground{false};
};

// 注册表把外部 ID/名称映射到内部存储位置；查询不存在的对象会报错。
class SpeciesRegistry {
public:
    void add(Species species);
    [[nodiscard]] bool contains(SpeciesId id) const noexcept;
    [[nodiscard]] const Species& at(SpeciesId id) const;
    [[nodiscard]] SpeciesId id_of(const std::string& name) const;
    [[nodiscard]] std::size_t size() const noexcept { return species_.size(); }
    [[nodiscard]] const std::vector<Species>& all() const noexcept { return species_; }

private:
    std::vector<Species> species_;
    std::unordered_map<SpeciesId, std::size_t> by_id_;
    std::unordered_map<std::string, SpeciesId> by_name_;
};

class StateRegistry {
public:
    void add(State state);
    [[nodiscard]] bool contains(StateId id) const noexcept;
    [[nodiscard]] const State& at(StateId id) const;
    [[nodiscard]] StateId find(SpeciesId species, const std::string& label) const;
    [[nodiscard]] StateId ground_state(SpeciesId species) const;
    [[nodiscard]] std::size_t size() const noexcept { return states_.size(); }
    [[nodiscard]] const std::vector<State>& all() const noexcept { return states_; }

private:
    std::vector<State> states_;
    std::unordered_map<StateId, std::size_t> by_id_;
    std::unordered_map<std::string, StateId> by_label_; // "species/label"
};

// 一个反应项可代表多个相同粒子：stoichiometry=2 表示系数 2。
// projectile 是本次跟踪的入射粒子；background 是从背景分布抽取的碰撞伙伴。
struct ReactantTerm {
    ReactantRole role{ReactantRole::Background};
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    unsigned stoichiometry{1};
};

struct ProductTerm {
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    unsigned stoichiometry{1};
};

// 一个反应通道的完整输入；不是一次实际碰撞的结果。
// 下列成员初值用于 C++ 构造，不代表 CSV 全部允许留空；加载函数决定必填项。
struct ReactionDefinition {
    ReactionId id{invalid_reaction};
    std::string name;
    CollisionAlgorithm algorithm{CollisionAlgorithm::C02Elastic};
    Real threshold_ev{};
    Real q_value_ev{};
    Real ker_min_ev{};
    Real radiated_energy_ev{};
    AngularModel angular_model{AngularModel::Isotropic};
    Real angular_cos_min{};
    Real angular_cos_max{};
    EnergyModel energy_model{EnergyModel::NBodyPhaseSpace};
    bool enabled{true};

    std::vector<ReactantTerm> reactants;
    std::vector<ProductTerm> products;

    RateKind rate_kind{RateKind::CrossSection};
    std::string dataset_id;
    std::string x_source;
    SpeciesId x_species{invalid_species};
    Table table; // fully resolved from datasets.csv + the table file

    std::string source_file;
    std::size_t source_line{0};
};

// 汇总已经解析的物种、能级、元素组成和反应；物理一致性还须通过 compile_model。
struct ModelDefinition {
    std::string package_dir;
    std::string name;
    std::string version;
    int format_version{1};
    SpeciesRegistry species;
    StateRegistry states;
    std::unordered_map<SpeciesId, std::map<std::string, unsigned>> composition;
    std::vector<ReactionDefinition> reactions;

    [[nodiscard]] const std::map<std::string, unsigned>& composition_of(SpeciesId id) const;
};

[[nodiscard]] ModelDefinition load_model_package(const std::filesystem::path& package_dir);

} // namespace mcc
} // namespace algoplasma
