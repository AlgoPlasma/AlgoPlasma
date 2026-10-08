#!/usr/bin/env python3
"""Generate the two publication figures for the AlgoPlasma example."""

from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LogNorm, TwoSlopeNorm
from scipy.ndimage import gaussian_filter
from scipy.optimize import root
from scipy.special import wofz


ROOT = Path(__file__).resolve().parent
DATA = ROOT / "output"
FIGURES = ROOT / "figures"
FIGURES.mkdir(parents=True, exist_ok=True)

NX = NY = 64
LX = LY = 64.0
DX = DY = 1.0
DT = 0.05
EPS0 = MASS = 1.0
CHARGE = -1.0
THERMAL_SPEED = 1.0
DRIFT_SPEED = 3.0
WEIGHT = 1.0 / 128.0
MODE_X, MODE_Y = 2, 1
FIT_LOWER, FIT_UPPER = 10.0, 19.0
KX = 2.0 * np.pi * MODE_X / LX
KY = 2.0 * np.pi * MODE_Y / LY
KNORM = np.hypot(KX, KY)

mpl.rcParams.update(
    {
        "font.family": "serif",
        "font.serif": ["DejaVu Serif"],
        "mathtext.fontset": "stix",
        "font.size": 10.0,
        "axes.labelsize": 11.5,
        "axes.titlesize": 11.5,
        "xtick.labelsize": 10.0,
        "ytick.labelsize": 10.0,
        "legend.fontsize": 10.0,
        "axes.linewidth": 1.0,
        "xtick.direction": "in",
        "ytick.direction": "in",
        "xtick.top": True,
        "ytick.right": True,
        "xtick.major.width": 1.0,
        "ytick.major.width": 1.0,
        "xtick.minor.width": 0.8,
        "ytick.minor.width": 0.8,
        "savefig.facecolor": "white",
        "figure.facecolor": "white",
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    }
)

def indexed_files(label):
    files = {}
    for path in (DATA / label).glob(f"{label}_*.bin"):
        match = re.search(r"_(\d{10})_\d{5}\.bin$", path.name)
        if match:
            files[int(match.group(1))] = path
    return files


def read_field(path):
    with path.open("rb") as stream:
        bounds = np.fromfile(stream, np.int32, 6)
        values = np.fromfile(stream, np.float64)
    shape = tuple(bounds[3:] - bounds[:3] + 1)
    return values.reshape(shape, order="F")


def read_particles(path):
    return np.fromfile(path, np.float64).reshape((-1, 6))


def save_figure(fig, name):
    path = FIGURES / name
    fig.savefig(path, dpi=600, bbox_inches="tight", pad_inches=0.02)
    plt.close(fig)
    print(path)


def field_diagnostics():
    ex_files, ey_files = indexed_files("Ex"), indexed_files("Ey")
    steps = np.asarray(sorted(set(ex_files) & set(ey_files)), dtype=int)
    times = steps * DT
    rms_field = np.empty(steps.size)
    mode_amplitude = np.empty(steps.size)
    for index, step in enumerate(steps):
        ex = read_field(ex_files[step])[:, :, 0]
        ey = read_field(ey_files[step])[:, :, 0]
        energy = 0.5 * EPS0 * DX * DY * np.sum(ex**2 + ey**2)
        rms_field[index] = np.sqrt(2.0 * energy / (LX * LY))
        e_parallel = (KX * ex + KY * ey) / KNORM
        spectrum = np.fft.fft2(e_parallel) / e_parallel.size
        mode_amplitude[index] = 2.0 * abs(spectrum[MODE_X, MODE_Y])
    return steps, times, rms_field, mode_amplitude


def log_linear_fit(times, values, lower=FIT_LOWER, upper=FIT_UPPER):
    mask = (times >= lower) & (times <= upper) & (values > 0.0)
    slope, intercept = np.polyfit(times[mask], np.log(values[mask]), 1)
    prediction = slope * times[mask] + intercept
    residual = np.sum((np.log(values[mask]) - prediction) ** 2)
    variance = np.sum((np.log(values[mask]) - np.mean(np.log(values[mask]))) ** 2)
    return slope, intercept, 1.0 - residual / variance


