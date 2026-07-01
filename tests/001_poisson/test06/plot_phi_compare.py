import argparse
import os
from pathlib import Path
import textwrap

import matplotlib
matplotlib.use('Agg')

import numpy as np
import matplotlib.pyplot as plt

STANDARD_FIGSIZE = (8.0, 4.5)
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


def new_figure(figsize=STANDARD_FIGSIZE):
    return plt.figure(figsize=figsize, constrained_layout=True)


def savefig(path: str, dpi: int = DEFAULT_DPI) -> None:
    plt.savefig(path, dpi=dpi)
    plt.close()


def build_title(prefix: str, subject: str, context: str | None = None, width: int = 68) -> str:
    return textwrap.fill(f"{prefix}: {subject}", width=width)


def current_test_name(script_path: str) -> str:
    return Path(script_path).resolve().parent.name

apply_plot_style(font_size=12)
TEST_NAME = current_test_name(__file__)


def build_2d_arrays(i_arr, k_arr, x_arr, y_arr, val_arr):
    """Build 2D arrays indexed by k (rows) and i (cols)."""
    i_unique = np.unique(i_arr)
    k_unique = np.unique(k_arr)
    nr = len(i_unique)
    nz = len(k_unique)

    i_to_col = {ii: idx for idx, ii in enumerate(i_unique)}
    k_to_row = {kk: idx for idx, kk in enumerate(k_unique)}

    X = np.full((nz, nr), np.nan)
    Y = np.full((nz, nr), np.nan)
    V = np.full((nz, nr), np.nan)

    for ii, kk, xx, yy, vv in zip(i_arr, k_arr, x_arr, y_arr, val_arr):
        col = i_to_col[ii]
        row = k_to_row[kk]
        X[row, col] = xx
        Y[row, col] = yy
        V[row, col] = vv

    return X, Y, V, i_unique, k_unique


def set_multiline_title(title_main: str, title_explain: str, fontsize: int = 13) -> None:
    plt.title(build_title(TEST_NAME, title_main, title_explain), fontsize=fontsize)


