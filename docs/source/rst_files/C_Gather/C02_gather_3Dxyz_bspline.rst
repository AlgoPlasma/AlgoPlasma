==========================
C02_gather_3Dxyz_bspline
==========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: C02 是什么

   ``C02_gather_3Dxyz_bspline`` 是三维直角坐标中的直接 B-spline gather 例程。
   它输入一个粒子的位置和 cell-centered 的六个电磁场分量 ``Ex,Ey,Ez,Bx,By,Bz``，
   输出该粒子位置处的 ``E(1:3)`` 和 ``B(1:3)``。

   .. list-table:: 输入和输出
      :header-rows: 1
      :widths: 18 42 40

      * - 类别
        - 传入什么
        - 得到什么
      * - 粒子信息
        - ``p``、``np``、``par(1:6,1:np)``，其中 ``par(1:3,p)`` 是网格指标单位下的位置
        - 单个粒子的 x、y、z 坐标
      * - 网格信息
        - ``il(1:3)``、``iu(1:3)``
        - cell-centered 场数组的有效指标范围
      * - 场数组
        - ``Ex,Ey,Ez,Bx,By,Bz``
        - 被插值到粒子位置的六个场分量
      * - 阶数
        - 运行时参数 ``order``
        - B-spline 阶数、每个方向 ``order+1`` 个模板点，以及 guard cell 宽度 ``ng=(order+2)/2``
      * - 输出
        - ``E(1:3)``、``B(1:3)``
        - 粒子位置处的电场和磁场

   .. important::

      当前程序名对应的实现是 ``sub_C02_gather_3Dxyz_bspline``。
      它会直接读取六个场数组并完成 gather，不只是生成权重和模板。

   .. rubric:: 为什么用 B-spline gather

   C01 已经能做 cell-centered 电磁场的三线性 gather。C02 保留同样的 cell-centered
   场数组约定，但把插值核改成运行时可选阶数的 centered B-spline。

   - 输入同一个粒子位置后，x、y、z 三个方向的权重会被六个场分量复用。
   - B-spline 有紧支撑，``order`` 确定后每个方向只访问 ``order+1`` 个网格点。
   - ``order=1`` 时，C02 的线性 B-spline gather 退化为 C01 的三线性 gather。
   - ``order`` 更高时，插值权重更平滑，适合需要高阶 shape function 的 gather 测试或物理模块。

   .. rubric:: B-spline 权重

   C02 使用 centered cardinal B-spline。对阶数 :math:`m=\texttt{order}`，
   程序里的 ``fun_C02_bspline_shape(order,r)`` 递归计算一维权重 :math:`S_m(r)`：

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r<\frac{1}{2},\\
      0, & \text{otherwise},
      \end{cases}

   .. math::

      S_m(r)=
      \frac{r+h}{m}S_{m-1}\left(r+\frac{1}{2}\right)
      +\frac{h-r}{m}S_{m-1}\left(r-\frac{1}{2}\right),
      \qquad h=\frac{m+1}{2}.

   三维权重由三个方向的一维权重做张量积：

   .. math::

      W_{abc}=w_x(a)\,w_y(b)\,w_z(c).

   下面的图展示了 ``order=0`` 到 ``4`` 时，一维 centered B-spline 的形状。

   .. plot::

      import numpy as np
      import matplotlib.pyplot as plt

      def shape(order, r):
          r = np.asarray(r, dtype=float)
          if order == 0:
              return np.where((r >= -0.5) & (r < 0.5), 1.0, 0.0)
          h = 0.5 * (order + 1)
          y = np.zeros_like(r)
          mask = (r > -h) & (r < h)
          y[mask] = (
              ((r[mask] + h) / order) * shape(order - 1, r[mask] + 0.5)
              + ((h - r[mask]) / order) * shape(order - 1, r[mask] - 0.5)
          )
          return y

      x = np.linspace(-2.8, 2.8, 900)
      fig, ax = plt.subplots(figsize=(6.0, 3.2))
      for order in range(5):
          ax.plot(x, shape(order, x), lw=2.0, label=fr"$S_{order}(r)$")
      ax.axhline(0.0, color="0.2", lw=0.8)
      ax.set_xlabel(r"distance to grid point $r$")
      ax.set_ylabel(r"weight $S_m(r)$")
      ax.set_title("Centered B-spline shape functions")
      ax.set_xlim(-2.8, 2.8)
      ax.set_ylim(-0.04, 1.08)
      ax.grid(True, alpha=0.28)
      ax.legend(ncol=5, frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.22))
      fig.tight_layout(rect=(0.0, 0.08, 1.0, 1.0))

   .. rubric:: 程序怎么实现

   顶层入口 ``sub_C02_gather_3Dxyz_bspline`` 分四步完成 gather。

   .. list-table:: 实现流程
      :header-rows: 1
      :widths: 18 45 37

      * - 步骤
        - 做什么
        - 输出给谁
      * - 换到 cell-centered 下标坐标
        - ``x=par(1,p)+0.5``，``y=par(2,p)+0.5``，``z=par(3,p)+0.5``
        - 给一维模板生成器使用
      * - 生成一维模板
        - 三次调用 ``sub_C02_bspline_stencil_1d(order,xp,idx,w)``
        - 得到 ``ix,iy,iz`` 和 ``wx,wy,wz``
      * - 组装三维权重
        - 使用 ``wx(a)*wy(b)*wz(c)``
        - 给标量场 gather 函数使用
      * - 汇总六个分量
        - 六次调用 ``fun_C02_gather_scalar_bspline``
        - 输出 ``E(1:3)`` 和 ``B(1:3)``

   这里的 ``+0.5`` 不是把粒子在物理空间里移动半格，而是把粒子坐标换到
   cell-centered 场数组的下标坐标系里。比如 ``field(4)`` 的几何位置是 ``3.5``，
   但代码访问它时用的数组下标是 ``4``。

   .. plot::

      import numpy as np
      import matplotlib.pyplot as plt

      par = 3.25
      node_idx = np.arange(2, 7)
      cell_idx = np.arange(3, 7)
      cell_phys = cell_idx - 0.5
      xp = par + 0.5

      fig, axes = plt.subplots(2, 1, figsize=(7.2, 3.8), sharex=True)

      def style_axis(ax, title):
          ax.hlines(0.0, 1.8, 6.2, color="0.78", lw=1.1)
          ax.set_title(title, fontsize=10.5, loc="left", pad=3)
          ax.set_ylim(-0.42, 0.48)
          ax.set_yticks([])
          ax.set_xticks([])
          for spine in ax.spines.values():
              spine.set_visible(False)

      style_axis(axes[0], r"physical geometry: field(4) is at x=3.5")
      axes[0].scatter(node_idx, np.zeros_like(node_idx), s=46, marker="o", facecolor="white", edgecolor="0.45", linewidth=1.0, zorder=2)
      axes[0].scatter(cell_phys, np.zeros_like(cell_phys), s=70, marker="s", facecolor="#f2c94c", edgecolor="#8a6d00", linewidth=1.0, zorder=3)
      for i, x in zip(cell_idx, cell_phys):
          axes[0].text(x, -0.12, f"field({i})", ha="center", va="top", fontsize=9.2)
      axes[0].axvline(par, ymin=0.18, ymax=0.82, color="#555555", lw=1.9, linestyle="--")
      axes[0].text(par, 0.20, r"$par=3.25$", ha="center", va="bottom", color="#555555")
      axes[0].annotate("", xy=(par, 0.31), xytext=(3.5, 0.31), arrowprops={"arrowstyle": "<->", "color": "#2f6f4e", "lw": 1.6})
      axes[0].text((par + 3.5) / 2, 0.36, r"$par-3.5=-0.25$", ha="center", va="bottom", color="#2f6f4e", fontsize=9.3)

      style_axis(axes[1], r"array-index coordinate: code uses xp=par+0.5")
      axes[1].scatter(cell_idx, np.zeros_like(cell_idx), s=70, marker="s", facecolor="#f2c94c", edgecolor="#8a6d00", linewidth=1.0, zorder=3)
      for i in cell_idx:
          axes[1].text(i, -0.12, f"i={i}", ha="center", va="top", fontsize=9.5)
      axes[1].axvline(par, ymin=0.18, ymax=0.82, color="#555555", lw=1.5, linestyle="--", alpha=0.55)
      axes[1].axvline(xp, ymin=0.18, ymax=0.82, color="#1f77b4", lw=2.1)
      axes[1].annotate("", xy=(xp, 0.21), xytext=(par, 0.21), arrowprops={"arrowstyle": "->", "color": "#1f77b4", "lw": 1.8})
      axes[1].text((par + xp) / 2, 0.26, r"$+0.5$", ha="center", va="bottom", color="#1f77b4")
      axes[1].text(xp, 0.36, r"$xp=3.75$", ha="center", va="bottom", color="#1f77b4")
      axes[1].annotate("", xy=(xp, 0.08), xytext=(4.0, 0.08), arrowprops={"arrowstyle": "<->", "color": "#2f6f4e", "lw": 1.6})
      axes[1].text((xp + 4.0) / 2, 0.13, r"$xp-4=-0.25$", ha="center", va="bottom", color="#2f6f4e", fontsize=9.3)

      axes[-1].set_xlim(1.8, 6.2)
      axes[-1].set_xlabel("coordinate value")
      fig.suptitle("The +0.5 shift converts particle position to cell-centered array-index coordinates", y=0.995, fontsize=12)
      fig.tight_layout(rect=(0.0, 0.0, 1.0, 0.94))

   .. rubric:: 模板起点和覆盖点

   一维模板由 ``sub_C02_bspline_stencil_1d`` 生成。程序先选模板起点：

   .. math::

      i_0=\left\lfloor xp-\frac{\texttt{order}-1}{2}\right\rfloor,

   然后对 ``a=0,...,order`` 设置

   .. math::

      idx(a)=i_0+a,\qquad w(a)=S_{\texttt{order}}\left(xp-idx(a)\right).

   下面用 ``xp=3.35`` 展示 ``order=0,1,2`` 的模板点。橙色曲线是放在 ``xp`` 附近的
   B-spline，红色竖线和红点表示在模板网格点上取到的权重。

   .. plot::
      :width: 88%
      :align: center

      import math
      import numpy as np
      import matplotlib.pyplot as plt

      xp = 3.35
      grid = np.arange(1, 7)
      fig, axes = plt.subplots(3, 1, figsize=(6.8, 5.9), sharex=True)

      def shape(order, r):
          r = np.asarray(r, dtype=float)
          if order == 0:
              return np.where((r >= -0.5) & (r < 0.5), 1.0, 0.0)
          h = 0.5 * (order + 1)
          y = np.zeros_like(r)
          mask = (r > -h) & (r < h)
          y[mask] = (
              ((r[mask] + h) / order) * shape(order - 1, r[mask] + 0.5)
              + ((h - r[mask]) / order) * shape(order - 1, r[mask] - 0.5)
          )
          return y

      for ax, order in zip(axes, [0, 1, 2]):
          half_support = 0.5 * (order + 1)
          i0 = math.floor(xp - 0.5 * (order - 1))
          stencil = np.arange(i0, i0 + order + 1)
          xx = np.linspace(xp - half_support - 0.05, xp + half_support + 0.05, 500)
          yy = shape(order, xp - xx)
          ww = shape(order, xp - stencil)
          if ww.sum() > 0.0:
              ww = ww / ww.sum()
          height = 0.28

          ax.hlines(0.0, grid[0] - 0.45, grid[-1] + 0.45, color="0.75", lw=1.1)
          ax.scatter(grid, np.zeros_like(grid), s=62, facecolor="white", edgecolor="0.35", linewidth=1.2, zorder=2)
          ax.fill_between(xx, 0.0, height * yy, where=yy > 0.0, color="#f2c94c", alpha=0.24, zorder=1)
          if order == 0:
              xs = [xp - half_support, xp - half_support, xp + half_support, xp + half_support]
              ys = [0.0, height, height, 0.0]
              ax.plot(xs, ys, color="#c98000", lw=2.1, zorder=3)
          else:
              ax.plot(xx, height * yy, color="#c98000", lw=2.1, zorder=3)
          ax.vlines(stencil, 0.0, height * ww, color="#d62728", lw=1.7, zorder=4)
          ax.scatter(stencil, np.zeros_like(stencil), s=96, color="#d62728", zorder=4)
          ax.scatter(stencil, height * ww, s=70, color="#d62728", edgecolor="white", linewidth=0.7, zorder=5)
          ax.axvline(xp, ymin=0.16, ymax=0.86, color="#1f77b4", lw=2.0)
          ax.text(xp, 0.34, r"$xp=3.35$", ha="center", va="bottom", color="#1f77b4")

          for i in grid:
              ax.text(i, -0.20, str(i), ha="center", va="top", fontsize=10)
          ax.text(xp + half_support + 0.12, 0.22, "B-spline", ha="left", va="center", color="#c98000", fontsize=9.5)
          ax.set_ylim(-0.34, 0.50)
          ax.set_yticks([])
          ax.set_xticks([])
          ax.set_title(
              rf"order={order}: $i_0={i0}$, stencil = "
              + "{" + ", ".join(str(i) for i in stencil) + "}",
              fontsize=11,
          )
          for spine in ax.spines.values():
              spine.set_visible(False)
      axes[-1].set_xlabel("target-grid index")
      fig.suptitle("B-spline support and stencil points selected by the start-index rule", y=0.99)
      fig.tight_layout()

   .. rubric:: 调用示例

   下面示例只展示接口形状。调用端准备好 cell-centered 场数组和 guard cell 后，
   直接调用 ``sub_C02_gather_3Dxyz_bspline`` 得到粒子处的 ``E`` 和 ``B``。

   .. code-block:: fortran

      #include "C_Gather/C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline.f90"

      program demo_c02_gather
          use mod_C02_gather_3Dxyz_bspline, only: sub_C02_gather_3Dxyz_bspline
          implicit none

          integer, parameter :: np = 1
          integer, parameter :: order = 2
          integer, parameter :: ng = (order + 2) / 2
          integer, parameter :: il(3) = [1, 1, 1]
          integer, parameter :: iu(3) = [8, 8, 8]
          real :: par(1:6,1:np)
          real :: Ex(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Ey(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Ez(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Bx(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: By(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Bz(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: E(1:3), B(1:3)

          par = 0.0
          par(1:3,1) = [3.25, 4.10, 2.80]

          Ex = 1.0; Ey = 2.0; Ez = 3.0
          Bx = 4.0; By = 5.0; Bz = 6.0

          call sub_C02_gather_3Dxyz_bspline(1, np, par, il, iu, Ex, Ey, Ez, &
              Bx, By, Bz, E, B, order)
      end program demo_c02_gather

   .. rubric:: 注意事项

   - ``order`` 是运行时参数，用来控制 B-spline 阶数。
   - 该实现面向 cell-centered 电磁场；顶层入口固定使用 ``par(1:3,p)+0.5``。
   - 场数组需要提供 ``ng=(order+2)/2`` 层 guard cell，否则高阶模板可能访问越界。
   - ``sub_C02_bspline_stencil_1d`` 会把一维权重归一化，避免截断误差导致权重和偏离 1。
   - 这个模块完成的是直接电磁场 gather；如果只想复用权重模板，需要单独调用低层的 ``sub_C02_bspline_stencil_1d``。

   .. rubric:: 文件分工

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 作用
      * - :doc:`mod_C02_gather_3Dxyz_bspline.f90 <C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline>`
        - 源码级 module 入口，汇入本目录下的 gather 子程序和辅助函数。
      * - :doc:`sub_C02_gather_3Dxyz_bspline.f90 <C02_gather_3Dxyz_bspline/sub_C02_gather_3Dxyz_bspline>`
        - 顶层单粒子 gather 例程，输入六个场分量并输出 ``E`` 和 ``B``。
      * - :doc:`sub_C02_bspline_stencil_1d.f90 <C02_gather_3Dxyz_bspline/sub_C02_bspline_stencil_1d>`
        - 为一个方向生成 ``order+1`` 个网格指标 ``idx`` 和对应权重 ``w``。
      * - :doc:`fun_C02_bspline_shape.f90 <C02_gather_3Dxyz_bspline/fun_C02_bspline_shape>`
        - 递归计算 centered B-spline 形函数 ``S_order(r)``。
      * - :doc:`fun_C02_gather_scalar_bspline.f90 <C02_gather_3Dxyz_bspline/fun_C02_gather_scalar_bspline>`
        - 对一个标量场分量执行三维张量积加权求和。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">罗鑫 (2025/12/23) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">赵中平 (2026/05/30) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: What C02 Does

   ``C02_gather_3Dxyz_bspline`` is a direct B-spline gather routine for 3D Cartesian grids.
   It takes one particle position and six cell-centered electromagnetic-field components
   ``Ex,Ey,Ez,Bx,By,Bz``, then returns the gathered ``E(1:3)`` and ``B(1:3)`` at that particle.

   .. list-table:: Inputs and outputs
      :header-rows: 1
      :widths: 18 42 40

      * - Category
        - Input
        - Output or role
      * - Particle data
        - ``p``, ``np``, and ``par(1:6,1:np)``; ``par(1:3,p)`` stores position in grid-index units
        - The selected particle position
      * - Grid metadata
        - ``il(1:3)`` and ``iu(1:3)``
        - Valid cell-centered field-index bounds
      * - Field arrays
        - ``Ex,Ey,Ez,Bx,By,Bz``
        - The six field components to interpolate
      * - Degree
        - Runtime argument ``order``
        - B-spline degree, ``order+1`` stencil points per direction, and guard width ``ng=(order+2)/2``
      * - Outputs
        - ``E(1:3)`` and ``B(1:3)``
        - Electric and magnetic fields at the particle position

   .. important::

      The current program name points to ``sub_C02_gather_3Dxyz_bspline``.
      It reads the six field arrays and performs the gather directly, rather than
      only returning stencil weights.

   .. rubric:: Why Use B-spline Gather

   C01 already performs trilinear gather from cell-centered electromagnetic fields.
   C02 keeps the same cell-centered convention, but replaces the interpolation kernel
   with a runtime-selectable centered B-spline degree.

   - The same x, y, and z weights are reused for all six field components.
   - B-splines have compact support; each direction touches only ``order+1`` grid points.
   - For ``order=1``, C02 reduces to the trilinear gather used by C01.
   - Higher ``order`` values provide smoother interpolation weights for higher-order gather tests or physics modules.

   .. rubric:: B-spline Weights

   C02 uses centered cardinal B-splines. For degree :math:`m=\texttt{order}`,
   ``fun_C02_bspline_shape(order,r)`` recursively evaluates the 1D weight :math:`S_m(r)`:

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r<\frac{1}{2},\\
      0, & \text{otherwise},
      \end{cases}

   .. math::

      S_m(r)=
      \frac{r+h}{m}S_{m-1}\left(r+\frac{1}{2}\right)
      +\frac{h-r}{m}S_{m-1}\left(r-\frac{1}{2}\right),
      \qquad h=\frac{m+1}{2}.

   The 3D weight is the tensor product of the three 1D weights:

   .. math::

      W_{abc}=w_x(a)\,w_y(b)\,w_z(c).

   The plot below shows the centered B-spline shapes for ``order=0`` through ``4``.

   .. plot::

      import numpy as np
      import matplotlib.pyplot as plt

      def shape(order, r):
          r = np.asarray(r, dtype=float)
          if order == 0:
              return np.where((r >= -0.5) & (r < 0.5), 1.0, 0.0)
          h = 0.5 * (order + 1)
          y = np.zeros_like(r)
          mask = (r > -h) & (r < h)
          y[mask] = (
              ((r[mask] + h) / order) * shape(order - 1, r[mask] + 0.5)
              + ((h - r[mask]) / order) * shape(order - 1, r[mask] - 0.5)
          )
          return y

      x = np.linspace(-2.8, 2.8, 900)
      fig, ax = plt.subplots(figsize=(6.0, 3.2))
      for order in range(5):
          ax.plot(x, shape(order, x), lw=2.0, label=fr"$S_{order}(r)$")
      ax.axhline(0.0, color="0.2", lw=0.8)
      ax.set_xlabel(r"distance to grid point $r$")
      ax.set_ylabel(r"weight $S_m(r)$")
      ax.set_title("Centered B-spline shape functions")
      ax.set_xlim(-2.8, 2.8)
      ax.set_ylim(-0.04, 1.08)
      ax.grid(True, alpha=0.28)
      ax.legend(ncol=5, frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.22))
      fig.tight_layout(rect=(0.0, 0.08, 1.0, 1.0))

   .. rubric:: Implementation Flow

   The top-level entry ``sub_C02_gather_3Dxyz_bspline`` performs the gather in four steps.

   .. list-table:: Implementation flow
      :header-rows: 1
      :widths: 18 45 37

      * - Step
        - Action
        - Result
      * - Map to cell-centered index coordinates
        - ``x=par(1,p)+0.5``, ``y=par(2,p)+0.5``, and ``z=par(3,p)+0.5``
        - Coordinates for the 1D stencil builder
      * - Build 1D stencils
        - Calls ``sub_C02_bspline_stencil_1d(order,xp,idx,w)`` three times
        - Produces ``ix,iy,iz`` and ``wx,wy,wz``
      * - Form tensor-product weights
        - Uses ``wx(a)*wy(b)*wz(c)``
        - Coefficients for scalar-field gather
      * - Sum six components
        - Calls ``fun_C02_gather_scalar_bspline`` six times
        - Outputs ``E(1:3)`` and ``B(1:3)``

   The ``+0.5`` shift does not physically move the particle. It maps the particle
   position to the array-index coordinate system of cell-centered fields. For example,
   ``field(4)`` is geometrically located at ``3.5``, but the code accesses it with
   array index ``4``.

   .. plot::

      import numpy as np
      import matplotlib.pyplot as plt

      par = 3.25
      node_idx = np.arange(2, 7)
      cell_idx = np.arange(3, 7)
      cell_phys = cell_idx - 0.5
      xp = par + 0.5

      fig, axes = plt.subplots(2, 1, figsize=(7.2, 3.8), sharex=True)

      def style_axis(ax, title):
          ax.hlines(0.0, 1.8, 6.2, color="0.78", lw=1.1)
          ax.set_title(title, fontsize=10.5, loc="left", pad=3)
          ax.set_ylim(-0.42, 0.48)
          ax.set_yticks([])
          ax.set_xticks([])
          for spine in ax.spines.values():
              spine.set_visible(False)

      style_axis(axes[0], r"physical geometry: field(4) is at x=3.5")
      axes[0].scatter(node_idx, np.zeros_like(node_idx), s=46, marker="o", facecolor="white", edgecolor="0.45", linewidth=1.0, zorder=2)
      axes[0].scatter(cell_phys, np.zeros_like(cell_phys), s=70, marker="s", facecolor="#f2c94c", edgecolor="#8a6d00", linewidth=1.0, zorder=3)
      for i, x in zip(cell_idx, cell_phys):
          axes[0].text(x, -0.12, f"field({i})", ha="center", va="top", fontsize=9.2)
      axes[0].axvline(par, ymin=0.18, ymax=0.82, color="#555555", lw=1.9, linestyle="--")
      axes[0].text(par, 0.20, r"$par=3.25$", ha="center", va="bottom", color="#555555")
      axes[0].annotate("", xy=(par, 0.31), xytext=(3.5, 0.31), arrowprops={"arrowstyle": "<->", "color": "#2f6f4e", "lw": 1.6})
      axes[0].text((par + 3.5) / 2, 0.36, r"$par-3.5=-0.25$", ha="center", va="bottom", color="#2f6f4e", fontsize=9.3)

      style_axis(axes[1], r"array-index coordinate: code uses xp=par+0.5")
      axes[1].scatter(cell_idx, np.zeros_like(cell_idx), s=70, marker="s", facecolor="#f2c94c", edgecolor="#8a6d00", linewidth=1.0, zorder=3)
      for i in cell_idx:
          axes[1].text(i, -0.12, f"i={i}", ha="center", va="top", fontsize=9.5)
      axes[1].axvline(par, ymin=0.18, ymax=0.82, color="#555555", lw=1.5, linestyle="--", alpha=0.55)
      axes[1].axvline(xp, ymin=0.18, ymax=0.82, color="#1f77b4", lw=2.1)
      axes[1].annotate("", xy=(xp, 0.21), xytext=(par, 0.21), arrowprops={"arrowstyle": "->", "color": "#1f77b4", "lw": 1.8})
      axes[1].text((par + xp) / 2, 0.26, r"$+0.5$", ha="center", va="bottom", color="#1f77b4")
      axes[1].text(xp, 0.36, r"$xp=3.75$", ha="center", va="bottom", color="#1f77b4")
      axes[1].annotate("", xy=(xp, 0.08), xytext=(4.0, 0.08), arrowprops={"arrowstyle": "<->", "color": "#2f6f4e", "lw": 1.6})
      axes[1].text((xp + 4.0) / 2, 0.13, r"$xp-4=-0.25$", ha="center", va="bottom", color="#2f6f4e", fontsize=9.3)

      axes[-1].set_xlim(1.8, 6.2)
      axes[-1].set_xlabel("coordinate value")
      fig.suptitle("The +0.5 shift converts particle position to cell-centered array-index coordinates", y=0.995, fontsize=12)
      fig.tight_layout(rect=(0.0, 0.0, 1.0, 0.94))

   .. rubric:: Stencil Start and Covered Points

   The 1D stencil is built by ``sub_C02_bspline_stencil_1d``. The first index is

   .. math::

      i_0=\left\lfloor xp-\frac{\texttt{order}-1}{2}\right\rfloor,

   then, for ``a=0,...,order``,

   .. math::

      idx(a)=i_0+a,\qquad w(a)=S_{\texttt{order}}\left(xp-idx(a)\right).

   The plot below uses ``xp=3.35`` for ``order=0,1,2``. The orange curve is the
   B-spline placed around ``xp``; the red vertical lines and red points mark the
   weights sampled at stencil grid points.

   .. plot::
      :width: 88%
      :align: center

      import math
      import numpy as np
      import matplotlib.pyplot as plt

      xp = 3.35
      grid = np.arange(1, 7)
      fig, axes = plt.subplots(3, 1, figsize=(6.8, 5.9), sharex=True)

      def shape(order, r):
          r = np.asarray(r, dtype=float)
          if order == 0:
              return np.where((r >= -0.5) & (r < 0.5), 1.0, 0.0)
          h = 0.5 * (order + 1)
          y = np.zeros_like(r)
          mask = (r > -h) & (r < h)
          y[mask] = (
              ((r[mask] + h) / order) * shape(order - 1, r[mask] + 0.5)
              + ((h - r[mask]) / order) * shape(order - 1, r[mask] - 0.5)
          )
          return y

      for ax, order in zip(axes, [0, 1, 2]):
          half_support = 0.5 * (order + 1)
          i0 = math.floor(xp - 0.5 * (order - 1))
          stencil = np.arange(i0, i0 + order + 1)
          xx = np.linspace(xp - half_support - 0.05, xp + half_support + 0.05, 500)
          yy = shape(order, xp - xx)
          ww = shape(order, xp - stencil)
          if ww.sum() > 0.0:
              ww = ww / ww.sum()
          height = 0.28

          ax.hlines(0.0, grid[0] - 0.45, grid[-1] + 0.45, color="0.75", lw=1.1)
          ax.scatter(grid, np.zeros_like(grid), s=62, facecolor="white", edgecolor="0.35", linewidth=1.2, zorder=2)
          ax.fill_between(xx, 0.0, height * yy, where=yy > 0.0, color="#f2c94c", alpha=0.24, zorder=1)
          if order == 0:
              xs = [xp - half_support, xp - half_support, xp + half_support, xp + half_support]
              ys = [0.0, height, height, 0.0]
              ax.plot(xs, ys, color="#c98000", lw=2.1, zorder=3)
          else:
              ax.plot(xx, height * yy, color="#c98000", lw=2.1, zorder=3)
          ax.vlines(stencil, 0.0, height * ww, color="#d62728", lw=1.7, zorder=4)
          ax.scatter(stencil, np.zeros_like(stencil), s=96, color="#d62728", zorder=4)
          ax.scatter(stencil, height * ww, s=70, color="#d62728", edgecolor="white", linewidth=0.7, zorder=5)
          ax.axvline(xp, ymin=0.16, ymax=0.86, color="#1f77b4", lw=2.0)
          ax.text(xp, 0.34, r"$xp=3.35$", ha="center", va="bottom", color="#1f77b4")

          for i in grid:
              ax.text(i, -0.20, str(i), ha="center", va="top", fontsize=10)
          ax.text(xp + half_support + 0.12, 0.22, "B-spline", ha="left", va="center", color="#c98000", fontsize=9.5)
          ax.set_ylim(-0.34, 0.50)
          ax.set_yticks([])
          ax.set_xticks([])
          ax.set_title(
              rf"order={order}: $i_0={i0}$, stencil = "
              + "{" + ", ".join(str(i) for i in stencil) + "}",
              fontsize=11,
          )
          for spine in ax.spines.values():
              spine.set_visible(False)
      axes[-1].set_xlabel("target-grid index")
      fig.suptitle("B-spline support and stencil points selected by the start-index rule", y=0.99)
      fig.tight_layout()

   .. rubric:: Calling Example

   This example only shows the interface shape. After the caller prepares the
   cell-centered field arrays and guard cells, ``sub_C02_gather_3Dxyz_bspline``
   directly returns ``E`` and ``B`` at the particle.

   .. code-block:: fortran

      #include "C_Gather/C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline.f90"

      program demo_c02_gather
          use mod_C02_gather_3Dxyz_bspline, only: sub_C02_gather_3Dxyz_bspline
          implicit none

          integer, parameter :: np = 1
          integer, parameter :: order = 2
          integer, parameter :: ng = (order + 2) / 2
          integer, parameter :: il(3) = [1, 1, 1]
          integer, parameter :: iu(3) = [8, 8, 8]
          real :: par(1:6,1:np)
          real :: Ex(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Ey(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Ez(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Bx(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: By(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: Bz(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng)
          real :: E(1:3), B(1:3)

          par = 0.0
          par(1:3,1) = [3.25, 4.10, 2.80]

          Ex = 1.0; Ey = 2.0; Ez = 3.0
          Bx = 4.0; By = 5.0; Bz = 6.0

          call sub_C02_gather_3Dxyz_bspline(1, np, par, il, iu, Ex, Ey, Ez, &
              Bx, By, Bz, E, B, order)
      end program demo_c02_gather

   .. rubric:: Notes

   - ``order`` is a runtime argument that selects the B-spline degree.
   - This implementation targets cell-centered electromagnetic fields and always maps positions with ``par(1:3,p)+0.5``.
   - Field arrays must provide ``ng=(order+2)/2`` guard cells so higher-order stencils stay in bounds.
   - ``sub_C02_bspline_stencil_1d`` normalizes each 1D weight array to avoid small roundoff drift from a unit sum.
   - This module performs direct electromagnetic-field gather; call ``sub_C02_bspline_stencil_1d`` separately only if a caller needs the stencil weights themselves.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_C02_gather_3Dxyz_bspline.f90 <C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline>`
        - Source-level module entry that includes the gather routine and helper functions in this directory.
      * - :doc:`sub_C02_gather_3Dxyz_bspline.f90 <C02_gather_3Dxyz_bspline/sub_C02_gather_3Dxyz_bspline>`
        - Top-level single-particle gather routine that takes six field components and returns ``E`` and ``B``.
      * - :doc:`sub_C02_bspline_stencil_1d.f90 <C02_gather_3Dxyz_bspline/sub_C02_bspline_stencil_1d>`
        - Builds ``order+1`` grid indices ``idx`` and corresponding weights ``w`` in one direction.
      * - :doc:`fun_C02_bspline_shape.f90 <C02_gather_3Dxyz_bspline/fun_C02_bspline_shape>`
        - Recursively evaluates the centered B-spline shape function ``S_order(r)``.
      * - :doc:`fun_C02_gather_scalar_bspline.f90 <C02_gather_3Dxyz_bspline/fun_C02_gather_scalar_bspline>`
        - Applies the 3D tensor-product weighted sum to one scalar field component.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Xin LUO (2025/12/23) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Zhongping ZHAO (2026/05/30) · Harbin Institute of Technology</p>
      </div>

.. toctree::
   :maxdepth: 1
   :hidden:

   C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline
   C02_gather_3Dxyz_bspline/sub_C02_gather_3Dxyz_bspline
   C02_gather_3Dxyz_bspline/sub_C02_bspline_stencil_1d
   C02_gather_3Dxyz_bspline/fun_C02_bspline_shape
   C02_gather_3Dxyz_bspline/fun_C02_gather_scalar_bspline
