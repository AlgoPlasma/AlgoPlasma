# AlgoPlasma: Open Algorithms for Plasma Modeling

[中文](README.zh-CN.md) | [English](README.en.md) | [Online documentation](https://algoplasma.readthedocs.io/en/latest/index.html)

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
├── K_Diagnostics     # Probe diagnostics and signal inversion
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

Read the [AlgoPlasma documentation](https://algoplasma.readthedocs.io/en/latest/index.html) online on Read the Docs.

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

<!-- CONTRIBUTORS:START -->
<p align="center"><sub>Thanks to everyone contributing code, tests, benchmarks, documentation, examples, and bug fixes to the project.</sub></p>

### Project Lead

<table class="ap-work-list ap-work-list--lead">
  <thead>
    <tr>
      <th scope="col" align="left" width="160">Member</th>
      <th scope="col" align="left">Biography</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://github.com/Yin-YinjianZhao"><img src="docs/source/_static/contributors/zhaoyinjian.png" width="160" height="160" alt="Yinjian Zhao"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://github.com/Yin-YinjianZhao">Yinjian Zhao</a></strong><br>
            <sub class="ap-member-role">Project Lead</sub>
            <br><small class="ap-member-links"><a href="https://homepage.hit.edu.cn/zhaoyinjian">Homepage</a> <a href="https://github.com/Yin-YinjianZhao">GitHub</a> <a href="https://gitee.com/Yin-YinjianZhao">Gitee</a></small>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <p class="ap-member-biography">I am an Associate Professor at Harbin Institute of Technology. I conducted postdoctoral research at Lawrence Berkeley National Laboratory and earned my PhD in Astronautical Engineering from the University of Southern California. My research has long focused on plasma physics and numerical simulation, spanning space electric propulsion, nuclear fusion, semiconductors, accelerators, numerical simulation algorithms, and high-performance parallel computing.</p>
        <p class="ap-member-statement">Throughout my career in research and teaching, I hope to make AlgoPlasma a lifelong endeavor, serving the plasma community across research, education, and industry, and contributing in my own small way to the field's progress.</p>
        <p class="ap-member-quote-intro">A thought to share:</p>
        <blockquote class="ap-member-quote"><p>Try to become not a man of success, but try rather to become a man of value. — Albert Einstein</p></blockquote>
      </td>
    </tr>
  </tbody>
</table>

### Current Maintainers

<table class="ap-maintainers">
  <tr>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/HermiteCat"><img src="docs/source/_static/contributors/wangbaisheng.jpg" width="72" height="72" alt="Baisheng Wang"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/HermiteCat">Baisheng Wang</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/HermiteCat">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Experiments and simulations of hollow cathodes for space electric propulsion</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/lzhe898"><img src="https://gitee.com/lzhe898.png" width="72" height="72" alt="Zhe Liu"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/lzhe898">Zhe Liu</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/lzhe898">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Photoionization and dense plasma focus</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://github.com/GooseGH"><img src="docs/source/_static/contributors/zhongping-zhao.svg" width="72" height="72" alt="Zhongping Zhao"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://github.com/GooseGH">Zhongping Zhao</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://github.com/GooseGH">GitHub</a> <a href="https://gitee.com/GooseGH">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Experiments and simulations of instabilities in Hall thrusters</p>
      </div>
    </td>
  </tr>
  <tr>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/peng-zilong123"><img src="docs/source/_static/contributors/pengzilong.jpg" width="72" height="72" alt="Zilong Peng"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/peng-zilong123">Zilong Peng</a></strong><br>
          <span class="ap-member-status">Master&#x27;s Student</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/peng-zilong123">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Experimental diagnostics of plasma waves</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/Luo-Xin-410"><img src="docs/source/_static/contributors/xin-luo.svg" width="72" height="72" alt="Xin Luo"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/Luo-Xin-410">Xin Luo</a></strong><br>
          <span class="ap-member-status">Postdoctoral Researcher</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/Luo-Xin-410">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Anomalous electron transport in Hall thrusters</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://orcid.org/0009-0009-6248-9781"><img src="docs/source/_static/contributors/lihuan-xie.svg" width="72" height="72" alt="Lihuan Xie"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://orcid.org/0009-0009-6248-9781">Lihuan Xie</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://orcid.org/0009-0009-6248-9781">ORCID</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Instabilities in iodine-propellant Hall thrusters</p>
      </div>
    </td>
  </tr>
  <tr>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><img src="docs/source/_static/contributors/xi-chen.svg" width="72" height="72" alt="Xi Chen"></span>
        <div class="ap-member-identity">
          <strong>Xi Chen</strong><br>
          <span class="ap-member-status">PhD Student</span>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Acceleration methods for 3D PIC simulations and reduced-dimensional models</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/jiaohuadetudouni"><img src="docs/source/_static/contributors/yingjie-chen.svg" width="72" height="72" alt="Yingjie Chen"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/jiaohuadetudouni">Yingjie Chen</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/jiaohuadetudouni">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Optimization of PIC algorithms in cylindrical coordinates</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><img src="docs/source/_static/contributors/kunpeng-zhong.svg" width="72" height="72" alt="Kunpeng Zhong"></span>
        <div class="ap-member-identity">
          <strong>Kunpeng Zhong</strong><br>
          <span class="ap-member-status">Master&#x27;s Student</span>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Magnetic focusing mechanisms in Hall thrusters</p>
      </div>
    </td>
  </tr>
  <tr>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><a href="https://gitee.com/HIT-ZhouZhijun"><img src="docs/source/_static/contributors/zhijun-zhou.svg" width="72" height="72" alt="Zhijun Zhou"></a></span>
        <div class="ap-member-identity">
          <strong><a href="https://gitee.com/HIT-ZhouZhijun">Zhijun Zhou</a></strong><br>
          <span class="ap-member-status">PhD Student</span>
          <br><small class="ap-member-links"><a href="https://gitee.com/HIT-ZhouZhijun">Gitee</a></small>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Azimuthal nonuniformity and instabilities in Hall thrusters</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><img src="docs/source/_static/contributors/wushun-zhang.svg" width="72" height="72" alt="Wushun Zhang"></span>
        <div class="ap-member-identity">
          <strong>Wushun Zhang</strong><br>
          <span class="ap-member-status">PhD Student</span>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Electron transpiration cooling of hypersonic vehicles</p>
      </div>
    </td>
    <td width="33.333%" valign="top">
      <div class="ap-member-profile">
        <span class="ap-member-avatar"><img src="docs/source/_static/contributors/huchangzheng.jpg" width="72" height="72" alt="Changzheng Hu"></span>
        <div class="ap-member-identity">
          <strong>Changzheng Hu</strong><br>
          <span class="ap-member-status">Master&#x27;s Student</span>
        </div>
      </div>
      <div class="ap-member-details">
        <p class="ap-member-research"><strong>Research Interests</strong><br>Theory of plasma waves</p>
      </div>
    </td>
  </tr>
</table>

<p align="center"><sub>Project lead and current maintainers: <a href="https://algoplasma.readthedocs.io/en/latest/community/contributors.html">Read the Docs</a></sub></p>
<!-- CONTRIBUTORS:END -->

## License

Original AlgoPlasma material is distributed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for copyright and attribution information. Third-party dependencies and any redistributed third-party code or data remain subject to their respective licenses.

Per-file license headers are not yet uniform across the source tree. Original project files without individual headers are covered by the repository-level `LICENSE` and `NOTICE`.

`D_Poisson/D01_hypre_3Dxyz/fun_D01_hypre_3Dxyz_bc.c` contains material adapted from the HYPRE Struct-interface examples. Its header retains the upstream copyright attribution, identifies the AlgoPlasma modifications, and specifies the Apache-2.0 option of the upstream dual license. The relevant upstream notice is retained in `NOTICE`.

## Initiator / Contact

- Yinjian Zhao / 赵隐剑
- Email: contact@algoplasma.com
- Homepage: <https://homepage.hit.edu.cn/zhaoyinjian>
