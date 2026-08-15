from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def load_map(path: Path):
    rows = []
    block = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip():
                if block:
                    rows.append(np.array(block, dtype=float))
                    block = []
                continue
            block.append([float(x) for x in line.split()])
        if block:
            rows.append(np.array(block, dtype=float))
    arr = np.stack(rows, axis=0)
    x = arr[0, :, 0]
    y = arr[:, 0, 1]
    z = arr[:, :, 2]
    return x, y, z


def plot_one(ax, path: Path, title: str):
    x, y, z = load_map(path)
    z = np.ma.masked_invalid(z)
    m = ax.pcolormesh(x, y, z, shading='nearest')
    ax.set_title(title)
    ax.set_xlabel('Grid point in z')
    ax.set_ylabel('Grid point in r')
    return m


def main():
    p_jr = Path('current_weighted_jr_map.dat')
    p_jphi = Path('current_weighted_jphi_map.dat')
    p_jz = Path('current_weighted_jz_map.dat')
    p_err = Path('current_weighted_error_map.dat')
    files = [p_jr, p_jphi, p_jz, p_err]
    if not all(p.exists() for p in files):
        missing = [str(p) for p in files if not p.exists()]
        raise FileNotFoundError('Missing files: ' + ', '.join(missing))

    fig, axes = plt.subplots(2, 2, figsize=(10, 8))

    m0 = plot_one(axes[0, 0], p_jr, 'Jr / Jr0')
    fig.colorbar(m0, ax=axes[0, 0])

    m1 = plot_one(axes[0, 1], p_jphi, 'Jphi / Jphi0')
    fig.colorbar(m1, ax=axes[0, 1])

    m2 = plot_one(axes[1, 0], p_jz, 'Jz / Jz0')
    fig.colorbar(m2, ax=axes[1, 0])

    m3 = plot_one(axes[1, 1], p_err, 'log10 |Error|')
    fig.colorbar(m3, ax=axes[1, 1])

    fig.tight_layout()
    fig.savefig('current_weighted_uniform_physics.png', dpi=200)
    print('Saved current_weighted_uniform_physics.png')


if __name__ == '__main__':
    main()
