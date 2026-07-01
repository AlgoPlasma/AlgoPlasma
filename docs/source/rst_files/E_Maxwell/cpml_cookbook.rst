CPML Cookbook
=============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: CPML 在 E_Maxwell 里的角色

   CPML（Convolutional Perfectly Matched Layer）用于有限计算域的吸收边界。普通 FDTD
   内核负责内部区域的 Maxwell curl 更新；CPML 内核在吸收层中用带有 ``kappa`` 缩放和
   ``psi`` memory 的差分项替代普通差分项，从而降低出射波在边界处的反射。

   本页关注“如何安全使用 AlgoPlasma 的 CPML routine”，不重新推导完整 PML 理论。公式细节见三篇
   FDTD notes，反射效果验证见 :doc:`CPML wave-packet tests </tests/005_maxwell/cpml_wavepacket>`。

   .. rubric:: 使用规则

   - CPML routine 应在吸收层区域替代对应的普通 FDTD routine，而不是在普通更新后叠加调用。
   - 每个被拉伸方向都需要一组系数数组，例如 ``a*``、``b*``、``k*``。
   - 每个被修正的 curl 差分都需要一个 persistent ``psi_*`` memory 数组；这些数组在时间步之间保留。
   - simulation 开始前将所有 ``psi_*`` memory 初始化为零。
   - 普通内部区若不调用 CPML routine，则不需要更新对应 ``psi_*``。
   - 若为了实现方便在包含内部区的较大范围调用 CPML routine，内部区系数应退化为
     ``kappa=1``、``a=0``、``b=1``，从而不给普通差分额外记忆项。

   .. rubric:: 方向和几何边界

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 几何
        - 可以设置 CPML 的方向
        - 特别注意
      * - 2D ``(r,z)``
        - 外半径 ``r_plus`` 和 ``z`` 两端
        - :math:`r=0` 是物理轴线，不是 PML；轴线使用专门闭合公式。
      * - 3D cylindrical
        - 外半径、``z`` 两端；非周期角扇区可考虑 ``phi`` 方向
        - 完整圆周问题中 ``phi`` 是周期方向，通常不设置真实 CPML。
      * - 3D Cartesian
        - ``x``、``y``、``z`` 的任意外边界
        - 每个方向的正负两侧可共用方向系数，但 update range 必须覆盖正确条带。

   .. rubric:: 调用顺序

   一个稳妥的组织方式是把计算区域分成内部区和 CPML 条带：

   .. code-block:: fortran

      call update_plain_fdtd_on_interior(...)

      call update_cpml_on_x_or_r_strips(...)
      call update_cpml_on_y_or_phi_strips_if_present(...)
      call update_cpml_on_z_strips(...)

      call fill_or_exchange_boundary_values(...)
      call diagnostics_if_needed(...)

   实际代码可以按 ``H`` 半步和 ``E`` 整步分别组织，但原则不变：同一个场量、同一个网格点、
   同一个时间层只更新一次。CPML 条带的边界/ghost cell 仍然要在调用前准备好。

   .. rubric:: 系数和 memory 的读法

   - ``k`` 或 ``kappa`` 控制被拉伸方向导数的缩放；内部区通常为 ``1``。
   - ``a`` 和 ``b`` 控制 memory 递推。``b`` 越接近 ``1``，历史项衰减越慢。
   - ``psi_E_x_y`` 这类名字可读作“更新 ``E_x`` 时，``y`` 方向导数对应的 memory 项”。
   - E01 中的 ``psi_ephi_r``、``psi_hr_z`` 等名字遵循同一规则：场分量在前，方向在后。
   - 柱坐标中，CPML 替换的是坐标方向上的有限差分；:math:`1/r` 这类 metric 因子仍应放在正确的
     Yee 半径位置上。

   .. rubric:: 参数选择建议

   这里不把 CPML 参数写成固定魔法数，因为合适参数依赖波长、网格分辨率、PML 厚度、入射角和介质。
   实际使用时建议：

   - 先复用 ``tests/005_maxwell/case_cpml_*_wavepacket_ref`` 中的参数量级。
   - 至少记录 ``npml``、目标波长或频率、网格步长、``sigma/kappa/alpha`` 剖面阶数和最大值。
   - 用 probe 误差或能量残留判断吸收效果，不只看单张场图。
   - 加厚 CPML 通常会降低反射，但也会增加计算量；测试中 3D Cartesian ``npml=24`` 明显优于
     ``npml=12``，可作为调参直觉。

   .. rubric:: 常见错误检查表

   - ``psi_*`` 每步被重新置零，导致 CPML 退化。
   - ``psi_*`` 没有初始化，第一步就带入随机历史项。
   - ``a/b/k`` 数组方向和场分量不匹配，例如把 ``z`` 方向系数用于 ``r`` 向差分。
   - 在轴线 :math:`r=0` 上调用需要 ``i-1`` 的 CPML 径向差分。
   - 在完整周期 ``phi`` 方向设置 PML，同时又做周期 wrap，边界含义冲突。
   - 为新增 CPML 子程序、版本或参数方案补测试时，只跑普通 FDTD single-step，
     没有跑 wave-packet reference 测试。

   .. rubric:: 参考文献

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.

