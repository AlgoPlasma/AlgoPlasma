// SPDX-License-Identifier: Apache-2.0
// C/C++ 桥梁：转换结构体、管理句柄、将异常转为状态码。
// 碰撞算法由 engine / batch 实现；这里负责接口和对象生命周期。
#include "c_api.h"

#include "batch.hpp"
#include "engine.hpp"

#include "c_api_internal.hpp"

#include <cstring>
#include <exception>
#include <limits>
#include <memory>
#include <new>
#include <string>
#include <vector>

using algoplasma::mcc::CollisionRequest;
using algoplasma::mcc::CompiledModel;
using algoplasma::mcc::Error;
using algoplasma::mcc::MccEngine;
using algoplasma::mcc::ParticleState;
using algoplasma::mcc::StepOutcome;

struct ap_g02_mcc_model {
    CompiledModel model;
};

struct ap_g02_mcc_outcome {
    StepOutcome outcome;
};

struct ap_g02_mcc_session {
    algoplasma::mcc::MccStepper stepper;
    algoplasma::mcc::MccWorkspace workspace;
    algoplasma::mcc::PreparedMccStep pending;
    std::vector<ParticleState> pending_input;
    std::uint64_t next_id{0};
    explicit ap_g02_mcc_session(MccEngine engine,
                                const algoplasma::mcc::StepOptions options,
                                const std::uint64_t first_id)
        : stepper(std::move(engine), options), next_id(first_id) {}
};

