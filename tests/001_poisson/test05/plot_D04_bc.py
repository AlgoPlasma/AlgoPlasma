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


def read_data(path: str):
    if not os.path.exists(path):
        raise FileNotFoundError(f'Cannot find input file: {path}')

    data = np.loadtxt(path, comments='#')
    if data.ndim == 1:
        data = data.reshape(1, -1)

    ncol = data.shape[1]
    if ncol not in (7, 9):
        raise ValueError(
            'Input file must have either 7 columns:\n'
            '  i j k r alpha z phi_num\n'
            'or 9 columns:\n'
            '  i j k r alpha z phi_num phi_exact abs_error'
        )

    i = data[:, 0].astype(int)
    j = data[:, 1].astype(int)
    k = data[:, 2].astype(int)
    phi_num = data[:, 6]

    phi_exact = None
    abs_error = None

    if ncol == 9:
        phi_exact = data[:, 7]
        abs_error = data[:, 8]

    return i, j, k, phi_num, phi_exact, abs_error


def build_index_field(i_arr, k_arr, val_arr):
    """
    Build a 2D array with:
      rows -> radial index i
      cols -> axial index k
    """
    i_unique = np.unique(i_arr)
    k_unique = np.unique(k_arr)

    nr = len(i_unique)
    nz = len(k_unique)

    i_to_row = {ii: idx for idx, ii in enumerate(i_unique)}
    k_to_col = {kk: idx for idx, kk in enumerate(k_unique)}

    V = np.full((nr, nz), np.nan)

    for ii, kk, vv in zip(i_arr, k_arr, val_arr):
        row = i_to_row[ii]
        col = k_to_col[kk]
        V[row, col] = vv

    return i_unique, k_unique, V


def plot_field(V, i_unique, k_unique, title, cbar_label, outpath, dpi=200):
    new_figure()
    extent = [
        k_unique[0] - 0.5, k_unique[-1] + 0.5,
        i_unique[0] - 0.5, i_unique[-1] + 0.5
    ]
    plt.imshow(V, origin='lower', aspect='auto', extent=extent)
    plt.xlabel('z grid index k')
    plt.ylabel('R grid index i')
    plt.title(build_title(TEST_NAME, title))
    plt.colorbar(label=cbar_label)
    savefig(outpath, dpi=dpi)


def main():
    parser = argparse.ArgumentParser(
        description='Plot D03 BC test on grid-index coordinates.'
    )
    parser.add_argument('--input', required=True, help='Input data file')
    parser.add_argument('--outdir', default='fig_bc_grid', help='Output directory')
    parser.add_argument('--j', type=int, default=None, help='Fixed j index')
    parser.add_argument('--dpi', type=int, default=DEFAULT_DPI, help='PNG dpi')
    parser.add_argument('--relative20', action='store_true',
                        help='Plot error normalized by 20 instead of using file abs_error')
    args = parser.parse_args()

    i, j, k, phi_num, phi_exact, abs_error = read_data(args.input)

    j_vals = np.unique(j)
    j0 = int(j_vals[0]) if args.j is None else args.j

    if j0 not in j_vals:
        raise ValueError(f'j={j0} not found. Available j: {j_vals.tolist()}')

    os.makedirs(args.outdir, exist_ok=True)

    mask = (j == j0)
    ii = i[mask]
    kk = k[mask]
    pn = phi_num[mask]

    i_unique, k_unique, V_num = build_index_field(ii, kk, pn)

    plot_field(
        V_num, i_unique, k_unique,
        title=f'Numerical potential on j={j0} slice',
        cbar_label='phi_num',
        outpath=os.path.join(args.outdir, f'grid_phi_num_j{j0}.png'),
        dpi=args.dpi
    )

    if phi_exact is not None:
        pe = phi_exact[mask]
        _, _, V_exact = build_index_field(ii, kk, pe)

        plot_field(
            V_exact, i_unique, k_unique,
            title=f'Theoretical potential on j={j0} slice',
            cbar_label='phi_exact',
            outpath=os.path.join(args.outdir, f'grid_phi_exact_j{j0}.png'),
            dpi=args.dpi
        )

        if args.relative20:
            err = np.abs(pn - pe) / 20.0
            err_label = '|phi_num - phi_exact| / 20'
            err_title = f'Normalized error on j={j0} slice'
        else:
            err = np.abs(pn - pe)
            err_label = '|phi_num - phi_exact|'
            err_title = f'Absolute error on j={j0} slice'

        _, _, V_err = build_index_field(ii, kk, err)

        plot_field(
            V_err, i_unique, k_unique,
            title=err_title,
            cbar_label=err_label,
            outpath=os.path.join(args.outdir, f'grid_error_j{j0}.png'),
            dpi=args.dpi
        )

    print(f'Input file : {args.input}')
    print(f'Output dir : {args.outdir}')
    print(f'Using j={j0}')
    print('Done.')


if __name__ == '__main__':
    main()
