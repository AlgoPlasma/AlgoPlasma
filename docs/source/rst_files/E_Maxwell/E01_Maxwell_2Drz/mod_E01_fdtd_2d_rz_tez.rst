mod_E01_fdtd_2d_rz_tez.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   这个 module wrapper 通过 ``#include`` 汇入 E01 TEz 分量组的 ``Ephi`` 与
   ``Hr/Hz`` 更新核，供上层 ``use mod_E01_fdtd_2d_rz_tez`` 后直接调用。
   
   .. rubric:: 公开入口 / include 关系

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - 入口 / 文件
        - 角色
        - 关系
      * - ``sub_E01_fdtd_2d_rz_tez_H``
        - 用 ``Ephi`` 更新 ``Hr/Hz`` 的磁场入口。
        - 由 Fortran 预处理 ``#include`` 汇入 module。
      * - ``sub_E01_fdtd_2d_rz_tez_E``
        - 用 ``Hr/Hz`` 更新 ``Ephi`` 的电场入口。
        - 由 Fortran 预处理 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 模块面向 2D 轴对称 ``r-z`` Yee 场；TEz/TMz 页面分别说明各分量约定。
   - 模块本身不分配场数组、不保存全局网格参数，也不做 MPI exchange。

   .. rubric:: 实现逻辑

   - 源码中 module 的 ``contains`` 段只做 ``#include``，真正的循环和参数说明在各 ``sub_*.rst`` 页面。
   - 普通 FDTD 版本只做局部 Yee curl 更新；吸收边界、源项和并行边界在上层处理。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module，然后直接调用表中入口；该 module 不是运行时 dispatcher。
   - 编译时需要让预处理器能够找到被 ``#include`` 的源文件，CPML module 则直接编译本文件即可。


.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   This module wrapper includes the E01 TEz component group kernels for updating ``Ephi`` and ``Hr/Hz``.

   .. rubric:: Public Entries / Include Relation

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - Entry / File
        - Role
        - Relation
      * - ``sub_E01_fdtd_2d_rz_tez_H``
        - Magnetic-field entry that updates ``Hr/Hz`` from ``Ephi``.
        - Included into the module by the Fortran preprocessor.
      * - ``sub_E01_fdtd_2d_rz_tez_E``
        - Electric-field entry that updates ``Ephi`` from ``Hr/Hz``.
        - Included into the module by the Fortran preprocessor.

   .. rubric:: Local Assumptions

   - The module targets 2D axisymmetric ``r-z`` Yee fields; TEz/TMz pages define the component conventions.
   - The module itself does not allocate field arrays, store global mesh parameters, or perform MPI exchange.

   .. rubric:: Implementation Notes

   - The module ``contains`` section only uses ``#include``; the actual loops and parameter details live on the dedicated ``sub_*.rst`` pages.
   - The regular FDTD variants perform only local Yee curl updates; absorbing boundaries, sources, and parallel boundaries are handled above this layer.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly; the module is not a runtime dispatcher.
   - Compilation must make the ``#include`` source files visible to the preprocessor; CPML modules are compiled directly as module files.

   .. rubric:: Generated API

   .. doxygenfile:: mod_E01_fdtd_2d_rz_tez.f90
