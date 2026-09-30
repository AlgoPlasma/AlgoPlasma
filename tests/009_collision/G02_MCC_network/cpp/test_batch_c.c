/* SPDX-License-Identifier: Apache-2.0 */
#include "c_api.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define CHECK(x) do { if (!(x)) { fprintf(stderr, "CHECK %s:%d: %s\n", \
    __FILE__, __LINE__, #x); return 1; } } while (0)

int main(int argc, char** argv) {
    CHECK(argc == 2);
    char error[512] = {0};
    ap_g02_mcc_model* model = NULL;
    ap_g02_mcc_engine* engine = NULL;
    CHECK(ap_g02_mcc_model_load(argv[1], &model, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_engine_create(model, &engine, error, sizeof(error)) == AP_G02_MCC_OK);

    size_t species_count = 0;
    CHECK(ap_g02_mcc_model_species_count(model, &species_count) == AP_G02_MCC_OK);
    CHECK(species_count >= 3);
    uint16_t enumerated = UINT16_MAX;
    char name[128];
    double mass = 0;
    int charge = 0, representation = -1;
    CHECK(ap_g02_mcc_model_species_get(model, 0, &enumerated, name, sizeof(name),
                                       &mass, &charge, &representation) == AP_G02_MCC_OK);
    CHECK(strlen(name) > 0 && mass > 0);

    uint16_t electron = 0, ground = 0;
    CHECK(ap_g02_mcc_model_species_id(model, "e-", &electron, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_state_id(model, electron, "ground", &ground,
                                    error, sizeof(error)) == AP_G02_MCC_OK);
    ap_g02_mcc_cell_background gas[3] = {{0}};
    const char* names[3] = {"M", "M2", "M2+"};
    for (size_t i = 0; i < 3; ++i) {
        gas[i].cell = UINT32_MAX;
        CHECK(ap_g02_mcc_model_species_id(model, names[i], &gas[i].species,
                                          error, sizeof(error)) == AP_G02_MCC_OK);
        CHECK(ap_g02_mcc_model_state_id(model, gas[i].species, "ground", &gas[i].state,
                                        error, sizeof(error)) == AP_G02_MCC_OK);
        gas[i].density_m3 = i == 0 ? 2.0e20 : 0.0;
        gas[i].temperature_k = 300.0;
    }
    ap_g02_mcc_particle particles[64] = {{0}};
    for (size_t i = 0; i < 64; ++i) {
        particles[i].species = electron;
        particles[i].state = ground;
        particles[i].velocity[0] = 1.0e6;
        particles[i].weight = 1.0;
        particles[i].id = 1000 + i;
    }
    size_t count = 64, required = 0;
    ap_g02_mcc_step_report* report = NULL;
    CHECK(ap_g02_mcc_step(engine, particles, &count, 64, &required, gas, 3,
                          1.0e-7, 0, 42, 0, 0, 1, &report,
                          error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(report != NULL && count == 64 && required == 64);
    ap_g02_mcc_step_stats stats = {0};
    CHECK(ap_g02_mcc_step_report_stats(report, &stats) == AP_G02_MCC_OK);
    CHECK(stats.particles_visited == 64 && stats.candidates >= stats.real_events);
    size_t reservoir_count = 0;
    CHECK(ap_g02_mcc_step_report_reservoir_count(report, &reservoir_count) == AP_G02_MCC_OK);
    for (size_t i = 0; i < reservoir_count; ++i) {
        ap_g02_mcc_cell_reservoir source = {0};
        CHECK(ap_g02_mcc_step_report_reservoir_get(report, i, &source) == AP_G02_MCC_OK);
        CHECK(source.cell == 0 && isfinite(source.kinetic_energy_j));
    }
    CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);

    particles[1].id = particles[0].id;
    const double before_velocity = particles[0].velocity[0];
    report = NULL;
    CHECK(ap_g02_mcc_step(engine, particles, &count, 64, &required, gas, 3,
                          1.0e-7, 1, 42, 0, 0, 1, &report,
                          error, sizeof(error)) == AP_G02_MCC_PHYSICS_ERROR);
    CHECK(report == NULL && count == 64 && particles[0].velocity[0] == before_velocity);

    int found_growth = 0;
    for (uint64_t attempt = 1; attempt < 128 && !found_growth; ++attempt) {
        ap_g02_mcc_particle one = {0};
        one.species = electron;
        one.state = ground;
        one.velocity[0] = sqrt(2.0 * 40.0 * 1.602176634e-19 / 9.1093837139e-31);
        one.weight = 1.0;
        one.id = 8000;
        size_t one_count = 1, needed = 0;
        report = NULL;
        const ap_g02_mcc_status result = ap_g02_mcc_step(
            engine, &one, &one_count, 1, &needed, gas, 3,
            1.0e-6, 3, attempt, 0, 0, 1, &report, error, sizeof(error));
        if (result == AP_G02_MCC_BUFFER_TOO_SMALL) {
            CHECK(needed > 1 && one_count == 1 && report == NULL);
            CHECK(one.velocity[0] == sqrt(2.0 * 40.0 * 1.602176634e-19 /
                                          9.1093837139e-31));
            ap_g02_mcc_particle grown[256] = {{0}};
            grown[0] = one;
            size_t grown_count = 1;
            CHECK(ap_g02_mcc_step(engine, grown, &grown_count, 256, &needed, gas, 3,
                                  1.0e-6, 3, attempt, 0, 0, 1, &report,
                                  error, sizeof(error)) == AP_G02_MCC_OK);
            CHECK(grown_count > 1 && grown_count == needed);
            CHECK(ap_g02_mcc_step_report_stats(report, &stats) == AP_G02_MCC_OK);
            CHECK(stats.particles_visited == 1 && stats.created_particles == grown_count - 1);
            CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);
            for (size_t i = 1; i < grown_count; ++i) {
                CHECK(grown[i].id > one.id && grown[i].birth_step == 4);
            }
            ap_g02_mcc_session* session = NULL;
            CHECK(ap_g02_mcc_session_create(engine, 0, 0, 1, 0, &session,
                                             error, sizeof(error)) == AP_G02_MCC_OK);
            ap_g02_mcc_particle resumed[256] = {{0}};
            resumed[0] = one;
            size_t resumed_count = 1;
            report = NULL;
            CHECK(ap_g02_mcc_session_step(session, resumed, &resumed_count, 1,
                    &needed, gas, 3, 1.0e-6, 3, attempt, &report,
                    error, sizeof(error)) == AP_G02_MCC_BUFFER_TOO_SMALL);
            CHECK(needed == grown_count && resumed_count == 1 && report == NULL);
            CHECK(resumed[0].velocity[0] == one.velocity[0]);
            resumed[0].velocity[0] += 1.0;
            CHECK(ap_g02_mcc_session_resume(session, resumed, &resumed_count, 256,
                    &needed, &report, error, sizeof(error)) == AP_G02_MCC_INVALID_ARGUMENT);
            resumed[0] = one;
            CHECK(ap_g02_mcc_session_resume(session, resumed, &resumed_count, 256,
                    &needed, &report, error, sizeof(error)) == AP_G02_MCC_OK);
            CHECK(resumed_count == grown_count && report != NULL);
            for (size_t i = 0; i < grown_count; ++i) {
                CHECK(resumed[i].velocity[0] == grown[i].velocity[0]);
                CHECK(resumed[i].species == grown[i].species);
            }
            CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);
            CHECK(ap_g02_mcc_session_destroy(session) == AP_G02_MCC_OK);
            CHECK(ap_g02_mcc_step(engine, grown, &grown_count, 256, &needed, gas, 3,
                                  0.0, 3, attempt, 0, 0, 1, &report,
                                  error, sizeof(error)) == AP_G02_MCC_OK);
            CHECK(ap_g02_mcc_step_report_stats(report, &stats) == AP_G02_MCC_OK);
            CHECK(stats.particles_visited == 1);
            CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);
            found_growth = 1;
        } else {
            CHECK(result == AP_G02_MCC_OK);
            CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);
        }
    }
    CHECK(found_growth);
    CHECK(ap_g02_mcc_engine_destroy(engine) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_destroy(model) == AP_G02_MCC_OK);
    return 0;
}
