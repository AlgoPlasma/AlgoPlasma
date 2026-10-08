Installation and setup
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   AlgoPlasma 以源码组件形式提供。应用程序按需选取和编译组件，或导入 Python 组件，无须先安装一个统一的二进制库。
   以下命令以 Ubuntu 22.04 LTS 为例。

   .. rubric:: 1. 环境与源码

   安装常用编译工具；具体需要哪些工具取决于所选组件及其构建脚本：

   .. code-block:: bash

      sudo apt update
      sudo apt install git gcc g++ gfortran cmake make

   ``G02_MCC_network`` 需要支持 C++20 的编译器；G02 和双流算例的 CMake 构建需要 CMake 3.20 或更高版本。
   仅使用 Python 组件时可跳过编译工具安装，直接按下文建立 Python 环境。

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
        - ``D01``--``D04`` 的 Poisson 求解接口，采用 3.0 或更高版本；下文示范安装 3.1.0。
      * - MPI
        - 调用 MPI 的例程，包括部分求解、碰撞、I/O 和数据交换组件。
      * - OpenMP
        - 启用共享内存并行的计算内核；GNU 编译器在编译和链接时使用 ``-fopenmp``。
      * - HDF5
        - ``F01``/``F02`` 中启用 HDF5 的粒子读写例程，需要 HDF5 的 Fortran 接口。
      * - Python / NumPy
        - ``K_Diagnostics`` 的计算例程，以及相关初始化、分析和测试脚本。
      * - SciPy / Matplotlib
        - ``I02`` 初始化脚本、双流算例分析及相关绘图；具体脚本的依赖有所不同。
      * - ImageIO / Pillow
        - 部分 Maxwell 测试的 GIF 和动画生成。
      * - Sphinx 及其扩展
        - 本地 HTML 文档构建；Python 包见 ``docs/requirements.txt``。
      * - Doxygen / Graphviz
        - 文档接口提取及图形生成，不是数值组件的运行依赖。

   **MPI、OpenMP 和 HDF5**

   使用 MPI 时安装编译包装器、头文件和启动器；以下选择 Open MPI：

   .. code-block:: bash

      sudo apt install openmpi-bin libopenmpi-dev
      mpicc --showme
      mpifort --showme
      mpirun --version

   MPI 例程通常通过 ``mpicc``、``mpicxx`` 或 ``mpifort`` 编译。
   应用程序、HYPRE 和 MPI 启动器应使用同一 MPI 实现，避免混用 Open MPI 与 MPICH。
   GNU 编译器自带 OpenMP 支持，无须另装一个 OpenMP 开发包；是否启用由组件的构建选项决定。

   使用 HDF5 粒子读写时安装：

   .. code-block:: bash

      sudo apt install libhdf5-dev
      h5fc -show

   当前这些例程逐 MPI rank 读写独立文件，串行 HDF5 即可。
   构建时以 ``USE_HDF5=1`` 启用相应分支，并配置 Fortran 模块搜索路径和链接库；
   ``h5fc -show`` 可用于查看所需参数。非 HDF5 读写无须此依赖。

   **HYPRE**

   `Ubuntu 22.04 软件源 <https://packages.ubuntu.com/jammy/libdevel/>`_ 中的 ``libhypre-dev`` 为 2.22.1，低于本文采用的 3.x 系列。
   已有兼容安装时可跳过以下步骤；否则可从官方源码安装固定版本 3.1.0。
   在 AlgoPlasma 仓库根目录执行，源码放在相邻目录，安装到用户目录：

   .. code-block:: bash

      git clone --depth 1 --branch v3.1.0 https://github.com/hypre-space/hypre.git ../hypre-3.1.0
      (
        set -e
        cd ../hypre-3.1.0/src
        ./configure --prefix="$HOME/.local/hypre-3.1.0" \
          --enable-fortran CC=mpicc CXX=mpicxx FC=mpifort
        make -j4
        make install
      )
      export HYPRE_ROOT="$HOME/.local/hypre-3.1.0"

   此配置使用 MPI，并保留默认双精度实数和整数配置。HYPRE 自身的 OpenMP 支持为可选项，
   与应用程序中是否启用 OpenMP 是两项独立设置。
   其他配置见 `HYPRE 官方安装说明 <https://hypre.readthedocs.io/en/stable/ch-misc.html>`_。

   ``HYPRE_ROOT`` 应指向安装前缀，而不是源码或构建目录。
   双流算例在该前缀的 ``include`` 下查找头文件、在 ``lib`` 下查找库；首次配置可使用：

   .. code-block:: bash

      cmake -S examples/001_two_stream_2d -B examples/001_two_stream_2d/build \
        -DCMAKE_C_COMPILER=mpicc -DCMAKE_Fortran_COMPILER=mpifort \
        -DHYPRE_ROOT="$HYPRE_ROOT"

   新的终端会话中需重新设置 ``HYPRE_ROOT``。
   其他组件的测试脚本可能使用不同的路径变量，应按其说明设置头文件和库路径。

   **Python 计算、初始化和后处理**

   K04 使用 Python 3.10 或更高版本；随附测试要求 NumPy 1.24 或更高版本，绘图要求 Matplotlib 3.6 或更高版本。
   建议从仓库根目录创建虚拟环境，不向系统 Python 安装项目依赖：

   .. code-block:: bash

      sudo apt install python3 python3-venv python3-pip
      python3 -m venv .venv
      source .venv/bin/activate
      python -m pip install --upgrade pip
      python -m pip install "numpy>=1.24"

   K01--K04 的计算例程仅依赖 NumPy。运行初始化、分析和绘图脚本时，按需补充：

   .. code-block:: bash

      python -m pip install scipy "matplotlib>=3.6"

   ``I02`` 初始化脚本和双流算例的分析脚本需要 NumPy、SciPy 与 Matplotlib。
   生成相关 Maxwell 动画时再安装：

   .. code-block:: bash

      python -m pip install imageio pillow

   后续使用时重新运行 ``source .venv/bin/activate``；退出环境使用 ``deactivate``。
   这些 Python 包不是 Fortran/C/C++ 数值组件的统一编译依赖。

   **本地文档**

   仅在构建文档时安装系统工具和 Python 扩展；以下命令在仓库根目录、已激活的虚拟环境中执行：

   .. code-block:: bash

      sudo apt install doxygen graphviz
      python -m pip install sphinx -r docs/requirements.txt

   依赖文件包含 Read the Docs 主题、Breathe、MyST Parser、KaTeX、复制按钮扩展和 Matplotlib。
   若要重新生成含中文标签的 G02 文档图片，还可安装 ``fonts-noto-cjk``。
   文档构建与维护方式见 :doc:`开发者快速入门 <developer_quick_start>`。

   .. rubric:: 3. 最小编译测试

   从仓库根目录运行 A01 Boris 推进器测试；此测试仅需 GNU Fortran，无须 HYPRE、MPI、OpenMP、HDF5 或 Python 包：

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
   compile the components they need, or import Python components; no single
   binary library must be installed first. The commands below target Ubuntu
   22.04 LTS.

   .. rubric:: 1. Environment and source

   Install the common build tools. The tools actually required depend on the
   selected components and their build scripts:

   .. code-block:: bash

      sudo apt update
      sudo apt install git gcc g++ gfortran cmake make

   ``G02_MCC_network`` requires a C++20 compiler. The G02 and two-stream CMake
   builds require CMake 3.20 or later. For Python-only use, skip the compiler
   installation and follow the Python environment instructions below.

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
        - Poisson solver interfaces in ``D01``--``D04``, using 3.0 or later; the example below installs 3.1.0.
      * - MPI
        - Routines that invoke MPI, including selected solver, collision, I/O, and data exchange components.
      * - OpenMP
        - Kernels with shared-memory parallelism enabled; GNU compilers use ``-fopenmp`` during compilation and linking.
      * - HDF5
        - Particle I/O in ``F01``/``F02`` with HDF5 enabled; the Fortran interface is required.
      * - Python / NumPy
        - Computational routines in ``K_Diagnostics`` and selected initialization, analysis, and test scripts.
      * - SciPy / Matplotlib
        - ``I02`` initialization, two-stream analysis, and related plots; requirements vary by script.
      * - ImageIO / Pillow
        - GIF and animation generation for selected Maxwell tests.
      * - Sphinx and extensions
        - Local HTML documentation builds; Python packages are listed in ``docs/requirements.txt``.
      * - Doxygen / Graphviz
        - API extraction and documentation diagrams, not execution of numerical components.

   **MPI, OpenMP, and HDF5**

   For MPI, install the compiler wrappers, development files, and launcher.
   These commands select Open MPI:

   .. code-block:: bash

      sudo apt install openmpi-bin libopenmpi-dev
      mpicc --showme
      mpifort --showme
      mpirun --version

   MPI routines are normally compiled through ``mpicc``, ``mpicxx``, or
   ``mpifort``. Use the same MPI implementation for the application, HYPRE,
   and launcher; do not mix Open MPI and MPICH. GNU compilers provide OpenMP
   support without a separate OpenMP development package; component build
   options determine whether it is enabled.

   For HDF5 particle I/O, install:

   .. code-block:: bash

      sudo apt install libhdf5-dev
      h5fc -show

   These routines currently read and write separate files per MPI rank, so
   serial HDF5 is sufficient. Enable the relevant branch with ``USE_HDF5=1``
   and supply the Fortran module paths and link libraries; ``h5fc -show``
   reports the required flags. Non-HDF5 I/O does not require this dependency.

   **HYPRE**

   The `Ubuntu 22.04 repositories <https://packages.ubuntu.com/jammy/libdevel/>`_
   provide ``libhypre-dev`` 2.22.1, below the 3.x series used here.
   Skip the following steps if a compatible
   installation is already available; otherwise, build the fixed release
   3.1.0 from the official source. From the AlgoPlasma repository root,
   place the source in a sibling directory and install to a user directory:

   .. code-block:: bash

      git clone --depth 1 --branch v3.1.0 https://github.com/hypre-space/hypre.git ../hypre-3.1.0
      (
        set -e
        cd ../hypre-3.1.0/src
        ./configure --prefix="$HOME/.local/hypre-3.1.0" \
          --enable-fortran CC=mpicc CXX=mpicxx FC=mpifort
        make -j4
        make install
      )
      export HYPRE_ROOT="$HOME/.local/hypre-3.1.0"

   This configuration uses MPI and retains the default double precision and
   integer configuration. OpenMP within HYPRE is optional and independent of
   OpenMP in the application. See the
   `official HYPRE installation guide <https://hypre.readthedocs.io/en/stable/ch-misc.html>`_
   for other configurations.

   ``HYPRE_ROOT`` must identify the installation prefix, not the source or
   build directory. The two-stream example looks for headers under
   ``include`` and libraries under ``lib`` within that prefix. For an initial
   configuration, use:

   .. code-block:: bash

      cmake -S examples/001_two_stream_2d -B examples/001_two_stream_2d/build \
        -DCMAKE_C_COMPILER=mpicc -DCMAKE_Fortran_COMPILER=mpifort \
        -DHYPRE_ROOT="$HYPRE_ROOT"

   Set ``HYPRE_ROOT`` again in a new terminal session.
   Other component test scripts may use different path variables; configure
   their include and library paths as documented.

   **Python calculations, initialization, and postprocessing**

   K04 uses Python 3.10 or later. Its distributed test requirements specify
   NumPy 1.24 or later and Matplotlib 3.6 or later for plots.
   Create a virtual environment from the repository
   root instead of installing project packages into the system Python:

   .. code-block:: bash

      sudo apt install python3 python3-venv python3-pip
      python3 -m venv .venv
      source .venv/bin/activate
      python -m pip install --upgrade pip
      python -m pip install "numpy>=1.24"

   The K01--K04 computational routines require only NumPy. For initialization,
   analysis, and plotting scripts, add packages as needed:

   .. code-block:: bash

      python -m pip install scipy "matplotlib>=3.6"

   ``I02`` initialization and the two-stream analysis scripts require NumPy,
   SciPy, and Matplotlib. For the relevant Maxwell animations, also install:

   .. code-block:: bash

      python -m pip install imageio pillow

   In later sessions, reactivate with ``source .venv/bin/activate``; use
   ``deactivate`` to leave the environment. These Python packages are not
   universal compilation dependencies of the Fortran/C/C++ components.

   **Local documentation**

   Install these tools only when building the documentation. Run from the
   repository root with the virtual environment active:

   .. code-block:: bash

      sudo apt install doxygen graphviz
      python -m pip install sphinx -r docs/requirements.txt

   The requirements file includes the Read the Docs theme, Breathe, MyST
   Parser, KaTeX, the copy-button extension, and Matplotlib. To regenerate
   G02 documentation diagrams with Chinese labels, optionally install
   ``fonts-noto-cjk``. See
   :doc:`Developer Quick Start <developer_quick_start>` for the documentation
   build and maintenance workflow.

   .. rubric:: 3. Minimal build test

   From the repository root, run the A01 Boris pusher test. It requires only
   GNU Fortran, without HYPRE, MPI, OpenMP, HDF5, or Python packages:

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
