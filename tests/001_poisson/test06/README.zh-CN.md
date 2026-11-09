# D04_hypre_3Draz_nonuniform：多 MPI 进程的非均匀柱坐标泊松测试

[English](README.md)

本目录提供一个使用**多个 MPI 进程**的回归测试，用于验证 \f$(r,\alpha,z)\f$ 非均匀正交网格上的三维柱坐标泊松求解器。

测试先构造已知的解析解及其对应的右端项，用 HYPRE 求解泊松方程，将逐点对比数据写入 `phi_compare.dat`，再绘制 `phi_num`、`phi_exact` 和 `abs_error`。

---

## 测试目的

该测试验证以下内容。

- 非均匀柱坐标离散是否正确组装。
- 基于 HYPRE 的求解流程是否正确。
- `r`、`alpha` 和 `z` 方向的 MPI 分解是否正确。
- 数值解是否与解析解一致。
- 非均匀网格上的误差分布是否合理。

这是用于验证正确性的**回归测试**，与性能基准测试用途不同。

---

## 文件说明

- `main_D04_test_multi_mpi_raz.f90` 是主测试程序。它构造全局网格，将计算域分配给各 MPI 进程，构造解析右端项，调用 HYPRE 求解器并写出 `phi_compare.dat`。

- `run_multi_raz.sh` 编译并运行 MPI 测试，然后调用 Python 绘图脚本。

- `clean.sh` 删除可执行文件、编译器生成的文件、`phi_compare.dat` 和生成的图。

- `plot_phi_compare.py` 是 Python 绘图脚本，读取 `phi_compare.dat` 并生成对比图。

- `fig_phi_compare/` 存放全部生成的 PNG 图。

---

## 主要输出文件

运行测试后会生成以下主要输出。

- `phi_compare.dat` 保存逐点对比数据，包含以下各列。
  - 网格索引。
  - 物理坐标。
  - 数值解 `phi_num`。
  - 精确解 `phi_exact`。
  - 绝对误差 `abs_error`。

- `fig_phi_compare/*.png` 包含以下图件。
  - 沿 `r` 方向的线对比图。
  - 沿 `z` 方向的线对比图。
  - `r-z` 切片散点图。
  - `r-z` 切片伪彩色网格图。
  - `x-y` 切片散点图。
  - 相应的 `phi_num`、`phi_exact` 和 `abs_error` 图。

---

## 运行依赖

运行测试需要以下工具和库。

- MPI Fortran 编译器，例如 `mpif90`
- `mpirun`
- HYPRE
- Python 3
- `numpy`
- `matplotlib`

可以用以下命令快速检查 Python 绘图依赖。

```bash
python3 -c "import numpy, matplotlib"
```

---

## 运行方法

```bash
bash run_multi_raz.sh
```

当前简化测试采用以下设置。

- 主程序将 `dims` 固定为 `dims = (/2,2,2/)`。
- 运行脚本应相应使用 `NPROC=8`。

因此，此版本采用**固定的 2 × 2 × 2 MPI 分解**。

---

## `main_D04_test_multi_mpi_raz.f90` 详解

下面按程序的**实际执行顺序**说明，从最先执行的 MPI 调用开始，在用到各变量时再介绍。

下文的行号对应当前的 `main_D04_test_multi_mpi_raz.f90`。

---

## 1. 启动 MPI 并获取进程基本信息

程序从以下调用开始。

```fortran
call mpi_init(ierr)
call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
call mpi_comm_size(mpi_comm_world,mpi_n,ierr)
```

（第 59–61 行。）

这里是程序执行逻辑的起点。

### 各调用的作用

- `mpi_init` 初始化 MPI 运行环境。
- `mpi_comm_rank` 获取当前进程在 `MPI_COMM_WORLD` 中的编号。
- `mpi_comm_size` 获取参与计算的 MPI 进程总数。

### 此处首次用到的变量

这些调用涉及以下变量。

```fortran
integer :: ierr,ierr_h
integer :: mpi_i,mpi_n
```

（第 19–20 行。）

各变量的含义如下。

- `ierr`：MPI 错误码。
- `ierr_h`：后面使用的 HYPRE 错误码，与 `ierr` 分开存储。
- `mpi_i`：当前 MPI 进程编号。
- `mpi_n`：MPI 进程总数。

此时尚未定义网格或泊松问题。程序已经知道**共有多少个进程**，以及**当前进程的编号**。

---

## 2. 定义全局测试规模

MPI 就绪后，程序设置以下参数。

```fortran
nr = 32
na = 16
nz = 32
```

（第 73–75 行。）

它们表示整个问题的**全局**网格尺寸。

- `nr`：径向单元数。
- `na`：方位角方向单元数。
- `nz`：轴向单元数。

对应的声明如下。

```fortran
integer :: nr,na,nz
```

（第 23 行。）

全局单元总数为

