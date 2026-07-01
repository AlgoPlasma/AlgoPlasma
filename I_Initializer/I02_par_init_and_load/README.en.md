# I02_par_init_and_load

[中文](README.zh-CN.md) | [English](README.en.md)

`I02_par_init_and_load` provides an offline binary particle generator and an MPI
loader workflow.

## Files

- `init_particles_bin.py`: generates initial electron and ion particles in a three-dimensional T-shaped region, then writes binary files and diagnostic plots.
- `mod_I02_load_init_particles_bin.f90`: Fortran module wrapper.
- `sub_I02_load_init_particles_bin.f90`: reads binary particle files and filters local particles for the current MPI subdomain.

## Inputs and Outputs

- Python output directory: `output_init_particles_bin/`
- Electron file: `par_ele_init.bin`
- Ion file: `par_ion_init.bin`
- Particle record layout: `x,y,z,vx,vy,vz` as `float64`.

## Dependencies

- The Python script depends on NumPy, SciPy, and Matplotlib.
- The Fortran loader depends on MPI and is organized with `include`.
- The default particle count is large, so check memory and disk space before running the script.
