I02_par_init_and_load
===========================

.. toctree::
    :maxdepth: 1
    :hidden:

    I02_par_init_and_load/init_particles_bin
    I02_par_init_and_load/mod_I02_load_init_particles_bin
    I02_par_init_and_load/sub_I02_load_init_particles_bin

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   ``I02_par_init_and_load`` 面向需要离线生成初始粒子文件的算例。Python 脚本先根据解析密度模型在三维 T 形区域中生成电子和离子的 ``x,y,z,vx,vy,vz`` 记录；Fortran 载入例程再在 MPI
   运行时读取这些二进制记录，并按本地子域范围筛选粒子。

   .. list-table:: 文件
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 说明
      * - :doc:`init_particles_bin.py <I02_par_init_and_load/init_particles_bin>`
        - 离线生成 ``output_init_particles_bin/par_ele_init.bin`` 和 ``par_ion_init.bin``，并输出诊断图。
      * - :doc:`mod_I02_load_init_particles_bin.f90 <I02_par_init_and_load/mod_I02_load_init_particles_bin>`
        - Fortran 模块包装器，暴露二进制粒子载入例程。
      * - :doc:`sub_I02_load_init_particles_bin.f90 <I02_par_init_and_load/sub_I02_load_init_particles_bin>`
        - MPI 并行载入二进制粒子文件并分配到当前 rank。

   .. rubric:: 数据流

   1. 在准备阶段运行 ``init_particles_bin.py``，生成全局粒子二进制文件。
   2. MPI 程序启动后，每个 rank 调用载入例程并顺序扫描全局文件。
   3. 载入例程只保留满足 ``il(d)-1 <= r(d) < iu(d)`` 的粒子。
   4. 所有 rank 用 ``MPI_Allreduce`` 得到跨物种的本地最大粒子数，并按 ``f_npmax`` 扩展分配 ``par``。

   .. rubric:: 应用文献

   该离线初始粒子生成和载入流程用于 Hall 推力器三维 PIC 模拟中的近壁输运研究。相关论文包括：

   .. raw:: html

      <ul>
        <li>Z. Liu, Z. Zhao, and Y. Zhao, <em>Near-Wall Pathways of Anomalous Electron Transport in Hall Thrusters Revealed by 3D PIC Simulations</em>, arXiv:2603.14849 [physics.plasm-ph] (2026). DOI: <a href="https://doi.org/10.48550/arXiv.2603.14849" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2603.14849</a>.</li>
      </ul>

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵中平 (2026/4/22) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``I02_par_init_and_load`` supports cases that prepare initial particles through
   offline binary files. The Python script generates electron and ion
   ``x,y,z,vx,vy,vz`` records in a three-dimensional T-shaped region from
   analytical density and velocity models; the Fortran loader then reads those
   records during MPI startup and keeps the particles owned by the local subdomain.

   .. list-table:: Files
      :header-rows: 1
      :widths: 38 62

      * - File
        - Description
      * - :doc:`init_particles_bin.py <I02_par_init_and_load/init_particles_bin>`
        - Offline generator for ``output_init_particles_bin/par_ele_init.bin`` and ``par_ion_init.bin``, plus diagnostic plots.
      * - :doc:`mod_I02_load_init_particles_bin.f90 <I02_par_init_and_load/mod_I02_load_init_particles_bin>`
        - Fortran module wrapper exposing the binary particle loader.
      * - :doc:`sub_I02_load_init_particles_bin.f90 <I02_par_init_and_load/sub_I02_load_init_particles_bin>`
        - MPI loader that reads binary particle files and assigns particles to the current rank.

   .. rubric:: Data Flow

   1. Run ``init_particles_bin.py`` during case preparation to generate global binary particle files.
   2. During MPI startup, each rank calls the loader and scans the global files.
   3. The loader keeps only particles satisfying ``il(d)-1 <= r(d) < iu(d)``.
   4. The ranks use ``MPI_Allreduce`` to find the local maximum particle count and allocate ``par`` with the ``f_npmax`` expansion factor.

   .. rubric:: Applications and References

   This offline initial-particle generation and loading workflow is used in a
   near-wall transport study for Hall-thruster 3D PIC simulations. Related
   papers include:

   .. raw:: html

      <ul>
        <li>Z. Liu, Z. Zhao, and Y. Zhao, <em>Near-Wall Pathways of Anomalous Electron Transport in Hall Thrusters Revealed by 3D PIC Simulations</em>, arXiv:2603.14849 [physics.plasm-ph] (2026). DOI: <a href="https://doi.org/10.48550/arXiv.2603.14849" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2603.14849</a>.</li>
      </ul>

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhongping ZHAO (2026/4/22) · Harbin Institute of Technology</p>
      </div>
