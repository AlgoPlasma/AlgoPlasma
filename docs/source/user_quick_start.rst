User Quick Start
================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-onboarding

   .. container:: ap-onboarding-hero

      .. rubric:: 使用者快速入门

      这条路线面向“只想调用 AlgoPlasma 子程序”的使用者。目标很简单：拿到源码，跑通一个小测试，然后在自己的程序里调用一个子程序。

      .. raw:: html

         <div class="ap-onboarding-path" aria-label="User quick start path">
           <span>获取源码</span>
           <span>跑 A01 测试</span>
           <span>看调用方式</span>
           <span>编译自己的程序</span>
         </div>

   .. container:: ap-onboarding-done

      .. rubric:: 完成标准

      - ``tests/002_pusher/A01_Boris_3Dxyz`` 能编译并运行。
      - 能调用 ``sub_A01_Boris_3Dxyz(v, E, B, k)``。
      - 知道 PIC 流程中每一步大致该查哪个 AlgoPlasma 模块。

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 1. 获取源码

      AlgoPlasma 目前主要是源码级算法库，不需要先打包安装。最简单的“安装”就是把源码仓库放在本机，并在编译时开启 C 预处理。

      .. code-block:: bash

         git clone <repo-url> algoplasma
         cd algoplasma

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 2. 跑一个最小测试

      先跑 A01 的 Boris 推进器测试。它依赖少，适合确认本机编译器和基本环境。

      .. code-block:: bash

         cd tests/002_pusher/A01_Boris_3Dxyz
         ./clean.sh
         ./make.sh
         ./run.sh

      如果 ``build/case*.dat`` 生成了，就说明这个最小测试跑通。想看轨道图时再运行：

      .. code-block:: bash

         ./plot.sh

      这个测试的详细说明见 :doc:`A01_Boris_3Dxyz 测试 <tests/002_pusher/A01_Boris_3Dxyz>`。

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 3. 调用一个子程序

      调用 AlgoPlasma 的基本方式是：在自己的 Fortran 程序里 ``#include`` 对应的 ``mod_*.f90``，然后 ``use`` 这个 module。

      .. code-block:: fortran

         #include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

         program demo_a01
             use mod_A01_Boris_3Dxyz
             implicit none

             real :: v(3), E(3), B(3), k

             v = (/1.0, 0.0, 0.0/)
             E = 0.0
             B = (/0.0, 0.0, 1.0/)
             k = 0.01

             call sub_A01_Boris_3Dxyz(v, E, B, k)
         end program demo_a01

      在仓库根目录编译这个例子最省事：

      .. code-block:: bash

         gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90

      注意：当前不少 Fortran 程序直接使用默认 ``real``。如果希望按双精度运行，需要在编译命令中加入对应选项，例如 ``gfortran -fdefault-real-8``；使用 Intel Fortran 时可用类似 ``ifx -real-size 64`` 的选项。测试目录里的 ``make.sh`` 若已经包含该选项，直接按脚本运行即可。

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 4. PIC 流程里该用哪些模块

      AlgoPlasma 不是一个固定的 PIC 主程序，而是一组可以拼到自己程序里的算法模块和子程序。一个常见 PIC 程序可以按下面的流程理解：

      .. figure:: images/onboarding/pic_workflow_zh-CN.png
         :align: center
         :width: 88%

         PIC 流程与 AlgoPlasma 模块对应关系。

      对应到 AlgoPlasma，可以先按这个表找模块：

      .. list-table::
         :header-rows: 1
         :widths: 24 34 42

         * - PIC 步骤
           - AlgoPlasma 模块
           - 常见子程序组
         * - 初始化粒子和读取初值
           - :doc:`I_Initializer <rst_files/I_Initializer>`，:doc:`F_IO <rst_files/F_IO>`
           - ``I01_par_distribute``，``I02_par_init_and_load``，``F01_par_load``，``F03_field_load``
         * - 网格场插值到粒子
           - :doc:`C_Gather <rst_files/C_Gather>`
           - ``C01_gather_3Dxyz``，``C02_gather_3Dxyz_bspline``
         * - 推进粒子
           - :doc:`A_Pusher <rst_files/A_Pusher>`
           - ``A01_Boris_3Dxyz``，``A02_Boris_3Drtz``，``A03_Higuera_Cary_relativistic_3Dxyz``
         * - 碰撞
           - :doc:`G_collision <rst_files/G_collision>`
           - ``G01_MCC``
         * - 粒子沉积到网格
           - :doc:`B_Scatter <rst_files/B_Scatter>`
           - ``B01_scatter_3Dxyz``，``B02_deposit_3d_cyl``
         * - 场求解或场推进
           - :doc:`D_Poisson <rst_files/D_Poisson>`，:doc:`E_Maxwell <rst_files/E_Maxwell>`
           - ``D01``-``D04`` Poisson/HYPRE 求解器，``E01``-``E03`` FDTD/CPML
         * - MPI 边界和粒子交换
           - :doc:`H_MPI_Exchange <rst_files/H_MPI_Exchange>`
           - ``H01_mpi_exchange_field``，``H02_mpi_exchange_par``，``H03_mpi_exchange_den``
         * - 输出粒子和场
           - :doc:`F_IO <rst_files/F_IO>`
           - ``F02_par_output``，``F04_field_output``

      静电 PIC 通常更关注 ``B_Scatter`` 得到电荷密度，然后用 ``D_Poisson`` 求电势或电场。电磁 PIC 通常还会沉积电流，并用 ``E_Maxwell`` 更新电磁场。并行程序里，``H_MPI_Exchange`` 可能会在场更新、沉积后、粒子跨区后分别出现。

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: 后续调用其他模块

         - 先看模块目录里的 ``README.zh-CN.md``。
         - 再看对应测试页，确认运行命令和输出含义。
         - 复杂模块可能需要 MPI、HYPRE、HDF5 或 Python 绘图环境，具体以模块说明为准。

      .. container:: ap-onboarding-note

         .. rubric:: 常见卡点

         - ``run.sh`` 报找不到 ``build``：先运行 ``./make.sh``。
         - ``make.sh`` 编译失败：先确认本机有 ``gfortran``，并从测试目录运行脚本。
         - ``plot.sh`` 失败：不影响调用 AlgoPlasma，先确认 ``build/case*.dat`` 已生成。
         - include 路径找不到：优先从仓库根目录编译，或把 include 路径改成相对当前编译目录的路径。

