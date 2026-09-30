// SPDX-License-Identifier: Apache-2.0
// C 接口实现内部共用的句柄定义，不是供应用程序包含的公共头文件。
// c_api.h 只公开句柄名字；此处说明句柄实际持有哪些 C++ 对象。
// 普通 C 接口与 MPI C 接口由此共享同一种引擎和报告。
#pragma once

#include "batch.hpp"
#include "c_api.h"

struct ap_g02_mcc_engine {
    algoplasma::mcc::MccEngine engine;
    mutable std::uint64_t next_batch_id{0};
    explicit ap_g02_mcc_engine(algoplasma::mcc::CompiledModel model)
        : engine(std::move(model)) {}
};

struct ap_g02_mcc_step_report {
    algoplasma::mcc::StepReport report;
};
