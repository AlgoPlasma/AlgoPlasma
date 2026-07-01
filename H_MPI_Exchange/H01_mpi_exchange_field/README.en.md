# H01_mpi_exchange_field

[中文](README.zh-CN.md) | [English](README.en.md)

`H01_mpi_exchange_field` exchanges one scalar-field ghost/halo cell layer.

## Files

- `mod_H01_mpi_exchange_field.f90`: module wrapper.
- `sub_H01_mpi_exchange_field.f90`: main field ghost-exchange routine.
- `inc_exchange_in_x.f90`: x-direction exchange implementation.
- `inc_exchange_in_y.f90`: y-direction exchange implementation.
- `inc_exchange_in_z.f90`: z-direction exchange implementation.
- `inc_send_recv.f90`: blocking send followed by recv.
- `inc_recv_send.f90`: blocking recv followed by send.

## Main Interface

`sub_H01_mpi_exchange_field(il,iu,f,mpi_n,rank_to_ijk,domain_split,ijk_to_rank,l)`

## Notes

`f` must include one ghost layer and span `il(d)-1:iu(d)+1`. Non-periodic
physical boundary conditions are not completed by this routine.
