# AlgoPlasma: Open Algorithms for Plasma Modeling

[中文](README.zh-CN.md) | [English](README.en.md)

AlgoPlasma, formerly PMSL, turns scattered and repeatedly reimplemented core algorithms for plasma modeling into an open, reusable, tested, and explainable algorithm library. It supports reliable modeling and result verification in research, while also helping learners understand algorithmic principles and gain hands-on experience in education. By bringing the community's efforts together, AlgoPlasma aims to build a shared algorithmic foundation so that others can build upon it instead of starting from scratch.

## Repository Layout

```text
AlgoPlasma
├── A_Pusher          # Particle pushers
├── B_Scatter         # Particle-to-grid deposition
├── C_Gather          # Grid-to-particle interpolation
├── D_Poisson         # Poisson solvers and electric field post-processing
├── E_Maxwell         # Maxwell / FDTD solvers
├── F_IO              # Data input and output
├── G_collision       # Collision models
├── H_MPI_Exchange    # MPI data exchange
├── I_Initializer     # Initialization
├── J_Fluid           # Fluid algorithms
├── docs              # Sphinx + Doxygen documentation
└── tests             # Algorithm tests and validation cases
```

An algorithm unit usually contains:

- Core implementation files, such as Fortran subroutine/function files, C/C++ source files, Python scripts, and related files.
- A module entry point or wrapper interface, such as a Fortran `mod_*.f90` file.
- A `README.md` or RST document explaining the algorithm purpose, equations, and interface.
- Test cases that validate numerical correctness, stability, convergence, or physical behavior.
- Optional visualization scripts, reference results, and educational notes.

## Implementation Languages

AlgoPlasma does not restrict implementation languages. The current repository is mostly Fortran, with some C helper code and Python scripts for testing, initialization, and plotting. Future contributions in C, C++, Python, CUDA, Julia, or other suitable languages are welcome.

## Quick Start

AlgoPlasma is currently organized mainly as a source-level algorithm library. Fortran modules are typically integrated through `mod_*.f90` entry files, which use C preprocessor `#include` directives to include the actual subroutines.

Example: call the 3D Boris particle pusher.

```fortran
#include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

program demo_boris
    use mod_A01_Boris_3Dxyz
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/1.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A01_Boris_3Dxyz(v, E, B, k)
end program demo_boris
```

Compilation usually requires C preprocessing:

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_boris.f90
```

Some modules may require extra dependencies such as MPI, OpenMP, HYPRE, or HDF5. See the corresponding algorithm and test directories for details.

## Tests

Tests live under `tests/`. Many test directories include:

- `make.sh`: build the test program.
- `run.sh`: run the test.
- `clean.sh`: remove generated files.
- `README.md`: explain the test objective, physical setup, and validation criteria.

For example, run the Maxwell FDTD single-step formula tests:

```bash
cd tests/005_maxwell/case_fdtd_single_step_formula
bash run.sh
```

After changing an algorithm, start with the most local tests for that algorithm, then run longer or more complete physical validation cases as needed.

## Documentation

The documentation is built with Sphinx, Doxygen, and Breathe:

- Doxygen comments in source files are used to generate API documentation.
- `docs/source/developer_onboarding.rst` provides quick-start paths for users and new contributors.
- `docs/source/rst_files/` contains algorithm notes, derivations, testing guides, and figures.
- `docs/source/creat_rst.py` helps generate or update some RST pages.

Typical documentation build workflow:

```bash
pip install -r docs/requirements.txt
cd docs
make html
```

Doxygen is also required on the system. The Read the Docs configuration is in `.readthedocs.yaml`. After a successful build, the HTML entry page is usually at `docs/build/html/index.html`; open that file in a browser to view the documentation.

## Contributing

Contributions are welcome for any algorithm implementation, test case, documentation, or validation result that serves plasma science.

A new algorithm contribution should ideally include:

- A clearly named algorithm directory.
- The core implementation and any necessary wrapper interface.
- Documentation for parameters, units, array layout, and boundary conventions.
- Algorithm equations, applicability notes, and key references.
- An independently runnable test or validation case.
- Python visualization or data-analysis scripts when useful.

Please keep algorithm units independent, interfaces clear, and dependencies explicit. For improvements to an existing algorithm, document whether the numerical behavior changes and update the corresponding tests when needed.

## License

AlgoPlasma is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for copyright and attribution information.

## Initiator / Contact

- Yinjian Zhao / 赵隐剑
- Email: zhaoyinjian0903@foxmail.com
- Homepage: <https://homepage.hit.edu.cn/zhaoyinjian>
