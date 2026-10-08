J01 Complete FM Solve
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 从局部过程到完整调用

   这一层直接调用 ``sub_J01_free_molecular_mc_2Drz``。
   入口准备、随机初值、自由飞行、壁面反射和统计归一化由正式程序依次完成。
   测试给定简单通道，使注入和出射的总粒子率可以独立核对。

   .. rubric:: 1. 单单元镜面通道

   测试为 ``test_J01_faceflux_2Drz_units.f90`` 中的
   ``test_free_molecular_single_cell``。
   计算区域 :math:`1\le r\le2,\ 0\le z\le1`，径向两面为镜面壁，轴向两端开放。
   入口位于轴向低端，固定种子 17，运行 200 条粒子历史。

   主入口完成以下步骤：

   1. 根据入口面积和速度分布确定每条历史的粒子率 :math:`q`。
   2. 抽样粒子位置与正轴向速度。
   3. 跟踪自由飞行；径向碰壁时翻转径向速度，轴向速度保持。
   4. 累加单元驻留时间和出口穿越次数。
   5. 返回密度、均速、面通量及完成/截断数。

   由于轴向速度始终为正，每条完整历史都应从高端离开一次。
   因此高端出口面积 :math:`A_{\rm out}` 与输出通量应满足

   .. math::

      A_{\rm out}\Gamma_{\rm out}=200q.

   测试检查返回成功、完成数 200、截断数零，
   并以 :math:`10^{-12}\max(1,200q)` 核对总粒子率。
   单元密度与轴向均速还必须为正。
   这一组断言同时连接了注入权重、轨迹完成判定和出口统计归一化。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 完成/截断历史数
        - 200 / 0
        - 200 / 0
        - 0
        - 精确相等
      * - 出口粒子率 AΓ
        - 9
        - 200q = 9
        - 0
        - 9e−12
      * - 密度
        - 2.999999997
        - 正值
        - —
        - n > 0
      * - 轴向均速
        - 2
        - 正值
        - —
        - u_z > 0

   每条历史粒子率为 0.045。密度和均速在本项只作正值检查，未把它们当作解析精度验证。

   .. rubric:: 2. 历史截断的返回状态

   测试为 ``test_J01_fm_units.f90`` 中的 ``test_driver_errors``。
   使用轴向两单元区域，只有低端入口开放，其余外边界反射；
   从入口注入 20 条历史，每条最多处理一个事件。

   初速度朝正轴向。粒子需要经历穿面或反射后才能返回低端出口，
   所以一个事件不足以完成这些历史。预期结果为

   .. math::

      N_{\rm completed}=0,\qquad N_{\rm truncated}=20.

   返回码必须为 ``J01_ERR_PARTICLE_TRACKING``。
   这使调用端能够根据状态区分完整统计与被事件上限中断的计算。

   随后把域外侧的径向低端面误标为内部面，重新调用主入口。
   由于该面没有相邻单元，程序应在跟踪前返回
   ``J01_ERR_CONFIGURATION``，完成数仍为零。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 输入
        - 实际返回码 / 完成数 / 截断数
        - 预期值
      * - 事件上限
        - 106 / 0 / 20
        - 106 / 0 / 20
      * - 非法内部面
        - 105 / 0
        - 105 / 0

   .. rubric:: 文件、执行与结果

   上述两个测试文件均位于
   ``tests/012_fluid/J01_free_molecular/source_f90``。
   主入口实现为 ``J_Fluid/J01_free_molecular/sub_J01_free_molecular_mc_2Drz.f90``。

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   在 ``build/test_J01_faceflux_2Drz_units.log`` 中检查完成数和粒子率断言；
   在 ``build/test_J01_fm_units.log`` 中检查截断及错误拓扑断言。
   两组在 2026-10-06 通过。J01 结果接入连续性方程的检查位于 J03 分组的串联测试。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Complete-driver test

   ``test_free_molecular_single_cell`` in ``test_J01_faceflux_2Drz_units.f90``
   calls ``sub_J01_free_molecular_mc_2Drz`` on r=[1,2], z=[0,1],
   with specular radial walls and open axial ends. It runs 200 histories with seed 17.
   The driver prepares the inlet, samples each particle, tracks flight and reflection,
   then normalizes residence and exit counts.

   Specular radial walls preserve positive axial velocity, so each history escapes
   once through the upper end. The assertions require success, 200 completed histories,
   zero truncations, positive density/axial velocity and

   .. math::

      |A_{\rm out}\Gamma_{\rm out}-200q|
          <10^{-12}\max(1,200q).

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Completed / truncated
        - 200 / 0
        - 200 / 0
        - 0
        - exact equality
      * - Outlet rate
        - 9
        - 200q = 9
        - 0
        - 9e−12
      * - Density
        - 2.999999997
        - Positive
        - —
        - n > 0
      * - Axial velocity
        - 2
        - Positive
        - —
        - u_z > 0

   .. rubric:: Failure reporting

   ``test_driver_errors`` in ``test_J01_fm_units.f90`` uses two axial cells,
   only the lower open boundary, and an event limit of one.
   All 20 histories must be truncated, with no completions and
   ``J01_ERR_PARTICLE_TRACKING``.
   Marking a domain edge as interior must instead return ``J01_ERR_CONFIGURATION``.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Input
        - Actual code / completed / truncated
        - Expected
      * - Event limit
        - 106 / 0 / 20
        - 106 / 0 / 20
      * - Invalid face
        - 105 / 0
        - 105 / 0

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   Both checks passed on 2026-10-06. Logs are
   ``build/test_J01_faceflux_2Drz_units.log`` and ``build/test_J01_fm_units.log``.
