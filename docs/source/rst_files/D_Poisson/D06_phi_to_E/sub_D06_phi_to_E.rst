sub_D06_phi_to_E.f90
--------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D06_phi_to_E`` 对物理域内每个格点做二阶中心差分，由势函数 :math:`\phi`
   计算三个电场分量 ``Ex``\ 、\ ``Ey``\ 、\ ``Ez``\ ，满足
   :math:`\mathbf{E} = -\nabla\phi` （dx=dy=dz=1）。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 30 42

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地子域 cell-center 下界索引，对应 x、y、z 三个方向。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地子域 cell-center 上界索引。
      * - ``phi``
        - in
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - 3D 势函数数组，每侧含一层 ghost 格；调用前 ghost 层必须已由 D05 填充并完成
          边界修正，否则差分结果不正确。
      * - ``Ex``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - x 方向电场分量；只有物理域格 ``il(1):iu(1)`` 被写入，ghost 格不改动。
      * - ``Ey``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - y 方向电场分量；只写物理域格。
      * - ``Ez``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - z 方向电场分量；只写物理域格。

   .. rubric:: 局部假设

   本页例程使用 cell-centered Cartesian ``(x,y,z)`` 布局；``phi`` 及三个电场数组
   均包含每侧一层 ghost 格。差分系数假设 dx=dy=dz=1，物理单位换算由调用方负责。
   无 MPI 或外部库依赖。

   .. rubric:: 实现逻辑

   三重 k-j-i 循环遍历物理域，对每个格点直接用邻格势函数值计算中心差分：

   .. math::

      E_x = (\phi_{i-1,j,k} - \phi_{i+1,j,k}) \times 0.5, \quad
      E_y = (\phi_{i,j-1,k} - \phi_{i,j+1,k}) \times 0.5, \quad
      E_z = (\phi_{i,j,k-1} - \phi_{i,j,k+1}) \times 0.5.

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D06_phi_to_E`` applies second-order central differences at every
   physical-domain cell to compute the three electric-field components ``Ex``,
   ``Ey``, and ``Ez`` from the electrostatic potential :math:`\phi`
   (:math:`\mathbf{E}=-\nabla\phi`, dx=dy=dz=1).

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 30 42

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - integer(1:3), lower cell-center indices of the local subdomain in x, y, z.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer(1:3), upper cell-center indices of the local subdomain.
      * - ``phi``
        - in
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - real(:,:,:), electrostatic potential with one ghost layer per side; ghost
          cells must be filled (e.g. by D05 plus boundary-condition fixup) before
          calling, or the finite-difference result will be incorrect.
      * - ``Ex``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - real(:,:,:), x-component of the electric field; only physical-domain
          cells ``il(1):iu(1)`` are written; ghost cells are not modified.
      * - ``Ey``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - real(:,:,:), y-component of the electric field; only physical-domain cells written.
      * - ``Ez``
        - out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - real(:,:,:), z-component of the electric field; only physical-domain cells written.

   .. rubric:: Local Assumptions

   These routines use a cell-centered Cartesian ``(x,y,z)`` layout; ``phi`` and
   the three field arrays carry one ghost layer per side. Finite-difference
   coefficients assume unit grid spacing dx=dy=dz=1; physical-unit conversion is
   the caller's responsibility. No MPI or external library dependencies.

   .. rubric:: Implementation Notes

   A triple k-j-i loop over the physical domain computes the central difference at
   each cell directly from neighbouring potential values:

   .. math::

      E_x = (\phi_{i-1,j,k} - \phi_{i+1,j,k}) \times 0.5, \quad
      E_y = (\phi_{i,j-1,k} - \phi_{i,j+1,k}) \times 0.5, \quad
      E_z = (\phi_{i,j,k-1} - \phi_{i,j,k+1}) \times 0.5.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D06_phi_to_E.f90