.. container:: ap-lang ap-lang-en ap-onboarding

   .. container:: ap-onboarding-hero

      .. rubric:: User Quick Start

      This route is for users who only want to call AlgoPlasma routines. The goal is simple: get the source tree, run one small test, then call one subroutine from your own program.

      .. raw:: html

         <div class="ap-onboarding-path" aria-label="User quick start path">
           <span>Get source</span>
           <span>Run A01 test</span>
           <span>Read call pattern</span>
           <span>Compile your program</span>
         </div>

   .. container:: ap-onboarding-done

      .. rubric:: The First Pass Is Done When

      - ``tests/002_pusher/A01_Boris_3Dxyz`` builds and runs.
      - You can call ``sub_A01_Boris_3Dxyz(v, E, B, k)``.
      - You know which AlgoPlasma module to check for each main PIC step.

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 1. Get The Source Tree

      AlgoPlasma is currently a source-level algorithm library. The simplest
      installation is to keep the source tree locally and compile callers with
      C preprocessing enabled.

      .. code-block:: bash

         git clone <repo-url> algoplasma
         cd algoplasma

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 2. Run One Minimal Test

      Start with the A01 Boris pusher test. It has few dependencies and is a
      good way to confirm that the compiler and basic environment work.

      .. code-block:: bash

         cd tests/002_pusher/A01_Boris_3Dxyz
         ./clean.sh
         ./make.sh
         ./run.sh

      If ``build/case*.dat`` is generated, the minimal test has passed. Run the
      plotting step only when you want figures:

      .. code-block:: bash

         ./plot.sh

      See :doc:`A01_Boris_3Dxyz Test <tests/002_pusher/A01_Boris_3Dxyz>` for the
      full test notes.

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 3. Call One Subroutine

      The basic call pattern is to ``#include`` the target ``mod_*.f90`` file,
      then ``use`` the module in your Fortran program.

      .. code-block:: fortran

         #include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

         program demo_a01
             use mod_A01_Boris_3Dxyz
             implicit none

             real :: v(3), E(3), B(3), k

             v = (/1.0, 0.0, 0.0/)
             E = 0.0
             B = (/0.0, 0.0, 1.0/)
             k = 0.01

             call sub_A01_Boris_3Dxyz(v, E, B, k)
         end program demo_a01

      Compile from the repository root for the simplest relative include path:

      .. code-block:: bash

         gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90

      Note: many Fortran programs currently use default ``real``. If double
      precision is required, add the corresponding compiler option, such as
      ``gfortran -fdefault-real-8``. With Intel Fortran, use an option such as
      ``ifx -real-size 64``. If a test directory's ``make.sh`` already contains
      that option, run the script as written.

   .. container:: ap-onboarding-step ap-onboarding-user

      .. rubric:: 4. Which Modules Fit The PIC Workflow

      AlgoPlasma is not a fixed PIC driver. It is a set of algorithm modules and subroutines that you can
      assemble into your own program. A common PIC program can be read as this
      workflow:

      .. figure:: images/onboarding/pic_workflow_en.png
         :align: center
         :width: 88%

         PIC workflow and related AlgoPlasma modules.

      Use this table as the first module map:

      .. list-table::
         :header-rows: 1
         :widths: 24 34 42

         * - PIC step
           - AlgoPlasma module
           - Common routine groups
         * - Initialize particles and load initial data
           - :doc:`I_Initializer <rst_files/I_Initializer>`, :doc:`F_IO <rst_files/F_IO>`
           - ``I01_par_distribute``, ``I02_par_init_and_load``, ``F01_par_load``, ``F03_field_load``
         * - Gather grid fields to particles
           - :doc:`C_Gather <rst_files/C_Gather>`
           - ``C01_gather_3Dxyz``, ``C02_gather_3Dxyz_bspline``
         * - Push particles
           - :doc:`A_Pusher <rst_files/A_Pusher>`
           - ``A01_Boris_3Dxyz``, ``A02_Boris_3Drtz``, ``A03_Higuera_Cary_relativistic_3Dxyz``
         * - Collisions
           - :doc:`G_collision <rst_files/G_collision>`
           - ``G01_MCC``
         * - Deposit particles to grid
           - :doc:`B_Scatter <rst_files/B_Scatter>`
           - ``B01_scatter_3Dxyz``, ``B02_deposit_3d_cyl``
         * - Solve or update fields
           - :doc:`D_Poisson <rst_files/D_Poisson>`, :doc:`E_Maxwell <rst_files/E_Maxwell>`
           - ``D01``-``D04`` Poisson/HYPRE solvers, ``E01``-``E03`` FDTD/CPML
         * - Exchange MPI boundaries and particles
           - :doc:`H_MPI_Exchange <rst_files/H_MPI_Exchange>`
           - ``H01_mpi_exchange_field``, ``H02_mpi_exchange_par``, ``H03_mpi_exchange_den``
         * - Output particles and fields
           - :doc:`F_IO <rst_files/F_IO>`
           - ``F02_par_output``, ``F04_field_output``

      Electrostatic PIC usually deposits charge with ``B_Scatter`` and then
      solves fields with ``D_Poisson``. Electromagnetic PIC often deposits
      current too and updates fields with ``E_Maxwell``. In MPI programs,
      ``H_MPI_Exchange`` may appear after field updates, after deposition, and
      after particles cross subdomain boundaries.

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: Calling Other Modules

         - Start with the module directory's ``README.md``.
         - Then read the related test page for run commands and output meaning.
         - More complex modules may require MPI, HYPRE, HDF5, or Python plotting packages; use the module notes as the source of truth.

      .. container:: ap-onboarding-note

         .. rubric:: Common Sticking Points

         - If ``run.sh`` cannot find ``build``, run ``./make.sh`` first.
         - If ``make.sh`` fails to compile, check that ``gfortran`` exists and run the script from the test directory.
         - If ``plot.sh`` fails, ignore it for calling AlgoPlasma and confirm that ``build/case*.dat`` exists.
         - If the include path is not found, compile from the repository root or adjust the path relative to the current build directory.