def theoretical_growth_rate():
    """Solve the warm symmetric two-stream dispersion relation."""
    drift_parallel = DRIFT_SPEED * KX / KNORM

    def plasma_dispersion(zeta):
        return 1j * np.sqrt(np.pi) * wofz(zeta)

    def dielectric(omega):
        susceptibility = 0.0j
        for sign in (-1.0, 1.0):
            zeta = (
                omega - sign * KNORM * drift_parallel
            ) / (np.sqrt(2.0) * KNORM * THERMAL_SPEED)
            susceptibility += 0.5 / (KNORM * THERMAL_SPEED)**2 * (
                1.0 + zeta * plasma_dispersion(zeta)
            )
        return 1.0 + susceptibility

    def residual(value):
        result = dielectric(value[0] + 1j * value[1])
        return [result.real, result.imag]

    solution = root(residual, [0.0, 0.26])
    return float(solution.x[1])


def gather_periodic(field, x, y):
    shifted_x, shifted_y = x + 0.5, y + 0.5
    i, j = np.floor(shifted_x).astype(int), np.floor(shifted_y).astype(int)
    fi, fj = shifted_x - i, shifted_y - j
    i0, i1 = (i - 1) % NX, i % NX
    j0, j1 = (j - 1) % NY, j % NY
    return (
        field[i0, j0] * (1.0 - fi) * (1.0 - fj)
        + field[i1, j0] * fi * (1.0 - fj)
        + field[i0, j1] * (1.0 - fi) * fj
        + field[i1, j1] * fi * fj
    )


def energy_history():
    ex_files, ey_files = indexed_files("Ex"), indexed_files("Ey")
    particle_files = indexed_files("par01")
    steps = sorted(set(ex_files) & set(ey_files) & set(particle_files))
    rows = []
    for step in steps:
        ex = read_field(ex_files[step])[:, :, 0]
        ey = read_field(ey_files[step])[:, :, 0]
        particles = read_particles(particle_files[step])
        velocities = particles[:, 3:6].copy()
        velocities[:, 0] += CHARGE * DT * gather_periodic(
            ex, particles[:, 0], particles[:, 1]
        ) / (2.0 * MASS)
        velocities[:, 1] += CHARGE * DT * gather_periodic(
            ey, particles[:, 0], particles[:, 1]
        ) / (2.0 * MASS)
        field = 0.5 * EPS0 * DX * DY * np.sum(ex**2 + ey**2)
        kinetic = 0.5 * MASS * WEIGHT * np.sum(velocities**2)
        rows.append((step, field, kinetic, field + kinetic))
    return np.asarray(rows)


