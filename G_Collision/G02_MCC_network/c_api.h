/* SPDX-License-Identifier: Apache-2.0
 *
 * Stable C ABI for the G02_MCC_network C++20 core.
 *
 * Rules:
 *   * fallible operations return ap_g02_mcc_status; operations with an error
 *     buffer write a bounded UTF-8 message on failure; other queries use
 *     their declared return types;
 *   * destroy functions are null-safe;
 *   * no C++ exception may cross this boundary;
 *   * handles are opaque and owned by the caller.
 *
 * Thread safety is not promised in v1.
 */
#ifndef ALGOPLASMA_MCC_C_API_H
#define ALGOPLASMA_MCC_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ap_g02_mcc_status {
    AP_G02_MCC_OK = 0,
    AP_G02_MCC_INVALID_ARGUMENT = 1,
    AP_G02_MCC_NOT_FOUND = 2,
    AP_G02_MCC_PARSE_ERROR = 3,
    AP_G02_MCC_COMPILE_ERROR = 4,
    AP_G02_MCC_PHYSICS_ERROR = 5,
    AP_G02_MCC_RUNTIME_ERROR = 6,
    AP_G02_MCC_BUFFER_TOO_SMALL = 7,
    AP_G02_MCC_INTERNAL_ERROR = 8
} ap_g02_mcc_status;

typedef enum ap_g02_mcc_primary_action {
    AP_G02_MCC_ACTION_NONE = 0,
    AP_G02_MCC_ACTION_UPDATE = 1,
    AP_G02_MCC_ACTION_REMOVE = 2,
    AP_G02_MCC_ACTION_MOVE_SPECIES = 3
} ap_g02_mcc_primary_action;

typedef struct ap_g02_mcc_model ap_g02_mcc_model;
typedef struct ap_g02_mcc_engine ap_g02_mcc_engine;
typedef struct ap_g02_mcc_outcome ap_g02_mcc_outcome;
typedef struct ap_g02_mcc_step_report ap_g02_mcc_step_report;
typedef struct ap_g02_mcc_session ap_g02_mcc_session;

/* 位置单位 m，速度 m/s；weight 是模拟粒子代表的真实粒子数。
 * C 的 {0} 初始化不会给 weight=1，须设置有效权重。
 * id 是跨排序和迁移保持不变的编号，不是数组下标。 */
typedef struct ap_g02_mcc_particle {
    uint16_t species;
    uint16_t state;
    double position[3];
    double velocity[3];
    double weight;
    uint64_t id;
    uint64_t birth_step;
    uint32_t cell;
} ap_g02_mcc_particle;

typedef struct ap_g02_mcc_background {
    uint16_t species;
    double density_m3;
    double temperature_k;
    double drift_m_per_s[3];
} ap_g02_mcc_background;

/* projectile 是被推进的主粒子，background 是给定背景。
 * dt_s 单位 s；background_count 是数组长度，不是数密度。
 * background 指针在调用期间须有效，数密度由 density_m3 给出。 */
typedef struct ap_g02_mcc_request {
    ap_g02_mcc_particle projectile;
    const ap_g02_mcc_background* background;
    size_t background_count;
    double dt_s;
    uint64_t global_step;
    uint64_t seed;
    uint32_t max_events_per_step;
} ap_g02_mcc_request;

typedef struct ap_g02_mcc_created {
    uint64_t parent_id;
    uint32_t event_index;
    uint32_t product_ordinal;
    uint16_t species;
    uint16_t state;
    double position[3];
    double velocity[3];
    double weight;
    uint64_t birth_step;
} ap_g02_mcc_created;

/* 记录与未逐个追踪的背景交换的物质、动量和能量。
 * 返回增量不意味着已经自动更新主程序的背景场。 */
typedef struct ap_g02_mcc_reservoir {
    uint16_t species;
    double physical_particles;
    double momentum_kg_m_per_s[3];
    double kinetic_energy_j;
    double internal_energy_j;
} ap_g02_mcc_reservoir;

/* majorant 是候选频率上界（1/s）；has_* 为零时对应字段无可用值。 */
typedef struct ap_g02_mcc_event {
    uint32_t event_index;
    uint32_t reaction;
    int algorithm;
    int real_event;
    int null_event;
    double majorant_s_inv;
    double sampled_rate_s_inv;
    uint16_t background_species;
    int has_relative_energy;
    double relative_energy_ev;
    int has_cross_section;
    double cross_section_m2;
} ap_g02_mcc_event;