namespace {

void write_error(char* buffer, const std::size_t size, const std::string& message) {
    if (buffer == nullptr || size == 0U) return;
    const std::size_t count = message.size() < size - 1U ? message.size() : size - 1U;
    std::memcpy(buffer, message.data(), count);
    buffer[count] = '\0';
}

[[nodiscard]] bool write_name(char* buffer, const std::size_t size,
                              const std::string& value) {
    if (buffer == nullptr || size <= value.size()) return false;
    std::memcpy(buffer, value.c_str(), value.size() + 1U);
    return true;
}

// 统一异常出口：C 调用者收到状态码和错误文字，不接收 C++ 异常。
template <typename Function>
ap_g02_mcc_status guard(char* error_buffer, const std::size_t error_buffer_size,
                        const ap_g02_mcc_status failure_status, Function&& function) {
    try {
        function();
        return AP_G02_MCC_OK;
    } catch (const Error& error) {
        write_error(error_buffer, error_buffer_size, error.what());
        return failure_status;
    } catch (const std::bad_alloc&) {
        write_error(error_buffer, error_buffer_size, "out of memory");
        return AP_G02_MCC_INTERNAL_ERROR;
    } catch (const std::exception& error) {
        write_error(error_buffer, error_buffer_size, error.what());
        return AP_G02_MCC_INTERNAL_ERROR;
    } catch (...) {
        write_error(error_buffer, error_buffer_size, "unknown error");
        return AP_G02_MCC_INTERNAL_ERROR;
    }
}

[[nodiscard]] ParticleState to_particle(const ap_g02_mcc_particle& source) {
    ParticleState particle;
    particle.species = source.species;
    particle.state = source.state;
    particle.position = {source.position[0], source.position[1], source.position[2]};
    particle.velocity = {source.velocity[0], source.velocity[1], source.velocity[2]};
    particle.weight = source.weight;
    particle.id = source.id;
    particle.birth_step = source.birth_step;
    particle.cell = source.cell;
    return particle;
}

void from_particle(const ParticleState& source, ap_g02_mcc_particle& target) noexcept {
    target.species = source.species;
    target.state = source.state;
    target.position[0] = source.position.x;
    target.position[1] = source.position.y;
    target.position[2] = source.position.z;
    target.velocity[0] = source.velocity.x;
    target.velocity[1] = source.velocity.y;
    target.velocity[2] = source.velocity.z;
    target.weight = source.weight;
    target.id = source.id;
    target.birth_step = source.birth_step;
    target.cell = source.cell;
}

bool same_particle(const ParticleState& a, const ParticleState& b) noexcept {
    return a.species == b.species && a.state == b.state && a.id == b.id &&
        a.birth_step == b.birth_step && a.cell == b.cell && a.weight == b.weight &&
        a.position.x == b.position.x && a.position.y == b.position.y &&
        a.position.z == b.position.z && a.velocity.x == b.velocity.x &&
        a.velocity.y == b.velocity.y && a.velocity.z == b.velocity.z;
}

struct CapacityError final : Error {
    std::size_t required;
    explicit CapacityError(const std::size_t count)
        : Error("particle buffer is too small for products"), required(count) {}
};

// 把 C 数组接到批量接口：先核对产物所需容量，再原位压缩并写回。
class CParticleAdapter final : public algoplasma::mcc::ParticleAdapter {
public:
    CParticleAdapter(ap_g02_mcc_particle* particles, std::size_t& count,
                     const std::size_t capacity, std::uint64_t& next_id)
        : particles_(particles), count_(count), capacity_(capacity), next_id_(next_id) {}
    [[nodiscard]] std::size_t size() const override { return count_; }
    [[nodiscard]] bool alive(const std::size_t index) const override { return index < count_; }
    [[nodiscard]] ParticleState particle(const std::size_t index) const override {
        return to_particle(particles_[index]);
    }
    [[nodiscard]] std::uint64_t next_id_hint() const noexcept override { return next_id_; }
    void prepare_commit(const std::vector<algoplasma::mcc::ParticleChange>& changes,
                        const std::vector<ParticleState>& created,
                        const std::uint64_t next_id) override {
        std::size_t removed = 0;
        for (const auto& change : changes) {
            if (change.action == algoplasma::mcc::PrimaryAction::Remove) ++removed;
        }
        if (removed > count_ || created.size() >
            std::numeric_limits<std::size_t>::max() - (count_ - removed)) {
            throw Error("particle buffer size overflow");
        }
        const std::size_t future = count_ - removed + created.size();
        if (future > capacity_) throw CapacityError(future);
        changes_ = &changes;
        created_ = &created;
        staged_next_id_ = next_id;
    }
    void commit() noexcept override {
        std::size_t write = 0, change_index = 0;
        for (std::size_t read = 0; read < count_; ++read) {
            if (change_index < changes_->size() && (*changes_)[change_index].index == read) {
                const auto& change = (*changes_)[change_index++];
                if (change.action != algoplasma::mcc::PrimaryAction::Remove) {
                    from_particle(change.after, particles_[write++]);
                }
            } else {
                if (write != read) particles_[write] = particles_[read];
                ++write;
            }
        }
        for (const ParticleState& created : *created_) {
            from_particle(created, particles_[write++]);
        }
        count_ = write;
        next_id_ = staged_next_id_;
        changes_ = nullptr;
        created_ = nullptr;
    }

private:
    ap_g02_mcc_particle* particles_;
    std::size_t& count_;
    std::size_t capacity_;
    std::uint64_t& next_id_;
    std::uint64_t staged_next_id_{0};
    const std::vector<algoplasma::mcc::ParticleChange>* changes_{nullptr};
    const std::vector<ParticleState>* created_{nullptr};
};

std::vector<algoplasma::mcc::CellBackground> cell_backgrounds(
    const ap_g02_mcc_cell_background* input, const std::size_t count) {
    std::vector<algoplasma::mcc::CellBackground> field;
    field.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        algoplasma::mcc::BackgroundComponent component;
        component.species = input[i].species;
        component.state = input[i].state;
        component.density_m3 = input[i].density_m3;
        component.temperature_k = input[i].temperature_k;
        component.drift_m_per_s = {input[i].drift_m_per_s[0], input[i].drift_m_per_s[1],
                                   input[i].drift_m_per_s[2]};
        field.push_back({input[i].cell, component});
    }
    return field;
}

void finish_prepared(algoplasma::mcc::PreparedMccStep& pending,
                     CParticleAdapter& adapter,
                     ap_g02_mcc_step_report** out_report) {
    std::uint64_t next = pending.largest_id();
    std::vector<std::uint64_t> ids;
    ids.reserve(pending.report().created_particles);
    for (std::size_t i = 0; i < pending.report().created_particles; ++i) {
        if (next == UINT64_MAX) throw Error("child particle ID overflow");
        ids.push_back(++next);
    }
    const std::uint64_t next_id = next == UINT64_MAX ? UINT64_MAX : next + 1U;
    auto report = std::make_unique<ap_g02_mcc_step_report>();
    pending.prepare_commit(adapter, ids, next_id);
    pending.commit(adapter);
    report->report = pending.take_report();
    *out_report = report.release();
}

