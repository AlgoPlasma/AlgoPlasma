# I_Initializer

[中文](README.zh-CN.md) | [English](README.en.md)

`I_Initializer` contains AlgoPlasma particle-initialization utilities.

## Subdirectories

- `I01_par_distribute`: Fortran-side regular particle initialization, currently covering uniform in-cell positions and Maxwellian velocities.
- `I02_par_init_and_load`: Offline Python binary particle generation plus MPI Fortran loading into local subdomains.

## Data Conventions

- Particle arrays use `par(1:6,...)`: `1:3` are `x,y,z` and `4:6` are `vx,vy,vz`.
- I01 assumes normalized mesh spacing `dx=dy=dz=1`.
- I02 binary files live under `output_init_particles_bin/`, with six `float64` values per particle record.

## Documentation

Detailed initialization workflows, coordinate conventions, and API notes live in
the Sphinx `I_Initializer` pages.
