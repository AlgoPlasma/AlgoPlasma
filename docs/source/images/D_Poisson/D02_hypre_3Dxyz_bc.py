import matplotlib
# 使用无图形界面后端，避免卡在 GUI 上
matplotlib.use("Agg")

import matplotlib.pyplot as plt

def draw_dirichlet(
    png_name="D02_hypre_3Dxyz_bc_Dirichlet.png"
):
    fig, ax = plt.subplots(figsize=(4.5, 2.0))

    # x-axis
    ax.arrow(-1.2, 0.0, 3.4, 0.0, head_width=0.05, length_includes_head=True)
    ax.text(2.3, -0.08, "x")

    # cell centers: ghost, i_L, i_L+1
    x_ghost, x_iL, x_iLp1 = -0.5, 0.5, 1.5
    ax.plot(x_ghost, 0.0, marker="o")
    ax.plot(x_iL,    0.0, marker="o")
    ax.plot(x_iLp1,  0.0, marker="o")
    ax.text(x_ghost-0.15, -0.18, r"$i_L-1$")
    ax.text(x_iL-0.07,    -0.18, r"$i_L$")
    ax.text(x_iLp1-0.18,  -0.18, r"$i_L+1$")

    # vertical dashed cell faces
    for xf in (-1.0, 0.0, 1.0, 2.0):
        ax.plot([xf, xf], [-0.4, 0.8], linestyle="--", linewidth=0.7)

    # wall at x = 0
    ax.plot([0.0, 0.0], [-0.5, 0.9], linewidth=2.0)
    ax.text(0.02, 0.85, "Dirichlet wall", fontsize=9, va="bottom")

    # labels for phi
    ax.text(x_ghost-0.18, 0.10, r"$\phi_{i_L-1}$")
    ax.text(x_iL-0.12,    0.10, r"$\phi_{i_L}$")

    # phi_bc at the wall
    ax.text(-0.05, 0.5, r"$\phi_{\mathrm{bc}}$", ha="right", va="center")
    #ax.annotate("", xy=(x_ghost, 0.05), xytext=(-0.02, 0.45),
    #            arrowprops=dict(arrowstyle="->", linewidth=0.7))
    #ax.annotate("", xy=(x_iL, 0.05), xytext=(0.02, 0.45),
    #            arrowprops=dict(arrowstyle="->", linewidth=0.7))

    # Delta x indication
    ax.plot([x_iL, x_iLp1], [-0.35, -0.35], linewidth=0.7)
    ax.plot([x_iL, x_iL], [-0.32, -0.38], linewidth=0.7)
    ax.plot([x_iLp1, x_iLp1], [-0.32, -0.38], linewidth=0.7)
    ax.text(0.95, -0.47, r"$\Delta x$")

    ax.set_ylim(-0.6, 1.0)
    ax.set_xlim(-1.2, 2.2)
    ax.axis("off")

    fig.tight_layout()
    fig.savefig(png_name, dpi=300, bbox_inches="tight")
    plt.close(fig)


def draw_neumann(
    png_name="D02_hypre_3Dxyz_bc_Neumann.png"
):
    fig, ax = plt.subplots(figsize=(4.5, 2.0))

    # x-axis
    ax.arrow(-1.2, 0.0, 3.4, 0.0, head_width=0.05, length_includes_head=True)
    ax.text(2.3, -0.08, "x")

    # cell centers: ghost, i_L, i_L+1
    x_ghost, x_iL, x_iLp1 = -0.5, 0.5, 1.5
    ax.plot(x_ghost, 0.0, marker="o")
    ax.plot(x_iL,    0.0, marker="o")
    ax.plot(x_iLp1,  0.0, marker="o")
    ax.text(x_ghost-0.15, -0.18, r"$i_L-1$")
    ax.text(x_iL-0.07,    -0.18, r"$i_L$")
    ax.text(x_iLp1-0.18,  -0.18, r"$i_L+1$")

    # cell faces (dashed)
    for xf in (-1.0, 0.0, 1.0, 2.0):
        ax.plot([xf, xf], [-0.4, 0.8], linestyle="--", linewidth=0.7)

    # wall at x = 0
    ax.plot([0.0, 0.0], [-0.5, 0.9], linewidth=2.0)
    ax.text(0.02, 0.85, "Neumann wall", fontsize=9, va="bottom")

    # outward normal n (to the left)
    ax.annotate("", xy=(-0.85, 0.6), xytext=(-0.25, 0.6),
                arrowprops=dict(arrowstyle="->", linewidth=1.0))
    ax.text(-0.55, 0.68, r"$\mathbf{n}$", ha="center")

    # E_n (to the right, into the domain)
    ax.annotate("", xy=(0.8, 0.5), xytext=(0.2, 0.5),
                arrowprops=dict(arrowstyle="->", linewidth=0.8))
    ax.text(0.5, 0.63, r"$E_n$", ha="center")

    # labels for phi
    ax.text(x_ghost-0.18, 0.10, r"$\phi_{i_L-1}$")
    ax.text(x_iL-0.12,    0.10, r"$\phi_{i_L}$")

    # Delta x
    ax.plot([x_iL, x_iLp1], [-0.35, -0.35], linewidth=0.7)
    ax.plot([x_iL, x_iL], [-0.32, -0.38], linewidth=0.7)
    ax.plot([x_iLp1, x_iLp1], [-0.32, -0.38], linewidth=0.7)
    ax.text(0.95, -0.47, r"$\Delta x$")

    ax.set_ylim(-0.6, 1.0)
    ax.set_xlim(-1.2, 2.2)
    ax.axis("off")

    fig.tight_layout()
    fig.savefig(png_name, dpi=300, bbox_inches="tight")
    plt.close(fig)

if __name__ == "__main__":
    draw_dirichlet()
    draw_neumann()
    print("Saved:")
    print("  D02_hypre_3Dxyz_bc_Dirichlet.png")
    print("  D02_hypre_3Dxyz_bc_Neumann.png")
