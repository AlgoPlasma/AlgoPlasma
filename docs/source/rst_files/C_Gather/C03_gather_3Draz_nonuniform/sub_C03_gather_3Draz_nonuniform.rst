sub_C03_gather_3Draz_nonuniform.f90
-----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 子程序说明

   ``sub_C03_gather_3Draz_nonuniform`` 为已经使用粒子数组的程序提供调用入口。
   ``par`` 每一列对应一个粒子，``p`` 指定当前处理哪一列，``np`` 是粒子总数。
   本例程只取该列前三个数作为位置，然后让单点接口完成场插值。
   这样调用者可以直接传入现有粒子数组，无需自行复制一个位置向量。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform( &
          p,np,par,il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1

      * - 参数
        - 方向
        - 类型 / 范围
        - 含义
      * - ``p,np``
        - in
        - integer
        - 粒子编号 ``1<=p<=np`` 与粒子总数。
      * - ``par``
        - in
        - real(1:6,1:np)
        - 仅读取 ``par(1:3,p)=(r,alpha,z)``；其余分量不修改。
      * - ``il,iu``
        - in
        - integer(3)
        - 各轴 owned 单元闭区间。
      * - ``r_face,a_face,z_face``
        - in
        - real(il(d)-1:iu(d))
        - 径向、角向、轴向单元面坐标；单位 m/rad/m。
      * - ``dr,da,dz``
        - in
        - real(il(d)-1:iu(d)+1)
        - 单元宽度，含两端各一层 ghost，单位 m/rad/m。
      * - ``Er,Ea,Ez,Br,Ba,Bz``
        - in
        - real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)
        - 统一存储范围，物理采样位置依各分量交错布局而定。
      * - ``E,B``
        - out
        - real(3)
        - 粒子处柱坐标场分量；单位与输入场相同。
      * - ``cell``
        - in, optional
        - integer(3)
        - 当前 owned 单元缓存；只读，失效时 error stop，不自动更新。
      * - ``a_period``
        - in, optional
        - real scalar
        - 正角向周期，单位 rad；省略则不归约角度。
      * - ``a_origin``
        - in, optional
        - real scalar
        - 周期起点，单位 rad，默认 0；仅与 a_period 同时使用。

   .. rubric:: 代码怎样执行

   .. code-block:: fortran

      if (p < 1 .or. p > np) error stop 'C03: invalid particle index'

   这句防止读取不存在的粒子列。通过检查后，程序执行：

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform_point( &
          par(1:3,p),il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   ``par(1:3,p)`` 是 Fortran 数组切片，表示第 p 列的第 1 至第 3 行。
   它们按顺序保存 r、alpha、z，单位是 m、rad、m。其余参数继续传给 point，
   point 将计算结果写入 ``E,B``，本例程即可返回。这里没有遍历所有粒子的循环，一次只处理一个粒子。

   .. rubric:: 调用注意

   ``cell``、``a_period``、``a_origin`` 是可选实参，不需要时可省略。
   本例程不改写 ``par`` 或网格场；``E,B`` 是这次调用的输出。
   电场采用 ``(face,center,center)/(center,face,center)/(center,center,face)`` 布局，
   磁场采用 ``(face,face,face)``。插值计算与边界要求见 :doc:`sub_C03_gather_3Draz_nonuniform_point`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Subroutine Description

   ``sub_C03_gather_3Draz_nonuniform`` is the entry for programs that store particles
   in an array. Each column of par holds one particle; p selects the column and np
   is the particle count. This routine reads its first three entries as position
   and delegates interpolation to the point routine, so callers can pass their
   existing particle array without making a separate position vector.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform( &
          p,np,par,il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1

      * - Parameter
        - Direction
        - Type / Range
        - Meaning
      * - ``p,np``
        - in
        - integer
        - Particle index (1<=p<=np) and particle count.
      * - ``par``
        - in
        - real(1:6,1:np)
        - Only par(1:3,p)=(r,alpha,z) is read; no particle data is modified.
      * - ``il,iu``
        - in
        - integer(3)
        - Inclusive owned-cell bounds in each axis.
      * - ``r_face,a_face,z_face``
        - in
        - real(il(d)-1:iu(d))
        - Radial/angular/axial face coordinates in m/rad/m.
      * - ``dr,da,dz``
        - in
        - real(il(d)-1:iu(d)+1)
        - Cell widths including one ghost at each end, in m/rad/m.
      * - ``Er,Ea,Ez,Br,Ba,Bz``
        - in
        - real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)
        - Common storage envelope; physical sample locations depend on staggering.
      * - ``E,B``
        - out
        - real(3)
        - Cylindrical field components at the particle, in input field units.
      * - ``cell``
        - in, optional
        - integer(3)
        - Read-only cached owned cell; stale values cause error stop, not a cache update.
      * - ``a_period``
        - in, optional
        - real scalar
        - Positive angular period in rad; no wrapping if omitted.
      * - ``a_origin``
        - in, optional
        - real scalar
        - Period origin in rad, default 0; requires a_period.

   .. rubric:: How the Code Runs

   .. code-block:: fortran

      if (p < 1 .or. p > np) error stop 'C03: invalid particle index'

   This prevents access to a nonexistent particle column. After this check:

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform_point( &
          par(1:3,p),il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   ``par(1:3,p)`` is a Fortran array slice selecting rows 1 through 3 in column p.
   They hold r, alpha, z in m, rad, m. Other arguments are forwarded to point, which
   writes the results into E and B. There is no loop over particles here: one call
   handles one particle.

   .. rubric:: Calling Notes

   ``cell``, ``a_period``, and ``a_origin`` are optional. Particle and grid-field
   arrays are not modified; E and B are the outputs. Electric components use
   ``(face,center,center)/(center,face,center)/(center,center,face)`` and all B
   components use ``(face,face,face)``. See :doc:`sub_C03_gather_3Draz_nonuniform_point`
   for interpolation and boundary requirements.

   .. rubric:: Generated API

   .. doxygenfile:: sub_C03_gather_3Draz_nonuniform.f90