\f[
N_{\mathrm{cell}} = n_r \cdot n_{\alpha} \cdot n_z = 32 \cdot 16 \cdot 32.
\f]

这些数值描述整个计算域。局部尺寸随后确定。

---

## 3. 固定 MPI 分解

接下来设置 MPI 分解。

```fortran
dims = (/2,2,2/)
```

（第 77 行。）

早期版本会自动搜索进程数的因数组合。当前简化版本直接给定 MPI 划分。

### `dims` 的含义

对应的声明如下。

```fortran
integer :: dims(1:3),coords(1:3),coords_p(1:3)
```

（第 29 行。）

此处 `dims` 的各分量含义如下。

- `dims(1) = 2`：将 `r` 方向划分为 2 块。
- `dims(2) = 2`：将 `alpha` 方向划分为 2 块。
- `dims(3) = 2`：将 `z` 方向划分为 2 块。

因此，MPI 笛卡尔分块总数为

\f[
2 \cdot 2 \cdot 2 = 8.
\f]

所以这个简化测试应使用 **8 个 MPI 进程**运行。

---

## 4. 创建笛卡尔通信器

接下来执行以下代码。

```fortran
periods_log = (/ .false., .true., .false. /)
reorder = .false.
call mpi_cart_create(mpi_comm_world,3,dims,periods_log,reorder,cart_comm,ierr)
fcomm = cart_comm
```

（第 79–82 行。）

### 此处引入的变量

相关声明如下。

```fortran
integer :: cart_comm,fcomm
logical :: periods_log(1:3),reorder
```

（第 21 和 33 行。）

### 变量含义

- `cart_comm` 是新建的笛卡尔通信器。
- `fcomm` 取 `cart_comm` 的值，随后传给 D04 求解器。
- `periods_log` 告知 MPI 哪些拓扑方向具有周期性。
- `reorder` 指定 MPI 是否可以重新排列进程编号。

### 为什么设置 `periods_log = (/ .false., .true., .false. /)`

三个逻辑方向按以下顺序排列。

\f$(r,\alpha,z)\f$.

因此，设置

```fortran
periods_log = (/ .false., .true., .false. /)
```

表示

- `r` 方向为非周期方向。
- `alpha` 方向为周期方向。
- `z` 方向为非周期方向。

这与问题的物理设置一致。

---

## 5. 查询当前进程在笛卡尔网格中的位置

接下来执行以下调用。

```fortran
call mpi_comm_rank(cart_comm,mpi_i,ierr)
call mpi_cart_coords(cart_comm,mpi_i,3,coords,ierr)
```

（第 84–85 行。）

### 为什么再次查询进程编号

第一次调用 `mpi_comm_rank` 时使用的是 `MPI_COMM_WORLD`。后续测试使用笛卡尔通信器，所以这里查询当前进程在 `cart_comm` 中的编号。

### `coords` 的含义

`coords(1:3)` 给出当前进程的逻辑笛卡尔坐标。

- `coords(1)`：`r` 方向划分中的进程坐标。
- `coords(2)`：`alpha` 方向划分中的进程坐标。
- `coords(3)`：`z` 方向划分中的进程坐标。

例如，某进程的坐标为

```text
coords = (1,0,1)
```

则该进程位于以下各块。

- `r` 方向的第二块。
- `alpha` 方向的第一块。
- `z` 方向的第二块。

---

## 6. 将笛卡尔坐标转换为负责的索引范围

接下来执行三个调用。

```fortran
call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))
```

（第 87–89 行。）

这些调用把 MPI 拓扑坐标转换为当前进程实际负责的全局索引范围。

### 相关变量

```fortran
integer :: il_loc(1:3),iu_loc(1:3),periodic(1:3)
integer :: nloc,nr_loc,na_loc,nz_loc
```

（第 25 和 30 行。）

各变量的含义如下。

- `il_loc(d)`：进程在方向 `d` 上负责的全局索引下界。
- `iu_loc(d)`：进程在方向 `d` 上负责的全局索引上界。
- `nr_loc`、`na_loc`、`nz_loc`：局部网格尺寸。
- `nloc`：当前进程的局部单元总数。

执行上述三次调用后，程序进行以下计算。

```fortran
nr_loc = iu_loc(1)-il_loc(1)+1
na_loc = iu_loc(2)-il_loc(2)+1
nz_loc = iu_loc(3)-il_loc(3)+1
nloc = nr_loc*na_loc*nz_loc
```

（第 91–94 行。）

若当前进程负责的索引范围为

```text
[i_min, i_max] x [j_min, j_max] x [k_min, k_max]
```

则

\f[
n_{r,\mathrm{loc}} = i_{\max} - i_{\min} + 1,
\f]

\f[
n_{\alpha,\mathrm{loc}} = j_{\max} - j_{\min} + 1,
\f]

\f[
n_{z,\mathrm{loc}} = k_{\max} - k_{\min} + 1,
\f]

