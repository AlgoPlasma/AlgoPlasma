import numpy as np
import scipy.constants as sc
import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.patches import Rectangle
from pathlib import Path

FONT_CANDIDATES = ["Arial", "Helvetica", "Nimbus Sans", "Liberation Sans", "DejaVu Sans"]
FIGURE_SIZE = (8.0, 6.0)
PROFILE_FIGURE_SIZE = (7.2, 4.8)
TITLE_FONT_SIZE = 19.5
AXIS_LABEL_SIZE = 18.2
SIDE_TITLE_SIZE = 19.5
TICK_LABEL_SIZE = 15.6


def configure_paper_style():
    available_font_names = {font.name for font in font_manager.fontManager.ttflist}
    preferred_font = next(
        (font for font in FONT_CANDIDATES if font in available_font_names),
        "DejaVu Sans",
    )
    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": [
            preferred_font,
            *[font for font in FONT_CANDIDATES if font != preferred_font],
        ],
        "mathtext.fontset": "dejavusans",
        "axes.unicode_minus": False,
        "font.size": 15.6,
        "figure.figsize": PROFILE_FIGURE_SIZE,
        "axes.labelsize": AXIS_LABEL_SIZE,
        "axes.linewidth": 1.2,
        "lines.linewidth": 1.8,
        # "xtick.direction": "in",
        # "ytick.direction": "in",
        "xtick.labelsize": TICK_LABEL_SIZE,
        "ytick.labelsize": TICK_LABEL_SIZE,
        "xtick.major.size": 5,
        "ytick.major.size": 5,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
    return preferred_font


# ============================================================
# 0. Basic parameters
# ============================================================

# Global grid size.
ix = 256
iy = 64
iz = 256

# T-shaped domain.
iz1 = 72
ix1 = 64
ix2 = 192

real_dtype = np.float64
rng_seed = None

# Output directory.
out_dir = Path("output_init_particles_bin")

# Output files.
file_e = "par_ele_init.bin"
file_i = "par_ion_init.bin"

# Output figure prefix.
plot_prefix = "init_"

# Number of sampled macro-particles.
np_e_global = 1000000*50
np_i_global = 1000000*50

# Thermal speeds.
vte = 0.11485273214334615
vti = 5.249591521794099e-05

# Drift velocities.
vde = (0.0, 0.0, 0.0)
vdi = (0.0, 0.0, 0.0)

vt_e = np.full(3, vte, dtype=real_dtype)
vt_i = np.full(3, vti, dtype=real_dtype)

vd_e = np.array(vde, dtype=real_dtype)
vd_i = np.array(vdi, dtype=real_dtype)

# Species IDs, consistent with Fortran:
# 1 -> electrons
# 2 -> ions
SPECIES_ELE = 1
SPECIES_ION = 2


# ============================================================
# 1. Analytical density profile parameters
# ============================================================

# x-direction parameters.
lx = (ix2 - ix1) * 2.0

# y-direction parameters.
ly = iy / 7.0
amp_y = 0.1

# z-direction parameters.
nmin_z = 0.2
zp = 60.0
zw = 30.0

# Physical density estimation.
nmax_real = 15.0 * 5.0e16
dv_real = 0.1e-3 ** 3

# ============================================================
# 2. Density profile functions
# ============================================================

def den_x(x, l, xm, nmin=0.2):
    """
    Return the x-direction density factor.
    """
    s = np.sin(2.0 * np.pi * (x - xm) / l)
    return nmin + (1.0 - nmin) * np.clip(s, 0.0, 1.0)


def den_y(y, l, amp):
    """
    Return the y-direction density factor.
    """
    return amp * np.sin(2.0 * sc.pi * y / l) + 1.0 - amp


def den_z(z, nmin, zp0, zw0):
    """
    Return the z-direction density factor.
    """
    return (1.0 - nmin) * np.exp(-((z - zp0) / zw0) ** 2) + nmin


def is_inside_t_domain(x, y, z):
    """
    Check whether points are inside the valid T-shaped domain.
    """
    inside_basic = (
        (x >= 0.0) & (x < ix) &
        (y >= 0.0) & (y < iy) &
        (z >= 0.0) & (z < iz)
    )

    inside_channel = (z < iz1) & (x >= ix1) & (x < ix2)
    inside_plume = (z >= iz1) & (x >= 0.0) & (x < ix)

    return inside_basic & (inside_channel | inside_plume)


