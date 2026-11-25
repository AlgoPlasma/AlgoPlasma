.. code-block:: bash

   cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_hybrid -DCMAKE_BUILD_TYPE=Release \
     -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
   cmake --build /tmp/g02_mcc_hybrid -j 4
   ctest --test-dir /tmp/g02_mcc_hybrid --output-on-failure
   /tmp/g02_mcc_hybrid/bench_batch 1000000 100 5 32 prefix
   /tmp/g02_mcc_hybrid/bench_batch 1000000 100 5 32 alias
   /tmp/g02_mcc_hybrid/g02_generate_test_data /tmp/g02_mcc_hybrid/generated_models
   mpirun -n 1 /tmp/g02_mcc_hybrid/mpi_collision_box \
     /tmp/g02_mcc_hybrid/generated_models/collision_box_elastic 1000000 5 1
   mpirun -n 2 /tmp/g02_mcc_hybrid/mpi_collision_box \
     /tmp/g02_mcc_hybrid/generated_models/collision_box_elastic 1000000 5 1
   mpirun -n 4 /tmp/g02_mcc_hybrid/mpi_collision_box \
     /tmp/g02_mcc_hybrid/generated_models/collision_box_elastic 1000000 5 1
   mpirun -n 4 /tmp/g02_mcc_hybrid/mpi_collision_box \
     /tmp/g02_mcc_hybrid/generated_models/collision_box_elastic 1000000 5 4

.. G02 contribution history (Git author dates; edit times include timezone).
   2026-11-25 11:54 +08:00 | Wushunzzz | git 65cc283b8592
   2026-11-25 15:54 +08:00 | Wushunzzz | edit (Codex-assisted)
   2026-11-25 16:27 +08:00 | Wushunzzz | edit (Codex-assisted)