并且

\f[
n_{\mathrm{loc}} = n_{r,\mathrm{loc}} \cdot n_{\alpha,\mathrm{loc}} \cdot n_{z,\mathrm{loc}}.
\f]

---

## 7. `partition_1d` 的工作原理

这个辅助子程序定义在第 387–403 行，是 MPI 分块的关键步骤之一。

代码如下。

```fortran
subroutine partition_1d(n_global,n_parts,coord,ilo,ihi)
    implicit none
    integer :: n_global,n_parts,coord,ilo,ihi
    integer :: base,rem_1d,n_local

    base = n_global/n_parts
    rem_1d = mod(n_global,n_parts)

    if (coord < rem_1d) then
        n_local = base + 1
        ilo = coord*n_local + 1
    else
        n_local = base
        ilo = rem_1d*(base+1) + (coord-rem_1d)*base + 1
    end if
    ihi = ilo + n_local - 1
end subroutine partition_1d
```

### 第一步：计算 `n_global` 的商和余数

子程序先进行以下计算。

\f[
n_{\mathrm{global}} = \mathrm{base} \cdot n_{\mathrm{parts}} + \mathrm{rem}_{1d},
\f]

对应的表达式为

\f[
0 \le \mathrm{rem}_{1d} < n_{\mathrm{parts}}.
\f]

其中

- `base = n_global / n_parts`
- `rem_1d = mod(n_global,n_parts)`

`base` 是每一块至少分到的单元数，`rem_1d` 是余下的单元数。

### 第二步：将余下的单元分给前几块

若

```fortran
coord < rem_1d
```

则当前块多分到一个单元。

\f[
n_{\mathrm{local}} = \mathrm{base} + 1.
\f]

其余块采用基本大小。

\f[
n_{\mathrm{local}} = \mathrm{base}.
\f]

这样可以尽量均衡分块，各块的局部单元数最多相差一个。

### 第三步：计算负责范围的起始索引 `ilo`

前 `rem_1d` 块的大小均为 `base+1`，因此起始索引为

\f[
i_{\mathrm{lo}} = \mathrm{coord} \cdot (\mathrm{base} + 1) + 1.
\f]

代码中写作

```fortran
ilo = coord*n_local + 1
```

因为在这个分支中 `n_local = base + 1`。

较大的块已排在前面，后续块的起始索引需要依次越过以下两部分。

- `rem_1d` 个大小为 `base+1` 的大块。
- `(coord-rem_1d)` 个大小为 `base` 的普通块。

因此得到

\f[
i_{\mathrm{lo}} = \mathrm{rem}_{1d} \cdot (\mathrm{base} + 1) + (\mathrm{coord} - \mathrm{rem}_{1d}) \cdot \mathrm{base} + 1,
\f]

这就是第 400 行的公式。

### 第四步：计算负责范围的结束索引 `ihi`

根据 `ilo` 和 `n_local` 可计算结束索引。

\f[
i_{\mathrm{hi}} = i_{\mathrm{lo}} + n_{\mathrm{local}} - 1.
\f]

对应第 402 行。

### 示例

假设

\f[
n_{\mathrm{global}} = 10, \qquad n_{\mathrm{parts}} = 3.
\f]

则

\f[
\mathrm{base} = 3, \qquad \mathrm{rem}_{1d} = 1.
\f]

各块的大小为

\f[
4,\ 3,\ 3.
\f]

对应的索引范围如下。

- `coord = 0` 得到 `ilo = 1`、`ihi = 4`。
- `coord = 1` 得到 `ilo = 5`、`ihi = 7`。
- `coord = 2` 得到 `ilo = 8`、`ihi = 10`。

这样得到的分块大小基本均匀。

---

## 8. 定义物理参数和边界条件

当前进程确定所负责的网格块后，程序先设置以下参数。

```fortran
eps0 = 1.0
rmin = 0.0
rmax = 1.0
lz = 1.0
tolerance = 1.0e-10
```

（第 96–100 行。）然后设置

```fortran
periodic = (/0,na,0/)
bc_type = (/BC_AXIS,BC_DIRICHLET,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
bc_value = 0.0
```

（第 102–104 行。）

### 参数含义

对应的声明如下。

```fortran
real :: eps0,rmin,rmax,lz,tolerance
real :: bc_value(1:6)
integer :: bc_type(1:6)
integer :: il_loc(1:3),iu_loc(1:3),periodic(1:3)
```

各变量含义如下。

- `eps0`：泊松方程中的介电常数。
- `rmin`、`rmax`：计算域的径向边界。
- `lz`：计算域在 `z` 方向的长度。
- `tolerance`：求解器容差。
- `periodic`：传给 HYPRE 的周期性描述。
- `bc_type`：六个面的边界类型。
- `bc_value`：边界值数组。

### `bc_type` 中的边界顺序

六个元素依次对应