def phase_space_figure(target_times=(0.0, 17.5, 25.0)):
    particle_files = indexed_files("par01")
    available = np.asarray(sorted(particle_files))
    selected = [int(available[np.argmin(abs(available - round(t / DT)))]) for t in target_times]
    phase_edges = np.linspace(0.0, 1.0, 161)
    velocity_edges = np.linspace(-6.0, 6.0, 181)
    histograms = []

    for step in selected:
        particles = read_particles(particle_files[step])
        phase = np.mod(MODE_X * particles[:, 0] / LX + MODE_Y * particles[:, 1] / LY, 1.0)
        velocity = (KX * particles[:, 3] + KY * particles[:, 4]) / KNORM
        histogram = np.histogram2d(
            phase, velocity, bins=(phase_edges, velocity_edges)
        )[0].T
        histograms.append(
            gaussian_filter(histogram, sigma=(0.7, 1.0), mode=("nearest", "wrap"))
        )

    common_maximum = max(float(histogram.max()) for histogram in histograms)
    histograms = [histogram / common_maximum for histogram in histograms]

    fig = plt.figure(figsize=(7.35, 2.46))
    grid = fig.add_gridspec(
        1, 4, width_ratios=(1.0, 1.0, 1.0, 0.040),
        left=0.072, right=0.972, bottom=0.19, top=0.87, wspace=0.20,
    )
    axes = [fig.add_subplot(grid[0, panel]) for panel in range(3)]
    colorbar_axis = fig.add_subplot(grid[0, 3])
    image = None
    for panel, (axis, step, histogram) in enumerate(zip(axes, selected, histograms)):
        image = axis.pcolormesh(
            phase_edges, velocity_edges, histogram, shading="flat",
            cmap="magma", norm=LogNorm(vmin=0.015, vmax=1.0), rasterized=True,
        )
        axis.set_xlim(0.0, 1.0)
        axis.set_ylim(-6.0, 6.0)
        axis.set_xticks(np.linspace(0.0, 1.0, 6))
        axis.xaxis.set_major_formatter(mpl.ticker.FormatStrFormatter("%.1f"))
        axis.set_xlabel(r"Wave phase, $\theta/2\pi$")
        axis.tick_params(axis="x", which="major", pad=6)
        axis.set_title(
            rf"({chr(97 + panel)}) $\omega_{{pe}}t={step * DT:g}$", loc="left", pad=4
        )
        axis.minorticks_on()
        if panel:
            axis.tick_params(axis="y", which="both", labelleft=False)

    axes[0].set_ylabel(r"$v_{\parallel}/v_{te}$")
    axes[0].tick_params(axis="y", which="major", pad=4)
    colorbar = fig.colorbar(image, cax=colorbar_axis)
    colorbar.ax.set_title(r"$f/f_{\max}$", pad=10)
    colorbar.ax.tick_params(direction="in")

    fig.canvas.draw()
    panel_position = axes[2].get_position()
    colorbar_position = colorbar_axis.get_position()
    colorbar_axis.set_position(
        [
            panel_position.x1 + 0.018,
            panel_position.y0,
            colorbar_position.width,
            panel_position.height,
        ]
    )
    save_figure(fig, "fig1_phase_space_evolution.png")

