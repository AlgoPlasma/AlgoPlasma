.. _g02-mcc-species-state-reaction:

.. rst-class:: ap-g02 ap-g02-reference

模型查询：物种、能级与反应
==================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   源码：``fortran_interface/sub_G02_mcc_model_queries.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途

   把数据文件里的名字转成 ID，或列出当前模型到底包含什么。
   ID 是标签，不保证从 0 连续排列；枚举 index 则是数组位置，**从 0 到 count−1**。
   Fortran 的这些 get 包装也沿用零起点。

   .. code-block:: fortran

      call sub_G02_mcc_species_id(context, name, species_id, status)
      call sub_G02_mcc_state_id(context, species, label, state_id, status)
      call sub_G02_mcc_species_count(context, count, status)
      call sub_G02_mcc_species_get(context, index, id, name, mass_kg, charge, representation, status)
      call sub_G02_mcc_state_count(context, count, status)
      call sub_G02_mcc_state_get(context, index, id, species, label, energy_ev, status)
      call sub_G02_mcc_reaction_count(context, count, status)
      call sub_G02_mcc_reaction_get(context, index, id, name, status)

   .. list-table:: 输入输出约定
      :header-rows: 1
      :widths: 26 15 59

      * - 参数
        - 方向
        - 类型与含义
      * - context / status
        - inout / out
        - 已加载上下文；integer(c_int) 状态码。
      * - count / index
        - out / in
        - integer(c_size_t)；条目数量与零起点序号。
      * - species_id / state_id / 物种或态 id
        - out
        - integer(c_int16_t)；用于粒子和背景字段。
      * - 反应 id
        - out
        - integer(c_int32_t)。
      * - name / label
        - 查询名称时 in；get 时 out
        - character(len=*)；输出字符串应留足长度。
      * - species
        - state_id 时 in；state_get 时 out
        - integer(c_int16_t)，内部态所属物种。
      * - mass_kg / energy_ev
        - out
        - real(c_double)，kg 或 eV。
      * - charge / representation
        - out
        - integer(c_int)；电荷数（电荷/e），表示方式 0=kinetic、1=background。

   state_id 的 label 必须与给定 species 一起查找，不能把别的物种的 ground ID 拿来使用。
   名称查询使用 256 字节内部缓冲（包含结束符）；get 的输出长度由调用者字符变量决定，
   不够长返回状态 7，扩大字符串后重试。失败时不要使用 ID 等输出。

   .. rubric:: 一个可放入初始化过程的片段

   .. code-block:: fortran

      integer(c_size_t) :: i, n
      integer(c_int16_t) :: sid
      integer(c_int) :: status, charge, representation
      real(c_double) :: mass
      character(len=256) :: name
      ! context has already been loaded.
      call sub_G02_mcc_species_count(context, n, status)
      if (status /= 0_c_int) stop 1
      do i = 0_c_size_t, n - 1_c_size_t
          call sub_G02_mcc_species_get(context, i, sid, name, mass, charge, representation, status)
          if (status /= 0_c_int) stop 2
          print *, sid, trim(name), mass
      end do

   ``fun_G02_mcc_api_version()`` 返回 integer(c_int)，当前 ABI 版本为 1；
   它检查接口版本，不返回模型数据版本。模型加载见 :doc:`sub_G02_mcc_load`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   Source: ``fortran_interface/sub_G02_mcc_model_queries.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Direct purpose

   Resolve names to IDs or inspect the loaded model.
   IDs are labels and need not be contiguous.
   Enumeration index is a position from 0 to count−1, including in the Fortran get wrappers.

   .. code-block:: fortran

      call sub_G02_mcc_species_id(context, name, species_id, status)
      call sub_G02_mcc_state_id(context, species, label, state_id, status)
      call sub_G02_mcc_species_count(context, count, status)
      call sub_G02_mcc_species_get(context, index, id, name, mass_kg, charge, representation, status)
      call sub_G02_mcc_state_count(context, count, status)
      call sub_G02_mcc_state_get(context, index, id, species, label, energy_ev, status)
      call sub_G02_mcc_reaction_count(context, count, status)
      call sub_G02_mcc_reaction_get(context, index, id, name, status)

   .. list-table:: Input/output conventions
      :header-rows: 1
      :widths: 26 15 59

      * - Argument
        - Direction
        - Type and meaning
      * - context / status
        - inout / out
        - Loaded context; integer(c_int) status.
      * - count / index
        - out / in
        - integer(c_size_t), count and zero-based position.
      * - Species/state IDs
        - out
        - integer(c_int16_t), for particle/background fields.
      * - Reaction ID
        - out
        - integer(c_int32_t).
      * - name / label
        - in for lookup; out for get
        - character(len=*); output storage must fit the name.
      * - species
        - in for state_id; out for state_get
        - integer(c_int16_t), species owning the state.
      * - mass_kg / energy_ev
        - out
        - real(c_double), kg or eV.
      * - charge / representation
        - out
        - integer(c_int), charge/e and 0=kinetic, 1=background.

   State labels are looked up within a species. Name lookups use 256-byte internal buffers including the terminator.
   Get functions use the caller's string length; status 7 requests a larger string.
   Do not consume outputs after failure.

   .. rubric:: Initialization fragment

   .. code-block:: fortran

      integer(c_size_t) :: i, n
      integer(c_int16_t) :: sid
      integer(c_int) :: status, charge, representation
      real(c_double) :: mass
      character(len=256) :: name
      ! context has already been loaded.
      call sub_G02_mcc_species_count(context, n, status)
      if (status /= 0_c_int) stop 1
      do i = 0_c_size_t, n - 1_c_size_t
          call sub_G02_mcc_species_get(context, i, sid, name, mass, charge, representation, status)
          if (status /= 0_c_int) stop 2
          print *, sid, trim(name), mass
      end do

   ``fun_G02_mcc_api_version()`` returns integer(c_int), currently ABI version 1, not a dataset version.
   See :doc:`sub_G02_mcc_load`.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_species_id(context, name, species_id, status)
   :end-before: character(kind=c_char), dimension(256), target :: cname

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_state_id(context, species, label, state_id, status)
   :end-before: character(kind=c_char), dimension(256), target :: clabel

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_species_count(context, count, status)
   :end-before: count = 0_c_size_t

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_species_get(context, index, id, name, mass_kg, charge, representation, status)
   :end-before: character(kind=c_char), allocatable :: raw(:)

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_state_count(context, count, status)
   :end-before: count = 0_c_size_t

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_state_get(context, index, id, species, label, energy_ev, status)
   :end-before: character(kind=c_char), allocatable :: raw(:)

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_reaction_count(context, count, status)
   :end-before: count = 0_c_size_t

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_reaction_get(context, index, id, name, status)
   :end-before: character(kind=c_char), allocatable :: raw(:)

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_model_queries.f90``

:doc:`Fortran API <group_fortran_interface>`
