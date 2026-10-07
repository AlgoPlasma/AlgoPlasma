Installation and setup
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   AlgoPlasma 以源码组件形式提供。应用程序按需选取和编译组件，无须先安装一个统一的二进制库。
   以下命令以 Ubuntu 22.04 LTS（包括 WSL2 中的该系统）为例。

   .. rubric:: 1. 环境与源码

   安装常用编译工具；具体需要哪些工具取决于所选组件及其构建脚本：

   .. code-block:: bash

      sudo apt update
      sudo apt install git gcc gfortran cmake make

   获取源码：

   .. code-block:: bash

      git clone https://github.com/AlgoPlasma/AlgoPlasma.git algoplasma
      cd algoplasma

   如需固定版本，请使用相应的已发布标签。

   .. rubric:: 2. 按需依赖

   下列依赖并非所有组件都需要，具体以组件说明和构建脚本为准。

   .. list-table::
      :header-rows: 1
      :widths: 25 75

      * - 依赖
        - 使用范围
      * - HYPRE
        - 基于 HYPRE 的 Poisson 求解接口。
      * - MPI
        - 调用 MPI 的例程，包括部分求解、碰撞、I/O 和数据交换组件。
      * - OpenMP
        - 启用共享内存并行的计算内核；GNU 编译器使用 ``-fopenmp``。
      * - HDF5
        - 启用 HDF5 格式读写的例程。

   Python 和 NumPy、SciPy、Matplotlib 等包用于相关初始化或后处理脚本，不是所有数值组件的编译依赖。
   Sphinx、Doxygen、Breathe 等工具仅在本地构建文档时需要，参见 :doc:`开发者快速入门 <developer_quick_start>`。

   .. rubric:: 3. 最小编译测试

   从仓库根目录运行 A01 Boris 推进器测试；此测试仅需 GNU Fortran，无须安装上述四项组件依赖：

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash make.sh
      bash run.sh

   正常结束后，结果写入 ``build/case*.dat``。已有结果会被覆盖。
   构建脚本使用 ``-cpp`` 开启预处理，并以 ``-fdefault-real-8`` 选择 64 位实数。
   自行编译时，应保持调用程序、所选组件及外部接口的精度一致。

   子程序调用方式见 :doc:`使用者快速入门 <user_quick_start>`。
   完整 PIC 应用见 :doc:`双流算例 <examples/001_two_stream_2d>`；其当前构建需要 MPI、OpenMP 和 HYPRE，HDF5 已关闭。

.. container:: ap-lang ap-lang-en

   AlgoPlasma is distributed as source components. Applications select and
   compile the components they need; no single binary library must be installed
   first. The commands below target Ubuntu 22.04 LTS, including that system
   running under WSL2.

   .. rubric:: 1. Environment and source

   Install the common build tools. The tools actually required depend on the
   selected components and their build scripts:

   .. code-block:: bash

      sudo apt update
      sudo apt install git gcc gfortran cmake make

   Obtain the source:

   .. code-block:: bash

      git clone https://github.com/AlgoPlasma/AlgoPlasma.git algoplasma
      cd algoplasma

   For a fixed version, use the corresponding published tag.

   .. rubric:: 2. Component dependencies

   Not every component requires these dependencies. Consult the component
   documentation and build scripts for the specific requirements.

   .. list-table::
      :header-rows: 1
      :widths: 25 75

      * - Dependency
        - Required for
      * - HYPRE
        - HYPRE-based Poisson solver interfaces.
      * - MPI
        - Routines that invoke MPI, including selected solver, collision, I/O, and data exchange components.
      * - OpenMP
        - Computational kernels with shared-memory parallelism enabled; GNU compilers use ``-fopenmp``.
      * - HDF5
        - Routines with HDF5 input or output enabled.

   Python packages such as NumPy, SciPy, and Matplotlib support selected
   initialization or postprocessing scripts, not compilation of every numerical
   component. Sphinx, Doxygen, and Breathe are needed only to build the
   documentation locally; see :doc:`Developer Quick Start <developer_quick_start>`.

   .. rubric:: 3. Minimal build test

   From the repository root, run the A01 Boris pusher test. It requires only
   GNU Fortran, without the four component dependencies listed above:

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash make.sh
      bash run.sh

   A completed run writes ``build/case*.dat``; existing results are overwritten.
   The build script enables preprocessing with ``-cpp`` and selects 64-bit real
   arithmetic with ``-fdefault-real-8``. For custom builds, keep the precision
   consistent across the caller, selected components, and external interfaces.

   See :doc:`User Quick Start <user_quick_start>` for routine integration.
   For a complete PIC application, see the :doc:`two-stream example <examples/001_two_stream_2d>`;
   its current build requires MPI, OpenMP, and HYPRE, with HDF5 disabled.
