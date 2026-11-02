# B04 minimal calling example / 最小调用示例

在非均匀柱坐标环形扇区上，依次准备几何、沉积一个粒子、读取总粒子数，并生成可选的单元体积平均。

Prepare geometry, deposit one particle on a nonuniform cylindrical annular sector,
read represented number, and optionally form cell-volume averages.

- [main.f90](main.f90)
- [双语说明与编译命令 / Bilingual guide and build command](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform/usage.rst)
- [本地编译后的网页 / Locally built HTML](../../docs/build/html/rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform/usage.html)
- [自动测试 / Automated tests](../../tests/004_scatter/B04_scatter_3d_cyl_nonuniform/README.md)

依赖 / Dependencies: GNU Fortran; preprocessing and matching real precision for module and caller.

预期输出 / Expected output:

```text
Represented number =     8.000000
Cell array shape = 2 2 2
```

Author: Xin Luo.
