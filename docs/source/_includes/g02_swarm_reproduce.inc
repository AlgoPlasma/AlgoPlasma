.. code-block:: bash

   git worktree add --detach ../g02-speed-runner 6ccb13e
   git worktree add --detach ../g02-memory-runner c20880e
   (cd ../g02-speed-runner && python3 tests/009_collision/G02_MCC_network/examples/swarm_benchmark/run.py --baseline 7db6abe --candidate 8c9e151 --reverse-all --cpu 2 --out ../g02-speed-results)
   (cd ../g02-memory-runner && python3 tests/009_collision/G02_MCC_network/examples/swarm_benchmark/run.py --baseline 7db6abe --candidate 8c9e151 --reverse-all --cpu 2 --out ../g02-memory-results)
