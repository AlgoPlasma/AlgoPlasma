/* SPDX-License-Identifier: Apache-2.0 */
#include "c_api.h"
#include <stdio.h>

int main(int argc, char** argv) {
    if (argc != 2) return 2;
    char error[512] = {0};
    ap_g02_mcc_model* model = NULL;
    ap_g02_mcc_engine* engine = NULL;
    ap_g02_mcc_outcome* outcome = NULL;
    ap_g02_mcc_step_report* report = NULL;
    ap_g02_mcc_status status = AP_G02_MCC_OK;
    ap_g02_mcc_request request = {0};
    ap_g02_mcc_background gas = {0};
    ap_g02_mcc_particle particles[1] = {0};
    ap_g02_mcc_cell_background background[1] = {0};
    size_t count = 1, capacity = 1, required = 0;
    const uint32_t max_candidates = 0; /* default limit */
    const unsigned threads = 0;       /* runtime chooses thread count */
    const int backend = 0 /* Auto; 1 = Serial, 2 = OpenMP */;
#define CHECK(call) do { status = (call); if (status != AP_G02_MCC_OK) goto cleanup; } while (0)
    CHECK(ap_g02_mcc_model_load(argv[1], &model, error, sizeof(error)));
    CHECK(ap_g02_mcc_engine_create(model, &engine, error, sizeof(error)));
    CHECK(ap_g02_mcc_model_species_id(model, "A", &request.projectile.species, error, sizeof(error)));
    CHECK(ap_g02_mcc_model_state_id(model, request.projectile.species, "ground", &request.projectile.state, error, sizeof(error)));
    CHECK(ap_g02_mcc_model_species_id(model, "B", &gas.species, error, sizeof(error)));
    request.projectile.weight = 1.0;
    request.projectile.id = 1;
    request.projectile.velocity[0] = 1000.0;
    gas.density_m3 = 1.0e20;
    gas.temperature_k = 300.0;
    request.background = &gas;
    request.background_count = 1;
    request.dt_s = 1.0e-7;
    request.global_step = 0;
    request.seed = 1234;
    request.max_events_per_step = 0; /* model's default legacy limit */
    CHECK(ap_g02_mcc_collide(engine, &request, &outcome, error, sizeof(error)));
    /* This demo inspects API success only; legacy outcome is not auto-committed. */
    particles[0] = request.projectile;
    background[0].cell = 0; /* matches particles[0].cell */
    background[0].species = gas.species;
    CHECK(ap_g02_mcc_model_state_id(model, gas.species, "ground", &background[0].state, error, sizeof(error)));
    background[0].density_m3 = gas.density_m3;
    background[0].temperature_k = gas.temperature_k;
    CHECK(ap_g02_mcc_step(engine, particles, &count, capacity, &required,
        background, 1, request.dt_s, 0, request.seed,
        max_candidates, threads, backend, &report, error, sizeof(error)));
    puts("PASS");
cleanup:
    if (status != AP_G02_MCC_OK) fprintf(stderr, "status=%d %s\n", (int)status, error);
    ap_g02_mcc_step_report_destroy(report);
    ap_g02_mcc_outcome_destroy(outcome);
    ap_g02_mcc_engine_destroy(engine);
    ap_g02_mcc_model_destroy(model);
    return status == AP_G02_MCC_OK ? 0 : 1;
}
