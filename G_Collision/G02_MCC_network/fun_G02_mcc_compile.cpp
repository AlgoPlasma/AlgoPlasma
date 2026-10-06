// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：先看末尾 compile_model 的阶段，再按需要回看前面的检查函数。
// 输入是已加载的 ModelDefinition；输出包含通过检查的通道、查询索引和频率上界。
// 这些检查保证当前算法假设下的数据一致性，不证明输入截面符合真实实验。

#include "compile.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <string>

namespace algoplasma {
namespace mcc {
namespace {

[[nodiscard]] std::string location(const ReactionDefinition& reaction) {
    return reaction.source_file + ":" + std::to_string(reaction.source_line);
}

[[nodiscard]] std::map<std::string, long long> elements_of(
    const std::unordered_map<SpeciesId, std::map<std::string, unsigned>>& composition,
    const SpeciesId species, const unsigned stoichiometry) {
    std::map<std::string, long long> result;
    const auto found = composition.find(species);
    if (found == composition.end()) return result;
    for (const auto& [element, count] : found->second) {
        result[element] += static_cast<long long>(count) * static_cast<long long>(stoichiometry);
    }
    return result;
}

[[nodiscard]] std::map<SpeciesId, unsigned> species_multiset(
    const std::vector<std::pair<SpeciesId, StateId>>& bodies) {
    std::map<SpeciesId, unsigned> result;
    for (const auto& body : bodies) result[body.first] += 1U;
    return result;
}

[[nodiscard]] bool masses_equal_strict(const Real a, const Real b) noexcept {
    const Real scale = std::max(std::fabs(a), std::fabs(b));
    return std::fabs(a - b) <= 8.0 * std::numeric_limits<Real>::epsilon() * scale;
}

[[nodiscard]] bool is_free_electron(const Species& species) noexcept {
    return species.charge_state == -1 && species.mass_kg < 1.0e-29;
}

// 速率量纲必须匹配反应阶数：单个入射粒子的频率为 n*sigma*v、n*k 或 n1*n2*k。
// 因此截面单位是 m2，二体/三体系数分别是 m3/s 和 m6/s，最终频率均为 1/s。
void validate_rate_law(const ReactionDefinition& reaction, const SpeciesRegistry& species,
                       const unsigned order) {
    const std::string prefix = "reaction '" + reaction.name + "' (" + location(reaction) + "): ";
    const std::string axis = to_lower(reaction.table.x_axis);
    const std::string yunit = to_lower(reaction.table.y_unit);
    if (reaction.rate_kind == RateKind::CrossSection) {
        if (order != 2U) {
            throw Error(prefix + "a cross_section rate law is only defined for two-body "
                                 "reactions (order 2)");
        }
        if (reaction.x_source != "relative_energy_ev") {
            throw Error(prefix + "a cross_section rate law requires x_source=relative_energy_ev");
        }
        if (axis != "energy") throw Error(prefix + "a cross_section table needs x_axis=energy");
        if (yunit != "m2") throw Error(prefix + "a cross_section table needs y_unit=m2");
        if (reaction.table.x_min() < 0.0) {
            throw Error(prefix + "a cross_section energy grid must be non-negative");
        }
        if (!(reaction.threshold_ev < reaction.table.x_max())) {
            throw Error(prefix + "threshold_ev is not below the cross-section energy domain");
        }
    } else {
        if (reaction.x_source != "temperature_k") {
            throw Error(prefix + "a rate_coefficient law requires x_source=temperature_k");
        }
        if (axis != "temperature") {
            throw Error(prefix + "a rate_coefficient table needs x_axis=temperature");
        }
        const std::string expected = order == 2U ? "m3/s" : "m6/s";
        if (order == 2U || order == 3U) {
            if (yunit != to_lower(expected)) {
                throw Error(prefix + "a " + std::to_string(order) +
                            "-body rate_coefficient needs y_unit=" + expected);
            }
        }
        if (reaction.threshold_ev != 0.0) {
            throw Error(prefix + "threshold_ev must be 0 for a rate_coefficient law");
        }
        if (reaction.x_species == invalid_species) {
            throw Error(prefix + "a rate_coefficient law needs x_species naming a background "
                                 "reactant");
        }
        bool x_is_background = false;
        for (const ReactantTerm& term : reaction.reactants) {
            if (term.role == ReactantRole::Background && term.species == reaction.x_species) {
                x_is_background = true;
            }
        }
        if (!x_is_background) {
            throw Error(prefix + "x_species must be one of the background reactants");
        }
        (void)species;
    }
}

// 分别检查角分布、能量分配以及 G02 算法 C02-C08 的支持条件。
// 例如“身份交换”模型有比一般电荷交换更严格的等质量等条件。
void validate_algorithm(const ReactionDefinition& reaction, const SpeciesRegistry& species) {
    const std::string prefix = "reaction '" + reaction.name + "' (" + location(reaction) + "): ";
    const std::size_t n_react = reaction.reactants.size();
    const std::size_t n_prod = reaction.products.size();

    // Expand for element/state bookkeeping.
    auto expand = [](const auto& terms) {
        std::vector<std::pair<SpeciesId, StateId>> bodies;
        for (const auto& term : terms) {
            for (unsigned i = 0; i < term.stoichiometry; ++i) {
                bodies.emplace_back(term.species, term.state);
            }
        }
        return bodies;
    };
    const auto reactant_bodies = expand(reaction.reactants);
    const auto product_bodies = expand(reaction.products);

    if (reaction.angular_model == AngularModel::Cone) {
        if (!(reaction.angular_cos_min >= -1.0 && reaction.angular_cos_max <= 1.0 &&
              reaction.angular_cos_min <= reaction.angular_cos_max)) {
            throw Error(prefix + "cone angular model needs -1 <= angular_cos_min <= "
                                 "angular_cos_max <= 1");
        }
        if (reactant_bodies.size() != 2U || product_bodies.size() != 2U) {
            throw Error(prefix + "cone angular model requires a two-body to two-body channel");
        }
    }
    if (reaction.angular_model == AngularModel::IdentityExchange) {
        if (reaction.algorithm != CollisionAlgorithm::C07ChargeExchange) {
            throw Error(prefix +
                        "identity_exchange is only valid for C07 charge exchange");
        }
        if (reaction.q_value_ev != 0.0 || reaction.radiated_energy_ev != 0.0 ||
            reaction.ker_min_ev != 0.0) {
            throw Error(prefix + "identity_exchange requires q_value_ev=0, "
                                 "radiated_energy_ev=0 and ker_min_ev=0");
        }
        if (n_react != 2U || n_prod != 2U) {
            throw Error(prefix + "identity_exchange requires exactly two reactants and two "
                                 "products");
        }
        if (species_multiset(reactant_bodies) != species_multiset(product_bodies)) {
            throw Error(prefix + "identity_exchange requires the same species multiset on both "
                                 "sides");
        }
        SpeciesId projectile_species = invalid_species;
        SpeciesId background_species = invalid_species;
        for (const ReactantTerm& term : reaction.reactants) {
            if (term.role == ReactantRole::Projectile) {
                projectile_species = term.species;
            } else {
                background_species = term.species;
            }
        }
        if (projectile_species == invalid_species || background_species == invalid_species ||
            projectile_species == background_species) {
            throw Error(prefix + "identity_exchange requires two distinct reactant species");
        }
        const Species& projectile = species.at(projectile_species);
        const Species& background = species.at(background_species);
        if (projectile.charge_state == background.charge_state) {
            throw Error(prefix + "identity_exchange requires reactants with different charge "
                                 "states that swap roles");
        }
        if (!masses_equal_strict(projectile.mass_kg, background.mass_kg)) {
            throw Error(prefix + "identity_exchange requires the two reactant masses to be equal "
                                 "(strict epsilon tolerance)");
        }
    }
    if (reaction.energy_model == EnergyModel::EqualShare && product_bodies.size() != 2U) {
        throw Error(prefix + "equal_share is only defined for exactly two product particles");
    }

    SpeciesId projectile_species = invalid_species;
    for (const ReactantTerm& term : reaction.reactants) {
        if (term.role == ReactantRole::Projectile) projectile_species = term.species;
    }
    const Species& projectile = species.at(projectile_species);

    switch (reaction.algorithm) {
    case CollisionAlgorithm::C02Elastic: {
        if (reaction.q_value_ev != 0.0 || reaction.radiated_energy_ev != 0.0) {
            throw Error(prefix + "C02 elastic requires q_value_ev=0 and radiated_energy_ev=0");
        }
        if (species_multiset(reactant_bodies) != species_multiset(product_bodies)) {
            throw Error(prefix + "C02 elastic requires the same species multiset on both sides");
        }
        if (reaction.angular_model == AngularModel::IdentityExchange) {
            throw Error(prefix + "C02 elastic cannot use identity_exchange");
        }
        break;
    }
    case CollisionAlgorithm::C03DiscreteTransition: {
        if (product_bodies.size() != 2U) {
            throw Error(prefix + "C03 discrete transition requires exactly two product particles");
        }
        if (reaction.angular_model == AngularModel::IdentityExchange) {
            throw Error(prefix + "C03 cannot use identity_exchange");
        }
        break;
    }
    case CollisionAlgorithm::C04Dissociation: {
        if (product_bodies.size() < 2U) {
            throw Error(prefix + "C04 dissociation needs at least two product particles");
        }
        break;
    }
    case CollisionAlgorithm::C05Ionization: {
        std::size_t free_before = 0;
        std::size_t free_after = 0;
        for (const auto& body : reactant_bodies) {
            if (is_free_electron(species.at(body.first))) ++free_before;
        }
        for (const auto& body : product_bodies) {
            if (is_free_electron(species.at(body.first))) ++free_after;
        }
        if (free_after <= free_before) {
            throw Error(prefix + "C05 ionization must create at least one free electron");
        }
        break;
    }
    case CollisionAlgorithm::C06AttachmentDetachment: {
        const bool projectile_is_electron = is_free_electron(projectile);
        const bool projectile_is_negative_ion =
            projectile.charge_state < 0 && !projectile_is_electron;
        bool negative_heavy_product = false;
        bool free_electron_product = false;
        for (const auto& body : product_bodies) {
            const Species& type = species.at(body.first);
            if (type.charge_state < 0 && !is_free_electron(type)) negative_heavy_product = true;
            if (is_free_electron(type)) free_electron_product = true;
        }
        if (projectile_is_electron) {
            if (!negative_heavy_product) {
                throw Error(prefix + "C06 attachment needs a negative heavy-ion product");
            }
        } else if (projectile_is_negative_ion) {
            if (!free_electron_product) {
                throw Error(prefix + "C06 detachment must release a free electron");
            }
        } else {
            throw Error(prefix + "C06 requires a free-electron or negative-ion projectile");
        }
        break;
    }
    case CollisionAlgorithm::C07ChargeExchange: {
        if (reactant_bodies.size() != 2U || product_bodies.size() != 2U) {
            throw Error(prefix + "C07 charge exchange requires exactly two reactants and two "
                                 "products");
        }
        break;
    }
    case CollisionAlgorithm::C08Recombination: {
        std::size_t charged_before = 0;
        std::size_t charged_after = 0;
        for (const auto& body : reactant_bodies) {
            if (species.at(body.first).charge_state != 0) ++charged_before;
        }
        for (const auto& body : product_bodies) {
            if (species.at(body.first).charge_state != 0) ++charged_after;
        }
        if (charged_after >= charged_before) {
            throw Error(prefix + "C08 recombination must reduce the number of charged particles");
        }
        break;
    }
    }
}

// majorant_shape 尚未乘背景密度：先在表格定义范围内为 sigma*v 或 k 建立上界。
// 每段 sigma 不超过两端最大值，v 随相对能量增加；二者上界之积仍是安全上界。
// 约化质量 mu=m1*m2/(m1+m2)，相对速率 v=sqrt(2*E/mu)，E 必须从 eV 换到 J。
[[nodiscard]] Real majorant_shape_for(const ReactionDefinition& reaction,
                                      const SpeciesRegistry& species,
                                      std::vector<Real>& segment_bounds) {
    segment_bounds.clear();
    if (reaction.rate_kind == RateKind::CrossSection) {
        // The unique background reactant of a two-body cross-section channel.
        SpeciesId background = invalid_species;
        SpeciesId projectile = invalid_species;
        for (const ReactantTerm& term : reaction.reactants) {
            if (term.role == ReactantRole::Background) background = term.species;
            if (term.role == ReactantRole::Projectile) projectile = term.species;
        }
        const Real m1 = species.at(projectile).mass_kg;
        const Real m2 = species.at(background).mass_kg;
        const Real reduced = m1 * m2 / (m1 + m2);
        const Table& table = reaction.table;
        segment_bounds.resize(table.x.size() - 1U, 0.0);
        Real maximum = 0.0;
        for (std::size_t i = 0; i + 1U < table.x.size(); ++i) {
            const Real energy_ev = table.x[i + 1U];
            const Real speed = std::sqrt(2.0 * energy_ev * elementary_charge_c / reduced);
            const Real bound = std::max(table.y[i], table.y[i + 1U]) * speed;
            segment_bounds[i] = bound;
            maximum = std::max(maximum, bound);
        }
        return maximum;
    }
    segment_bounds = reaction.table.segment_upper_bounds();
    Real maximum = 0.0;
    for (const Real bound : segment_bounds) maximum = std::max(maximum, bound);
    return maximum;
}

} // namespace

const CompiledReaction& CompiledModel::reaction(const ReactionId id) const {
    const auto found = by_id_.find(id);
    if (found == by_id_.end()) throw Error("reaction id is not part of the compiled model");
    return reactions[found->second];
}

std::vector<std::size_t> CompiledModel::reactions_for_projectile(const SpeciesId id,
                                                                const StateId state) const {
    return reactions_for_projectile_view(id, state);
}

// 把两个 16 位 ID 合并为一个 32 位键；同物种不同能级拥有各自的通道列表。
// 返回引用可免去列表复制；调用者须保证 CompiledModel 仍然存活。
const std::vector<std::size_t>& CompiledModel::reactions_for_projectile_view(
    const SpeciesId id, const StateId state) const noexcept {
    static const std::vector<std::size_t> empty;
    const auto key = (static_cast<std::uint32_t>(id) << 16U) | state;
    const auto found = by_projectile_state_.find(key);
    return found == by_projectile_state_.end() ? empty : found->second;
}

CompiledModel compile_model(ModelDefinition model, const CompileOptions options) {
    if (!(options.majorant_safety_factor > 0.0) || !is_finite(options.majorant_safety_factor)) {
        throw Error("compile options: majorant_safety_factor must be positive and finite");
    }
    if (!(options.diagnostic_majorant_scale > 0.0) || !is_finite(options.diagnostic_majorant_scale)) {
        throw Error("compile options: diagnostic_majorant_scale must be positive and finite");
    }
    if (!(options.relative_tolerance > 0.0) || !is_finite(options.relative_tolerance)) {
        throw Error("compile options: relative_tolerance must be positive and finite");
    }
    if (options.max_events_per_step == 0U) {
        throw Error("compile options: max_events_per_step must be positive");
    }
    if (model.species.size() == 0U) throw Error("model has no species");

    CompiledModel compiled;
    compiled.name = model.name;
    compiled.version = model.version;
    compiled.package_dir = model.package_dir;
    compiled.species = model.species;
    compiled.states = model.states;
    compiled.composition = model.composition;
    compiled.options = options;

    std::set<ReactionId> ids;
    for (const ReactionDefinition& source : model.reactions) {
        if (!source.enabled) continue;
        if (!ids.insert(source.id).second) {
            throw Error("duplicate enabled reaction id " + std::to_string(source.id));
        }
        const std::string prefix = "reaction '" + source.name + "' (" + location(source) + "): ";

        // ---- 1. 反应物和阶数：每条通道恰有一个逐粒子跟踪的 projectile -----
        unsigned projectile_terms = 0U;
        unsigned background_terms = 0U;
        std::set<SpeciesId> background_species;
        std::vector<std::pair<SpeciesId, StateId>> reactant_bodies;
        unsigned order = 0U;
        for (const ReactantTerm& term : source.reactants) {
            (void)compiled.species.at(term.species);
            (void)compiled.states.at(term.state);
            if (term.role == ReactantRole::Projectile) {
                ++projectile_terms;
                if (term.stoichiometry != 1U) {
                    throw Error(prefix + "the kinetic projectile must have stoichiometry 1");
                }
                if (compiled.species.at(term.species).representation != Representation::Kinetic) {
                    throw Error(prefix + "the projectile species must have representation=kinetic");
                }
            } else {
                ++background_terms;
                if (compiled.species.at(term.species).representation != Representation::Background) {
                    throw Error(prefix +
                                "background reactants must have representation=background");
                }
                if (!background_species.insert(term.species).second) {
                    throw Error(prefix + "the same background species is listed more than once; "
                                         "use stoichiometry 2 for n^2 channels");
                }
            }
            order += term.stoichiometry;
            for (unsigned i = 0; i < term.stoichiometry; ++i) {
                reactant_bodies.emplace_back(term.species, term.state);
            }
        }
        if (projectile_terms != 1U) {
            throw Error(prefix + "exactly one kinetic projectile reactant is required");
        }
        if (background_terms < 1U || background_terms > 2U) {
            throw Error(prefix + "one or two background reactants are required");
        }
        if (order != 2U && order != 3U) {
            throw Error(prefix + "the total reaction order must be 2 or 3");
        }

        std::vector<std::pair<SpeciesId, StateId>> product_bodies;
        for (const ProductTerm& term : source.products) {
            (void)compiled.species.at(term.species);
            (void)compiled.states.at(term.state);
            for (unsigned i = 0; i < term.stoichiometry; ++i) {
                product_bodies.emplace_back(term.species, term.state);
            }
        }
        if (product_bodies.empty()) throw Error(prefix + "the reaction needs at least one product");

        // ---- 2. 守恒记账：反应物加、产物减，元素数残差应全部为零 ----------
        std::map<std::string, long long> element_balance;
        int charge_before = 0;
        for (const ReactantTerm& term : source.reactants) {
            const auto contribution = elements_of(compiled.composition, term.species,
                                                  term.stoichiometry);
            for (const auto& [element, count] : contribution) element_balance[element] += count;
            charge_before += compiled.species.at(term.species).charge_state *
                             static_cast<int>(term.stoichiometry);
        }
        int charge_after = 0;
        for (const ProductTerm& term : source.products) {
            const auto contribution = elements_of(compiled.composition, term.species,
                                                  term.stoichiometry);
            for (const auto& [element, count] : contribution) element_balance[element] -= count;
            charge_after += compiled.species.at(term.species).charge_state *
                            static_cast<int>(term.stoichiometry);
        }
        for (const auto& [element, residual] : element_balance) {
            if (residual != 0) {
                throw Error(prefix + "element '" + element + "' is not conserved (residual " +
                            std::to_string(residual) + ")");
            }
        }
        if (charge_before != charge_after) {
            throw Error(prefix + "charge is not conserved (" + std::to_string(charge_before) +
                        " -> " + std::to_string(charge_after) + ")");
        }

        // ---- 3. 能量参数：吸热反应 q<0，阈值至少覆盖所需吸收的能量 ----------
        if (!is_finite(source.threshold_ev) || source.threshold_ev < 0.0) {
            throw Error(prefix + "threshold_ev must be finite and non-negative");
        }
        if (!is_finite(source.q_value_ev)) throw Error(prefix + "q_value_ev must be finite");
        if (!is_finite(source.ker_min_ev) || source.ker_min_ev < 0.0) {
            throw Error(prefix + "ker_min_ev must be finite and non-negative");
        }
        if (!is_finite(source.radiated_energy_ev) || source.radiated_energy_ev < 0.0) {
            throw Error(prefix + "radiated_energy_ev must be finite and non-negative");
        }
        if (source.q_value_ev < 0.0 && source.threshold_ev + 1.0e-12 < -source.q_value_ev) {
            throw Error(prefix + "an endothermic channel needs threshold_ev >= -q_value_ev");
        }
        if (product_bodies.size() < 2U && source.ker_min_ev > 0.0) {
            throw Error(prefix + "ker_min_ev>0 requires at least two product particles so that a "
                                 "final relative kinetic energy exists");
        }

        Real internal_before = 0.0;
        for (const auto& body : reactant_bodies) {
            internal_before += compiled.states.at(body.second).energy_ev;
        }
        Real internal_after = 0.0;
        for (const auto& body : product_bodies) {
            internal_after += compiled.states.at(body.second).energy_ev;
        }
        if (source.algorithm == CollisionAlgorithm::C03DiscreteTransition) {
            const Real residual = source.q_value_ev + (internal_after - internal_before);
            const Real scale = std::max(1.0, std::fabs(source.q_value_ev));
            if (std::fabs(residual) > 1.0e-9 * scale) {
                throw Error(prefix + "q_value_ev is inconsistent with the declared state energies "
                                     "(residual " + std::to_string(residual) + " eV)");
            }
            if (internal_after == internal_before) {
                throw Error(prefix + "C03 requires a discrete state change");
            }
        }

        // ---- 4. 检查算法支持范围，以及速率定律的轴和单位 --------------------
        validate_algorithm(source, compiled.species);
        validate_rate_law(source, compiled.species, order);

        // ---- 5. 保存预处理结果，建立频率上界和物种/能级查询索引 -------------
        CompiledReaction reaction;
        reaction.id = source.id;
        reaction.name = source.name;
        reaction.algorithm = source.algorithm;
        reaction.reactants = source.reactants;
        reaction.products = source.products;
        reaction.reactant_bodies = std::move(reactant_bodies);
        reaction.product_bodies = std::move(product_bodies);
        reaction.order = order;
        reaction.background_count = background_terms;
        for (const ReactantTerm& term : source.reactants) {
            if (term.role == ReactantRole::Projectile) {
                reaction.projectile = term.species;
                reaction.projectile_state = term.state;
            }
        }
        reaction.threshold_ev = source.threshold_ev;
        reaction.q_value_ev = source.q_value_ev;
        reaction.ker_min_ev = source.ker_min_ev;
        reaction.radiated_energy_ev = source.radiated_energy_ev;
        reaction.internal_before_ev = internal_before;
        reaction.internal_after_ev = internal_after;
        reaction.charge_before = charge_before;
        reaction.charge_after = charge_after;
        reaction.angular_model = source.angular_model;
        reaction.angular_cos_min = source.angular_cos_min;
        reaction.angular_cos_max = source.angular_cos_max;
        reaction.energy_model = source.energy_model;
        reaction.rate_kind = source.rate_kind;
        reaction.table = source.table;
        reaction.x_source = source.x_source;
        reaction.x_species = source.x_species;
        reaction.resonant = source.angular_model == AngularModel::IdentityExchange;
        reaction.source_file = source.source_file;
        reaction.source_line = source.source_line;
        reaction.majorant_shape = majorant_shape_for(source, compiled.species,
                                                     reaction.segment_shape_bounds);
        reaction.applied_majorant_scale =
            options.majorant_safety_factor * options.diagnostic_majorant_scale;
        if (!(reaction.applied_majorant_scale > 0.0) ||
            !is_finite(reaction.applied_majorant_scale)) {
            throw Error(prefix + "the combined majorant safety/diagnostic scale is not finite");
        }
        if (!(reaction.majorant_shape > 0.0) || !is_finite(reaction.majorant_shape)) {
            throw Error(prefix + "the rate table has a zero or non-finite majorant");
        }
        // 初始化时建索引，后续每次碰撞只访问匹配通道，不扫描整个反应网络。
        compiled.by_id_.emplace(reaction.id, compiled.reactions.size());
        const auto key = (static_cast<std::uint32_t>(reaction.projectile) << 16U)
                       | reaction.projectile_state;
        compiled.by_projectile_state_[key].push_back(compiled.reactions.size());
        compiled.reactions.push_back(std::move(reaction));
    }
    if (compiled.reactions.empty()) throw Error("model has no enabled reactions");
    return compiled;
}

} // namespace mcc
} // namespace algoplasma