def sample_density(x, y, z):
    """
    Return the target normalized density distribution in the T-shaped domain.
    """
    val = den_x(x, lx, ix / 4.0) * den_y(y, ly, amp_y) * den_z(z, nmin_z, zp, zw)

    if np.isscalar(x):
        if z < iz1 and x >= ix1 and x < ix2:
            return val
        if z >= iz1:
            return val
        return 0.0

    out = np.zeros_like(x, dtype=real_dtype)
    mask = is_inside_t_domain(x, y, z)
    out[mask] = val[mask]
    return out


# ============================================================
# 3. Target-density diagnostics
# ============================================================


def compute_target_density_grid():
    """
    Build a node-like visualization grid similar to old initial_par.py.
    """
    x = np.linspace(0.0, ix, ix + 1)
    y = np.linspace(0.0, iy, iy + 1)
    z = np.linspace(0.0, iz, iz + 1)

    xg, yg, zg = np.meshgrid(x, y, z, indexing="ij")
    nn = sample_density(xg, yg, zg)

    total_real_particles = np.sum(nn) * nmax_real * dv_real
    print("Total number of estimated real particles:", total_real_particles)

    return nn


def add_mask_rect(ax, xy, width, height, color="white"):
    ax.add_patch(
        Rectangle(
            xy,
            width,
            height,
            facecolor=color,
            edgecolor="none",
            linewidth=0,
            zorder=2,
            clip_on=True,
        )
    )


def overlay_t_domain_mask(ax_top, ax_main, ax_z1, ax_z2, x_index, z_indices):
    if ix1 > 0:
        add_mask_rect(ax_main, (0, 0), iz1, ix1)
    if ix2 < ix:
        add_mask_rect(ax_main, (0, ix2), iz1, ix - ix2)

    if x_index < ix1 or x_index >= ix2:
        add_mask_rect(ax_top, (0, 0), iz1, iy)

    for ax, z_index in ((ax_z1, z_indices[0]), (ax_z2, z_indices[1])):
        if z_index < iz1:
            if ix1 > 0:
                add_mask_rect(ax, (0, 0), iy, ix1)
            if ix2 < ix:
                add_mask_rect(ax, (0, ix2), iy, ix - ix2)


def save_density_slice_group(nn, file_name):
    x_index = ix // 2
    y_index = iy // 2
    z_indices = (60, 100)

    top_slice = nn[x_index, :, :]
    main_slice = nn[:, y_index, :]
    z1_slice = nn[:, :, z_indices[0]]
    z2_slice = nn[:, :, z_indices[1]]

    vmin = 0.0
    vmax = max(float(np.nanmax(item)) for item in (top_slice, main_slice, z1_slice, z2_slice))

    fig = plt.figure(figsize=FIGURE_SIZE, constrained_layout=False)
    gs = fig.add_gridspec(
        nrows=2,
        ncols=5,
        width_ratios=(1.5, 1.5, 0.75, 0.75, 0.12),
        height_ratios=(0.55, 2.25),
        left=0.12,
        right=0.92,
        bottom=0.10,
        top=0.90,
        wspace=0.18,
        hspace=0.08,
    )

    ax_top = fig.add_subplot(gs[0, 0:2])
    ax_main = fig.add_subplot(gs[1, 0:2])
    ax_z1 = fig.add_subplot(gs[1, 2])
    ax_z2 = fig.add_subplot(gs[1, 3])
    cax = fig.add_subplot(gs[:, 4])

    cmap = "viridis"
    im_top = ax_top.imshow(
        top_slice,
        origin="lower",
        extent=(0, iz, 0, iy),
        aspect="auto",
        cmap=cmap,
        vmin=vmin,
        vmax=vmax,
        interpolation="nearest",
    )
    ax_top.set_ylabel(r"$y$", fontsize=AXIS_LABEL_SIZE, labelpad=10)
    ax_top.set_xticklabels([])
    ax_top.tick_params(labelsize=TICK_LABEL_SIZE)

    ax_main.imshow(
        main_slice,
        origin="lower",
        extent=(0, iz, 0, ix),
        aspect="auto",
        cmap=cmap,
        vmin=vmin,
        vmax=vmax,
        interpolation="nearest",
    )
    ax_main.set_xlabel(r"$z$", fontsize=AXIS_LABEL_SIZE)
    ax_main.set_ylabel(r"$x$", fontsize=AXIS_LABEL_SIZE, labelpad=10)
    ax_main.tick_params(labelsize=TICK_LABEL_SIZE)

    for ax, z_index, z_slice in ((ax_z1, z_indices[0], z1_slice), (ax_z2, z_indices[1], z2_slice)):
        ax.imshow(
            z_slice,
            origin="lower",
            extent=(iy, 0, 0, ix),
            aspect="auto",
            cmap=cmap,
            vmin=vmin,
            vmax=vmax,
            interpolation="nearest",
        )
        ax.set_title(rf"$z = {z_index}$", fontsize=SIDE_TITLE_SIZE, pad=6)
        ax.set_xlabel(r"$y$", fontsize=AXIS_LABEL_SIZE)
        ax.tick_params(labelsize=TICK_LABEL_SIZE)

    overlay_t_domain_mask(ax_top, ax_main, ax_z1, ax_z2, x_index, z_indices)

    ax_z1.set_yticklabels([])
    ax_z2.set_yticklabels([])

    cbar = fig.colorbar(im_top, cax=cax)
    # cbar.set_label(r"$n/n_0$", fontsize=AXIS_LABEL_SIZE)
    cbar.ax.tick_params(labelsize=TICK_LABEL_SIZE)

    fig.suptitle(r"Initial normalized density $n/n_0$", fontsize=TITLE_FONT_SIZE, y=0.965)
    fig.savefig(out_dir / file_name, dpi=300, bbox_inches="tight", pad_inches=0.08)
    plt.close(fig)