1. `r` 下侧。
2. `r` 上侧。
3. `alpha` 下侧。
4. `alpha` 上侧。
5. `z` 下侧。
6. `z` 上侧。

因此，以下设置

```fortran
bc_type = (/BC_AXIS,BC_DIRICHLET,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
```

表示

- `r = 0` 处采用轴线处理。
- 外半径处采用狄利克雷边界。
- `alpha` 方向为周期方向，无需显式边界。
- `z` 两端均采用狄利克雷边界。

### `periodic = (/0,na,0/)` 的含义

这是 HYPRE 的周期位移表示，含义如下。

- `r` 方向无周期性。
- `alpha` 方向以完整的方位角网格长度 `na` 为周期。
- `z` 方向无周期性。

---

## 9. 用 `mpi_cart_shift` 查找相邻进程

接下来的关键代码如下。

```fortran
call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)
```

（第 106–108 行。）

### 此处引入的变量

```fortran
integer :: nbr_r_lo,nbr_r_hi,nbr_a_lo,nbr_a_hi,nbr_z_lo,nbr_z_hi
logical :: has_neighbor(1:6)
```

（第 27 和 34 行。）

### `mpi_cart_shift` 参数的含义

MPI 接口如下。

```fortran
call mpi_cart_shift(comm,direction,disp,rank_source,rank_dest,ierr)
```

在本程序中，各参数含义如下。

- `comm = cart_comm`：使用笛卡尔通信器。
- `direction = 0,1,2`：选择要查询的逻辑方向。
- `disp = 1`：移动**一个相邻块**。
- `rank_source`：返回负方向上的相邻进程。
- `rank_dest`：返回正方向上的相邻进程。

下面对应到三次实际调用。

### 第一次调用

```fortran
call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
```

各参数含义如下。

- `0` 表示**第一个笛卡尔方向**，即本程序的 `r` 方向。
- `1` 表示**移动一步**。
- `nbr_r_lo` 接收 `r` 下侧的相邻进程编号。
- `nbr_r_hi` 接收 `r` 上侧的相邻进程编号。

### 第二次调用

```fortran
call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
```

各参数含义如下。

- 第一个 `1` 表示**第二个笛卡尔方向**，即 `alpha`。
- 第二个 `1` 同样表示**移动一步**。
- `nbr_a_lo` 和 `nbr_a_hi` 分别是 `alpha` 下侧和上侧的相邻进程。

`alpha` 方向为周期方向，必要时会跨周期边界查找相邻进程。

### 第三次调用

```fortran
call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)
```

各参数含义如下。

- `2` 表示**第三个笛卡尔方向**，即 `z`。
- `1` 同样表示**移动一块**。
- `nbr_z_lo` 和 `nbr_z_hi` 分别是 `z` 下侧和上侧的相邻进程。

### 这些信息的用途

调用完成后，程序就知道局部 MPI 网格块的每个面是与另一进程相接，还是位于物理边界。

这些信息被转换成以下布尔标记。

```fortran
has_neighbor(1) = (nbr_r_lo /= MPI_PROC_NULL)
has_neighbor(2) = (nbr_r_hi /= MPI_PROC_NULL)
has_neighbor(3) = (nbr_a_lo /= MPI_PROC_NULL)
has_neighbor(4) = (nbr_a_hi /= MPI_PROC_NULL)
has_neighbor(5) = (nbr_z_lo /= MPI_PROC_NULL)
has_neighbor(6) = (nbr_z_hi /= MPI_PROC_NULL)
```

（第 110–115 行。）

因此，`has_neighbor(face)` 回答的是以下问题。

> 这个局部面是否与另一个 MPI 进程相接？

组装矩阵时需要这些标记。

---

## 10. 定义方位角间距

接下来设置间距。

```fortran
da0 = 2.0*pi/real(na)
```

（第 117 行。）

相关声明如下。

```fortran
real,parameter :: pi = 3.14159265358979323846
real :: da0
```

（第 16 和 37 行。）

这表示方位角方向采用均匀间距，数值为

\f[
\Delta \alpha = \frac{2\pi}{n_{\alpha}}.
\f]

因此后面用到的方位角单元中心坐标为

\f[
\alpha_j = \left(j - \frac{1}{2}\right)\Delta \alpha.
\f]

---

## 11. 分配全局网格数组

程序随后分配以下数组。

```fortran
allocate(dr_global(1:nr))
allocate(da_global(1:na))
allocate(dz_global(1:nz))
allocate(wr(1:nr))
allocate(wz(1:nz))
allocate(rcell_global(1:nr))
allocate(zcell_global(1:nz))
allocate(rface_global(0:nr))
allocate(zface_global(0:nz))
```

（第 119–127 行。）

### 各数组的作用

第 47–50 行声明的数组含义如下。

