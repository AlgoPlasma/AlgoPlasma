import matplotlib
matplotlib.use('Agg')

from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt


def main():
    p_map = Path('density_weighted_uniform_physics_map.dat')
    p_axis = Path('density_weighted_uniform_physics_axis0.dat')

    if not p_map.exists() or not p_axis.exists():
        missing = [str(p) for p in [p_map, p_axis] if not p.exists()]
        raise FileNotFoundError('Missing files: ' + ', '.join(missing))

    data = np.loadtxt(p_map)
    axis0 = np.loadtxt(p_axis)

    r = np.unique(data[:, 0])
    z = np.unique(data[:, 1])
    val = data[:, 2].reshape(len(z), len(r))

    fig, ax = plt.subplots(figsize=(7.2, 4.8), constrained_layout=True)
    pcm = ax.pcolormesh(z, r, val.T, shading='nearest')
    cbar = fig.colorbar(pcm, ax=ax)
    cbar.set_label(r'$n/n_0$')
    ax.set_xlabel('z (m)')
    ax.set_ylabel('r (m)')
    ax.set_title(r'Weighted test: $\phi=\pi$ (left), $\phi=0$ (right)')
    ax.set_xlim(z[0], z[-1])
    ax.set_ylim(r[0], r[-1])
    fig.savefig('density_weighted_uniform_physics_map.png', dpi=200, bbox_inches='tight')
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(6.0, 4.0), constrained_layout=True)
    ax.plot(axis0[:, 0], axis0[:, 1], 'o-')
    ax.set_xlabel('z (m)')
    ax.set_ylabel(r'$n(r=0)/n_0$')
    ax.set_title('Weighted test: axis-averaged value at r = 0')
    ax.grid(True, alpha=0.3)
    fig.savefig('density_weighted_uniform_physics_axis0.png', dpi=200, bbox_inches='tight')
    plt.close(fig)

    print('Saved: density_weighted_uniform_physics_map.png')
    print('Saved: density_weighted_uniform_physics_axis0.png')


if __name__ == '__main__':
    main()
