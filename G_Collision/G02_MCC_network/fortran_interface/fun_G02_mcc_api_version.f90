! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 返回 C ABI 的接口版本整数，用来确认链接的是兼容的库。
    ! 不加载 CSV，不创建模型，也不进行碰撞计算。
    integer(c_int) function fun_G02_mcc_api_version() result(version)
        version = ap_g02_mcc_api_version()
    end function fun_G02_mcc_api_version
