import os
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import textwrap

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


def load_field(path: str):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Cannot find field file: {path}")

    data = np.loadtxt(path, comments="#")
    if data.ndim == 1:
        data = data.reshape(1, -1)

    if data.shape[1] != 9:
        raise ValueError(
            "Field file must have 9 columns:\n"
            "i j k r alpha z phi_num phi_exact abs_error"
        )

    i = data[:, 0].astype(int)
    j = data[:, 1].astype(int)
    k = data[:, 2].astype(int)
    r = data[:, 3]
    z = data[:, 5]
    phi_num = data[:, 6]
    phi_exact = data[:, 7]
    abs_error = data[:, 8]

    return i, j, k, r, z, phi_num, phi_exact, abs_error


def reconstruct_edges(xc: np.ndarray) -> np.ndarray:
    """
    Reconstruct cell edges from monotone cell centers.
    """
    xc = np.asarray(xc, dtype=float)
    n = len(xc)

    if n == 1:
        dx = 1.0
        return np.array([xc[0] - 0.5 * dx, xc[0] + 0.5 * dx], dtype=float)

    xe = np.empty(n + 1, dtype=float)
    xe[1:-1] = 0.5 * (xc[:-1] + xc[1:])
    xe[0] = xc[0] - 0.5 * (xc[1] - xc[0])
    xe[-1] = xc[-1] + 0.5 * (xc[-1] - xc[-2])
    return xe


def build_physical_field(i_arr, k_arr, r_arr, z_arr, val_arr):
    """
    Build a 2D field V(r_i, z_k), with rows -> i (radial), cols -> k (axial),
    together with physical center coordinates r_centers and z_centers.
    """
    i_unique = np.unique(i_arr)
    k_unique = np.unique(k_arr)

    ni = len(i_unique)
    nk = len(k_unique)

    i_to_row = {ii: idx for idx, ii in enumerate(i_unique)}
    k_to_col = {kk: idx for idx, kk in enumerate(k_unique)}

    V = np.full((ni, nk), np.nan, dtype=float)
    r_centers = np.full(ni, np.nan, dtype=float)
    z_centers = np.full(nk, np.nan, dtype=float)

    for ii, kk, rr, zz, vv in zip(i_arr, k_arr, r_arr, z_arr, val_arr):
        row = i_to_row[ii]
        col = k_to_col[kk]
        V[row, col] = vv
        r_centers[row] = rr
        z_centers[col] = zz

    return r_centers, z_centers, V


def plot_rz_field(V, r_centers, z_centers, title, cbar_label, outpath, dpi=200):
    r_edges = reconstruct_edges(r_centers)
    z_edges = reconstruct_edges(z_centers)

    # convert to cm
    r_edges_cm = 100.0 * r_edges
    z_edges_cm = 100.0 * z_edges

    new_figure()
    plt.pcolormesh(z_edges_cm, r_edges_cm, V, shading="auto")
    plt.xlabel("z (cm)")
    plt.ylabel("r (cm)")
    plt.title(build_title(TEST_NAME, title))
    plt.colorbar(label=cbar_label)
    savefig(outpath, dpi=dpi)


def plot_field_file(field_file: str, outdir: str, prefix: str, j_slice: int = None, dpi: int = 200) -> None:
    i, j, k, r, z, phi_num, phi_exact, abs_error = load_field(field_file)

    j_vals = np.unique(j)
    j0 = int(j_vals[0]) if j_slice is None else j_slice

    if j0 not in j_vals:
        raise ValueError(f"Requested j={j0} not found in {field_file}. Available j: {j_vals.tolist()}")

    mask = (j == j0)

    ii = i[mask]
    kk = k[mask]
    rr = r[mask]
    zz = z[mask]

    r_centers, z_centers, V_num = build_physical_field(ii, kk, rr, zz, phi_num[mask])
    _, _, V_exact = build_physical_field(ii, kk, rr, zz, phi_exact[mask])
    _, _, V_err = build_physical_field(ii, kk, rr, zz, abs_error[mask])

    plot_rz_field(
        V_num, r_centers, z_centers,
        title=f"{prefix}: numerical potential on j={j0} slice",
        cbar_label="phi_num",
        outpath=os.path.join(outdir, f"{prefix}_phi_num_j{j0}.png"),
        dpi=dpi
    )

    plot_rz_field(
        V_exact, r_centers, z_centers,
        title=f"{prefix}: exact potential on j={j0} slice",
        cbar_label="phi_exact",
        outpath=os.path.join(outdir, f"{prefix}_phi_exact_j{j0}.png"),
        dpi=dpi
    )

    plot_rz_field(
        V_err, r_centers, z_centers,
        title=f"{prefix}: absolute error on j={j0} slice",
        cbar_label="|phi_num - phi_exact|",
        outpath=os.path.join(outdir, f"{prefix}_error_j{j0}.png"),
        dpi=dpi
    )


def plot_mms_convergence(summary_file: str, outdir: str, dpi: int = 200) -> None:
    if not os.path.exists(summary_file):
        raise FileNotFoundError(f"Cannot find MMS summary file: {summary_file}")

    data = np.loadtxt(summary_file, comments="#")
    if data.ndim == 1:
        data = data.reshape(1, -1)

    if data.shape[1] != 5:
        raise ValueError(
            "MMS summary file must have 5 columns:\n"
            "N err_inf_uniform err_l2_uniform err_inf_nonuniform err_l2_nonuniform"
        )

    n = data[:, 0]
    err_inf_uniform = data[:, 1]
    err_l2_uniform = data[:, 2]
    err_inf_nonuniform = data[:, 3]
    err_l2_nonuniform = data[:, 4]

    new_figure(figsize=STANDARD_FIGSIZE)
    plt.semilogy(n, err_inf_uniform, "o-", linewidth=2, label="D03 uniform L_inf")
    plt.semilogy(n, err_l2_uniform, "s--", linewidth=2, label="D03 uniform relL2")
    plt.semilogy(n, err_inf_nonuniform, "o-", linewidth=2, label="D04 nonuniform L_inf")
    plt.semilogy(n, err_l2_nonuniform, "s--", linewidth=2, label="D04 nonuniform relL2")
    plt.xlabel("N")
    plt.ylabel("Error")
    plt.title(build_title(TEST_NAME, "MMS error convergence"))
    plt.grid(True, which="both", alpha=0.25)
    plt.legend()
    savefig(os.path.join(outdir, "mms_error_convergence.png"), dpi=dpi)


def main():
    uniform_field_file = "field_uniform_fine.dat"
    nonuniform_field_file = "field_nonuniform_fine.dat"
    mms_summary_file = "compare_uniform_nonuniform_rz_mms.dat"
    outdir = "fig_compare_uniform_nonuniform_rz_mms"
    dpi = DEFAULT_DPI

    os.makedirs(outdir, exist_ok=True)

    plot_field_file(uniform_field_file, outdir, prefix="uniform", j_slice=None, dpi=dpi)
    plot_field_file(nonuniform_field_file, outdir, prefix="nonuniform", j_slice=None, dpi=dpi)
    plot_mms_convergence(mms_summary_file, outdir, dpi=dpi)

    print("Done.")
    print("Uniform field   :", uniform_field_file)
    print("Nonuniform field:", nonuniform_field_file)
    print("MMS summary     :", mms_summary_file)
    print("Output dir      :", outdir)


if __name__ == "__main__":
    main()
