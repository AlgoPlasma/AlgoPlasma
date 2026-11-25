Transport Closure
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J03_transport_closure.f90`` 由参考密度与参考通量建立面输运系数。
   本页只完成初始化，不推进时间。
   数据类型 ``neutral_transport_closure_2drz_type`` 定义在模块文件中，
   用一个 ``closure`` 对象保存几何、参考场、面系数及规定入流与损失频率。

   .. rubric:: 1. 从已知参考通量提出当前通量关系

   考虑两个相邻单元 L、R 之间的一个内部面，正方向从 L 指向 R。
   给定参考通量 :math:`\Gamma_f^{\mathrm{ref}}`，
   先按它的符号确定上游参考单元：

   .. math::

      n_{\mathrm{up}}^{\mathrm{ref}}=
      \begin{cases}
         n_L^{\mathrm{ref}},&\Gamma_f^{\mathrm{ref}}\ge0,\\
         n_R^{\mathrm{ref}},&\Gamma_f^{\mathrm{ref}}<0.
      \end{cases}

   假设后续输运方向及“单位上游密度造成的通量”保持不变，
   定义系数 :math:`u_f` 并使用

   .. math::

      u_f=\frac{\Gamma_f^{\mathrm{ref}}}{n_{\mathrm{up}}^{\mathrm{ref}}},
      \qquad \Gamma_f(n)=u_f n_{\mathrm{up}}.

   后一式就是本模块采用的闭合假设，不是由连续性方程单独推导出的唯一关系。
   :math:`u_f` 的单位为 m/s，源码字段因而命名为 ``velocity_*_face``；
   但它不等于参考场的单元平均粒子速度。J03 初始化不接收单元平均速度数组。

   .. figure:: /_static/J_Fluid/continuity_closure.svg
      :alt: 正负参考通量分别选左侧或右侧密度，固定系数乘当前密度得到变化的面通量
      :width: 900px

      面系数不变时，当前通量仍随当前上游密度变化。

   对径向面，L、R 分别是 :math:`(i,k)` 和 :math:`(i+1,k)`；
   对轴向面，分别是 :math:`(i,k)` 和 :math:`(i,k+1)`。
   系数与参考通量同号，后续可直接按 :math:`u_f` 的符号选择当前迎风密度。

   .. rubric:: 2. 参考密度过小时的下限

   实际代码不直接除以可能为零的参考密度。
   记正参数 ``density_floor_fraction`` 为 :math:`\varepsilon_{\mathrm f}`，取

   .. math::

      n_{\max}^{\mathrm{ref}}
         =\max_{K\ \mathrm{active}}|n_K^{\mathrm{ref}}|,\qquad
      n_{\mathrm{floor}}
         =\max(\varepsilon_{\mathrm f}n_{\max}^{\mathrm{ref}},
               \operatorname{tiny}(1.0)),

   .. math::

      u_f=\frac{\Gamma_f^{\mathrm{ref}}}
                {\max(n_{\mathrm{up}}^{\mathrm{ref}},n_{\mathrm{floor}})}.

   :math:`\operatorname{tiny}(1.0)` 是当前实数类型的最小正常正数，
   这里只是数值除法的保护量，不是另一个物理密度模型。
   代码要求 :math:`\varepsilon_{\mathrm f}>0`，但不自动检查这个选择是否过大。

   当下限未生效时，代入参考密度可重现参考通量。
   下限生效时则有

   .. math::

      \Gamma_f(n^{\mathrm{ref}})
         =\Gamma_f^{\mathrm{ref}}
           \frac{n_{\mathrm{up}}^{\mathrm{ref}}}
                {\max(n_{\mathrm{up}}^{\mathrm{ref}},n_{\mathrm{floor}})}.

   下限生效时，重构通量的幅值减小，参考场不一定保持原有的离散平衡。
   下限也不是负参考密度的修复方法；有限性和非负性须由调用程序检查。

   .. rubric:: 3. 开放边界必须分开保存入射与出射

   设边界属于单元 K。规定入射通量记为 :math:`\Gamma_{b,\mathrm{in}}`，
   参考出射通量为 :math:`\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}`。
   出射系数与当前净通量是

   .. math::

      u_{b,\mathrm{out}}
         =\frac{\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}}
                {\max(n_K^{\mathrm{ref}},n_{\mathrm{floor}})},\qquad
      \Gamma_b(n)=\Gamma_{b,\mathrm{in}}+u_{b,\mathrm{out}}n_K.

   规定入射不乘当前密度；出射随边界单元密度变化。
   两项都采用坐标方向符号。记外法向符号
   :math:`s_f=(-1,+1,-1,+1)`，有效物理数据应满足

   .. math::

      s_f\Gamma_{b,\mathrm{in}}\le0,\qquad
      s_f\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}\ge0.

   例如下端入口的入射为正，反向逃逸为负。
   若只提供一个净通量，就无法分别知道哪些粒子由外部供应、哪些随域内密度流出，
   也就不能建立上述边界关系。

   壁面在时间推进中固定零净通量，不使用边界出射系数。
   同一开放面即使包含只在局部注入的区域，输入仍按完整面面积平均；
   本模块不会另算开口面积比例。

   .. rubric:: 4. 初始化过程的完整输入

   ``sub_J03_initialize_transport_closure`` 接收下表全部输入。

   .. list-table::
      :header-rows: 1
      :widths: 33 25 42

      * - 参数
        - 形状与单位
        - 使用方式
      * - ``active``
        - ``(nr,nz)``，逻辑
        - 标出参与计算的单元，至少一个为真
      * - ``face_type``
        - ``(4,nr,nz)``，整数
        - 内部面 0、开放面 1、壁面 2
      * - ``volume``
        - ``(nr,nz)``，m³
        - 有效单元体积须为正
      * - ``face_area``
        - ``(4,nr,nz)``，m²
        - 非负面积，内部面两侧须为相同正值
      * - ``density_ref``
        - ``(nr,nz)``，m⁻³
        - 选择迎风参考密度、确定下限
      * - ``flux_r_ref``
        - ``(nr-1,nz)``，m⁻²s⁻¹
        - 建立径向内部面系数
      * - ``flux_z_ref``
        - ``(nr,nz-1)``，m⁻²s⁻¹
        - 建立轴向内部面系数
      * - ``boundary_inflow_flux``
        - ``(4,nr,nz)``，m⁻²s⁻¹
        - 直接保存规定入流
      * - ``boundary_outflow_flux_ref``
        - ``(4,nr,nz)``，m⁻²s⁻¹
        - 在开放面建立出射系数
      * - ``loss_frequency``
        - ``(nr,nz)``，s⁻¹
        - 保存非负线性损失频率，不是单位路程损失
      * - ``density_floor_fraction``
        - 无量纲正标量
        - 相对于有效区域最大参考密度的下限比例

   输出为 ``closure`` 和 ``ierr``。输入数组被复制到对象中，
   之后修改调用端的原数组不会自动修改已经建立的闭合。
   其中也不保存 ``source_rate``：体产生率由每次单步调用单独传入。

   .. rubric:: 5. closure 中哪些数据固定，哪些允许逐步改变

   .. list-table::
      :header-rows: 1
      :widths: 32 37 31

      * - 字段
        - 含义
        - 后续使用
      * - ``nr,nz,active,face_type,volume,face_area``
        - 几何与拓扑
        - 每次散度与时间步计算都读取
      * - ``density_ref,flux_r_ref,flux_z_ref,boundary_outflow_flux_ref``
        - 初始化参考场的副本
        - 参考数据、稳态初值与尺度
      * - ``velocity_r_face,velocity_z_face,boundary_outflow_velocity``
        - 本页推导的固定面系数
        - 乘当前密度生成当前通量
      * - ``boundary_inflow_flux``
        - 规定入射通量
        - 可在单步调用前更新
      * - ``loss_frequency``
        - 当前给定的线性损失频率
        - 可更新，更新后重新选择时间步

   仅修改 ``density_ref`` 或 ``flux_*_ref`` 不会重新计算面系数。
   需要更换参考场时，应重新初始化整个对象，避免旧系数与新参考数据混用。

   .. rubric:: 6. 初始化实际检查什么

   代码检查尺寸、损失非负、有效区域非空、体积和面积、合法面类型，
   以及每个内部面的邻居存在、有效且反向也标为内部面。
   公共面面积差需满足

   .. math::

      |A_L-A_R|
        \le100\,\operatorname{epsilon}(1.0)\max(A_L,A_R).

   轴线外边界允许零面积；内部面必须具有正面积。
   这些检查是后续内部面粒子率抵消的前提。

   初始化没有全面检查参考场有限性、参考密度非负性和边界入射/出射符号。
   这些是调用者的输入责任，返回成功不能替代物理验收。
   非内部或未使用的数组位置应填写零，以免后续诊断或适配时误用。

   .. rubric:: 7. 与前处理无关的统一入口

   所有参考场都调用 ``sub_J03_initialize_transport_closure``。
   该过程只接收密度、通量和几何数组，不读取文件、不执行前处理，
   也不需要链接前处理模块。新增前处理方法只需满足同一组输入约定。

   模块以 ``contains`` 下包含文件的方式组织源码；
   只编译 ``mod_J03_neutral_continuity_faceflux_2Drz.f90`` 并启用预处理。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J03_transport_closure.f90`` initializes face transport coefficients from reference density and
   flux. No time step is taken here. The module defines ``neutral_transport_closure_2drz_type``; a
   ``closure`` object holds the geometry, reference fields, coefficients, prescribed inflow and loss
   frequency.

   .. rubric:: 1. Deriving a current-flux relation from reference flux

   Consider an internal face between cells L and R, oriented from L to R. The sign of reference flux
   :math:`\Gamma_f^{\mathrm{ref}}` determines the upwind reference cell:

   .. math::

      n_{\mathrm{up}}^{\mathrm{ref}}=
      \begin{cases}
         n_L^{\mathrm{ref}},&\Gamma_f^{\mathrm{ref}}\ge0,\\
         n_R^{\mathrm{ref}},&\Gamma_f^{\mathrm{ref}}<0.
      \end{cases}

   Assume the direction of transport and flux per unit upwind density remain fixed. Define :math:`u_f` and use

   .. math::

      u_f=\frac{\Gamma_f^{\mathrm{ref}}}{n_{\mathrm{up}}^{\mathrm{ref}}},
      \qquad \Gamma_f(n)=u_f n_{\mathrm{up}}.

   The second relation is the closure assumed by this module. The continuity equation does not determine a
   unique flux-density relation. :math:`u_f` has units of m/s, hence the name ``velocity_*_face``. It
   differs from the cell-averaged particle velocity; initialization takes no array of mean velocities.

   .. figure:: ../../../images/J_Fluid/continuity_closure_en.svg
      :alt: The sign of reference flux selects the left or right density. The fixed coefficient multiplies the current upwind density to give the evolving face flux.
      :width: 900px

      A fixed coefficient still allows the flux to change as upstream density evolves.

   For a radial face, L and R are :math:`(i,k)` and :math:`(i+1,k)`; for an axial face, they are
   :math:`(i,k)` and :math:`(i,k+1)`. The coefficient has the sign of the reference flux, so :math:`u_f`
   also selects the current upwind density.

   .. rubric:: 2. A floor for small reference densities

   The code guards division by a small or zero reference density. Write the positive parameter
   ``density_floor_fraction`` as :math:`\varepsilon_{\mathrm f}` and set

   .. math::

      n_{\max}^{\mathrm{ref}}
         =\max_{K\ \mathrm{active}}|n_K^{\mathrm{ref}}|,\qquad
      n_{\mathrm{floor}}
         =\max(\varepsilon_{\mathrm f}n_{\max}^{\mathrm{ref}},
               \operatorname{tiny}(1.0)),

   .. math::

      u_f=\frac{\Gamma_f^{\mathrm{ref}}}
                {\max(n_{\mathrm{up}}^{\mathrm{ref}},n_{\mathrm{floor}})}.

   :math:`\operatorname{tiny}(1.0)` is the smallest positive normal number of the working real type. Here
   it only protects the division. The code checks :math:`\varepsilon_{\mathrm f}>0`; the caller must judge
   whether the chosen fraction is too large.

   When the floor is inactive, inserting reference density reproduces the reference flux. When the floor is
   active,

   .. math::

      \Gamma_f(n^{\mathrm{ref}})
         =\Gamma_f^{\mathrm{ref}}
           \frac{n_{\mathrm{up}}^{\mathrm{ref}}}
                {\max(n_{\mathrm{up}}^{\mathrm{ref}},n_{\mathrm{floor}})}.

   The floor reduces the magnitude of the reconstructed flux and can change the discrete balance of the
   reference field. It cannot repair negative or nonfinite reference densities, which the caller should
   detect.

   .. rubric:: 3. Keeping incoming and outgoing flux separate at open boundaries

   For a boundary face of cell K let :math:`\Gamma_{b,\mathrm{in}}` denote prescribed incoming flux and
   :math:`\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}` reference outgoing flux. The outgoing coefficient and
   current net flux are

   .. math::

      u_{b,\mathrm{out}}
         =\frac{\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}}
                {\max(n_K^{\mathrm{ref}},n_{\mathrm{floor}})},\qquad
      \Gamma_b(n)=\Gamma_{b,\mathrm{in}}+u_{b,\mathrm{out}}n_K.

   Prescribed inflow is independent of the current density, while outflow varies with the boundary cell
   density. Both use coordinate-direction signs. With outward-normal signs :math:`s_f=(-1,+1,-1,+1)`,
   physically consistent data satisfy

   .. math::

      s_f\Gamma_{b,\mathrm{in}}\le0,\qquad
      s_f\Gamma_{b,\mathrm{out}}^{\mathrm{ref}}\ge0.

   At a lower inlet the incoming flux is positive and backflow escaping the domain is negative. A single
   net flux cannot distinguish the externally supplied component from the density-dependent outgoing
   component, so it cannot determine this boundary relation.

   Walls have zero net flux during time integration and use no outgoing coefficient. Even an open face with
   injection over only part of its area requires input averaged over the whole face. J03 does not apply
   another aperture fraction.

   .. rubric:: 4. Inputs to the initializer

   ``sub_J03_initialize_transport_closure`` takes all inputs listed below.

   .. list-table::
      :header-rows: 1
      :widths: 33 25 42

      * - Argument
        - Shape and units
        - Use
      * - ``active``
        - ``(nr,nz)``, logical
        - Marks participating cells; at least one must be active
      * - ``face_type``
        - ``(4,nr,nz)``, integer
        - Internal 0, open 1, wall 2
      * - ``volume``
        - ``(nr,nz)``, m³
        - Active-cell volumes must be positive
      * - ``face_area``
        - ``(4,nr,nz)``, m²
        - Nonnegative areas; both sides of an internal face require the same positive area
      * - ``density_ref``
        - ``(nr,nz)``, m⁻³
        - Select upwind reference density and determine the floor
      * - ``flux_r_ref``
        - ``(nr-1,nz)``, m⁻²s⁻¹
        - Build radial internal-face coefficients
      * - ``flux_z_ref``
        - ``(nr,nz-1)``, m⁻²s⁻¹
        - Build axial internal-face coefficients
      * - ``boundary_inflow_flux``
        - ``(4,nr,nz)``, m⁻²s⁻¹
        - Store the prescribed inflow directly
      * - ``boundary_outflow_flux_ref``
        - ``(4,nr,nz)``, m⁻²s⁻¹
        - Build outgoing coefficients on open faces
      * - ``loss_frequency``
        - ``(nr,nz)``, s⁻¹
        - Store the nonnegative loss frequency per unit time, rather than loss per unit length
      * - ``density_floor_fraction``
        - Positive dimensionless scalar
        - Floor as a fraction of maximum reference density over active cells

   The outputs are ``closure`` and ``ierr``. The object stores copies of input arrays, so later edits to
   the caller's arrays do not update the closure. The object does not store ``source_rate``; the caller
   supplies volume production at each step.

   .. rubric:: 5. Fixed and evolving fields in the closure

   .. list-table::
      :header-rows: 1
      :widths: 32 37 31

      * - Field
        - Meaning
        - Subsequent use
      * - ``nr,nz,active,face_type,volume,face_area``
        - Geometry and topology
        - Read by each divergence and time-step calculation
      * - ``density_ref,flux_r_ref,flux_z_ref,boundary_outflow_flux_ref``
        - Copy of initial reference fields
        - Reference data, initial guess and scale for the steady solver
      * - ``velocity_r_face,velocity_z_face,boundary_outflow_velocity``
        - Fixed face coefficients derived above
        - Multiply the current density to obtain current flux
      * - ``boundary_inflow_flux``
        - Prescribed incoming flux
        - May be updated before each time step
      * - ``loss_frequency``
        - Current linear loss frequency
        - May be updated; recompute the time-step bound afterward

   Changing ``density_ref`` or ``flux_*_ref`` alone does not recalculate the face coefficients.
   Reinitialize the object when changing reference fields so coefficients and reference data remain
   consistent.

   .. rubric:: 6. Checks performed during initialization

   The routine validates shapes, nonnegative losses, a nonempty active region, volumes and areas, and valid
   face types. Each internal face needs an existing active neighbour whose opposite face is also internal.
   The two areas of a common face must satisfy

   .. math::

      |A_L-A_R|
        \le100\,\operatorname{epsilon}(1.0)\max(A_L,A_R).

   An external boundary on the axis may have zero area. Internal faces require positive area. These
   conditions permit internal particle rates to cancel in the discrete balance.

   Initialization does not fully check finiteness of the reference field, nonnegative reference density or
   signs of incoming and outgoing boundary flux. The caller must verify these. Fill unused and noninternal
   locations with zero to avoid accidental use during diagnostics or field conversion.

   .. rubric:: 7. One initializer for every reference-field source

   All sources use ``sub_J03_initialize_transport_closure``. It takes only geometry, density and flux
   arrays. It does not read files, run the preprocessors or depend on linking a preprocessor module. A new
   method can supply any reference fields that satisfy the same input conventions.

   The module includes its implementation files after ``contains``. Compile only
   ``mod_J03_neutral_continuity_faceflux_2Drz.f90`` with preprocessing enabled.
