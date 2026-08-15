import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from pathlib import Path
# =========================================================
# input files
# =========================================================
par_file = "./build/output_case04_hollowH_par.dat"
den_file = "./build/output_case04_hollowH_den.dat"

# =========================================================
# slice positions
# these should match the printed suggested slices
# =========================================================
k0 = 5   # xy slice at k = 5
j0 = 5   # xz slice at j = 5
i0 = 5   # yz slice at i = 5

# =========================================================
# read particle coordinates
# =========================================================
par_data = np.loadtxt(par_file, comments="#")
xp = par_data[:, 1]
yp = par_data[:, 2]
zp = par_data[:, 3]

# =========================================================
# read deposited density
# =========================================================
den_data = np.loadtxt(den_file, comments="#")
ii = den_data[:, 0].astype(int)
jj = den_data[:, 1].astype(int)
kk = den_data[:, 2].astype(int)
vv = den_data[:, 3]

# grid ranges
i_min, i_max = ii.min(), ii.max()
j_min, j_max = jj.min(), jj.max()
k_min, k_max = kk.min(), kk.max()

ni = i_max - i_min + 1
nj = j_max - j_min + 1
nk = k_max - k_min + 1

den = np.zeros((ni, nj, nk))

for a, b, c, val in zip(ii, jj, kk, vv):
    den[a - i_min, b - j_min, c - k_min] = val

# =========================================================
# extract slices
# =========================================================
xy_slice = den[:, :, k0 - k_min]
xz_slice = den[:, j0 - j_min, :]
yz_slice = den[i0 - i_min, :, :]

# =========================================================
# coordinates for plotting
# =========================================================
x_nodes = np.arange(i_min, i_max + 1)
y_nodes = np.arange(j_min, j_max + 1)
z_nodes = np.arange(k_min, k_max + 1)

# =========================================================
# create figure
# =========================================================
fig = plt.figure(figsize=(14, 10))

# ---------------------------------------------------------
# 1. 3D particle layout
# ---------------------------------------------------------
ax1 = fig.add_subplot(2, 2, 1, projection='3d')
ax1.scatter(xp, yp, zp, s=30)

# draw slice planes
xx, yy = np.meshgrid(
    np.linspace(x_nodes.min(), x_nodes.max(), 2),
    np.linspace(y_nodes.min(), y_nodes.max(), 2)
)
zz = np.full_like(xx, k0 + 0.5)
ax1.plot_surface(xx, yy, zz, alpha=0.15)

xx, zz = np.meshgrid(
    np.linspace(x_nodes.min(), x_nodes.max(), 2),
    np.linspace(z_nodes.min(), z_nodes.max(), 2)
)
yy = np.full_like(xx, j0 + 0.5)
ax1.plot_surface(xx, yy, zz, alpha=0.15)

yy, zz = np.meshgrid(
    np.linspace(y_nodes.min(), y_nodes.max(), 2),
    np.linspace(z_nodes.min(), z_nodes.max(), 2)
)
xx = np.full_like(yy, i0 + 0.5)
ax1.plot_surface(xx, yy, zz, alpha=0.15)

ax1.set_title("3D particle layout")
ax1.set_xlabel("x")
ax1.set_ylabel("y")
ax1.set_zlabel("z")
ax1.view_init(elev=22, azim=35)

# ---------------------------------------------------------
# 2. xy slice
# ---------------------------------------------------------
ax2 = fig.add_subplot(2, 2, 2)
im2 = ax2.imshow(
    xy_slice.T,
    origin="lower",
    extent=[x_nodes.min(), x_nodes.max(), y_nodes.min(), y_nodes.max()],
    aspect="equal"
)
ax2.set_title(f"XY slice at k = {k0}")
ax2.set_xlabel("i")
ax2.set_ylabel("j")
fig.colorbar(im2, ax=ax2, fraction=0.046, pad=0.04)

# ---------------------------------------------------------
# 3. xz slice
# ---------------------------------------------------------
ax3 = fig.add_subplot(2, 2, 3)
im3 = ax3.imshow(
    xz_slice.T,
    origin="lower",
    extent=[x_nodes.min(), x_nodes.max(), z_nodes.min(), z_nodes.max()],
    aspect="equal"
)
ax3.set_title(f"XZ slice at j = {j0}")
ax3.set_xlabel("i")
ax3.set_ylabel("k")
fig.colorbar(im3, ax=ax3, fraction=0.046, pad=0.04)

# ---------------------------------------------------------
# 4. yz slice
# ---------------------------------------------------------
ax4 = fig.add_subplot(2, 2, 4)
im4 = ax4.imshow(
    yz_slice.T,
    origin="lower",
    extent=[y_nodes.min(), y_nodes.max(), z_nodes.min(), z_nodes.max()],
    aspect="equal"
)
ax4.set_title(f"YZ slice at i = {i0}")
ax4.set_xlabel("j")
ax4.set_ylabel("k")
fig.colorbar(im4, ax=ax4, fraction=0.046, pad=0.04)

plt.tight_layout()
plt.savefig("./build/result_many.png", dpi=200)
#plt.show()

