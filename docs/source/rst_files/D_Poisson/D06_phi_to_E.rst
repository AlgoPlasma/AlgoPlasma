D06_phi_to_E
============

.. toctree::
    :maxdepth: 1
    :hidden:

    D06_phi_to_E/mod_D06_phi_to_E
    D06_phi_to_E/sub_D06_phi_to_E

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D06_phi_to_E`` 在 Poisson 求解后由势函数 :math:`\phi` 计算三个电场分量，
   采用二阶中心差分格式（ :math:`\mathbf{E} = -\nabla\phi` ，规范化为 dx=dy=dz=1）。
   对每个物理域格点 ``(i,j,k)``，差分模板为：

   .. math::

      \begin{aligned}
      E_x(i,j,k) &= \frac{\phi(i-1,j,k) - \phi(i+1,j,k)}{2}, \\
      E_y(i,j,k) &= \frac{\phi(i,j-1,k) - \phi(i,j+1,k)}{2}, \\
      E_z(i,j,k) &= \frac{\phi(i,j,k-1) - \phi(i,j,k+1)}{2}.
      \end{aligned}

   该模板各方向需要一层 ghost 格，因此调用前 ``phi3d`` 的 ghost 层
   必须已由 D05 填充完毕（并完成物理边界修正）。
   本模块无 MPI、无外部库依赖，只写物理域 ``il:iu`` 内的电场值；
   ghost 格电场由调用方在此之后通过 H01 等方式交换。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_D06_phi_to_E.f90 <D06_phi_to_E/mod_D06_phi_to_E>`
        - 模块包装文件，集中 include D06 子程序。
      * - :doc:`sub_D06_phi_to_E.f90 <D06_phi_to_E/sub_D06_phi_to_E>`
        - 主子程序：逐格点二阶中心差分，输出 Ex/Ey/Ez 三分量。

   .. rubric:: 单位与归一化

   差分系数中不含实际网格间距 :math:`\Delta x`\ ；调用方需在调用后自行乘以 :math:`1/\Delta x`\ （或等效物理单位）以得到 SI 单位的电场。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/06/05) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D06_phi_to_E`` computes the three electric-field components from the
   electrostatic potential :math:`\phi` using second-order central differences
   (:math:`\mathbf{E} = -\nabla\phi`, normalised to unit grid spacing dx=dy=dz=1).
   For each physical-domain cell ``(i,j,k)`` the stencil is:

   .. math::

      \begin{aligned}
      E_x(i,j,k) &= \frac{\phi(i-1,j,k) - \phi(i+1,j,k)}{2}, \\
      E_y(i,j,k) &= \frac{\phi(i,j-1,k) - \phi(i,j+1,k)}{2}, \\
      E_z(i,j,k) &= \frac{\phi(i,j,k-1) - \phi(i,j,k+1)}{2}.
      \end{aligned}

   The stencil requires one ghost layer per side, so ``phi3d`` ghost cells must
   already be filled by D05 (and any boundary-condition fixup) before calling.
   This module has no MPI or external library dependencies. Only physical-domain
   cells ``il:iu`` of the output arrays are written; electric-field ghost cells
   should be filled afterwards (e.g. via H01).

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_D06_phi_to_E.f90 <D06_phi_to_E/mod_D06_phi_to_E>`
        - Module wrapper collecting the D06 subroutine.
      * - :doc:`sub_D06_phi_to_E.f90 <D06_phi_to_E/sub_D06_phi_to_E>`
        - Main subroutine: cell-by-cell second-order central difference, outputs Ex/Ey/Ez.

   .. rubric:: Units and Normalisation

   The finite-difference coefficients do not include the physical grid spacing
   :math:`\Delta x`. The caller must multiply the returned field components by
   :math:`1/\Delta x` (or the appropriate physical-unit factor) to obtain SI
   electric-field values.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/06/05) · Harbin Institute of Technology</p>
      </div>
