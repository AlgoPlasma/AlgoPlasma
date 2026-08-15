# D06_phi_to_E

[中文](README.zh-CN.md) | [English](README.en.md)

使用二阶中心差分格式由静电势计算三个电场分量（E = -∇φ，dx = dy = dz = 1）。

## 文件

- `mod_D06_phi_to_E.f90`: 模块包装文件。
- `sub_D06_phi_to_E.f90`: 主子程序。

## 主接口

```fortran
call sub_D06_phi_to_E(il, iu, phi, Ex, Ey, Ez)
```

- `phi(il(1)-1:iu(1)+1, ...)`：含单层幽灵格点的三维势场数组，调用前幽灵格点须已填充（如由 D05 完成）。
- `Ex/Ey/Ez(il(1)-1:iu(1)+1, ...)`：输出电场数组，物理域 `il:iu` 内的值在调用后被赋值。

差分格式：
```
Ex(i,j,k) = (phi(i-1,j,k) - phi(i+1,j,k)) * 0.5
Ey(i,j,k) = (phi(i,j-1,k) - phi(i,j+1,k)) * 0.5
Ez(i,j,k) = (phi(i,j,k-1) - phi(i,j,k+1)) * 0.5
```

## 依赖

无（不需要 MPI 或外部库）。
