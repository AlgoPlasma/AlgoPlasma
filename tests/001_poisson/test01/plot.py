import numpy as np
import scipy.constants as sc
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import textwrap
from pathlib import Path

STANDARD_FIGSIZE = (8.0, 6.0)
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

apply_plot_style(font_size=16)
TEST_NAME = current_test_name(__file__)

nx = 32
ny = 8
nz = 32

phi1d = np.loadtxt('phi.dat')

phi3d = np.zeros((nx,ny,nz))

l = 0
for k in range(nz):
    for j in range(ny):
        for i in range(nx):
            phi3d[i,j,k] = phi1d[l]
            l = l + 1

new_figure()
plt.imshow(
    np.log10(phi3d[:,int(ny/2),:]),
    aspect='auto',
    origin='lower',
)
plt.xlabel(r'$z$')
plt.ylabel(r'$x$')
plt.title(build_title(TEST_NAME, r'$\log_{10}{\phi}$', 'Mid-y x-z slice of the reconstructed potential field.'))
plt.colorbar()
savefig('phi_zx.png', dpi=DEFAULT_DPI)
