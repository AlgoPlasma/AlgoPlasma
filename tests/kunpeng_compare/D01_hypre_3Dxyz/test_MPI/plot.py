import numpy as np
import matplotlib.pyplot as plt

plt.rcParams.update({"font.size": 16})

nx = 320
ny = 80
nz = 320

phi1d = np.loadtxt("phi.dat")
phi3d = np.zeros((nx, ny, nz))

l = 0
for k in range(nz):
    for j in range(ny):
        for i in range(nx):
            phi3d[i, j, k] = phi1d[l]
            l += 1

plt.figure(dpi=300)
plt.imshow(np.log10(phi3d[:, int(ny / 2), :]), aspect="auto", origin="lower")
#plt.imshow((phi3d[:, int(ny / 2), :]), aspect="auto", origin="lower")
plt.xlabel(r"$z$")
plt.ylabel(r"$x$")
plt.title(r"$\log_{10}{\phi}$")
#plt.title(r"$\phi$")
plt.colorbar()
plt.savefig("phi_zx.png", bbox_inches="tight")
plt.close()
