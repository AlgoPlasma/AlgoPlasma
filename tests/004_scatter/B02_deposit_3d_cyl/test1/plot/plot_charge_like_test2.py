import matplotlib
matplotlib.use('Agg')

import numpy as np
import matplotlib.pyplot as plt


def main():
    data = np.loadtxt('density_uniform_map.dat')
    axis0 = np.loadtxt('density_uniform_axis0.dat')

    r = np.unique(data[:, 0])
    z = np.unique(data[:, 1])
    val = data[:, 2].reshape(len(z), len(r))

    fig, ax = plt.subplots(figsize=(7.2, 4.8), constrained_layout=True)
    pcm = ax.pcolormesh(z, r, val.T, shading='nearest')
    cbar = fig.colorbar(pcm, ax=ax)
    cbar.set_label(r'$n/n_0$')
    ax.set_xlabel('z (m)')
    ax.set_ylabel('r (m)')
    ax.set_title(r'Uniform grid: $\phi=\pi$ (left), $\phi=0$ (right)')
    ax.set_xlim(z[0], z[-1])
    ax.set_ylim(r[0], r[-1])
    fig.savefig('density_uniform_map.png', dpi=200, bbox_inches='tight')
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(6.0, 4.0), constrained_layout=True)
    ax.plot(axis0[:, 0], axis0[:, 1], 'o-')
    ax.set_xlabel('z (m)')
    ax.set_ylabel(r'$n(r=0)/n_0$')
    ax.set_title('Axis-averaged value at r = 0')
    ax.grid(True, alpha=0.3)
    fig.savefig('density_uniform_axis0.png', dpi=200, bbox_inches='tight')
    plt.close(fig)

    print('Saved: density_uniform_map.png')
    print('Saved: density_uniform_axis0.png')


if __name__ == '__main__':
    main()
