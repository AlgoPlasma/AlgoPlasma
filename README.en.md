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
├── G_Collision       # Collision models
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

## Contributors

This list is generated from `contributors.yml`; do not edit this section by hand. Run `python3 tools/generate_contributors.py` to regenerate it.

<!-- CONTRIBUTORS:START -->
<p align="center"><sub>Thanks to everyone contributing code, tests, benchmarks, documentation, examples, and bug fixes to the project.</sub></p>

<p align="center"><sub>Contribution types: 💻 Code · 🧪 Tests · 📊 Benchmark · 📖 Documentation · 🎓 Examples · 🐛 Bug Fixes</sub></p>

<table>
  <tr>
    <td align="center" width="110" valign="top">
      <a href="https://github.com/Yin-YinjianZhao"><img src="https://github.com/Yin-YinjianZhao.png" width="80" height="80" alt="Yinjian Zhao"></a><br>
      <sub><b>Yinjian Zhao</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://github.com/GooseGH"><img src="https://github.com/GooseGH.png" width="80" height="80" alt="Zhongping Zhao"></a><br>
      <sub><b>Zhongping Zhao</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/lzhe898"><img src="https://gitee.com/lzhe898.png" width="80" height="80" alt="Zhe Liu"></a><br>
      <sub><b>Zhe Liu</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/HermiteCat"><img src="docs/source/_static/contributors/baisheng-wang.svg" width="80" height="80" alt="Baisheng Wang"></a><br>
      <sub><b>Baisheng Wang</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/peng-zilong123"><img src="docs/source/_static/contributors/zilong-peng.svg" width="80" height="80" alt="Zilong Peng"></a><br>
      <sub><b>Zilong Peng</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/Luo-Xin-410"><img src="docs/source/_static/contributors/xin-luo.svg" width="80" height="80" alt="Xin Luo"></a><br>
      <sub><b>Xin Luo</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="110" valign="top">
      <a href="https://orcid.org/0009-0009-6248-9781"><img src="docs/source/_static/contributors/lihuan-xie.svg" width="80" height="80" alt="Lihuan Xie"></a><br>
      <sub><b>Lihuan Xie</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <img src="docs/source/_static/contributors/xi-chen.svg" width="80" height="80" alt="Xi Chen"><br>
      <sub><b>Xi Chen</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/HIT-ZhouZhijun"><img src="docs/source/_static/contributors/zhijun-zhou.svg" width="80" height="80" alt="Zhijun Zhou"></a><br>
      <sub><b>Zhijun Zhou</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <img src="docs/source/_static/contributors/kunpeng-zhong.svg" width="80" height="80" alt="Kunpeng Zhong"><br>
      <sub><b>Kunpeng Zhong</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <a href="https://gitee.com/jiaohuadetudouni"><img src="docs/source/_static/contributors/yingjie-chen.svg" width="80" height="80" alt="Yingjie Chen"></a><br>
      <sub><b>Yingjie Chen</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
    <td align="center" width="110" valign="top">
      <img src="docs/source/_static/contributors/changzheng-hu.svg" width="80" height="80" alt="Changzheng Hu"><br>
      <sub><b>Changzheng Hu</b></sub><br>
      <sub><abbr title="Code">💻</abbr> <abbr title="Tests">🧪</abbr> <abbr title="Benchmark">📊</abbr> <abbr title="Documentation">📖</abbr> <abbr title="Examples">🎓</abbr> <abbr title="Bug Fixes">🐛</abbr></sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="110" valign="top">
      <a href="https://github.com/bocong-zheng"><img src="https://github.com/bocong-zheng.png" width="80" height="80" alt="Bocong Zheng"></a><br>
      <sub><b>Bocong Zheng</b></sub><br>
      <sub><abbr title="Code">💻</abbr></sub>
    </td>
  </tr>
</table>

<p align="center"><sub>Full list with roles and links: <a href="https://algoplasma.readthedocs.io/en/latest/community/contributors.html">Read the Docs</a></sub></p>
<!-- CONTRIBUTORS:END -->

## License

AlgoPlasma is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for copyright and attribution information.

## Initiator / Contact

- Yinjian Zhao / 赵隐剑
- Email: contact@algoplasma.com
- Homepage: <https://homepage.hit.edu.cn/zhaoyinjian>
