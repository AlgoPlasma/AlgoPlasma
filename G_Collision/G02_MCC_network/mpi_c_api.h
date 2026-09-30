/* SPDX-License-Identifier: Apache-2.0 */
/* MPI 的 C 入口，也供 Fortran 包装层调用。
 * 调用顺序：初始化 MPI → 创建 session → 重复推进 → 销毁 session → 结束 MPI。
 * collective 表示同一通信组的全体进程都须参加，粒子数为零也不能跳过。 */
#ifndef ALGOPLASMA_MCC_MPI_C_API_H
#define ALGOPLASMA_MCC_MPI_C_API_H

#include "c_api.h"
#include <mpi.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ap_g02_mcc_mpi_session ap_g02_mcc_mpi_session;

/* Collective on communicator. The host initializes MPI_THREAD_FUNNELED or higher.
 * sampler: 0 prefix, 1 alias. The session duplicates communicator. */
ap_g02_mcc_status ap_g02_mcc_mpi_session_create(const ap_g02_mcc_engine* engine,
    MPI_Comm communicator, uint32_t max_candidates, unsigned threads,
    int backend, int sampler, ap_g02_mcc_mpi_session** out_session,
    char* error_buffer, size_t error_buffer_size);

/* Fortran MPI communicator handle (default INTEGER must match C int width). */
ap_g02_mcc_status ap_g02_mcc_mpi_session_create_f(const ap_g02_mcc_engine* engine,
    int communicator, uint32_t max_candidates, unsigned threads,
    int backend, int sampler, ap_g02_mcc_mpi_session** out_session,
    char* error_buffer, size_t error_buffer_size);

ap_g02_mcc_status ap_g02_mcc_mpi_session_destroy(ap_g02_mcc_mpi_session* session);

/* Collective step. Every rank's particles remain unchanged on any rank's
 * preparation or capacity failure. BUFFER_TOO_SMALL sets required on each
 * rank that needs a larger buffer; retrying recomputes the deterministic step. */
ap_g02_mcc_status ap_g02_mcc_mpi_session_step(ap_g02_mcc_mpi_session* session,
    ap_g02_mcc_particle* particles, size_t* inout_count, size_t capacity,
    size_t* required, const ap_g02_mcc_cell_background* background,
    size_t background_count, double dt_s, uint64_t global_step, uint64_t seed,
    ap_g02_mcc_step_report** out_report, char* error_buffer, size_t error_buffer_size);

#ifdef __cplusplus
}
#endif

#endif
