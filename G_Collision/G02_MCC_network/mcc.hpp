// SPDX-License-Identifier: Apache-2.0
//
// Umbrella header for the G02_MCC_network C++20 core.
// G02 的普通 C++ 总入口：应用程序包含此文件即可获得下面各层接口。
// 阅读顺序：common.hpp（基本量）→ model.hpp / compile.hpp（反应模型）
// → engine.hpp / kinematics.hpp（单粒子碰撞）→ batch.hpp（整批推进）。
// 本文件只汇集声明；算法实现位于对应的 .cpp 中。MPI 接口另见 mpi.hpp。
#pragma once

#include "common.hpp"
#include "batch.hpp"
#include "compile.hpp"
#include "csv.hpp"
#include "engine.hpp"
#include "kinematics.hpp"
#include "model.hpp"
#include "rng.hpp"
#include "table.hpp"
