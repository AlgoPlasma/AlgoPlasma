# B04 最小调用示例

[English](README.md)

[main.f90](main.f90) 在非均匀柱坐标环形扇区上，沉积一个代表八个真实粒子的宏粒子，
角向两端采用物理端面。调用顺序为 **准备体积 → 清零密度 → 沉积 → 汇总代表粒子数 → 可选的单元体积平均**。

## 编译与运行

使用 Bash（例如 Linux 或 WSL 环境）和 GNU Fortran。从仓库根目录执行：

```bash
mkdir -p examples/B04_scatter_3Draz_nonuniform/build
gfortran -cpp -std=f2008 -fdefault-real-8 -O0 -g -fcheck=all \
  -I B_Scatter/B04_scatter_3Draz_nonuniform \
  -J examples/B04_scatter_3Draz_nonuniform/build \
  B_Scatter/B04_scatter_3Draz_nonuniform/mod_B04_scatter_3Draz_nonuniform.f90 \
  examples/B04_scatter_3Draz_nonuniform/main.f90 \
  -o examples/B04_scatter_3Draz_nonuniform/build/b04_minimal
examples/B04_scatter_3Draz_nonuniform/build/b04_minimal
```

命令启用预处理，并以相同的双精度选项编译模块和调用方。
构建产物保存在示例目录的 `build/` 中，由 Git 忽略。

## 预期输出

```text
Represented number =     8.000000
Cell array shape = 2 2 2
```

沉积后的节点数据合计代表八个真实粒子，与输入宏粒子的权重一致。
单元平均数组在径向、角向和轴向各有两个单元。

## 继续阅读

- [模块与调用约定](../../B_Scatter/B04_scatter_3Draz_nonuniform/README.zh-CN.md)
- [使用指南及接入自己程序的方法](../../docs/source/rst_files/B_Scatter/B04_scatter_3Draz_nonuniform/usage.rst)（双语 Sphinx 源文件）
- [自动测试](../../tests/004_scatter/B04_scatter_3Draz_nonuniform/README.zh-CN.md)

文档构建完成后，可打开相对于仓库根目录的本地文件
`docs/build/html/rst_files/B_Scatter/B04_scatter_3Draz_nonuniform/usage.html`。

作者：Xin Luo。