# ============================================================
# 4. Position sampling
# ============================================================

def sample_positions_from_density(npar, rng):
    """
    Rejection sample positions according to sample_density(x,y,z).
    Return shape = (3, npar).
    """
    pos = np.empty((3, npar), dtype=real_dtype)

    i = 0
    batch_size = max(10000, min(500000, npar))

    while i < npar:
        xx = rng.random(batch_size) * ix
        yy = rng.random(batch_size) * iy
        zz = rng.random(batch_size) * iz

        dens = sample_density(xx, yy, zz)
        keep = dens > rng.random(batch_size)

        n_keep = np.count_nonzero(keep)
        if n_keep == 0:
            continue

        n_write = min(n_keep, npar - i)

        pos[0, i:i + n_write] = xx[keep][:n_write]
        pos[1, i:i + n_write] = yy[keep][:n_write]
        pos[2, i:i + n_write] = zz[keep][:n_write]

        i += n_write

        if i % max(1, npar // 20) < n_write:
            print(f"[Sampling] {i:10d} / {npar:10d} = {100.0 * i / npar:.1f}%")

    return pos


# ============================================================
# 5. Velocity sampling
# ============================================================

def sample_velocities_maxwellian(npar, vt, vd, rng):
    """
    Sample Maxwellian + drift velocities.
    Return shape = (3, npar).
    """
    vx = rng.normal(loc=vd[0], scale=vt[0], size=npar)
    vy = rng.normal(loc=vd[1], scale=vt[1], size=npar)
    vz = rng.normal(loc=vd[2], scale=vt[2], size=npar)

    vel = np.vstack([vx, vy, vz]).astype(real_dtype, copy=False)
    return vel


def ion_axial_drift_m_per_s(z_grid):
    z = np.asarray(z_grid, dtype=real_dtype) * 0.1e-3

    a = 1.6575e4
    b = -1.5208e3
    c = 0.0091
    d = 4.4528

    return 0.5 * (a + (b - a) / (1.0 + (z / c) ** d))


def apply_ion_vz_profile(par, species_id):
    """
    Overwrite ion vz using the same functional form as inc_load_particles_v.f90.

    Parameters
    ----------
    par : ndarray
        Particle array with shape (6, npar):
        par[0] = x, par[1] = y, par[2] = z,
        par[3] = vx, par[4] = vy, par[5] = vz
    species_id : int
        1 for electrons, 2 for ions.

    Returns
    -------
    par : ndarray
        Modified particle array.
    """
    # Only modify ions.
    if species_id != SPECIES_ION:
        return par

    # IMPORTANT:
    # Here z is directly taken from par[2], which is currently sampled in grid units.
    # If the original Fortran formula expects physical length in meters,
    # then this place may need:
    #     z = par[2] * dz
    # instead of:
    #     z = par[2]
    VV = 20000000.00
    par[5] = ion_axial_drift_m_per_s(par[2]) / VV

    return par


# ============================================================
# 6. Particle assembly and output
# ============================================================

def generate_species_particles_from_positions(pos, vt, vd, rng, species_id):
    """
    Build full 6D particle array from shared positions and species-specific velocities.
    Return shape = (6, npar).

    species_id:
        1 -> electrons
        2 -> ions
    """
    npar = pos.shape[1]
    vel = sample_velocities_maxwellian(npar, vt, vd, rng)

    if not np.all(is_inside_t_domain(pos[0], pos[1], pos[2])):
        raise RuntimeError("Generated positions outside valid T domain.")

    par = np.vstack([pos, vel]).astype(real_dtype, copy=False)

    # Apply species-dependent post-processing to velocity initialization.
    par = apply_ion_vz_profile(par, species_id)

    return par


def write_global_bin(file_path, par):
    """
    Write particle array as raw float64 binary stream.

    Input
    -----
    par : ndarray, shape = (6, np)
        par[0] = x
        par[1] = y
        par[2] = z
        par[3] = vx
        par[4] = vy
        par[5] = vz

    Output file layout
    ------------------
    Each particle is written as one record:
        x, y, z, vx, vy, vz
    """
    if par.ndim != 2 or par.shape[0] != 6:
        raise ValueError(f"par shape must be (6,np), got {par.shape}")

    data = par.T.astype(np.float64, copy=False)
    data.tofile(file_path)


# ============================================================
# 7. Velocity diagnostic plots
# ============================================================


def save_ion_axial_drift_profile(file_name):
    z_grid = np.linspace(0.0, iz, iz + 1)
    z_mm = z_grid
    vz_m_per_s = ion_axial_drift_m_per_s(z_grid)

    fig, ax = plt.subplots(figsize=PROFILE_FIGURE_SIZE)
    ax.plot(z_mm, vz_m_per_s)
    ax.set_xlabel(r"$z$", fontsize=AXIS_LABEL_SIZE)
    ax.set_ylabel(r"$v_{z,i}$ (m/s)", fontsize=AXIS_LABEL_SIZE)
    ax.set_title(r"Ion axial drift profile", fontsize=TITLE_FONT_SIZE)
    ax.grid(True, alpha=0.25)
    ax.tick_params(labelsize=TICK_LABEL_SIZE)
    fig.tight_layout()
    fig.savefig(out_dir / file_name, dpi=300, bbox_inches="tight")
    plt.close(fig)


# ============================================================
# 8. Main
# ============================================================

def main():
    out_dir.mkdir(parents=True, exist_ok=True)
    configure_paper_style()

    rng = np.random.default_rng(rng_seed)

    print("Setting up analytical distributions...")
    nn = compute_target_density_grid()
    save_density_slice_group(nn, f"{plot_prefix}_nn_slices.png")

    # Shared position distribution.
    np_pos_global = max(np_e_global, np_i_global)

    print("Sampling particle positions from analytical density...")
    pos_all = sample_positions_from_density(np_pos_global, rng)

    # Electrons.
    print("[Info] Generating electrons...")
    pos_e = pos_all[:, :np_e_global]
    par_e = generate_species_particles_from_positions(
        pos=pos_e,
        vt=vt_e,
        vd=vd_e,
        rng=rng,
        species_id=SPECIES_ELE,
    )
    write_global_bin(out_dir / file_e, par_e)
    print(f"[Info] Wrote {out_dir / file_e}, np = {par_e.shape[1]}")

    # Ions.
    print("[Info] Generating ions...")
    pos_i = pos_all[:, :np_i_global]
    par_i = generate_species_particles_from_positions(
        pos=pos_i,
        vt=vt_i,
        vd=vd_i,
        rng=rng,
        species_id=SPECIES_ION,
    )
    write_global_bin(out_dir / file_i, par_i)
    print(f"[Info] Wrote {out_dir / file_i}, np = {par_i.shape[1]}")

    save_ion_axial_drift_profile(f"{plot_prefix}_ion_axial_drift_profile.png")

    print("[Done]")


if __name__ == "__main__":
    main()
