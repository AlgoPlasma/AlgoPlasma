Particle Tracking
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_fm_trajectory.f90`` 从一个已采样的位置和速度出发，追踪到正常逃逸或中断。
   它在飞行中累加原始统计量，不在每个事件后计算密度，也不使用一个固定的全域时间步。

   .. rubric:: 1. 找到当前单元

   ``fun_J01_locate_cell(x,edge)`` 用二分搜索寻找

   .. math::

      \mathrm{edge}(j)\le x<\mathrm{edge}(j+1).

   输入为坐标与单调递增的边界数组，输出为单元号；域外返回 -1。
   共享边归高索引侧，最外侧高端点不属于任何单元。
   径向、轴向分别调用它，就得到当前 :math:`K=(i,k)`。
   该函数不检查数组单调性、不插值，也不判断单元是否有效；有效性由跟踪过程另查。

   .. rubric:: 2. 哪个面最先到达

   在单元内，粒子保持当前速度：

   .. math::

      r(t+\tau)=r(t)+v_r\tau,\qquad
      z(t+\tau)=z(t)+v_z\tau.

   下一径向碰面时间按速度符号选择：

   .. math::

      \tau_r=
      \begin{cases}
        (r_{i+1}-r)/v_r,&v_r>0,\\
        (r_i-r)/v_r,&v_r<0,\\
        +\infty,&v_r=0.
      \end{cases}

   轴向相同：

   .. math::

      \tau_z=
      \begin{cases}
        (z_{k+1}-z)/v_z,&v_z>0,\\
        (z_k-z)/v_z,&v_z<0,\\
        +\infty,&v_z=0,
      \end{cases}
      \qquad \tau=\min(\tau_r,\tau_z).

   负速度分支中距离和速度同时为负，所以有效碰面时间仍为正。
   代码用 ``huge(1.0)`` 表示不参与竞争的候选值；
   仅排除不大于零的候选时间，保留相邻两次碰面之间很短但为正的飞行段。
   若两方向都没有有效事件，则中断历史，不能当作正常逃逸。

   .. rubric:: 3. 先记当前飞行段，再处理碰面

   在离开当前单元前，累计

   .. math::

      T_K\leftarrow T_K+\tau,\qquad
      M_{r,K}\leftarrow M_{r,K}+v_r\tau,\qquad
      M_{z,K}\leftarrow M_{z,K}+v_z\tau.

   :math:`T_K` 对应 ``tally%residence``，单位为秒；
   :math:`M_{r,K},M_{z,K}` 对应 ``moment_r/moment_z``，单位为米。
   随后才把位置移到碰面点，按面类型执行下表。

   .. list-table::
      :header-rows: 1
      :widths: 20 43 37

      * - 面类型
        - 统计操作
        - 下一步
      * - 内部面
        - 正坐标穿越记 +1，反向记 −1
        - 保持速度，进入相邻单元
      * - 开放面
        - 在该单元的边界数组记录有符号逃逸
        - 正常结束历史
      * - 壁面
        - 不记净穿面次数
        - 调用反射过程，回到气体侧继续

   例如从 :math:`(i,k)` 向径向高端穿越，增加
   ``count_r(i,k)``；向径向低端穿越，减少 ``count_r(i-1,k)``。
   这两个数组位置都代表实际穿过的公共面，不是两个独立的单元出口。

   穿面次数只加减 1，不乘速度。高速粒子较短的停留由驻留时间体现，
   穿过一个面这一事实则由事件计数体现。两类统计在归一化页再转换成不同物理量。

   .. rubric:: 4. 跨面后的微小位移

   对每个确认命中的面，先将相应坐标对齐到该网格面的精确位置。
   内部穿越后，再把粒子沿穿越方向移动 :math:`\varepsilon_r` 或 :math:`\varepsilon_z`；
   壁面反射后则沿面法向移回气体侧。
   这些位移只帮助下一次定位，不增加飞行时间，也不增加驻留统计。

   主入口采用

   .. math::

      \varepsilon_r=\max(10^{-12},10^{-9}\min_i\Delta r_i)\ \mathrm m,
      \qquad
      \varepsilon_z=\max(10^{-12},10^{-9}\min_k\Delta z_k)\ \mathrm m.

   这里数值按米解释。网格尺度过小时，固定的最小位移可能不再足够小。
   独立调用底层过程时应检查位移相对于网格宽度的大小，不能把定位修正当作物理自由程。

   .. rubric:: 5. 同时碰到两个面的角点

   记当前实数类型的机器精度为 :math:`\epsilon_{\mathrm{mach}}=\operatorname{epsilon}(1.0)`，定义
   :math:`\tau_{\mathrm{tol}}=16\epsilon_{\mathrm{mach}}\tau`。
   满足 :math:`|\tau_r-\tau|\le\tau_{\mathrm{tol}}` 或
   :math:`|\tau_z-\tau|\le\tau_{\mathrm{tol}}` 的面被判为本次命中。
   只有舍入精度内的同时碰面才采用径向优先顺序：

   1. 先按当前单元的径向面处理穿越、逃逸或反射。
   2. 若穿过内部径向面，立即更新径向单元索引，再处理新单元的轴向面。
   3. 若径向面已经开放逃逸，历史结束，不再记录轴向逃逸。
   4. 若径向漫反射改变了轴向速度的正负，使它转回单元内，
      则取消原轴向穿越，并沿轴向作向内定位。
   5. 否则继续处理对应轴向面。

   两次内部穿越因此形成一条连通路径：原单元—径向邻居—对角邻居。
   中间单元没有额外驻留时间；不会从原单元同时向两个邻居各记一次流出。
   超出舍入容差的两个碰面按实际到达次序分别处理，中间飞行段照常统计驻留时间。
   每次计数都与跨面后的定位一致，因此下一轮不会再次统计同一个穿越。

   .. rubric:: 6. 主跟踪过程的输入与输出

   ``sub_J01_trace_fm_history``：

   - 输入 ``r_edge,z_edge,active,face_type``，以及已确定的壁面参数
     ``diffuse_fraction,sigma_wall``。
   - 输入正整数 ``max_events`` 和定位位移 ``eps_r,eps_z``。
     事件上限约束整个跟踪循环，不只是壁面反射次数。
   - 输入并原地更新 ``r,z,ur,uz``。
   - 输入输出 ``tally``：须预先分配清零；本过程只累加，不能在每条历史前重新清零。
   - 输出 ``escaped``：只有通过开放面结束才为真。
   - 输出 ``truncated``：事件耗尽、进入域外或无效位置、无可用下一事件等非逃逸结束均为真。

   本过程不返回整数错误码，也不区分各类中断原因。
   主入口汇总中断数量并返回跟踪错误；单独调用时必须检查两个逻辑输出。
   轨迹中没有体损失、随机散射或加速度步骤。
   新增这些物理过程时，需要重新定义最近事件和统计贡献，不能只在最终密度上乘一个修正系数。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   The tracker advances one sampled state to escape or truncation and adds raw tallies.
   Cell location uses half-open intervals edge(j)≤x<edge(j+1); out-of-domain coordinates return -1.

   For constant velocity in a cell, divide the distance to the next face in each moving direction
   by its signed velocity and choose the smallest positive arrival time.
   Zero velocities and nonpositive candidates are disabled using a large sentinel; positive short flights are retained.

   Before handling the face, add residence τ and velocity-time moments vrτ,vzτ.
   An interior crossing adds ±1 according to coordinate orientation; an open face adds a signed
   escape count and ends the history. A wall changes velocity and retains the history.
   Each hit coordinate is first snapped to its grid face; small post-event offsets add no residence time.

   Only ties within 16*epsilon(1.0)*arrival_time are resolved radially first,
   then axially in the resulting cell. Distinct nearby hits keep their arrival order and intervening residence.
   A radial escape stops immediately; a diffuse radial reflection that reverses the axial sign
   cancels the original axial crossing. Intermediate cells get zero extra residence.

   ``sub_J01_trace_fm_history`` reads validated grid/topology and wall parameters,
   updates r,z,ur,uz and tally, and returns escaped/truncated.
   max_events limits all event-loop iterations. Invalid locations, missing events and exhausted
   limits are all truncations, without distinct detailed error codes.
   ``fun_J01_locate_cell`` only locates an index; it assumes sorted edges.
