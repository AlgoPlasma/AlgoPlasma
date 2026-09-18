# FM application test

从仓库根目录运行：

```bash
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference_J01/run.sh
```

默认读取同级 `application_inputs` 中的网格；区域和 ION 损失由 `application_case.f90` 生成。不需要外部程序或历史输出目录。FM 的第一个参数、SN 的第二个参数可指定同样结构的网格目录。

SN 的 B0 参数可改为 ION；FM 目前只有无损 B0。出图需要 NumPy 和 Matplotlib。输入缺失或网格不合法会在编译前报错。

默认输出仍在本应用的 build 目录。若输出目录已有文件，脚本拒绝覆盖；请设置 `APPLICATION_OUTPUT` 到一个新目录。不要为了重跑而直接清理需要保留的结果。

完整应用必须满足前处理完成、密度有限、J03 密度非负、J03 收敛、归一化残差≤1e-8、相对粒子率失衡≤1e-6。密度场变化只记录，不要求与前处理场相同。输出 summary.txt、日志、场数据和两幅密度图。

本次已验证编译和小测试；更改后的大规模应用结果需要重新运行确认。
