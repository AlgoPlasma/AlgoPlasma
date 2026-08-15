mod_E01_cpml_2d_rz_tmz.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   这个模块提供 E01 TMz 分量组的 CPML 版本 ``Er/Ez`` 与 ``Ha/Hphi`` 更新例程。
   
   .. rubric:: 公开入口 / include 关系

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - 入口 / 文件
        - 角色
        - 关系
      * - ``sub_E01_cpml_2d_rz_tmz_E``
        - 用 ``Ha/Hphi`` 更新 ``Er/Ez`` 的 CPML 电场入口。
        - 在本 module 文件的 ``contains`` 段中定义。
      * - ``sub_E01_cpml_2d_rz_tmz_H``
        - 用 ``Er/Ez`` 更新 ``Ha/Hphi`` 的 CPML 磁场入口。
        - 在本 module 文件的 ``contains`` 段中定义。

   .. rubric:: 局部假设

   - 模块面向 2D 轴对称 ``r-z`` Yee 场；TEz/TMz 页面分别说明各分量约定。
   - CPML memory variables 必须跨时间步保存，不能每次调用前重新清零，除非正在重新初始化吸收层。
   - 模块本身不分配场数组、不保存全局网格参数，也不做 MPI exchange。

   .. rubric:: 实现逻辑

   - 源码中在 module 的 ``contains`` 段直接定义 CPML 更新例程，参数较多，因此本页把它们作为 module 内公开入口说明。
   - CPML 版本在普通 curl 差分外增加 ``psi = b*psi + a*d`` 形式的 memory update，并用 ``k`` 系数缩放相应方向导数。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module，然后直接调用表中入口；该 module 不是运行时 dispatcher。
   - 编译时需要让预处理器能够找到被 ``#include`` 的源文件，CPML module 则直接编译本文件即可。


.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   This module provides CPML update routines for the E01 TMz component group,
   namely the ``Er/Ez`` electric update and the ``Ha/Hphi`` magnetic update.

   .. rubric:: Public Entries / Include Relation

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - Entry / File
        - Role
        - Relation
      * - ``sub_E01_cpml_2d_rz_tmz_E``
        - CPML electric-field entry that updates ``Er/Ez`` from ``Ha/Hphi``.
        - Defined in the ``contains`` section of this module file.
      * - ``sub_E01_cpml_2d_rz_tmz_H``
        - CPML magnetic-field entry that updates ``Ha/Hphi`` from ``Er/Ez``.
        - Defined in the ``contains`` section of this module file.

   .. rubric:: Local Assumptions

   - The module targets 2D axisymmetric ``r-z`` Yee fields; TEz/TMz pages define the component conventions.
   - CPML memory variables must persist across time steps and should not be reset before each call unless the absorbing layer is being reinitialized.
   - The module itself does not allocate field arrays, store global mesh parameters, or perform MPI exchange.

   .. rubric:: Implementation Notes

   - The module defines CPML update routines directly in its ``contains`` section, so this page treats them as public module entries.
   - The CPML variants add ``psi = b*psi + a*d`` memory updates to the curl differences and scale the directional derivatives by the corresponding ``k`` coefficients.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly; the module is not a runtime dispatcher.
   - Compilation must make the ``#include`` source files visible to the preprocessor; CPML modules are compiled directly as module files.

   .. rubric:: Generated API

   .. doxygenfile:: mod_E01_cpml_2d_rz_tmz.f90
