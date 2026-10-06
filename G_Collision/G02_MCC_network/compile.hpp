// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：“编译模型”是把输入数据检查并整理成适合反复计算的形式，
// 不是调用 C++ 编译器。初始化时完成这些工作，碰撞循环就不用重复做。

//
// Compiled, physics-validated collision network.
//
// compile_model() is the last point at which a bad model can be rejected
// cheaply. It checks the reaction order, the rate-law unit against that order,
// the supported angular/energy models, element and charge balance and the
// endothermic threshold, and it builds a *conservative* majorant from the
// analytic segments of every table. Adding a species or a supported two/three
// body channel only requires editing the CSV package.
#pragma once

#include "model.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace algoplasma {
namespace mcc {

// majorant 是真实碰撞频率的上界，用它先抽候选事件，再筛出真实碰撞。
// 上界偏松会多抽到空碰撞；上界偏小可能漏事件，因此不能当作随意调小的加速参数。
struct CompileOptions {
    // Multiplies every conservative majorant.
    Real majorant_safety_factor{1.05};
    // Diagnostic-only global scale. Values below 1.0 deliberately under-bound
    // the rate so that tests can exercise the majorant-violation guard.
    // Production code must leave this at 1.0.
    Real diagnostic_majorant_scale{1.0};
    // Relative tolerance for momentum and energy residuals.
    Real relative_tolerance{1.0e-9};
    // Default per-step candidate-event cap (null + real events).
    std::uint32_t max_events_per_step{64};
};

// 每个启用的反应对应一份预处理结果；保留 source_file/line 便于错误追溯。
struct CompiledReaction {
    ReactionId id{invalid_reaction};
    std::string name;
    CollisionAlgorithm algorithm{CollisionAlgorithm::C02Elastic};
    SpeciesId projectile{invalid_species};
    StateId projectile_state{invalid_state};
    std::vector<ReactantTerm> reactants; // as declared
    std::vector<ProductTerm> products;   // as declared
    // Expanded stoichiometry, projectile/background bodies in declaration order.
    std::vector<std::pair<SpeciesId, StateId>> reactant_bodies;
    std::vector<std::pair<SpeciesId, StateId>> product_bodies;

    unsigned order{2};
    unsigned background_count{1};

    // 能量字段统一用 eV：threshold 为阈值，q_value>0 表示释放能量，
    // ker_min 为碰后相对动能下限，radiated_energy 为辐射带走的能量。
    Real threshold_ev{};
    Real q_value_ev{};
    Real ker_min_ev{};
    Real radiated_energy_ev{};
    Real internal_before_ev{};
    Real internal_after_ev{};
    int charge_before{};
    int charge_after{};

    AngularModel angular_model{AngularModel::Isotropic};
    Real angular_cos_min{};
    Real angular_cos_max{};
    EnergyModel energy_model{EnergyModel::NBodyPhaseSpace};

    RateKind rate_kind{RateKind::CrossSection};
    Table table;
    std::string x_source; // "relative_energy_ev" or "temperature_k"
    SpeciesId x_species{invalid_species};

    // Conservative majorant per unit density product (m^3/s or m^6/s):
    //   cross_section   max over segments of sigma(E) * v(E)
    //   rate_coefficient max over segments of k(x)
    Real majorant_shape{};
    std::vector<Real> segment_shape_bounds;
    Real applied_majorant_scale{1.0}; // safety * diagnostic

    bool resonant{false};
    std::string source_file;
    std::size_t source_line{0};

    [[nodiscard]] bool is_cross_section() const noexcept {
        return rate_kind == RateKind::CrossSection;
    }
};

// 除反应表外还保存查询索引：按入射物种+能级快速找出候选通道。
class CompiledModel {
public:
    std::string name;
    std::string version;
    std::string package_dir;
    SpeciesRegistry species;
    StateRegistry states;
    std::unordered_map<SpeciesId, std::map<std::string, unsigned>> composition;
    std::vector<CompiledReaction> reactions;
    CompileOptions options;

    [[nodiscard]] const CompiledReaction& reaction(ReactionId id) const;
    // Channels whose kinetic projectile is exactly (species, state). A channel
    // is only eligible when the incoming primary particle matches its declared
    // projectile state, so state is part of the lookup key.
    [[nodiscard]] std::vector<std::size_t> reactions_for_projectile(SpeciesId id,
                                                                    StateId state) const;
    [[nodiscard]] const std::vector<std::size_t>& reactions_for_projectile_view(
        SpeciesId id, StateId state) const noexcept;

private:
    std::unordered_map<ReactionId, std::size_t> by_id_;
    std::unordered_map<std::uint32_t, std::vector<std::size_t>> by_projectile_state_;
    friend CompiledModel compile_model(ModelDefinition, CompileOptions);
};

[[nodiscard]] CompiledModel compile_model(ModelDefinition model, CompileOptions options = {});

} // namespace mcc
} // namespace algoplasma
