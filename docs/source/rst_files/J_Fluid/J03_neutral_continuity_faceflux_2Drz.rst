J03 Continuity
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   01 Transport Closure <J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>
   02 Time Advance and Diagnostics <J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>
   03 Complete Calculation <J03_neutral_continuity_faceflux_2Drz/complete_calculation>
   Error Reference <J03_neutral_continuity_faceflux_2Drz/sub_J03_error>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   J03 按物理时间推进二维柱坐标中性粒子密度。
   它接收参考密度与参考面通量，先建立面上的输运系数，
   再用当前密度计算每一步的实际通量。体源和损失频率由调用程序提供。

   .. rubric:: 本章要解决的问题

   已知网格、有效区域和物理边界，给定初始密度 :math:`n(r,z,0)`、
   体产生率 :math:`S(r,z,t)` 及线性损失频率 :math:`\nu(r,z,t)`，
   求密度怎样随时间变化：

   .. math::

      \frac{\partial n}{\partial t}
        +\frac1r\frac{\partial(r\Gamma_r)}{\partial r}
        +\frac{\partial\Gamma_z}{\partial z}=S-\nu n.

   其中 :math:`S` 的单位为 :math:`\mathrm{m^{-3}\,s^{-1}}`，
   :math:`\nu` 为 :math:`\mathrm{s^{-1}}`，面通量为 :math:`\mathrm{m^{-2}\,s^{-1}}`。
   给定密度还不足以更新这个方程，需要另行规定通量与密度的关系，称为输运闭合。

   当前闭合从参考场得到固定的面输运系数。
   内部面通量随当前迎风密度变化；开放边界将规定入流与随密度变化的出流相加；
   壁面保持零净粒子通量。参考场可以来自任意满足数组约定的计算方法，
   连续性过程不按来源改变算法。

   .. rubric:: 参考场、初始场、当前场不是同一个概念

   .. list-table::
      :header-rows: 1
      :widths: 23 41 36

      * - 数据
        - 用途
        - 何时确定或更新
      * - 参考密度与参考通量
        - 确定面输运系数
        - 初始化闭合时提供
      * - 初始密度
        - 瞬态问题的初始条件
        - 调用者决定，不要求等于参考密度
      * - 当前密度
        - 计算本时间步通量并产生下一时刻密度
        - 每个物理时间步更新
      * - 体源、损失和规定入流
        - 描述当前外部条件
        - 可在两次单步调用之间更新

   固定输运系数不意味着密度固定，也不意味着一次调用会达到稳态。
   只在研究时间无关的最终平衡时，才使用额外提供的稳态辅助过程。
   它从参考密度开始反复推进，以变化量和方程残差决定停止；
   瞬态计算则从给定初态推进到所需的物理时刻。

   .. rubric:: 页面与源码的分工

   .. list-table::
      :header-rows: 1
      :widths: 24 39 37

      * - 页面
        - 本页回答的问题
        - 对应源码
      * - 01 Transport Closure
        - 参考通量怎样变成面系数？边界数据怎样保存？
        - ``mod_J03_neutral_continuity_faceflux_2Drz.f90`` 与 ``sub_J03_transport_closure.f90``
      * - 02 Time Advance and Diagnostics
        - 当前通量、时间步、单步更新、残差和总量收支怎样计算？
        - ``sub_J03_continuity_solver.f90`` 的全部过程
      * - 03 Complete Calculation
        - 应用怎样准备参考场、组织瞬态循环并解释诊断？
        - 上述公开过程的调用顺序
      * - Error Reference
        - 返回的状态码说明什么？还能不能使用输出？
        - ``sub_J03_error.f90``

   .. rubric:: 使用范围

   J03 使用单域二维结构网格，不包含 MPI 空间通信或自动汇集过程。
   网格、面类型与面系数通常保持不变，源损项和规定入流可更新。
   若改变入口速度分布、壁面温度、几何或导致速度分布明显变化的反应条件，
   应重新评估参考场；单独更新密度并不能描述所有动力学变化。
   本模块没有能量方程、动量方程、壁面吸附或非线性反应求解器。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   J03 advances the transient r-z continuity equation using a reference-derived face closure:

   .. math::

      \partial_t n+\frac1r\partial_r(r\Gamma_r)+\partial_z\Gamma_z=S-\nu n.

   Reference fields define transport coefficients; the initial field defines the transient problem;
   the current field determines the actual flux at each step. These are distinct roles.
   Prescribed incoming flux, production and linear loss may change between steps.

   Read Transport Closure, Time Advance and Diagnostics, then Complete Calculation.
   The first page covers module data and initialization; the second covers every solver routine;
   the third assembles their application workflow. Error Reference documents return status.

   Physical-time stepping does not require steady convergence.
   An optional steady driver starts from reference density and requires both iterate change and residual convergence.
   The implementation is single-domain, with no distributed J03 solver or automatic MPI gather.
   It evolves neither momentum nor energy and does not supply reaction-rate physics.
