# J_Fluid

[中文](README.zh-CN.md) | [English](README.en.md)

`J_Fluid` contains AlgoPlasma fluid updates and neutral-transport
preprocessors.

## Subdirectories

- `J01_free_molecular`: particle preprocessing and the existing continuity/flux utilities, kept as two modules in one source directory.
- `J02_neutral_sn_transport_2Drz`: reusable neutral SN P1-DG preprocessing
  components on an axisymmetric r-z mesh.
- `J03_neutral_continuity_faceflux_2Drz`: consumes J01/J02 reference face
  fluxes and solves the axisymmetric continuity equation without rerunning the
  transport preprocessor.

## Conventions

- J01 retains its normalized three-dimensional interface and adds an r-z FM
  interface using physical cell volume and face area.
- J02 uses physical r-z cell-edge coordinates and explicit cylindrical
  geometry; its numerical kernel does not read PIC input files.
- J03 freezes the transport closure supplied by J01 or J02.

## Documentation

Detailed numerical schemes, index conventions, and API notes live in the Sphinx
`J_Fluid` pages.
