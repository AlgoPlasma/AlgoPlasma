/* SPDX-License-Identifier: Apache-2.0 */
/* C ABI lifecycle, error buffer and null-pointer tests. */
#include "c_api.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

static int failures = 0;
static int checks = 0;

#define CHECK(condition)                                                                 \
    do {                                                                                 \
        ++checks;                                                                        \
        if (!(condition)) {                                                              \
            ++failures;                                                                  \
            fprintf(stderr, "CHECK failed %s:%d: %s\n", __FILE__, __LINE__, #condition); \
        }                                                                                \
    } while (0)

static int main_impl(int argc, char** argv) {
    char error[512];

    CHECK(ap_g02_mcc_api_version() == 1);

    /* Null-safe destroy. */
    CHECK(ap_g02_mcc_model_destroy(NULL) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_engine_destroy(NULL) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_outcome_destroy(NULL) == AP_G02_MCC_OK);

    /* Null arguments and bounded error buffer. */
    error[0] = '\0';
    CHECK(ap_g02_mcc_model_load("whatever", NULL, error, sizeof(error)) ==
          AP_G02_MCC_INVALID_ARGUMENT);
    CHECK(error[0] != '\0');

    {
        char tiny[8];
        ap_g02_mcc_model* model = NULL;
        memset(tiny, 'x', sizeof(tiny));
        CHECK(ap_g02_mcc_model_load("/definitely/not/a/package", &model, tiny, sizeof(tiny)) !=
              AP_G02_MCC_OK);
        CHECK(model == NULL);
        CHECK(tiny[sizeof(tiny) - 1] == '\0');
        CHECK(strlen(tiny) > 0);
    }

    if (argc < 2) {
        fprintf(stderr, "usage: test_c_abi <demo_binary_dir>\n");
        return 1;
    }

    ap_g02_mcc_model* model = NULL;
    error[0] = '\0';
    CHECK(ap_g02_mcc_model_load(argv[1], &model, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(model != NULL);

    uint16_t electron = 0;
    uint16_t neutral = 0;
    uint16_t ion = 0;
    uint16_t molecular_ion = 0;
    uint16_t unknown = 0;
    CHECK(ap_g02_mcc_model_species_id(model, "e-", &electron, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_species_id(model, "M", &neutral, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_species_id(model, "M2", &ion, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_species_id(model, "M2+", &molecular_ion, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_species_id(model, "nope", &unknown, error, sizeof(error)) ==
          AP_G02_MCC_NOT_FOUND);
    CHECK(error[0] != '\0');
    CHECK(ap_g02_mcc_model_species_id(NULL, "e-", &unknown, error, sizeof(error)) ==
          AP_G02_MCC_INVALID_ARGUMENT);

    uint16_t ground = 0;
    CHECK(ap_g02_mcc_model_state_id(model, electron, "ground", &ground, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_state_id(model, electron, "bogus", &ground, error, sizeof(error)) ==
          AP_G02_MCC_NOT_FOUND);

    ap_g02_mcc_engine* engine = NULL;
    CHECK(ap_g02_mcc_engine_create(model, &engine, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(engine != NULL);
    CHECK(ap_g02_mcc_engine_create(NULL, &engine, error, sizeof(error)) ==
          AP_G02_MCC_INVALID_ARGUMENT);
    CHECK(ap_g02_mcc_collide(NULL, NULL, NULL, error, sizeof(error)) ==
          AP_G02_MCC_INVALID_ARGUMENT);

    ap_g02_mcc_background background[3];
    memset(background, 0, sizeof(background));
    background[0].species = neutral;
    background[0].density_m3 = 2.0e20;
    background[0].temperature_k = 300.0;
    background[1].species = ion;
    background[1].density_m3 = 5.0e19;
    background[1].temperature_k = 300.0;
    background[2].species = molecular_ion;
    background[2].density_m3 = 1.0e19;
    background[2].temperature_k = 300.0;

    ap_g02_mcc_request request;
    memset(&request, 0, sizeof(request));
    request.projectile.species = electron;
    request.projectile.state = ground;
    request.projectile.weight = 1.0;
    request.projectile.id = 42;
    {
        const double mass = 9.1093837139e-31;
        const double energy_ev = 30.0;
        request.projectile.velocity[0] =
            sqrt(2.0 * energy_ev * 1.602176634e-19 / mass);
    }
    request.background = background;
    request.background_count = 3;
    request.dt_s = 1.0e-5;
    request.global_step = 3;
    request.seed = 123456789;

    ap_g02_mcc_outcome* outcome = NULL;
    CHECK(ap_g02_mcc_collide(engine, &request, &outcome, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(outcome != NULL);

    ap_g02_mcc_particle primary;
    int action = -1;
    uint16_t destination = 0;
    CHECK(ap_g02_mcc_outcome_primary(outcome, &primary, &action, &destination, error,
                                     sizeof(error)) == AP_G02_MCC_OK);
    CHECK(action >= AP_G02_MCC_ACTION_NONE && action <= AP_G02_MCC_ACTION_MOVE_SPECIES);

    uint32_t candidates = 0;
    uint32_t real_events = 0;
    uint32_t null_events = 0;
    int limit_reached = 0;
    CHECK(ap_g02_mcc_outcome_counters(outcome, &candidates, &real_events, &null_events,
                                      &limit_reached, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(candidates >= 1);
    CHECK(real_events + null_events == candidates);

    size_t created_count = 0;
    CHECK(ap_g02_mcc_outcome_created_count(outcome, &created_count, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    for (size_t i = 0; i < created_count; ++i) {
        ap_g02_mcc_created created;
        CHECK(ap_g02_mcc_outcome_created_get(outcome, i, &created, error, sizeof(error)) ==
              AP_G02_MCC_OK);
        CHECK(created.parent_id == request.projectile.id);
        CHECK(created.birth_step == request.global_step + 1);
    }
    {
        ap_g02_mcc_created out_of_range;
        CHECK(ap_g02_mcc_outcome_created_get(outcome, created_count + 10, &out_of_range, error,
                                             sizeof(error)) == AP_G02_MCC_INVALID_ARGUMENT);
    }

    size_t reservoir_count = 0;
    CHECK(ap_g02_mcc_outcome_reservoir_count(outcome, &reservoir_count, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    for (size_t i = 0; i < reservoir_count; ++i) {
        ap_g02_mcc_reservoir delta;
        CHECK(ap_g02_mcc_outcome_reservoir_get(outcome, i, &delta, error, sizeof(error)) ==
              AP_G02_MCC_OK);
    }

    size_t event_count = 0;
    CHECK(ap_g02_mcc_outcome_event_count(outcome, &event_count, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(event_count == candidates);
    for (size_t i = 0; i < event_count; ++i) {
        ap_g02_mcc_event event;
        CHECK(ap_g02_mcc_outcome_event_get(outcome, i, &event, error, sizeof(error)) ==
              AP_G02_MCC_OK);
        CHECK(event.real_event || event.null_event);
    }

    ap_g02_mcc_ledger ledger;
    CHECK(ap_g02_mcc_outcome_ledger_get(outcome, &ledger, error, sizeof(error)) ==
          AP_G02_MCC_OK);
    CHECK(fabs(ledger.charge_before_c - ledger.charge_after_c) < 1.0e-30);
    CHECK(fabs(ledger.energy_residual_j) <= ledger.tolerance_j);

    CHECK(ap_g02_mcc_outcome_destroy(outcome) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_engine_destroy(engine) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_destroy(model) == AP_G02_MCC_OK);

    if (failures == 0) {
        printf("PASS test_c_abi (%d checks)\n", checks);
        return 0;
    }
    printf("FAIL test_c_abi (%d/%d checks failed)\n", failures, checks);
    return 1;
}

int main(int argc, char** argv) { return main_impl(argc, argv); }
