/* SPDX-License-Identifier: Apache-2.0 */
#include "mpi_c_api.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(x) do { if (!(x)) { fprintf(stderr, "MPI C test line %d: %s\n", \
    __LINE__, #x); MPI_Abort(MPI_COMM_WORLD, 1); } } while (0)

static int by_id(const void* a, const void* b) {
    const ap_g02_mcc_particle* left = a;
    const ap_g02_mcc_particle* right = b;
    return (left->id > right->id) - (left->id < right->id);
}

int main(int argc, char** argv) {
    int provided = MPI_THREAD_SINGLE;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    CHECK(provided >= MPI_THREAD_FUNNELED && argc == 2);
    int rank = 0, ranks = 1;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &ranks);
    char error[512] = {0};
    ap_g02_mcc_model* model = NULL;
    ap_g02_mcc_engine* engine = NULL;
    ap_g02_mcc_mpi_session* session = NULL;
    CHECK(ap_g02_mcc_model_load(argv[1], &model, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_engine_create(model, &engine, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_mpi_session_create(engine, MPI_COMM_WORLD, 0, 1, 1, 0,
        &session, error, sizeof(error)) == AP_G02_MCC_OK);
    uint16_t electron = 0, ground = 0;
    CHECK(ap_g02_mcc_model_species_id(model, "e-", &electron, error,
        sizeof(error)) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_state_id(model, electron, "ground", &ground,
        error, sizeof(error)) == AP_G02_MCC_OK);
    ap_g02_mcc_cell_background gas[3] = {{0}};
    const char* names[] = {"M", "M2", "M2+"};
    for (int i = 0; i < 3; ++i) {
        gas[i].cell = UINT32_MAX;
        CHECK(ap_g02_mcc_model_species_id(model, names[i], &gas[i].species,
            error, sizeof(error)) == AP_G02_MCC_OK);
        CHECK(ap_g02_mcc_model_state_id(model, gas[i].species, "ground", &gas[i].state,
            error, sizeof(error)) == AP_G02_MCC_OK);
        gas[i].density_m3 = i == 0 ? 2e20 : 0;
        gas[i].temperature_k = 300;
    }
    ap_g02_mcc_particle local[2048] = {{0}}, before[2048] = {{0}};
    ap_g02_mcc_particle reference[2048] = {{0}};
    size_t local_count = 0;
    const double speed = sqrt(2 * 40 * 1.602176634e-19 / 9.1093837139e-31);
    for (uint64_t id = 1; id <= 256; ++id) {
        ap_g02_mcc_particle p = {0};
        p.id = id;
        p.species = electron;
        p.state = ground;
        p.weight = 1;
        p.velocity[0] = speed;
        reference[id - 1] = p;
        if ((id - 1) % (uint64_t)ranks == (uint64_t)rank) local[local_count++] = p;
    }
    memcpy(before, local, sizeof(local));
    ap_g02_mcc_cell_background invalid[3];
    memcpy(invalid, gas, sizeof(gas));
    if (rank == 0) invalid[0].density_m3 = -1;
    size_t required = 0;
    ap_g02_mcc_step_report* report = NULL;
    CHECK(ap_g02_mcc_mpi_session_step(session, local, &local_count, 2048, &required,
        invalid, 3, 1e-7, 1, 157, &report, error, sizeof(error)) ==
        AP_G02_MCC_PHYSICS_ERROR);
    CHECK(report == NULL && memcmp(local, before, sizeof(local)) == 0);

    const size_t original_count = local_count;
    const size_t capacity = rank == 0 ? local_count : 2048;
    CHECK(ap_g02_mcc_mpi_session_step(session, local, &local_count, capacity, &required,
        gas, 3, 1e-7, 1, 157, &report, error, sizeof(error)) ==
        AP_G02_MCC_BUFFER_TOO_SMALL);
    CHECK(report == NULL && local_count == original_count);
    CHECK(memcmp(local, before, sizeof(local)) == 0);
    if (rank == 0) CHECK(required > capacity);

    CHECK(ap_g02_mcc_mpi_session_step(session, local, &local_count, 2048, &required,
        gas, 3, 1e-7, 1, 157, &report, error, sizeof(error)) == AP_G02_MCC_OK);
    CHECK(report != NULL && required == local_count);
    CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);

    const int bytes = (int)(local_count * sizeof(ap_g02_mcc_particle));
    int* counts = calloc((size_t)ranks, sizeof(int));
    int* offsets = calloc((size_t)ranks, sizeof(int));
    CHECK(counts != NULL && offsets != NULL);
    MPI_Gather(&bytes, 1, MPI_INT, counts, 1, MPI_INT, 0, MPI_COMM_WORLD);
    int total = 0;
    for (int i = 0; i < ranks; ++i) {
        offsets[i] = total;
        total += counts[i];
    }
    ap_g02_mcc_particle gathered[2048] = {{0}};
    CHECK(total <= (int)sizeof(gathered));
    MPI_Gatherv(local, bytes, MPI_BYTE, gathered, counts, offsets, MPI_BYTE, 0,
                MPI_COMM_WORLD);
    if (rank == 0) {
        size_t reference_count = 256;
        report = NULL;
        CHECK(ap_g02_mcc_step(engine, reference, &reference_count, 2048, &required,
            gas, 3, 1e-7, 1, 157, 0, 1, 1, &report, error, sizeof(error)) == AP_G02_MCC_OK);
        CHECK(ap_g02_mcc_step_report_destroy(report) == AP_G02_MCC_OK);
        CHECK(reference_count == (size_t)total / sizeof(ap_g02_mcc_particle));
        qsort(reference, reference_count, sizeof(reference[0]), by_id);
        qsort(gathered, reference_count, sizeof(gathered[0]), by_id);
        for (size_t i = 0; i < reference_count; ++i) {
            CHECK(reference[i].id == gathered[i].id);
            CHECK(reference[i].species == gathered[i].species);
            CHECK(reference[i].velocity[0] == gathered[i].velocity[0]);
            CHECK(reference[i].velocity[1] == gathered[i].velocity[1]);
            CHECK(reference[i].velocity[2] == gathered[i].velocity[2]);
        }
    }
    free(offsets);
    free(counts);
    CHECK(ap_g02_mcc_mpi_session_destroy(session) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_engine_destroy(engine) == AP_G02_MCC_OK);
    CHECK(ap_g02_mcc_model_destroy(model) == AP_G02_MCC_OK);
    MPI_Finalize();
    return 0;
}
