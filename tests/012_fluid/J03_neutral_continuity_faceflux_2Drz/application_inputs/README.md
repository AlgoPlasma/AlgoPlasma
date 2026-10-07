# Application inputs

This directory contains the fixed 256-cell radial and axial edge tables for the B0 and ION applications. Columns are cell index (1-based), lower edge, upper edge and width, in metres. These are input geometry, not reference solution fields. The tables preserve the nonuniform mesh used for the existing application figures.

The common `../application_case.f90` defines the active region: `(65:192,1:72)` and `(:,73:256)`, using Fortran 1-based indices. There are 56320 active cells. Both preprocessors and both J03 drivers use this same definition.

B0 has zero volume loss. ION uses a prescribed cosine window evaluated at cell centres:

```text
nu(r,z) = 1e5*cos(pi*(r-rmid)/(rmax-rmin))*cos(pi*(z-zmid)/(zmax-zmin)) [s^-1]
rmin = 0.013683098220475191 m
rmax = 0.024672244366128356 m
zmin = 0.0024709824265487373 m
zmax = 0.010022411397665104 m
```

It is zero outside the window and inactive region. No archived mask, ionization field or density output is needed. FM currently implements B0 only. This prescribed ION field tests transport with loss, not self-consistent PIC ionization.

Validate with `python3 ../validate_application_inputs.py .` from this directory. A custom input directory must contain the same two grid filenames and the same 256x256 index topology.