typedef struct ap_g02_mcc_ledger {
    double charge_before_c;
    double charge_after_c;
    double momentum_before_kg_m_per_s[3];
    double momentum_after_kg_m_per_s[3];
    double kinetic_before_j;
    double kinetic_after_j;
    double internal_before_j;
    double internal_after_j;
    double released_energy_j;
    double radiated_or_unresolved_j;
    double energy_residual_j;
    double tolerance_j;
} ap_g02_mcc_ledger;

typedef struct ap_g02_mcc_cell_background {
    uint32_t cell; /* UINT32_MAX is the uniform fallback. */
    uint16_t species;
    uint16_t state; /* UINT16_MAX preserves species-aggregated v1 semantics. */
    double density_m3;
    double temperature_k;
    double drift_m_per_s[3];
} ap_g02_mcc_cell_background;

typedef struct ap_g02_mcc_cell_reservoir {
    uint32_t cell;
    uint16_t species;
    uint16_t state;
    double physical_particles;
    double momentum_kg_m_per_s[3];
    double kinetic_energy_j;
    double internal_energy_j;
} ap_g02_mcc_cell_reservoir;

typedef struct ap_g02_mcc_step_stats {
    uint64_t particles_visited;
    uint64_t candidates;
    uint64_t real_events;
    uint64_t null_events;
    uint64_t created_particles;
    double preparation_seconds;
    double sampling_seconds;
    double reduction_seconds;
    double commit_seconds;
    double total_seconds;
} ap_g02_mcc_step_stats;

/* Returns the ABI version implemented by this build (currently 1). */
int ap_g02_mcc_api_version(void);

