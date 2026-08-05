import glob
import os
from pathlib import Path
import textwrap

import matplotlib.pyplot as plt
import numpy as np

STANDARD_FIGSIZE = (13.5, 4.8)
DEFAULT_DPI = 300


def apply_plot_style(font_size: int = 12) -> None:
    plt.rcParams.update(
        {
            "font.size": font_size,
            "axes.titlesize": font_size,
            "axes.labelsize": font_size,
            "legend.fontsize": font_size - 1,
            "xtick.labelsize": font_size - 1,
            "ytick.labelsize": font_size - 1,
            "figure.figsize": STANDARD_FIGSIZE,
            "figure.dpi": DEFAULT_DPI,
            "savefig.dpi": DEFAULT_DPI,
            "lines.linewidth": 1.8,
            "lines.markersize": 5,
        }
    )


def new_subplots(*args, figsize=STANDARD_FIGSIZE, **kwargs):
    kwargs.setdefault("constrained_layout", True)
    return plt.subplots(*args, figsize=figsize, **kwargs)


def savefig(path: str, dpi: int = DEFAULT_DPI) -> None:
    plt.savefig(path, dpi=dpi)
    plt.close()


def build_title(prefix: str, subject: str, context: str | None = None, width: int = 68) -> str:
    return textwrap.fill(f"{prefix}: {subject}", width=width)


def current_test_name(script_path: str) -> str:
    return Path(script_path).resolve().parent.name

apply_plot_style(font_size=12)
TEST_NAME = current_test_name(__file__)


def build_grid(data, j0=8):
    i = data[:, 0].astype(int)
    j = data[:, 1].astype(int)
    k = data[:, 2].astype(int)
    phi_num = data[:, 3]
    phi_exact = data[:, 4]
    phi_err = data[:, 5]

    mask = j == j0

    i_unique = np.unique(i[mask])
    k_unique = np.unique(k[mask])

    exact_grid = np.full((i_unique.size, k_unique.size), np.nan)
    num_grid = np.full((i_unique.size, k_unique.size), np.nan)
    err_grid = np.full((i_unique.size, k_unique.size), np.nan)

    for ii, kk, vv_num, vv_ex, vv_err in zip(
        i[mask], k[mask], phi_num[mask], phi_exact[mask], phi_err[mask]
    ):
        ix = np.where(i_unique == ii)[0][0]
        kz = np.where(k_unique == kk)[0][0]

        exact_grid[ix, kz] = vv_ex
        num_grid[ix, kz] = vv_num
        err_grid[ix, kz] = vv_err

    return exact_grid, num_grid, err_grid


def field_limits_from_exact(exact_grid, pad_frac=0.05, min_pad=1.0e-3):
    """
    用 phi_exact 的物理范围作为 phi_exact 和 phi_num 的共同色标范围。

    这样可以避免 case2、case4 这种近似常数场中，
    1e-10 或 1e-11 量级的浮点误差被 imshow 自动放大。
    """
    vmin = np.nanmin(exact_grid)
    vmax = np.nanmax(exact_grid)
    span = vmax - vmin

    # 如果 exact 是常数场，例如 case2、case4
    if span <= 0.0 or not np.isfinite(span):
        center = 0.5 * (vmin + vmax)
        pad = max(abs(center) * pad_frac, min_pad)
        return center - pad, center + pad

    # 非常数场，给上下界留一点余量
    pad = pad_frac * span
    return vmin - pad, vmax + pad


def error_limits(err_grid):
    """
    误差图从 0 开始显示。
    """
    vmax = np.nanmax(err_grid)

    if not np.isfinite(vmax) or vmax <= 0.0:
        vmax = 1.0

    return 0.0, vmax


for path in sorted(glob.glob("case*_compare.dat")):
    data = np.loadtxt(path, comments="#")

    exact_grid, num_grid, err_grid = build_grid(data, j0=8)

    stem = os.path.splitext(os.path.basename(path))[0]

    phi_vmin, phi_vmax = field_limits_from_exact(exact_grid)
    err_vmin, err_vmax = error_limits(err_grid)

    fig, ax = new_subplots(1, 3, figsize=STANDARD_FIGSIZE)

    # phi_exact
    im0 = ax[0].imshow(
        exact_grid,
        aspect="equal",
        origin="lower",
        vmin=phi_vmin,
        vmax=phi_vmax,
    )
    ax[0].set_title(build_title(TEST_NAME, f"{stem} phi_exact", "Reference field on the fixed j slice."))
    ax[0].set_xlabel("z index")
    ax[0].set_ylabel("x index")
    fig.colorbar(im0, ax=ax[0], fraction=0.046, pad=0.04)

    # phi_num：使用和 phi_exact 完全相同的 colorbar 范围
    im1 = ax[1].imshow(
        num_grid,
        aspect="equal",
        origin="lower",
        vmin=phi_vmin,
        vmax=phi_vmax,
    )
    ax[1].set_title(build_title(TEST_NAME, f"{stem} phi_num", "Numerical field on the same slice."))
    ax[1].set_xlabel("z index")
    ax[1].set_ylabel("x index")
    fig.colorbar(im1, ax=ax[1], fraction=0.046, pad=0.04)

    # abs error
    im2 = ax[2].imshow(
        err_grid,
        aspect="equal",
        origin="lower",
        vmin=err_vmin,
        vmax=err_vmax,
    )
    ax[2].set_title(build_title(TEST_NAME, f"{stem} abs_error", "Pointwise absolute error on the same slice."))
    ax[2].set_xlabel("z index")
    ax[2].set_ylabel("x index")
    fig.colorbar(im2, ax=ax[2], fraction=0.046, pad=0.04)

    savefig(f"{stem}_limited_colorbar.png", dpi=DEFAULT_DPI)