- `dr_global(i)`：全局径向单元宽度。
- `da_global(j)`：全局方位角单元宽度。
- `dz_global(k)`：全局轴向单元宽度。
- `wr(i)`：临时径向权重。
- `wz(k)`：临时轴向权重。
- `rface_global(0:nr)`：径向单元面坐标。
- `zface_global(0:nz)`：轴向单元面坐标。
- `rcell_global(i)`：径向单元中心坐标。
- `zcell_global(k)`：轴向单元中心坐标。

每个进程都构造相同的全局网格描述。然后，各进程提取自己负责的部分，并交换一层幽灵单元的宽度。

---

## 12. 构造非均匀径向网格

径向网格在第 133–155 行生成。

首先设置以下参数。

```fortran
beta_r = 4.0
```

（第 133 行。）`beta_r` 声明在第 38 行。

### 第一步：定义径向权重

代码使用以下公式。

```fortran
s = real(i-1)/real(nr-1)
wr(i) = 1.0 + beta_r*s*s
```

（第 138–139 行。）

`s` 从 0 变化到 1，权重沿径向二次增长。因此，`r` 越大的单元越宽。

### 第二步：将权重归一化为实际单元宽度

程序随后计算以下数值。

```fortran
wsum = sum(wr(1:nr))
dr_global(i) = (rmax-rmin)*wr(i)/wsum
```

（第 143–146 行。）

这样保证

\f[
\sum_{i=1}^{n_r} \Delta r_i = r_{\max} - r_{\min}.
\f]

### 第三步：构造单元面坐标

代码通过累加宽度计算单元面坐标。

```fortran
rface_global(0) = rmin
do i = 1,nr
    rface_global(i) = rface_global(i-1) + dr_global(i)
end do
```

（第 148–151 行。）

因此

\f[
r_{i+1/2} = r_{i-1/2} + \Delta r_i.
\f]

### 第四步：构造单元中心

最后计算单元中心。

```fortran
rcell_global(i) = 0.5*(rface_global(i-1) + rface_global(i))
```

（第 153–155 行。）因此

\f[
r_i = 0.5 \cdot \left(r_{i-1/2} + r_{i+1/2}\right).
\f]

---

## 13. 构造方位角网格

这一部分直接使用均匀间距。

```fortran
do j = 1,na
    da_global(j) = da0
end do
```

（第 157–159 行。）

因此，每个方位角单元的宽度均为

\f[
\Delta \alpha_j = \Delta \alpha = \frac{2\pi}{n_{\alpha}}.
\f]

---

## 14. 构造非均匀轴向网格

轴向网格在第 161–183 行构造。

程序先设置以下参数。

```fortran
beta_z = 4.0
```

（第 161 行。）

然后用以下公式定义权重。

```fortran
s = real(k-1)/real(nz-1)
wz(k) = 1.0 + beta_z*(1.0 - (2.0*s - 1.0)**2)
```

（第 166–167 行。）

### 权重分布的含义

函数

\f[
1 - (2s - 1)^2
\f]

在区间中部附近最大，在两端较小。因此，`z` 方向的间距分布与径向不同，较大的权重集中在计算域中部附近。

接着，程序对宽度进行归一化。

```fortran
wsum = sum(wz(1:nz))
dz_global(k) = lz*wz(k)/wsum
```

（第 171–174 行。）这样保证

\f[
\sum_{k=1}^{n_z} \Delta z_k = L_z.
\f]

最后构造单元面和单元中心坐标。

```fortran
zface_global(0) = 0.0
do k = 1,nz
    zface_global(k) = zface_global(k-1) + dz_global(k)
end do

do k = 1,nz
    zcell_global(k) = 0.5*(zface_global(k-1) + zface_global(k))
end do
```

（第 176–182 行。）

---

## 15. 分配局部间距数组，并在每侧留出一个幽灵宽度

接下来分配以下数组。

```fortran
allocate(dr(il_loc(1)-1:iu_loc(1)+1))
allocate(da(il_loc(2)-1:iu_loc(2)+1))
allocate(dz(il_loc(3)-1:iu_loc(3)+1))
```

（第 185–187 行。）

这些数组在第 51 行声明。

### 下标范围为何扩展 `-1` 和 `+1`

每个进程存储以下宽度。

- 自己负责的各单元宽度。
- 下侧的一个幽灵宽度。
- 上侧的一个幽灵宽度。

因此，数组的下标范围在负责区间的两端各扩展一位。

随后，程序将数组清零，并仅从对应的全局数组复制自己负责的宽度（第 189–200 行）。

---

## 16. 交换一层幽灵宽度

接下来执行以下调用。

```fortran
call exchange_ghost_width(cart_comm,nbr_r_lo,nbr_r_hi,101,102,dr,il_loc(1),iu_loc(1))
call exchange_ghost_width(cart_comm,nbr_a_lo,nbr_a_hi,201,202,da,il_loc(2),iu_loc(2))
call exchange_ghost_width(cart_comm,nbr_z_lo,nbr_z_hi,301,302,dz,il_loc(3),iu_loc(3))
```