def main():
    parser = argparse.ArgumentParser(
        description='Plot multiple views from phi_compare.dat for the 3D R-A-Z Poisson test.'
    )
    parser.add_argument('--input', default='phi_compare.dat', help='Input data file')
    parser.add_argument('--outdir', default='fig_phi_compare', help='Output directory for PNGs')
    parser.add_argument('--j', type=int, default=None, help='Fixed j index for r-z slices (default: first j)')
    parser.add_argument('--k', type=int, default=None, help='Fixed k index for x-y and r-line slices (default: middle k)')
    parser.add_argument('--i', type=int, default=None, help='Fixed i index for z-line slice (default: middle i)')
    parser.add_argument('--dpi', type=int, default=DEFAULT_DPI, help='PNG dpi')
    args = parser.parse_args()

    if not os.path.exists(args.input):
        raise FileNotFoundError(f'Cannot find input file: {args.input}')

    data = np.loadtxt(args.input, comments='#')
    if data.ndim == 1:
        data = data.reshape(1, -1)

    if data.shape[1] < 9:
        raise ValueError('Input file must have at least 9 columns: i j k r alpha z phi_num phi_exact abs_error')

    i = data[:, 0].astype(int)
    j = data[:, 1].astype(int)
    k = data[:, 2].astype(int)
    r = data[:, 3]
    alpha = data[:, 4]
    z = data[:, 5]
    phi_num = data[:, 6]
    phi_exact = data[:, 7]
    abs_error = data[:, 8]

    i_vals = np.unique(i)
    j_vals = np.unique(j)
    k_vals = np.unique(k)

    j0 = int(j_vals[0]) if args.j is None else args.j
    k0 = int(k_vals[len(k_vals) // 2]) if args.k is None else args.k
    i0 = int(i_vals[len(i_vals) // 2]) if args.i is None else args.i

    if j0 not in j_vals:
        raise ValueError(f'j={j0} not found. Available j: {j_vals.tolist()}')
    if k0 not in k_vals:
        raise ValueError(f'k={k0} not found. Available k: {k_vals.tolist()}')
    if i0 not in i_vals:
        raise ValueError(f'i={i0} not found. Available i: {i_vals.tolist()}')

    os.makedirs(args.outdir, exist_ok=True)

    # ------------------------------------------------------------
    # 1) r-z scatter on fixed j
    # ------------------------------------------------------------
    mask_j = (j == j0)
    rj = r[mask_j]
    zj = z[mask_j]
    ij = i[mask_j]
    kj = k[mask_j]
    phi_num_j = phi_num[mask_j]
    phi_exact_j = phi_exact[mask_j]
    abs_error_j = abs_error[mask_j]

    new_figure()
    sc = plt.scatter(rj, zj, c=phi_num_j)
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'phi_num on j={j0} slice',
        'Fixed azimuthal index j; each dot is one cell center in the r-z plane, and color shows the numerical solution.'
    )
    plt.colorbar(sc, label='phi_num')
    savefig(os.path.join(args.outdir, f'rz_scatter_phi_num_j{j0}.png'), dpi=args.dpi)

    new_figure()
    sc = plt.scatter(rj, zj, c=phi_exact_j)
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'phi_exact on j={j0} slice',
        'Same r-z slice as above; color shows the analytic solution used for direct visual comparison.'
    )
    plt.colorbar(sc, label='phi_exact')
    savefig(os.path.join(args.outdir, f'rz_scatter_phi_exact_j{j0}.png'), dpi=args.dpi)

    new_figure()
    sc = plt.scatter(rj, zj, c=abs_error_j)
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'abs_error on j={j0} slice',
        'Same r-z slice; color is |phi_num - phi_exact|, so brighter regions indicate where the numerical error is larger.'
    )
    plt.colorbar(sc, label='abs_error')
    savefig(os.path.join(args.outdir, f'rz_scatter_abs_error_j{j0}.png'), dpi=args.dpi)

    # ------------------------------------------------------------
    # 2) r-z pcolormesh on fixed j
    # ------------------------------------------------------------
    R, Z, PHI_NUM, _, _ = build_2d_arrays(ij, kj, rj, zj, phi_num_j)
    _, _, PHI_EXACT, _, _ = build_2d_arrays(ij, kj, rj, zj, phi_exact_j)
    _, _, ERR, _, _ = build_2d_arrays(ij, kj, rj, zj, abs_error_j)

    new_figure()
    pcm = plt.pcolormesh(R, Z, PHI_NUM, shading='auto')
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'phi_num on j={j0} slice',
        'Structured r-z view at fixed j; this emphasizes how the numerical solution varies over the nonuniform mesh.'
    )
    plt.colorbar(pcm, label='phi_num')
    savefig(os.path.join(args.outdir, f'rz_pcolormesh_phi_num_j{j0}.png'), dpi=args.dpi)

    new_figure()
    pcm = plt.pcolormesh(R, Z, PHI_EXACT, shading='auto')
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'phi_exact on j={j0} slice',
        'Structured r-z view at fixed j; this is the reference field from the analytic formula on the same mesh.'
    )
    plt.colorbar(pcm, label='phi_exact')
    savefig(os.path.join(args.outdir, f'rz_pcolormesh_phi_exact_j{j0}.png'), dpi=args.dpi)

    new_figure()
    pcm = plt.pcolormesh(R, Z, ERR, shading='auto')
    plt.xlabel('r')
    plt.ylabel('z')
    set_multiline_title(
        f'abs_error on j={j0} slice',
        'Structured r-z error map at fixed j; use this to locate where the discretization error concentrates in the domain.'
    )
    plt.colorbar(pcm, label='abs_error')
    savefig(os.path.join(args.outdir, f'rz_pcolormesh_abs_error_j{j0}.png'), dpi=args.dpi)

    # ------------------------------------------------------------
    # 3) line in r at fixed (j, k)
    # ------------------------------------------------------------
    mask_jk = (j == j0) & (k == k0)
    if np.any(mask_jk):
        order = np.argsort(r[mask_jk])
        rr = r[mask_jk][order]
        pn = phi_num[mask_jk][order]
        pe = phi_exact[mask_jk][order]
        ee = abs_error[mask_jk][order]

        new_figure()
        plt.plot(rr, pn, 'o-', label='phi_num')
        plt.plot(rr, pe, 's--', label='phi_exact')
        plt.xlabel('r')
        plt.ylabel('phi')
        set_multiline_title(
            f'r-line at j={j0}, k={k0}',
            'Radial cut with fixed azimuthal and axial indices; overlapping curves mean the numerical and analytic solutions agree well along r.'
        )
        plt.legend()
        savefig(os.path.join(args.outdir, f'line_r_j{j0}_k{k0}.png'), dpi=args.dpi)

        new_figure()
        plt.plot(rr, ee, 'o-')
        plt.xlabel('r')
        plt.ylabel('abs_error')
        set_multiline_title(
            f'r-line abs_error at j={j0}, k={k0}',
            'Radial error profile on the same cut; this shows how the pointwise error changes from the axis side to the outer radius.'
        )
        savefig(os.path.join(args.outdir, f'line_r_abs_error_j{j0}_k{k0}.png'), dpi=args.dpi)

    # ------------------------------------------------------------
    # 4) line in z at fixed (i, j)
    # ------------------------------------------------------------
    mask_ij = (i == i0) & (j == j0)
    if np.any(mask_ij):
        order = np.argsort(z[mask_ij])
        zz = z[mask_ij][order]
        pn = phi_num[mask_ij][order]
        pe = phi_exact[mask_ij][order]
        ee = abs_error[mask_ij][order]

        new_figure()
        plt.plot(zz, pn, 'o-', label='phi_num')
        plt.plot(zz, pe, 's--', label='phi_exact')
        plt.xlabel('z')
        plt.ylabel('phi')
        set_multiline_title(
            f'z-line at i={i0}, j={j0}',
            'Axial cut with fixed radial and azimuthal indices; compare the two curves to judge agreement along z.'
        )
        plt.legend()
        savefig(os.path.join(args.outdir, f'line_z_i{i0}_j{j0}.png'), dpi=args.dpi)

        new_figure()
        plt.plot(zz, ee, 'o-')
        plt.xlabel('z')
        plt.ylabel('abs_error')
        set_multiline_title(
            f'z-line abs_error at i={i0}, j={j0}',
            'Axial error profile on the same cut; this is useful for checking whether the error is symmetric and where it peaks in z.'
        )
        savefig(os.path.join(args.outdir, f'line_z_abs_error_i{i0}_j{j0}.png'), dpi=args.dpi)

    # ------------------------------------------------------------
    # 5) x-y scatter at fixed k
    # ------------------------------------------------------------
    mask_k = (k == k0)
    rk = r[mask_k]
    ak = alpha[mask_k]
    xk = rk * np.cos(ak)
    yk = rk * np.sin(ak)
    phi_num_k = phi_num[mask_k]
    abs_error_k = abs_error[mask_k]

    new_figure()
    sc = plt.scatter(xk, yk, c=phi_num_k)
    plt.xlabel('x = r cos(alpha)')
    plt.ylabel('y = r sin(alpha)')
    set_multiline_title(
        f'x-y scatter phi_num at k={k0}',
        'Cartesian view of one z layer; color shows the numerical field over the polar grid after mapping to x-y coordinates.'
    )
    plt.axis('equal')
    plt.colorbar(sc, label='phi_num')
    savefig(os.path.join(args.outdir, f'xy_scatter_phi_num_k{k0}.png'), dpi=args.dpi)

    new_figure()
    sc = plt.scatter(xk, yk, c=abs_error_k)
    plt.xlabel('x = r cos(alpha)')
    plt.ylabel('y = r sin(alpha)')
    set_multiline_title(
        f'x-y scatter abs_error at k={k0}',
        'Cartesian view of the same z layer; color shows pointwise error, which helps reveal angular patterns in the error distribution.'
    )
    plt.axis('equal')
    plt.colorbar(sc, label='abs_error')
    savefig(os.path.join(args.outdir, f'xy_scatter_abs_error_k{k0}.png'), dpi=args.dpi)

    print(f'Input file : {args.input}')
    print(f'Output dir : {args.outdir}')
    print(f'Using j={j0}, k={k0}, i={i0}')
    print('Done.')


if __name__ == '__main__':
    main()
