Cartesian Step
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_continuity_freeflow.f90`` 保留原三维笛卡尔连续性单步接口。
   它输入节点存储的密度、给定速度和本步扣减量，先生成数值面通量，
   再原地更新密度。此过程不追踪粒子、不建立参考场，也不返回内部通量数组。

   .. rubric:: 1. 数组索引与更新范围

   输入整数向量 ``il(1:3),iu(1:3)``。
   六个实数数组 ``n,s,ux,uy,uz,n0`` 的每个方向声明范围都是

   .. math::

      \mathrm{il}(d)-2:\mathrm{iu}(d)+1,\qquad d=1,2,3.

   实际更新区间是
   ``i=il(1)-1:iu(1)``、``j=il(2)-1:iu(2)``、
   ``k=il(3)-1:iu(3)``。
   最外一层用于相邻取值，由调用者在进入过程前设置边界和保护层。

   ``n0=n`` 先保存整个旧数组，包括保护层。
   后面的三个方向都读取这份旧场，因此不是先更新 x、再用新密度更新 y 的分裂推进。

   .. rubric:: 2. 相邻节点之间的数值通量

   对于一个方向上的相邻位置 L、R，使用局部 Lax–Friedrichs（LF）通量：

   .. math::

      F_{L/R}=\frac{u_Ln_L^0+u_Rn_R^0}{2}
           -\frac{\alpha_{L/R}}{2}(n_R^0-n_L^0),
      \qquad \alpha_{L/R}=\max(|u_L|,|u_R|).

   第一项是两侧物理通量的平均，第二项是与密度跳跃有关的数值耗散。
   当 :math:`u_L=u_R=u` 时，

   .. math::

      F_{L/R}=
      \begin{cases}u n_L^0,&u\ge0,\\u n_R^0,&u<0.\end{cases}

   因此常速度下退化为迎风通量。三个方向分别使用 ``ux,uy,uz``。

   .. list-table::
      :header-rows: 1
      :widths: 17 40 43

      * - 工作数组
        - 含义
        - 索引范围
      * - ``Fx(i,j,k)``
        - :math:`i` 与 :math:`i+1` 之间的 x 向通量
        - x 为 ``il-2:iu``，其余为 ``il-1:iu``
      * - ``Fy(i,j,k)``
        - :math:`j` 与 :math:`j+1` 之间的 y 向通量
        - y 为 ``il-2:iu``，其余为 ``il-1:iu``
      * - ``Fz(i,j,k)``
        - :math:`k` 与 :math:`k+1` 之间的 z 向通量
        - z 为 ``il-2:iu``，其余为 ``il-1:iu``

   这些是过程内部临时数组，调用者不会接收到它们。

   .. rubric:: 3. 一次更新与源项符号

   代码将三个方向的通量差同时从旧密度扣除：

   .. math::

      \begin{aligned}
      n_{i,j,k}^{\mathrm{new}}={}&n_{i,j,k}^0
         -[F^x_{i,j,k}-F^x_{i-1,j,k}]\\
         &-[F^y_{i,j,k}-F^y_{i,j-1,k}]
          -[F^z_{i,j,k}-F^z_{i,j,k-1}]
          -s_{i,j,k}.
      \end{aligned}

   当前约定是 :math:`\Delta t=\Delta x=\Delta y=\Delta z=1`，
   没有另外传入物理时间步或网格宽度。
   输入速度和扣减量必须已经满足这一归一化约定，不能直接将任意 SI 速度传入。

   ``s`` 是本次更新的密度扣减量，正值减少密度；
   它不是二维接口中正值增加粒子的每秒体产生率。
   没有输运时，结果就是 :math:`n^{\mathrm{new}}=n^0-s`。

   .. rubric:: 4. 每个参数的输入输出

   .. list-table::
      :header-rows: 1
      :widths: 22 19 59

      * - 参数
        - 方向
        - 含义
      * - ``il,iu``
        - 输入
        - 三个方向的参考上下索引，决定上述声明和循环范围
      * - ``n``
        - 输入输出
        - 旧密度进入，更新区域被新密度覆盖，其余位置不改
      * - ``s``
        - 输入
        - 与密度同布局、同单位的本步扣减量
      * - ``ux,uy,uz``
        - 输入
        - 同布局的三个归一化速度分量，本次调用内固定
      * - ``n0``
        - 工作输出
        - 接收整块旧密度副本，调用者须提供存储空间

   本过程没有 ``ierr``、数组分配、边界更新或负值修复。
   调用者负责索引、保护层、输入尺度及稳定性。

   .. rubric:: 5. 稳定性与重复调用

   对恒定速度、无扣减项，常用充分条件是

   .. math::

      |u_x|+|u_y|+|u_z|\le1.

   不能只分别检查每个方向小于一。
   变速度需要结合局部面耗散系数检查具体更新；
   过大的扣减量即使在稳定步长下也可能使密度为负。

   下一次调用前，应用需要更新边界/保护层，以及需要变化的速度和扣减量。
   过程本身只执行一次更新，不判断稳态，也不推进调用者的物理时钟。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   The retained Cartesian routine forms local Lax–Friedrichs fluxes from old node-stored density
   and prescribed velocities, then overwrites density in place.

   All six real arrays use il(d)-2:iu(d)+1. The updated region is il(d)-1:iu(d),
   not simply il:iu. The caller fills guards. n0 receives the entire old density;
   all three flux directions use it before the unsplit update.

   .. math::

      F_{L/R}=\tfrac12(u_Ln_L+u_Rn_R)
              -\tfrac12\max(|u_L|,|u_R|)(n_R-n_L).

   Fx/Fy/Fz stagger across the corresponding adjacent nodes and remain internal work arrays.
   The update subtracts the three high-minus-low differences and s.
   The normalization is dt=dx=dy=dz=1: s is a per-step density decrement, not a positive physical source rate.

   Inputs are il,iu,s,ux,uy,uz; n is inout and n0 stores the previous field.
   There is no ierr, allocation, boundary update or positivity repair.
   For constant velocity without decrement, :math:`|u_x|+|u_y|+|u_z|\le 1` is sufficient;
   variable velocities and removal require additional local checks.