（第 203–205 行。）

这样填充两侧各一层幽灵单元的宽度。

### 为什么需要交换

在 MPI 子域交界面附近组装矩阵时，仍需要界面另一侧相邻单元的宽度。因此，每个进程负责自己的局部块，同时还需要各方向上相邻单元的宽度。

辅助子程序 `exchange_ghost_width` 定义在第 405–418 行，用 `mpi_sendrecv` 在每侧交换一个标量宽度。

---

## 17. 定义局部径向起始面的坐标

以下语句

```fortran
rface_lo = rface_global(il_loc(1)-1)
```

（第 207 行）设置第一个局部单元下侧径向面的物理位置。

对应的声明如下。

```fortran
real :: rface_lo
```

（第 44 行。）

此值随后传给局部矩阵组装例程，使例程能够确定局部块在物理空间中的起点。

---

## 18. 分配数值解、精确解、右端项和矩阵数组

程序随后分配以下数组。

```fortran
allocate(phi1d(1:nloc))
allocate(phi_exact(1:nloc))
allocate(rho1d(1:nloc))
allocate(RHS(1:nloc))
allocate(A_values(1:7*nloc))
```

（第 209–213 行。）

### 各数组的含义

第 52 行声明的数组含义如下。

- `phi1d`：求解器返回的数值解。
- `phi_exact`：在局部单元上采样的解析精确解。
- `rho1d`：在局部单元上采样的解析源项。
- `RHS`：实际传给 HYPRE 的右端项。
- `A_values`：局部矩阵的模板系数。

### `A_values` 为什么有 `7*nloc` 个元素

本程序使用结构化七点模板，包含以下位置。

- 中心。
- `-r`、`+r`。
- `-alpha`、`+alpha`。
- `-z`、`+z`。

因此，每个局部单元对应 7 个系数。

---

## 19. 初始化 HYPRE 控制标志和句柄

接下来执行以下代码。

```fortran
do_init = .false.
do_updateA = .false.
do_finalize = .false.
grid = 0_8
stencil = 0_8
A = 0_8
b = 0_8
x = 0_8
```

（第 221–228 行。）

这些变量在第 56–57 行声明。

### 变量含义

包装例程 `sub_D04_hypre_3Draz_nonuniform` 根据以下逻辑标志决定执行的操作。

- `do_init`：创建并初始化 HYPRE 对象。
- `do_updateA`：更新矩阵，无需重建所有对象。
- `do_finalize`：销毁 HYPRE 对象。

以下 `integer(8)` 变量为 HYPRE 句柄。

- `grid`
- `stencil`
- `A`
- `b`
- `x`

第一次调用前，这些句柄都初始化为零。

---

## 20. 定义解析解的参数

接下来的代码如下。

```fortran
kappa = j1_zero_1/rmax
mu = pi/lz
```

（第 230–231 行。）

对应的声明如下。

```fortran
real,parameter :: j1_zero_1 = 3.8317059702075123156
real,parameter :: pi = 3.14159265358979323846
real :: kappa,mu
```

（第 16–17 和 40 行。）

本测试采用的解析解为

\f[
\phi(r,\alpha,z) = J_1(\kappa r) \cdot \cos(\alpha) \cdot \sin(\mu z),
\f]

其中

\f[
\kappa = \frac{j_{1,1}}{r_{\max}},
\f]

\f[
\mu = \frac{\pi}{L_z},
\f]

\f$j_{1,1}\f$ 为 \f$J_1\f$ 的第一个零点。

---

## 21. 在局部单元中心采样解析解和源项

主采样循环位于第 233–249 行。

```fortran
l = 1
do k = il_loc(3),iu_loc(3)
do j = il_loc(2),iu_loc(2)
do i = il_loc(1),iu_loc(1)
    r = rcell_global(i)
    alpha = (real(j)-0.5)*da0
    z = zcell_global(k)

    phi_ex = bessel_j1(kappa*r)*cos(alpha)*sin(mu*z)
    rho_ex = eps0*(kappa*kappa + mu*mu)*phi_ex

    phi_exact(l) = phi_ex
    rho1d(l) = rho_ex
    l = l + 1
end do
end do
end do
```

### 为什么使用这些坐标

代码在**单元中心**采样。

\f[
r = r_i,
\f]

\f[
\alpha = \left(j - \frac{1}{2}\right)\Delta \alpha,
\f]

\f[
z = z_k.
\f]

因此，精确场的求值位置与单元中心未知量的物理位置相同。

### 源项为何采用这种形式

对于泊松方程

\f[
\nabla^2 \phi = -\rho / \varepsilon_0,
\f]

选取的解析模态满足

\f[
\rho = \varepsilon_0 \cdot (\kappa^2 + \mu^2) \cdot \phi.
\f]