template <typename T>
[[nodiscard]] bool checked_index(const std::vector<T>& values, const std::size_t index) {
    return index < values.size();
}

} // namespace

extern "C" {

int ap_g02_mcc_api_version(void) { return 1; }

// 从数据包加载并校验模型；成功后调用者负责释放返回的句柄。
ap_g02_mcc_status ap_g02_mcc_model_load(const char* package_dir, ap_g02_mcc_model** out_model,
                                        char* error_buffer, size_t error_buffer_size) {
    if (out_model == nullptr) {
        write_error(error_buffer, error_buffer_size, "out_model must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_model = nullptr;
    if (package_dir == nullptr) {
        write_error(error_buffer, error_buffer_size, "package_dir must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_COMPILE_ERROR, [&]() {
        auto* handle = new ap_g02_mcc_model();
        try {
            handle->model = algoplasma::mcc::compile_model(
                algoplasma::mcc::load_model_package(package_dir));
        } catch (...) {
            delete handle;
            throw;
        }
        *out_model = handle;
    });
}

ap_g02_mcc_status ap_g02_mcc_model_destroy(ap_g02_mcc_model* model) {
    delete model;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_species_id(const ap_g02_mcc_model* model, const char* name,
                                              uint16_t* out_id, char* error_buffer,
                                              size_t error_buffer_size) {
    if (model == nullptr || name == nullptr || out_id == nullptr) {
        write_error(error_buffer, error_buffer_size, "model, name and out_id must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_NOT_FOUND, [&]() {
        *out_id = model->model.species.id_of(name);
    });
}

ap_g02_mcc_status ap_g02_mcc_model_state_id(const ap_g02_mcc_model* model, uint16_t species,
                                            const char* label, uint16_t* out_id,
                                            char* error_buffer, size_t error_buffer_size) {
    if (model == nullptr || label == nullptr || out_id == nullptr) {
        write_error(error_buffer, error_buffer_size, "model, label and out_id must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_NOT_FOUND, [&]() {
        *out_id = model->model.states.find(species, label);
    });
}

ap_g02_mcc_status ap_g02_mcc_model_species_count(const ap_g02_mcc_model* model,
                                                 size_t* out_count) {
    if (model == nullptr || out_count == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_count = model->model.species.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_species_get(const ap_g02_mcc_model* model,
    const size_t index, uint16_t* out_id, char* name, const size_t name_capacity,
    double* out_mass_kg, int* out_charge_state, int* out_representation) {
    if (model == nullptr || out_id == nullptr || out_mass_kg == nullptr ||
        out_charge_state == nullptr || out_representation == nullptr ||
        index >= model->model.species.size()) return AP_G02_MCC_INVALID_ARGUMENT;
    const auto& value = model->model.species.all()[index];
    if (!write_name(name, name_capacity, value.name)) return AP_G02_MCC_BUFFER_TOO_SMALL;
    *out_id = value.id;
    *out_mass_kg = value.mass_kg;
    *out_charge_state = value.charge_state;
    *out_representation = static_cast<int>(value.representation);
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_state_count(const ap_g02_mcc_model* model,
                                               size_t* out_count) {
    if (model == nullptr || out_count == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_count = model->model.states.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_state_get(const ap_g02_mcc_model* model,
    const size_t index, uint16_t* out_id, uint16_t* out_species,
    char* label, const size_t label_capacity, double* out_energy_ev) {
    if (model == nullptr || out_id == nullptr || out_species == nullptr ||
        out_energy_ev == nullptr || index >= model->model.states.size()) {
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& value = model->model.states.all()[index];
    if (!write_name(label, label_capacity, value.label)) return AP_G02_MCC_BUFFER_TOO_SMALL;
    *out_id = value.id;
    *out_species = value.species;
    *out_energy_ev = value.energy_ev;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_reaction_count(const ap_g02_mcc_model* model,
                                                  size_t* out_count) {
    if (model == nullptr || out_count == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_count = model->model.reactions.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_model_reaction_get(const ap_g02_mcc_model* model,
    const size_t index, uint32_t* out_id, char* name, const size_t name_capacity) {
    if (model == nullptr || out_id == nullptr || index >= model->model.reactions.size()) {
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& value = model->model.reactions[index];
    if (!write_name(name, name_capacity, value.name)) return AP_G02_MCC_BUFFER_TOO_SMALL;
    *out_id = value.id;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_engine_create(const ap_g02_mcc_model* model,
                                           ap_g02_mcc_engine** out_engine, char* error_buffer,
                                           size_t error_buffer_size) {
    if (model == nullptr || out_engine == nullptr) {
        write_error(error_buffer, error_buffer_size, "model and out_engine must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_engine = nullptr;
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_RUNTIME_ERROR, [&]() {
        *out_engine = new ap_g02_mcc_engine(model->model);
    });
}

ap_g02_mcc_status ap_g02_mcc_engine_destroy(ap_g02_mcc_engine* engine) {
    delete engine;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_collide(const ap_g02_mcc_engine* engine,
                                     const ap_g02_mcc_request* request,
                                     ap_g02_mcc_outcome** out_outcome, char* error_buffer,
                                     size_t error_buffer_size) {
    if (engine == nullptr || request == nullptr || out_outcome == nullptr) {
        write_error(error_buffer, error_buffer_size,
                    "engine, request and out_outcome must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_outcome = nullptr;
    if (request->background_count > 0U && request->background == nullptr) {
        write_error(error_buffer, error_buffer_size,
                    "request background pointer is null with a positive count");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_PHYSICS_ERROR, [&]() {
        CollisionRequest cpp_request;
        cpp_request.projectile = to_particle(request->projectile);
        cpp_request.background.reserve(request->background_count);
        for (std::size_t i = 0; i < request->background_count; ++i) {
            const ap_g02_mcc_background& source = request->background[i];
            algoplasma::mcc::BackgroundComponent component;
            component.species = source.species;
            component.density_m3 = source.density_m3;
            component.temperature_k = source.temperature_k;
            component.drift_m_per_s = {source.drift_m_per_s[0], source.drift_m_per_s[1],
                                       source.drift_m_per_s[2]};
            cpp_request.background.push_back(component);
        }
        cpp_request.dt_s = request->dt_s;
        cpp_request.global_step = request->global_step;
        cpp_request.seed = request->seed;
        cpp_request.max_events_per_step = request->max_events_per_step;

        auto* handle = new ap_g02_mcc_outcome();
        try {
            handle->outcome = engine->engine.collide(cpp_request);
        } catch (...) {
            delete handle;
            throw;
        }
        *out_outcome = handle;
    });
}

ap_g02_mcc_status ap_g02_mcc_outcome_destroy(ap_g02_mcc_outcome* outcome) {
    delete outcome;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_primary(const ap_g02_mcc_outcome* outcome,
                                             ap_g02_mcc_particle* out_particle, int* out_action,
                                             uint16_t* out_destination, char* error_buffer,
                                             size_t error_buffer_size) {
    if (outcome == nullptr || out_particle == nullptr || out_action == nullptr ||
        out_destination == nullptr) {
        write_error(error_buffer, error_buffer_size, "output arguments must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    from_particle(outcome->outcome.primary_after, *out_particle);
    *out_action = static_cast<int>(outcome->outcome.primary_action);
    *out_destination = outcome->outcome.primary_destination;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_counters(const ap_g02_mcc_outcome* outcome,
                                              uint32_t* out_candidates, uint32_t* out_real,
                                              uint32_t* out_null, int* out_limit_reached,
                                              char* error_buffer, size_t error_buffer_size) {
    if (outcome == nullptr || out_candidates == nullptr || out_real == nullptr ||
        out_null == nullptr || out_limit_reached == nullptr) {
        write_error(error_buffer, error_buffer_size, "output arguments must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_candidates = outcome->outcome.candidates;
    *out_real = outcome->outcome.real_events;
    *out_null = outcome->outcome.null_events;
    *out_limit_reached = outcome->outcome.event_limit_reached ? 1 : 0;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_created_count(const ap_g02_mcc_outcome* outcome,
                                                   size_t* out_count, char* error_buffer,
                                                   size_t error_buffer_size) {
    if (outcome == nullptr || out_count == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_count must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_count = outcome->outcome.created.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_created_get(const ap_g02_mcc_outcome* outcome,
                                                 const size_t index,
                                                 ap_g02_mcc_created* out_created,
                                                 char* error_buffer, size_t error_buffer_size) {
    if (outcome == nullptr || out_created == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_created must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    if (!checked_index(outcome->outcome.created, index)) {
        write_error(error_buffer, error_buffer_size, "created product index is out of range");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& source = outcome->outcome.created[index];
    out_created->parent_id = source.parent_id;
    out_created->event_index = source.event_index;
    out_created->product_ordinal = source.product_ordinal;
    out_created->species = source.species;
    out_created->state = source.state;
    out_created->position[0] = source.position.x;
    out_created->position[1] = source.position.y;
    out_created->position[2] = source.position.z;
    out_created->velocity[0] = source.velocity.x;
    out_created->velocity[1] = source.velocity.y;
    out_created->velocity[2] = source.velocity.z;
    out_created->weight = source.weight;
    out_created->birth_step = source.birth_step;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_reservoir_count(const ap_g02_mcc_outcome* outcome,
                                                     size_t* out_count, char* error_buffer,
                                                     size_t error_buffer_size) {
    if (outcome == nullptr || out_count == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_count must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_count = outcome->outcome.reservoir.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_reservoir_get(const ap_g02_mcc_outcome* outcome,
                                                   const size_t index,
                                                   ap_g02_mcc_reservoir* out_reservoir,
                                                   char* error_buffer, size_t error_buffer_size) {
    if (outcome == nullptr || out_reservoir == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_reservoir must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    if (!checked_index(outcome->outcome.reservoir, index)) {
        write_error(error_buffer, error_buffer_size, "reservoir index is out of range");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& source = outcome->outcome.reservoir[index];
    out_reservoir->species = source.species;
    out_reservoir->physical_particles = source.physical_particles;
    out_reservoir->momentum_kg_m_per_s[0] = source.momentum_kg_m_per_s.x;
    out_reservoir->momentum_kg_m_per_s[1] = source.momentum_kg_m_per_s.y;
    out_reservoir->momentum_kg_m_per_s[2] = source.momentum_kg_m_per_s.z;
    out_reservoir->kinetic_energy_j = source.kinetic_energy_j;
    out_reservoir->internal_energy_j = source.internal_energy_j;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_event_count(const ap_g02_mcc_outcome* outcome,
                                                 size_t* out_count, char* error_buffer,
                                                 size_t error_buffer_size) {
    if (outcome == nullptr || out_count == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_count must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_count = outcome->outcome.events.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_event_get(const ap_g02_mcc_outcome* outcome,
                                               const size_t index, ap_g02_mcc_event* out_event,
                                               char* error_buffer, size_t error_buffer_size) {
    if (outcome == nullptr || out_event == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_event must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    if (!checked_index(outcome->outcome.events, index)) {
        write_error(error_buffer, error_buffer_size, "event index is out of range");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& source = outcome->outcome.events[index];
    out_event->event_index = source.event_index;
    out_event->reaction = source.reaction;
    out_event->algorithm = static_cast<int>(source.algorithm);
    out_event->real_event = source.real_event ? 1 : 0;
    out_event->null_event = source.null_event ? 1 : 0;
    out_event->majorant_s_inv = source.majorant_s_inv;
    out_event->sampled_rate_s_inv = source.sampled_rate_s_inv;
    out_event->background_species = source.background_species;
    out_event->has_relative_energy = source.has_relative_energy ? 1 : 0;
    out_event->relative_energy_ev = source.relative_energy_ev;
    out_event->has_cross_section = source.has_cross_section ? 1 : 0;
    out_event->cross_section_m2 = source.cross_section_m2;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_outcome_ledger_get(const ap_g02_mcc_outcome* outcome,
                                                ap_g02_mcc_ledger* out_ledger,
                                                char* error_buffer, size_t error_buffer_size) {
    if (outcome == nullptr || out_ledger == nullptr) {
        write_error(error_buffer, error_buffer_size, "outcome and out_ledger must not be null");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& source = outcome->outcome.ledger;
    out_ledger->charge_before_c = source.charge_before_c;
    out_ledger->charge_after_c = source.charge_after_c;
    out_ledger->momentum_before_kg_m_per_s[0] = source.momentum_before_kg_m_per_s.x;
    out_ledger->momentum_before_kg_m_per_s[1] = source.momentum_before_kg_m_per_s.y;
    out_ledger->momentum_before_kg_m_per_s[2] = source.momentum_before_kg_m_per_s.z;
    out_ledger->momentum_after_kg_m_per_s[0] = source.momentum_after_kg_m_per_s.x;
    out_ledger->momentum_after_kg_m_per_s[1] = source.momentum_after_kg_m_per_s.y;
    out_ledger->momentum_after_kg_m_per_s[2] = source.momentum_after_kg_m_per_s.z;
    out_ledger->kinetic_before_j = source.kinetic_before_j;
    out_ledger->kinetic_after_j = source.kinetic_after_j;
    out_ledger->internal_before_j = source.internal_before_j;
    out_ledger->internal_after_j = source.internal_after_j;
    out_ledger->released_energy_j = source.released_energy_j;
    out_ledger->radiated_or_unresolved_j = source.radiated_or_unresolved_j;
    out_ledger->energy_residual_j = source.energy_residual_j;
    out_ledger->tolerance_j = source.tolerance_j;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step(const ap_g02_mcc_engine* engine,
                                  ap_g02_mcc_particle* particles,
                                  size_t* inout_count, const size_t capacity, size_t* required,
                                  const ap_g02_mcc_cell_background* background,
                                  const size_t background_count, const double dt_s,
                                  const uint64_t global_step, const uint64_t seed,
                                  const uint32_t max_candidates, const unsigned threads,
                                  const int backend, ap_g02_mcc_step_report** out_report,
                                  char* error_buffer, const size_t error_buffer_size) {
    if (engine == nullptr || inout_count == nullptr || required == nullptr ||
        out_report == nullptr || *inout_count > capacity ||
        (*inout_count != 0U && particles == nullptr) ||
        (background_count != 0U && background == nullptr) || backend < 0 || backend > 2) {
        write_error(error_buffer, error_buffer_size, "invalid batch step argument");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_report = nullptr;
    *required = *inout_count;
    bool too_small = false;
    const auto status = guard(error_buffer, error_buffer_size, AP_G02_MCC_PHYSICS_ERROR, [&]() {
        CParticleAdapter adapter(particles, *inout_count, capacity, engine->next_batch_id);
        const auto field = cell_backgrounds(background, background_count);
        algoplasma::mcc::StepOptions options;
        options.backend = static_cast<algoplasma::mcc::CpuBackend>(backend);
        options.threads = threads;
        options.max_candidates_per_particle = max_candidates == 0U
            ? 1000000U : max_candidates;
        algoplasma::mcc::MccStepper stepper(engine->engine, options);
        algoplasma::mcc::MccWorkspace workspace;
        auto pending = stepper.prepare_step(adapter, field, dt_s, global_step, seed, workspace);
        try {
            finish_prepared(pending, adapter, out_report);
        } catch (const CapacityError& error) {
            *required = error.required;
            too_small = true;
        }
        if (!too_small) *required = *inout_count;
    });
    if (status != AP_G02_MCC_OK) return status;
    if (too_small) {
        write_error(error_buffer, error_buffer_size, "particle buffer is too small for products");
        return AP_G02_MCC_BUFFER_TOO_SMALL;
    }
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_session_create(const ap_g02_mcc_engine* engine,
    const uint32_t max_candidates, const unsigned threads, const int backend,
    const int sampler, ap_g02_mcc_session** out_session,
    char* error_buffer, const size_t error_buffer_size) {
    if (engine == nullptr || out_session == nullptr || backend < 0 || backend > 2 ||
        sampler < 0 || sampler > 1) {
        write_error(error_buffer, error_buffer_size, "invalid MCC session argument");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_session = nullptr;
    return guard(error_buffer, error_buffer_size, AP_G02_MCC_INVALID_ARGUMENT, [&]() {
        algoplasma::mcc::StepOptions options;
        options.backend = static_cast<algoplasma::mcc::CpuBackend>(backend);
        options.threads = threads;
        options.max_candidates_per_particle = max_candidates == 0U
            ? 1000000U : max_candidates;
        options.sampler = static_cast<algoplasma::mcc::ChannelSampler>(sampler);
        *out_session = new ap_g02_mcc_session(engine->engine, options,
                                               engine->next_batch_id);
    });
}

ap_g02_mcc_status ap_g02_mcc_session_destroy(ap_g02_mcc_session* session) {
    delete session;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_session_abort(ap_g02_mcc_session* session) {
    if (session == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    session->pending = {};
    session->pending_input.clear();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_session_step(ap_g02_mcc_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, const size_t capacity,
    size_t* required, const ap_g02_mcc_cell_background* background,
    const size_t background_count, const double dt_s, const uint64_t global_step,
    const uint64_t seed, ap_g02_mcc_step_report** out_report,
    char* error_buffer, const size_t error_buffer_size) {
    if (session == nullptr || inout_count == nullptr || required == nullptr ||
        out_report == nullptr || *inout_count > capacity ||
        (*inout_count != 0U && particles == nullptr) ||
        (background_count != 0U && background == nullptr) || session->pending.valid()) {
        write_error(error_buffer, error_buffer_size, "invalid MCC session step or pending retry");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_report = nullptr;
    *required = *inout_count;
    bool too_small = false;
    const auto status = guard(error_buffer, error_buffer_size, AP_G02_MCC_PHYSICS_ERROR, [&]() {
        CParticleAdapter adapter(particles, *inout_count, capacity, session->next_id);
        const auto field = cell_backgrounds(background, background_count);
        session->pending = session->stepper.prepare_step(adapter, field, dt_s,
                                                         global_step, seed,
                                                         session->workspace);
        try {
            finish_prepared(session->pending, adapter, out_report);
            *required = *inout_count;
        } catch (const CapacityError& error) {
            *required = error.required;
            session->pending_input.reserve(*inout_count);
            for (size_t i = 0; i < *inout_count; ++i) {
                session->pending_input.push_back(to_particle(particles[i]));
            }
            too_small = true;
        }
    });
    if (status != AP_G02_MCC_OK) {
        session->pending = {};
        session->pending_input.clear();
        return status;
    }
    if (too_small) {
        write_error(error_buffer, error_buffer_size, "particle buffer is too small for products");
        return AP_G02_MCC_BUFFER_TOO_SMALL;
    }
    session->pending_input.clear();
    return AP_G02_MCC_OK;
}

// 扩容后提交已准备的结果，不重新抽样；原粒子内容和顺序必须保留。
ap_g02_mcc_status ap_g02_mcc_session_resume(ap_g02_mcc_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, const size_t capacity,
    size_t* required, ap_g02_mcc_step_report** out_report,
    char* error_buffer, const size_t error_buffer_size) {
    if (session == nullptr || !session->pending.valid() || inout_count == nullptr ||
        required == nullptr || out_report == nullptr || *inout_count > capacity ||
        *inout_count != session->pending_input.size() ||
        (*inout_count != 0U && particles == nullptr)) {
        write_error(error_buffer, error_buffer_size, "invalid MCC session resume argument");
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    *out_report = nullptr;
    *required = *inout_count;
    for (size_t i = 0; i < *inout_count; ++i) {
        if (!same_particle(to_particle(particles[i]), session->pending_input[i])) {
            write_error(error_buffer, error_buffer_size, "particle input changed before MCC resume");
            return AP_G02_MCC_INVALID_ARGUMENT;
        }
    }
    bool too_small = false;
    const auto status = guard(error_buffer, error_buffer_size, AP_G02_MCC_PHYSICS_ERROR, [&]() {
        CParticleAdapter adapter(particles, *inout_count, capacity, session->next_id);
        try {
            finish_prepared(session->pending, adapter, out_report);
            *required = *inout_count;
        } catch (const CapacityError& error) {
            *required = error.required;
            too_small = true;
        }
    });
    if (status != AP_G02_MCC_OK) {
        session->pending = {};
        session->pending_input.clear();
        return status;
    }
    if (too_small) {
        write_error(error_buffer, error_buffer_size, "particle buffer is too small for products");
        return AP_G02_MCC_BUFFER_TOO_SMALL;
    }
    session->pending_input.clear();
    return AP_G02_MCC_OK;
}

// 报告读取完成后释放，避免时间循环中累积内存。
ap_g02_mcc_status ap_g02_mcc_step_report_destroy(ap_g02_mcc_step_report* report) {
    delete report;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_stats(const ap_g02_mcc_step_report* report,
                                               ap_g02_mcc_step_stats* out_stats) {
    if (report == nullptr || out_stats == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    const auto& source = report->report;
    out_stats->particles_visited = source.particles_visited;
    out_stats->candidates = source.candidates;
    out_stats->real_events = source.real_events;
    out_stats->null_events = source.null_events;
    out_stats->created_particles = source.created_particles;
    out_stats->preparation_seconds = source.preparation_seconds;
    out_stats->sampling_seconds = source.sampling_seconds;
    out_stats->reduction_seconds = source.reduction_seconds;
    out_stats->commit_seconds = source.commit_seconds;
    out_stats->total_seconds = source.total_seconds;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_ledger(const ap_g02_mcc_step_report* report,
                                                ap_g02_mcc_ledger* out_ledger) {
    if (report == nullptr || out_ledger == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    const auto& source = report->report.ledger;
    out_ledger->charge_before_c = source.charge_before_c;
    out_ledger->charge_after_c = source.charge_after_c;
    out_ledger->momentum_before_kg_m_per_s[0] = source.momentum_before_kg_m_per_s.x;
    out_ledger->momentum_before_kg_m_per_s[1] = source.momentum_before_kg_m_per_s.y;
    out_ledger->momentum_before_kg_m_per_s[2] = source.momentum_before_kg_m_per_s.z;
    out_ledger->momentum_after_kg_m_per_s[0] = source.momentum_after_kg_m_per_s.x;
    out_ledger->momentum_after_kg_m_per_s[1] = source.momentum_after_kg_m_per_s.y;
    out_ledger->momentum_after_kg_m_per_s[2] = source.momentum_after_kg_m_per_s.z;
    out_ledger->kinetic_before_j = source.kinetic_before_j;
    out_ledger->kinetic_after_j = source.kinetic_after_j;
    out_ledger->internal_before_j = source.internal_before_j;
    out_ledger->internal_after_j = source.internal_after_j;
    out_ledger->released_energy_j = source.released_energy_j;
    out_ledger->radiated_or_unresolved_j = source.radiated_or_unresolved_j;
    out_ledger->energy_residual_j = source.energy_residual_j;
    out_ledger->tolerance_j = source.tolerance_j;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_reservoir_count(
    const ap_g02_mcc_step_report* report, size_t* out_count) {
    if (report == nullptr || out_count == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_count = report->report.reservoir.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_reservoir_get(
    const ap_g02_mcc_step_report* report, const size_t index,
    ap_g02_mcc_cell_reservoir* out_delta) {
    if (report == nullptr || out_delta == nullptr || index >= report->report.reservoir.size()) {
        return AP_G02_MCC_INVALID_ARGUMENT;
    }
    const auto& entry = report->report.reservoir[index];
    const auto& source = entry.delta;
    out_delta->cell = entry.cell;
    out_delta->species = source.species;
    out_delta->state = source.state;
    out_delta->physical_particles = source.physical_particles;
    out_delta->momentum_kg_m_per_s[0] = source.momentum_kg_m_per_s.x;
    out_delta->momentum_kg_m_per_s[1] = source.momentum_kg_m_per_s.y;
    out_delta->momentum_kg_m_per_s[2] = source.momentum_kg_m_per_s.z;
    out_delta->kinetic_energy_j = source.kinetic_energy_j;
    out_delta->internal_energy_j = source.internal_energy_j;
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_reaction_count(
    const ap_g02_mcc_step_report* report, size_t* out_count) {
    if (report == nullptr || out_count == nullptr) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_count = report->report.by_reaction.size();
    return AP_G02_MCC_OK;
}

ap_g02_mcc_status ap_g02_mcc_step_report_reaction_get(
    const ap_g02_mcc_step_report* report, const size_t index,
    uint32_t* out_reaction_id, uint64_t* out_count) {
    if (report == nullptr || out_reaction_id == nullptr || out_count == nullptr ||
        index >= report->report.by_reaction.size()) return AP_G02_MCC_INVALID_ARGUMENT;
    *out_reaction_id = report->report.by_reaction[index].first;
    *out_count = report->report.by_reaction[index].second;
    return AP_G02_MCC_OK;
}

} // extern "C"
