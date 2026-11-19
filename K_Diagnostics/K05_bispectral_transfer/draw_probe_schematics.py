# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-30 08:23 +08:00 | Yinjian Zhao | git 3f6fce651490
# 2026-10-30 11:25 +08:00 | Yinjian Zhao | git 303832d65c08
# 2026-11-17 13:54 +08:00 | Yinjian Zhao | git 9085032adbf6
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Draw English-labelled K05 probe and circuit schematics (no data fitting).

Source: the experiment owner's circuit/layout sketch and channel identification.
The 100 V scan bias is a DC power supply; the fast 40.5 V bias is a battery.
Geometry is schematic, not to scale; voltage-sense polarity is the page's
explicit assumption. No propagation direction or instrument isolation is inferred.
"""

from pathlib import Path
import argparse
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle, Polygon

INK = "#26354a"
MUTED = "#586a80"
BLUE = "#196db6"
ORANGE = "#be5b14"
TEAL = "#187f7a"
PALE = "#edf4fa"


def text(ax, x, y, value, size=14, color=INK, **kw):
    return ax.text(x, y, value, fontsize=size, color=color,
                   ha=kw.pop("ha", "center"), va=kw.pop("va", "center"), **kw)


def line(ax, points, color=INK, lw=1.7, **kw):
    ax.plot(*zip(*points), color=color, lw=lw, solid_capstyle="round", **kw)


def node(ax, x, y, color=INK):
    ax.add_patch(Circle((x, y), .045, color=color, zorder=5))


def arrow(ax, start, end, color=INK, style="->", lw=1.5):
    ax.annotate("", xy=end, xytext=start,
                arrowprops=dict(arrowstyle=style, color=color, lw=lw,
                                shrinkA=0, shrinkB=0, mutation_scale=12))


def axes(fig, rect, xlim, ylim):
    ax = fig.add_axes(rect)
    ax.set(xlim=xlim, ylim=ylim, aspect="equal")
    ax.axis("off")
    return ax


def save(fig, output, name, description):
    # Glyph paths keep the English figure labels portable across browsers.
    fig.savefig(output / f"{name}.svg", metadata={"Date": None,
                "Description": description}, facecolor="white")
    fig.savefig(output / f"{name}.png", dpi=160, facecolor="white")
    svg = output/f'{name}.svg'
    svg.write_text('\n'.join(line.rstrip() for line in svg.read_text(encoding="utf-8").splitlines())+'\n', encoding="utf-8")
    plt.close(fig)


def layout(output, lang):
    # Keep legacy language-specific filenames; figure labels are always English.
    fig = plt.figure(figsize=(11, 4.9))
    ax = axes(fig, [.025, .12, .46, .82], (0, 5.5), (0, 4.6))
    text(ax, .15, 4.38, "(a) Top view: sampling downstream", 15, ha="left", weight="bold")
    ax.add_patch(Rectangle((.9, 2.9), 3.8, .83, fc="#e5eaf0", ec=MUTED))
    text(ax, 2.8, 3.32, "Hall thruster", 15)
    ax.add_patch(Polygon([(.9, 2.9), (4.7, 2.9), (5.05, 1.20), (.55, 1.20)],
                         fc=PALE, ec="none", zorder=0))
    line(ax, [(.9, 2.9), (4.7, 2.9)], lw=2.1)
    text(ax, 4.75, 2.75, "Exit", 12, ha="right")
    line(ax, [(1.0, 1.30), (4.65, 1.30)], color=MUTED, lw=1, ls="--")
    for x, color, name in [(2.5, BLUE, "C1"), (3.55, ORANGE, "C3")]:
        ax.add_patch(Circle((x, 1.3), .09, fc="white", ec=color, lw=2.4, zorder=5))
        line(ax, [(x, 1.12), (x, .74)], color=color, lw=1)
        text(ax, x, .28, name + ("\nFixed") if name == "C1" else name + ("\nMovable"),
             13, color, weight="bold")
    arrow(ax, (2.5, .79), (3.55, .79), style="<->")
    text(ax, 3.025, 1.0, "3.7 mm", 12)
    # Axial distance and local azimuth are independent dimensions.
    for y in [1.3, 2.9]:
        line(ax, [(.40, y), (.86, y)], color=MUTED, lw=1)
    arrow(ax, (.48, 1.3), (.48, 2.9), style="<->")
    text(ax, .23, 2.10, "5.5 mm", 13, rotation=90)
    arrow(ax, (4.90, 2.35), (4.90, 1.65), color=TEAL)
    text(ax, 4.63, 2.0, "Downstream", 11, TEAL,
         rotation=90)
    text(ax, 3.05, -.08, "Local azimuthal separation", 12, MUTED)

    ax = axes(fig, [.52, .12, .46, .82], (0, 5.5), (0, 4.6))
    text(ax, .15, 4.38, "(b) Front view: facing the annular exit", 15, ha="left", weight="bold")
    center = (2.75, 2.58)
    ax.add_patch(Circle(center, 1.5, fc="#e5eaf0", ec=MUTED, lw=1.4))
    ax.add_patch(Circle(center, .99, fc="white", ec=MUTED, lw=1.4))
    text(ax, 2.75, 2.65, "Annular exit", 15)
    for x, color, label in [(2.53, BLUE, "C1"), (2.97, ORANGE, "C3")]:
        ax.add_patch(Rectangle((x-.09, .48), .18, .58, fc="white", ec=color, lw=1.7))
        line(ax, [(x, 1.06), (x, 1.43)], color=color, lw=2.7)
    line(ax, [(2.53, .72), (1.72, .34)], color=BLUE, lw=1)
    line(ax, [(2.97, .72), (3.78, .34)], color=ORANGE, lw=1)
    text(ax, 1.5, .18, "C1 · Left, fixed", 13, BLUE)
    text(ax, 4.0, .18, "C3 · Movable", 13, ORANGE)
    fig.text(.5, .035, "Redrawn from the experimental layout · Not to scale · No wave direction inferred",
             ha="center", fontsize=13, color=MUTED)
    save(fig, output, f"k05-response-layout-{lang}",
         "C1 left fixed, C3 right movable (stationary here); azimuthal separation 3.7 mm, axial offset 5.5 mm. Not to scale.")


def resistor(ax, x1, x2, y):
    line(ax, [(x1, y), (x1+.24, y)])
    ax.add_patch(Rectangle((x1+.24, y-.14), x2-x1-.48, .28, fc="white", ec=INK, lw=1.7))
    line(ax, [(x2-.24, y), (x2, y)])
    text(ax, (x1+x2)/2, y+.43, r"$R=1\,\mathrm{k}\Omega$", 14)


def supply(ax, x, y, label, positive="right"):
    r = .28
    ax.add_patch(Circle((x, y), r, fc="white", ec=INK, lw=1.7))
    text(ax, x-.13, y, "−" if positive == "right" else "+", 12)
    text(ax, x+.13, y, "+" if positive == "right" else "−", 12)
    text(ax, x, y+.69, label, 13)
    return x-r, x+r


def measurement(ax, x1, x2, y, bottom, label, color, zh=False):
    """Draw English labels; retain the legacy zh argument for existing callers."""
    mid = (x1+x2)/2
    node(ax, x1, y); node(ax, x2, y)
    line(ax, [(x1, y), (x1, bottom), (mid-.24, bottom)], color=color, lw=1.5)
    line(ax, [(mid+.24, bottom), (x2, bottom), (x2, y)], color=color, lw=1.5)
    ax.add_patch(Circle((mid, bottom), .24, fc="white", ec=color, lw=1.5))
    text(ax, mid, bottom, "V", 14, color)
    text(ax, x1+.10, y-.3, "Tip +", 12, color, ha="left")
    text(ax, x2-.10, y-.3, "Clip −", 12, color, ha="right")
    text(ax, mid, bottom-.48, label, 13, color)


def circuits(output, lang):
    # Keep legacy language-specific filenames; figure labels are always English.
    fig = plt.figure(figsize=(11, 7.6))
    ax = axes(fig, [.02, .51, .96, .46], (0, 11), (0, 3.5))
    text(ax, .28, 3.3, "(a) Fast wave probe: 40.5 V battery bias", 16, ha="left", weight="bold")
    y = 1.95
    text(ax, .5, y+.48, "Probe", 14)
    text(ax, .5, y-.37, r"$V_p$", 15)
    line(ax, [(.3, y), (3.04, y)])
    line(ax, [(3.04, y-.14), (3.04, y+.14)], lw=2)
    line(ax, [(3.20, y-.29), (3.20, y+.29)], lw=2)
    text(ax, 2.86, y+.32, "−", 14)
    text(ax, 3.40, y+.32, "+", 14)
    text(ax, 3.12, y+.75, "40.5 V", 14)
    line(ax, [(3.20, y), (4.6, y)])
    resistor(ax, 4.6, 7.4, y)
    line(ax, [(7.4, y), (10.35, y)])
    text(ax, 9.45, y+.48, "Cathode negative", 14)
    text(ax, 9.45, y-.37, r"$V_c$", 15)
    measurement(ax, 4.6, 7.4, y, .88,
                ("Fast oscilloscope ×1 · ")+r"$u_R$", BLUE)
    text(ax, 4.08, y+.40, r"$V_p+40.5\,\mathrm{V}$", 13)

    ax = axes(fig, [.02, .05, .96, .46], (0, 11), (-.1, 3.5))
    text(ax, .28, 3.3, "(b) Slow sweep: 100 V DC bias supply + variable supply", 16, ha="left", weight="bold")
    y = 1.95
    line(ax, [(.3, y), (1.05, y)])
    text(ax, .52, y+.45, "Probe", 14)
    text(ax, .52, y-.38, r"$V_p$", 15)
    resistor(ax, 1.05, 3.9, y)
    line(ax, [(3.9, y), (5.02, y)])
    supply(ax, 5.3, y, r"$V_b=100\,\mathrm{V}$", positive="right")
    line(ax, [(5.58, y), (7.52, y)])
    supply(ax, 7.8, y, "0–350 V", positive="left")
    line(ax, [(8.08, y), (10.25, y), (10.25, y-.52)])
    for yy, width in [(y-.52, .29), (y-.62, .19), (y-.72, .08)]:
        line(ax, [(10.25-width, yy), (10.25+width, yy)])
    text(ax, 10.2, y+.52, "Chamber", 13)
    text(ax, 10.2, .77, "0 V", 13)
    text(ax, 4.04, y+.38, r"$V_s-V_b$", 14)
    text(ax, 6.37, y+.38, r"$V_s$", 15)
    measurement(ax, 1.05, 3.9, y, .85, r"CH4_2 ×1 · $u_R$", BLUE)
    measurement(ax, 6.37, 9.3, y, .85, r"CH3_2 ×1 · $V_s$", TEAL)
    fig.text(.5, .026, "Voltage convention: tip minus clip. Fast and slow circuits use different reference nodes.",
             ha="center", fontsize=13, color=MUTED)
    save(fig, output, f"k05-response-circuits-{lang}",
         "Fast: 40.5 V battery, cathode reference. Slow: 100 V DC supply and 0–350 V supply, chamber reference.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    plt.rcParams.update({"font.family": "DejaVu Sans", "svg.fonttype": "path",
                         "svg.hashsalt": "k05-probe-schematics", "mathtext.fontset": "dejavusans"})
    for lang in ("en", "zh"):
        layout(args.output, lang)
        circuits(args.output, lang)


if __name__ == "__main__":
    main()