因此，`rho_ex` 是与所选精确解对应的源项。

### `l` 的含义

求解器将局部块存为一维向量。因此，`l` 是与 `(i,j,k)` 三重循环对应的展平局部索引。

---

## 22. 初始化 HYPRE 并组装局部系统

程序随后调用

```fortran
call HYPRE_Initialize(ierr_h)
```

（第 251 行），接着调用

```fortran
call sub_D04_hypre_3Draz_nonuniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
    periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)
```

（第 253–254 行。）

### 组装例程使用的数据

例程接收以下数据。

- 当前进程负责的局部索引范围 `il_loc:iu_loc`。
- 局部径向起始位置 `rface_lo`。
- 含幽灵宽度的局部间距 `dr, da, dz`。
- 周期性信息。
- 相邻进程标记 `has_neighbor`。
- 边界类型及边界值。
- 解析源项 `rho1d`。

并生成以下数组。

- `A_values`：局部模板系数。
- `RHS`：局部右端项。

这一步构造离散线性系统。

---

## 23. 通过 D04 HYPRE 包装例程求解

接下来的两次调用完成求解阶段。

### 第一次调用：初始化对象并求解

```fortran
do_init = .true.
do_updateA = .false.
do_finalize = .false.
call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
    tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
    grid,stencil,A,b,x)
```

（第 256–261 行。）

此调用创建 HYPRE 对象，载入矩阵与向量，执行求解，并在 `phi1d` 中返回局部数值解。

### 第二次调用：销毁 HYPRE 对象

```fortran
do_init = .false.
do_updateA = .false.
do_finalize = .true.
call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
    tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
    grid,stencil,A,b,x)
```

（第 263–268 行。）

此调用通过同一个包装接口释放这些对象。

之后调用

```fortran
call HYPRE_Finalize(ierr_h)
```

（第 270 行）结束 HYPRE 库的使用。

---

## 24. 计算局部误差范数

接下来在第 275–293 行计算局部误差。

代码将下列量清零

```fortran
err_linf_loc = 0.0
err_l2_loc = 0.0
ref_l2_loc = 0.0
```

然后再次遍历当前进程负责的单元。

关键公式如下。

```fortran
diff = phi1d(l)-phi_exact(l)
vol = rcell_global(i)*dr_global(i)*da_global(j)*dz_global(k)
```

（第 283–284 行。）

### 单元体积为何采用此形式

柱坐标中的体积元为

\f[
dV = r \cdot dr \cdot d(\alpha) \cdot dz.
\f]

所以程序使用以下单元中心近似。

\f[
V_{ijk} \approx r_i \cdot \Delta r_i \cdot \Delta \alpha_j \cdot \Delta z_k.
\f]

对应第 284 行的计算。

随后，程序累加以下各项。

```fortran
err_linf_loc = max(err_linf_loc,abs(diff))
err_l2_loc = err_l2_loc + diff*diff*vol
ref_l2_loc = ref_l2_loc + phi_exact(l)*phi_exact(l)*vol
```

（第 286–288 行。）

各局部误差量含义如下。

- `err_linf_loc` 是最大绝对误差。
- `err_l2_loc` 是加权误差平方积分。
- `ref_l2_loc` 是加权精确解平方积分。

---

## 25. 将局部误差归约到根进程

程序用以下调用汇总各进程的贡献。

```fortran
call mpi_reduce(err_linf_loc,err_linf,1,MPI_DOUBLE_PRECISION,MPI_MAX,0,cart_comm,ierr)
call mpi_reduce(err_l2_loc,err_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
call mpi_reduce(ref_l2_loc,ref_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
```

（第 295–297 行。）

### 归约方式

- 全局 `L_inf` 误差采用 `MPI_MAX`。
- 全局加权 `L2` 分子采用 `MPI_SUM`。
- 全局加权参考范数项采用 `MPI_SUM`。

随后，进程 0 计算

```fortran
err_l2 = sqrt(err_l2/max(ref_l2,tiny(1.0)))
```

（第 300 行），对应以下相对范数。

\f[
\lVert \phi_h - \phi \rVert_{L2} / \lVert \phi \rVert_{L2}.
\f]

---

## 26. 打印全局汇总和进程分块表

在下面的代码块中

```fortran
if (mpi_i == 0) then
```

（第 299–326 行），进程 0 打印以下信息。

- 解析解公式。
- `r` 和 `z` 方向使用非均匀网格。
- MPI 进程总数。
- 固定分解 `dims`。
- `beta_r`、`beta_z`、`kappa`。
- `nr,na,nz`。
- `min(dr), max(dr)`。
- `min(dz), max(dz)`。
- 误差范数。

进程 0 也遍历所有进程，重建各自的笛卡尔坐标，对每个方向再次调用 `partition_1d`，并打印各进程负责的全局网格块。

这些调试输出可用来检查实际的三维 MPI 分块布局。