.. container:: ap-lang ap-lang-en

   .. rubric:: Role of CPML in E_Maxwell

   CPML (Convolutional Perfectly Matched Layer) provides absorbing boundaries
   for finite computational domains. Plain FDTD kernels update Maxwell curls in
   the interior. CPML kernels replace ordinary finite differences inside
   absorbing layers with ``kappa``-scaled derivatives plus ``psi`` memory terms,
   reducing outgoing-wave reflection at domain edges.

   This page focuses on safe use of AlgoPlasma CPML routines. It does not rederive
   the full PML theory. Formula details live in the three FDTD notes, and
   reflection behavior is validated by
   :doc:`CPML wave-packet tests </tests/005_maxwell/cpml_wavepacket>`.

   .. rubric:: Usage Rules

   - In an absorbing layer, call the CPML routine instead of the matching plain
     FDTD routine; do not stack it after the normal update.
   - Each stretched direction needs coefficient arrays such as ``a*``, ``b*``,
     and ``k*``.
   - Each corrected curl difference needs a persistent ``psi_*`` memory array;
     these arrays must survive across time steps.
   - Initialize all ``psi_*`` memory arrays to zero before the simulation starts.
   - Interior cells that do not call CPML routines do not need their ``psi_*``
     arrays updated.
   - If a CPML routine is called over a range that includes interior cells, set
     interior coefficients to ``kappa=1``, ``a=0``, and ``b=1`` so the update
     reduces to the plain derivative.

   .. rubric:: Directions and Geometric Boundaries

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - Geometry
        - CPML directions
        - Special note
      * - 2D ``(r,z)``
        - outer radial boundary and both ``z`` ends
        - :math:`r=0` is a physical axis, not a PML boundary; use the axis closure.
      * - 3D cylindrical
        - outer radius and both ``z`` ends; ``phi`` only for intentionally non-periodic angular sectors
        - In full-cylinder problems, ``phi`` is periodic and normally not a real CPML boundary.
      * - 3D Cartesian
        - any outer boundary in ``x``, ``y``, or ``z``
        - Positive and negative sides may share direction profiles, but update ranges must cover the correct strips.

   .. rubric:: Calling Order

   A robust organization is to split the domain into an interior and CPML strips:

   .. code-block:: fortran

      call update_plain_fdtd_on_interior(...)

      call update_cpml_on_x_or_r_strips(...)
      call update_cpml_on_y_or_phi_strips_if_present(...)
      call update_cpml_on_z_strips(...)

      call fill_or_exchange_boundary_values(...)
      call diagnostics_if_needed(...)

   Real solvers may organize this separately for the ``H`` half step and ``E``
   full step, but the invariant is the same: one field component at one grid
   point and one time layer should be updated once. CPML strips still need valid
   neighbor and ghost values before the call.

   .. rubric:: Reading Coefficients and Memory Names

   - ``k`` or ``kappa`` scales the derivative in the stretched direction;
     interior values are normally ``1``.
   - ``a`` and ``b`` control the memory recursion. Values of ``b`` closer to
     ``1`` make the history decay more slowly.
   - A name such as ``psi_E_x_y`` means the memory term for the ``y`` derivative
     while updating ``E_x``.
   - E01 names such as ``psi_ephi_r`` and ``psi_hr_z`` follow the same rule:
     field component first, coordinate direction second.
   - In cylindrical coordinates, CPML replaces coordinate finite differences;
     metric factors such as :math:`1/r` still belong at the correct Yee radius.

   .. rubric:: Parameter-Tuning Guidance

   CPML parameters are not fixed magic numbers; suitable values depend on
   wavelength, grid resolution, PML thickness, incidence angle, and material.
   Practical guidance:

   - Start from the parameter scale used by
     ``tests/005_maxwell/case_cpml_*_wavepacket_ref``.
   - Record ``npml``, target wavelength or frequency, grid spacing, profile
     order, and the maximum ``sigma/kappa/alpha`` values.
   - Judge absorption using probe error or residual energy, not only a field
     snapshot.
   - Thicker CPML usually reduces reflection at extra cost. In the current tests,
     3D Cartesian ``npml=24`` is much better than ``npml=12``, which is useful
     tuning intuition.

   .. rubric:: Common Error Checklist

   - ``psi_*`` arrays are reset to zero every step, destroying the memory.
   - ``psi_*`` arrays are never initialized, so the first step uses random history.
   - ``a/b/k`` arrays are attached to the wrong field component or direction.
   - A radial CPML difference requiring ``i-1`` is called on the physical axis
     :math:`r=0`.
   - A full-periodic ``phi`` direction is both wrapped periodically and treated
     as a PML boundary.
   - Tests for a new CPML subroutine, version, or parameter scheme include only
     plain FDTD single-step checks; run the wave-packet reference tests as well.

   .. rubric:: References

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.