ap_g02_mcc_status ap_g02_mcc_model_load(const char* package_dir,
                                        ap_g02_mcc_model** out_model,
                                        char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_model_destroy(ap_g02_mcc_model* model);

ap_g02_mcc_status ap_g02_mcc_model_species_id(const ap_g02_mcc_model* model, const char* name,
                                              uint16_t* out_id, char* error_buffer,
                                              size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_model_state_id(const ap_g02_mcc_model* model, uint16_t species,
                                            const char* label, uint16_t* out_id,
                                            char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_model_species_count(const ap_g02_mcc_model* model,
                                                 size_t* out_count);
ap_g02_mcc_status ap_g02_mcc_model_species_get(const ap_g02_mcc_model* model,
    size_t index, uint16_t* out_id, char* name, size_t name_capacity,
    double* out_mass_kg, int* out_charge_state, int* out_representation);
ap_g02_mcc_status ap_g02_mcc_model_state_count(const ap_g02_mcc_model* model,
                                               size_t* out_count);
ap_g02_mcc_status ap_g02_mcc_model_state_get(const ap_g02_mcc_model* model,
    size_t index, uint16_t* out_id, uint16_t* out_species,
    char* label, size_t label_capacity, double* out_energy_ev);
ap_g02_mcc_status ap_g02_mcc_model_reaction_count(const ap_g02_mcc_model* model,
                                                  size_t* out_count);
ap_g02_mcc_status ap_g02_mcc_model_reaction_get(const ap_g02_mcc_model* model,
    size_t index, uint32_t* out_id, char* name, size_t name_capacity);

ap_g02_mcc_status ap_g02_mcc_engine_create(const ap_g02_mcc_model* model,
                                           ap_g02_mcc_engine** out_engine,
                                           char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_engine_destroy(ap_g02_mcc_engine* engine);

ap_g02_mcc_status ap_g02_mcc_collide(const ap_g02_mcc_engine* engine,
                                     const ap_g02_mcc_request* request,
                                     ap_g02_mcc_outcome** out_outcome,
                                     char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_destroy(ap_g02_mcc_outcome* outcome);

ap_g02_mcc_status ap_g02_mcc_outcome_primary(const ap_g02_mcc_outcome* outcome,
                                             ap_g02_mcc_particle* out_particle,
                                             int* out_action, uint16_t* out_destination,
                                             char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_counters(const ap_g02_mcc_outcome* outcome,
                                              uint32_t* out_candidates, uint32_t* out_real,
                                              uint32_t* out_null, int* out_limit_reached,
                                              char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_created_count(const ap_g02_mcc_outcome* outcome,
                                                   size_t* out_count, char* error_buffer,
                                                   size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_created_get(const ap_g02_mcc_outcome* outcome,
                                                 size_t index, ap_g02_mcc_created* out_created,
                                                 char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_reservoir_count(const ap_g02_mcc_outcome* outcome,
                                                     size_t* out_count, char* error_buffer,
                                                     size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_reservoir_get(const ap_g02_mcc_outcome* outcome,
                                                   size_t index,
                                                   ap_g02_mcc_reservoir* out_reservoir,
                                                   char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_event_count(const ap_g02_mcc_outcome* outcome,
                                                 size_t* out_count, char* error_buffer,
                                                 size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_event_get(const ap_g02_mcc_outcome* outcome, size_t index,
                                               ap_g02_mcc_event* out_event, char* error_buffer,
                                               size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_outcome_ledger_get(const ap_g02_mcc_outcome* outcome,
                                                ap_g02_mcc_ledger* out_ledger,
                                                char* error_buffer, size_t error_buffer_size);

/* backend: 0 auto, 1 serial, 2 OpenMP. cap must include possible products.
 * On insufficient capacity, particles and count are untouched, and required
 * receives the necessary size. All other failures are equally atomic. */
ap_g02_mcc_status ap_g02_mcc_step(const ap_g02_mcc_engine* engine,
                                  ap_g02_mcc_particle* particles,
                                  size_t* inout_count, size_t capacity, size_t* required,
                                  const ap_g02_mcc_cell_background* background,
                                  size_t background_count, double dt_s,
                                  uint64_t global_step, uint64_t seed,
                                  uint32_t max_candidates, unsigned threads, int backend,
                                  ap_g02_mcc_step_report** out_report,
                                  char* error_buffer, size_t error_buffer_size);

/* Persistent batch workspace. sampler: 0 prefix (default), 1 alias.
 * On BUFFER_TOO_SMALL, retry with session_resume() after enlarging the
 * unchanged particle input, or discard with session_abort(). */
ap_g02_mcc_status ap_g02_mcc_session_create(const ap_g02_mcc_engine* engine,
    uint32_t max_candidates, unsigned threads, int backend, int sampler,
    ap_g02_mcc_session** out_session, char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_session_destroy(ap_g02_mcc_session* session);
ap_g02_mcc_status ap_g02_mcc_session_abort(ap_g02_mcc_session* session);
ap_g02_mcc_status ap_g02_mcc_session_step(ap_g02_mcc_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, size_t capacity,
    size_t* required, const ap_g02_mcc_cell_background* background,
    size_t background_count, double dt_s, uint64_t global_step, uint64_t seed,
    ap_g02_mcc_step_report** out_report, char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_session_resume(ap_g02_mcc_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, size_t capacity,
    size_t* required, ap_g02_mcc_step_report** out_report,
    char* error_buffer, size_t error_buffer_size);
ap_g02_mcc_status ap_g02_mcc_step_report_destroy(ap_g02_mcc_step_report* report);
ap_g02_mcc_status ap_g02_mcc_step_report_stats(const ap_g02_mcc_step_report* report,
                                               ap_g02_mcc_step_stats* out_stats);
ap_g02_mcc_status ap_g02_mcc_step_report_ledger(const ap_g02_mcc_step_report* report,
                                                ap_g02_mcc_ledger* out_ledger);
ap_g02_mcc_status ap_g02_mcc_step_report_reservoir_count(
    const ap_g02_mcc_step_report* report, size_t* out_count);
ap_g02_mcc_status ap_g02_mcc_step_report_reservoir_get(
    const ap_g02_mcc_step_report* report, size_t index,
    ap_g02_mcc_cell_reservoir* out_delta);
ap_g02_mcc_status ap_g02_mcc_step_report_reaction_count(
    const ap_g02_mcc_step_report* report, size_t* out_count);
ap_g02_mcc_status ap_g02_mcc_step_report_reaction_get(
    const ap_g02_mcc_step_report* report, size_t index,
    uint32_t* out_reaction_id, uint64_t* out_count);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* ALGOPLASMA_MCC_C_API_H */