---

## 27. 将分布式解汇集到进程 0

为写出一个全局输出文件，进程 0 分配以下数组。

```fortran
allocate(phi_all(1:nr,1:na,1:nz))
allocate(phi_exact_all(1:nr,1:na,1:nz))
```

（第 329–330 行。）

这些数组在第 54 行声明。

它们存储完整的全局数值解和精确解。

进程 0 先用以下调用填入自己的局部块。

```fortran
call unpack_block(phi1d,phi_all,il_loc,iu_loc)
call unpack_block(phi_exact,phi_exact_all,il_loc,iu_loc)
```

（第 334–335 行。）

然后，从其余各进程分别接收以下数据。

1. 含全局网格块边界的消息头。
2. 局部数值解块。
3. 局部精确解块。

这段逻辑位于第 337–348 行。

---

## 28. 显式汇集的数据格式

非根进程发送以下数据。

```fortran
header = (/il_loc(1),iu_loc(1),il_loc(2),iu_loc(2),il_loc(3),iu_loc(3)/)
call mpi_send(header,6,MPI_INTEGER,0,401,cart_comm,ierr)
call mpi_send(phi1d,nloc,MPI_DOUBLE_PRECISION,0,402,cart_comm,ierr)
call mpi_send(phi_exact,nloc,MPI_DOUBLE_PRECISION,0,403,cart_comm,ierr)
```

（第 367–370 行。）

`header` 编码当前进程负责的确切全局网格块。进程 0 收到消息头后，就知道传入块的形状及其在全局三维数组中的位置。

这是手动汇集的方式，数据布局直观，适合回归测试。

---

## 29. 写出 `phi_compare.dat`

进程 0 收集全部局部块后，先写入表头。

```fortran
open(unit=1001,file='phi_compare.dat',status='replace')
write(1001,*) '# i j k r alpha z phi_num phi_exact abs_error'
```

（第 351–352 行。）

接着遍历所有全局单元，写出以下各列。

- `i, j, k`
- `r, alpha, z`
- `phi_num`
- `phi_exact`
- `abs_error`

这里采用与前面相同的单元中心坐标公式（第 354–361 行）。

因此，绘图脚本可以直接从一个文件重建全局切片。

---

## 30. 释放数组并结束 MPI

最后，程序释放所有数组（第 373–381 行）并调用

```fortran
call mpi_finalize(ierr)
```

（第 383 行。）

至此 MPI 程序结束。

---

## 31. 辅助子程序 `exchange_ghost_width`

这个辅助子程序定义在第 405–418 行。

它在局部间距数组两侧各交换一个标量宽度。对于以下数组

```text
arr(ilo-1 : ihi+1)
```

当前进程负责的数据存放在 `arr(ilo:ihi)`，两个幽灵位置如下。

- 下侧的 `arr(ilo-1)`。
- 上侧的 `arr(ihi+1)`。

例程执行两次 `mpi_sendrecv` 调用。

1. 将负责范围下边界的值 `arr(ilo)` 发送给下侧邻居，同时从上侧邻居接收上侧幽灵值，存入 `arr(ihi+1)`。
2. 将负责范围上边界的值 `arr(ihi)` 发送给上侧邻居，同时从下侧邻居接收下侧幽灵值，存入 `arr(ilo-1)`。

这些网格宽度正是 MPI 交界面附近的局部有限体积组装所需的信息。

---

## 32. 辅助子程序 `unpack_block`

这个辅助子程序从第 420 行开始定义。

它将局部一维缓冲区恢复为全局三维数组中的一个块，接收以下数据。

- `buf(:)`：展平后的局部数据。
- `field(:,:,:)`：目标全局三维数组。
- `il_box(1:3), iu_box(1:3)`：数据所在全局块的索引范围。

然后按以下顺序遍历

```fortran
kk -> jj -> ii
```

并逐项填入目标网格块。

这个过程与求解器向量使用的局部展平过程互为逆过程。

---

## 33. 主程序执行流程

主程序的完整执行顺序如下。

1. 初始化 MPI。
2. 定义全局问题规模。
3. 固定 MPI 分解 `dims = (/2,2,2/)`。
4. 创建笛卡尔通信器。
5. 获取当前进程的笛卡尔坐标。
6. 将坐标转换为当前进程负责的全局索引范围。
7. 定义物理参数及边界类型。
8. 用 `mpi_cart_shift` 获取相邻进程。
9. 构造全局非均匀网格。
10. 提取局部宽度并交换一层幽灵宽度。
11. 采样解析精确解和源项。
12. 组装局部矩阵和右端项。
13. 用 HYPRE 求解。
14. 计算误差范数。
15. 将分布式解汇集到进程 0。
16. 写出 `phi_compare.dat`。
17. 结束 HYPRE 和 MPI。

以上是 `main_D04_test_multi_mpi_raz.f90` 的实际执行流程。