def field_growth_energy_figure():
    steps, times, rms_field, mode_amplitude = field_diagnostics()
    snapshot_step = int(steps[np.argmin(abs(steps * DT - 22.5))])
    snapshot_time = snapshot_step * DT
    ex = read_field(indexed_files("Ex")[snapshot_step])[:, :, 0]
    ey = read_field(indexed_files("Ey")[snapshot_step])[:, :, 0]
    e_parallel = (KX * ex + KY * ey) / KNORM
    field_limit = float(np.max(np.abs(e_parallel)))

    gamma, intercept, r_squared = log_linear_fit(times, mode_amplitude)
    gamma_theory = theoretical_growth_rate()
    fit_times = np.linspace(FIT_LOWER, FIT_UPPER, 200)
    fit_values = np.exp(intercept + gamma * fit_times)
    fit_mask = (times >= FIT_LOWER) & (times <= FIT_UPPER)
    theory_intercept = np.mean(
        np.log(mode_amplitude[fit_mask]) - gamma_theory * times[fit_mask]
    )
    theory_values = np.exp(theory_intercept + gamma_theory * fit_times)
    snapshot_index = int(np.argmin(abs(times - snapshot_time)))

    energy = energy_history()
    energy_time = energy[:, 0] * DT
    initial_total = energy[0, 3]
    field_change = (energy[:, 1] - energy[0, 1]) / initial_total
    kinetic_change = (energy[:, 2] - energy[0, 2]) / initial_total
    total_error_percent = 100.0 * (energy[:, 3] - initial_total) / initial_total
    maximum_error_percent = float(np.max(np.abs(total_error_percent)))

    fig = plt.figure(figsize=(7.35, 5.75))
    outer = fig.add_gridspec(
        2, 2, width_ratios=(1.0, 1.25), height_ratios=(1.08, 0.95),
        left=0.092, right=0.908, bottom=0.095, top=0.955,
        wspace=0.40, hspace=0.05,
    )
    field_grid = outer[0, 0].subgridspec(
        1, 2, width_ratios=(1.0, 0.050), wspace=0.065
    )
    field_axis = fig.add_subplot(field_grid[0, 0])
    colorbar_axis = fig.add_subplot(field_grid[0, 1])
    growth_axis = fig.add_subplot(outer[0, 1])
    energy_axis = fig.add_subplot(outer[1, :])
    error_axis = energy_axis.twinx()

    image = field_axis.imshow(
        e_parallel.T, origin="lower", extent=(0.0, LX, 0.0, LY),
        interpolation="bilinear", cmap="RdBu_r",
        norm=TwoSlopeNorm(vmin=-field_limit, vcenter=0.0, vmax=field_limit),
        aspect="equal", rasterized=True,
    )
    field_axis.set_xlabel(r"$x/\lambda_{De}$")
    field_axis.set_ylabel(r"$y/\lambda_{De}$")
    field_axis.set_anchor("N")
    field_axis.set_title(rf"(a) $\omega_{{pe}}t={snapshot_time:g}$", loc="left", pad=4)
    field_axis.minorticks_on()
    colorbar = fig.colorbar(image, cax=colorbar_axis)
    colorbar.ax.set_title(r"$E_{\parallel}$", pad=6)
    colorbar.ax.tick_params(direction="in")

    growth_axis.semilogy(
        times, mode_amplitude, color="#1f5a99", linewidth=1.50,
        label=rf"PIC $(m_x,m_y)=({MODE_X},{MODE_Y})$",
    )
    growth_axis.semilogy(
        fit_times, fit_values, color="#c43c39", linestyle="--",
        linewidth=1.50, label="PIC fit",
    )
    growth_axis.semilogy(
        fit_times, theory_values, color="#2f6f44", linestyle=":",
        linewidth=1.50, label="Kinetic theory",
    )
    growth_axis.axvspan(FIT_LOWER, FIT_UPPER, color="0.5", alpha=0.11, linewidth=0)
    growth_axis.axvline(snapshot_time, color="0.35", linestyle=":", linewidth=1.0)
    growth_axis.plot(
        snapshot_time, mode_amplitude[snapshot_index], marker="o", markersize=4.5,
        color="0.25", linestyle="none",
    )
    growth_axis.annotate(
        "Field snapshot", xy=(snapshot_time, mode_amplitude[snapshot_index]),
        xytext=(-20, -18), textcoords="offset points", ha="left", va="top",
        color="0.25", fontsize=9.0,
        # bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.72, "pad": 0.2},
    )
    growth_axis.text(
        0.055, 0.91,
        rf"$\gamma_{{\rm PIC}}={gamma:.3f}\,\omega_{{pe}}$" + "\n"
        + rf"$\gamma_{{\rm th}}={gamma_theory:.3f}\,\omega_{{pe}}$" + "\n"
        + rf"$R^2={r_squared:.4f}$",
        transform=growth_axis.transAxes, ha="left", va="top",
        fontsize=10.0
    )
    growth_axis.set_xlabel(r"$\omega_{pe}t$")
    growth_axis.set_ylabel(
        r"Mode amplitude, $2|\widehat{E}_{\parallel}(2,1)|$",
        labelpad=6,
    )
    growth_axis.yaxis.set_label_position("right")
    growth_axis.yaxis.tick_right()
    growth_axis.tick_params(
        axis="y", which="both",
        left=True, right=True,
        labelleft=False, labelright=True,
    )
    growth_axis.set_xlim(times.min(), times.max())
    growth_axis.set_xticks(np.arange(0.0, 40.1, 10.0))
    growth_axis.set_ylim(5.0e-4, growth_axis.get_ylim()[1])
    growth_axis.set_yticks([1.0e-3, 1.0e-2, 1.0e-1])
    growth_axis.set_title("(b) Electric field growth", loc="left", pad=4)
    growth_axis.grid(which="major", color="0.84", linewidth=0.5)
    growth_axis.grid(which="minor", axis="y", color="0.975", linewidth=0.35)
    growth_axis.legend(
        frameon=False, loc="lower right", handlelength=2.0,
        labelspacing=0.35, borderaxespad=0.45,
    )
    growth_axis.minorticks_on()

    field_line = energy_axis.plot(
        energy_time, field_change, color="#c43c39", marker="o",
        markersize=3.2, linewidth=1.50, label="Field",
    )[0]
    particle_line = energy_axis.plot(
        energy_time, kinetic_change, color="#1f5a99", marker="s",
        markersize=3.2, linewidth=1.50, label="Particles",
    )[0]
    total_line = error_axis.plot(
        energy_time, total_error_percent, color="#2f6f44", linestyle="--",
        marker="o", markersize=3.2, linewidth=1.50, label="Total error",
    )[0]
    energy_axis.axhline(0.0, color="0.35", linewidth=0.7)
    energy_axis.set_xlabel(r"$\omega_{pe}t$")
    energy_axis.set_ylabel(r"Energy change, $\Delta W_{E,K}/W_0$")
    error_axis.set_ylabel(r"Total energy error, $\Delta W/W_0$ (\%)")
    error_color = "#2f6f44"
    energy_axis.spines["right"].set_visible(False)
    energy_axis.tick_params(axis="y", which="both", right=False)
    error_axis.spines["left"].set_visible(False)
    error_axis.spines["right"].set_color(error_color)
    error_axis.spines["right"].set_linewidth(1.0)
    error_axis.tick_params(
        axis="y", which="both", left=False, right=True,
        labelleft=False, labelright=True, colors=error_color,
    )
    error_axis.yaxis.label.set_color(error_color)
    energy_axis.set_ylim(-0.04, 0.04)
    energy_axis.set_yticks([-0.04, -0.02, 0.0, 0.02, 0.04])
    error_axis.set_ylim(-0.04, 0.04)
    error_axis.set_yticks([-0.04, -0.02, 0.0, 0.02, 0.04])
    energy_axis.set_xlim(energy_time.min(), energy_time.max())
    energy_axis.set_xticks(np.arange(0.0, 40.1, 5.0))
    energy_axis.tick_params(axis="x", which="major", pad=6)
    energy_axis.set_title("(c) Energy exchange and total energy balance", loc="left", pad=4)
    energy_axis.grid(which="major", color="0.88", linewidth=0.5)
    energy_axis.minorticks_on()
    error_axis.minorticks_on()
    left_legend = energy_axis.legend(
        handles=[field_line, particle_line], frameon=False, loc="upper left",
        bbox_to_anchor=(0.02, 0.98),
        ncol=1, labelspacing=0.35, handlelength=2.0, borderaxespad=0.25,
    )
    energy_axis.add_artist(left_legend)
    right_legend = energy_axis.legend(
        handles=[total_line], frameon=False, loc="upper left",
        bbox_to_anchor=(0.745, 0.98), handlelength=2.0,
        labelspacing=0.35, borderaxespad=0.25,
        labelcolor=error_color,
    )

    # Render the legends before placing the maximum-error annotation.
    # Its left edge follows the start of the Total error legend line, and
    # its vertical center follows the Particles entry in the left legend.
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    total_handle_box = right_legend.get_lines()[0].get_window_extent(renderer)
    particle_text_box = left_legend.get_texts()[1].get_window_extent(renderer)
    maximum_error_position = energy_axis.transAxes.inverted().transform(
        (
            total_handle_box.x0,
            0.5 * (particle_text_box.y0 + particle_text_box.y1),
        )
    )
    energy_axis.text(
        maximum_error_position[0], maximum_error_position[1],
        rf"$\max |\Delta W/W_0|={maximum_error_percent:.4f}\%$",
        transform=energy_axis.transAxes, ha="left", va="center",
        color=error_color, fontsize=10.0,
        bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.86, "pad": 0.3},
        zorder=6,
    )

    fig.canvas.draw()
    
    field_position = field_axis.get_position()
    colorbar_position = colorbar_axis.get_position()
    growth_position = growth_axis.get_position()
    energy_position = energy_axis.get_position()
    
    # Expand panel (b) to the left; keep its right edge aligned with (c).
    extra_width = 0.06
    growth_left = growth_position.x0 - extra_width
    growth_right = energy_position.x1
    
    growth_axis.set_position([
        growth_left,
        field_position.y0,
        growth_right - growth_left,
        field_position.height,
    ])
    
    # Keep the colorbar aligned with panel (a).
    colorbar_axis.set_position([
        colorbar_position.x0,
        field_position.y0,
        colorbar_position.width,
        field_position.height,
    ])
    
    save_figure(fig, "fig2_field_growth_energy.png")


if __name__ == "__main__":
    phase_space_figure()
    field_growth_energy_figure()

