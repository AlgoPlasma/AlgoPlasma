Error Reference
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J03_error.f90`` 提供 ``fun_J03_error_message(ierr)``，
   将整数状态码转换为长度 160 的字符串。
   调用程序根据返回码取得错误说明，再决定如何输出信息和处理失败。
   先检查状态，再决定能否读取本次输出。

   .. rubric:: 1. 返回码与排查位置

   .. list-table::
      :header-rows: 1
      :widths: 10 32 58

      * - 值
        - 常量
        - 含义与排查方向
      * - 0
        - ``J03_SUCCESS``
        - 已执行的接口检查通过；不等于所有物理输入均已验收
      * - 101
        - ``J03_ERR_SHAPE``
        - 单元、内部面、四面数组的形状不一致
      * - 102
        - ``J03_ERR_GEOMETRY``
        - 无有效单元、有效体积非正、面积为负，或内部面面积非正/两侧不一致
      * - 103
        - ``J03_ERR_NEGATIVE_INPUT``
        - 对应过程检测到负损失、负源项，或关闭截断时的负输入密度
      * - 104
        - ``J03_ERR_FACE_TYPE``
        - 非法面类型，或内部面没有合法、有效且相互对应的邻居
      * - 105
        - ``J03_ERR_OPTIONS``
        - 时间步、CFL、密度下限比例、容差、迭代数或进度间隔不满足该过程要求
      * - 106
        - ``J03_ERR_NOT_CONVERGED``
        - 稳态求解达到迭代上限，尚未同时满足变化量和残差条件

   消息字符串是英文简述，表中补充了实际检查范围。
   例如几何错误字符串写“面积须为正”，但代码对物理轴线边界允许零面积，
   仅内部公共面要求严格正值。应以接口页列出的条件为准。

   未识别的整数返回包含该数值的 unknown J03 error code 说明。
   错误码只在 J03 内解释，记录日志时应同时写出模块、过程名、物理时间或迭代数。

   .. rubric:: 2. 错误发生后还能使用什么

   初始化或单步的早期检查失败时，输出对象或可分配数组可能没有建立。
   不能不加判断地继续调用下一过程。

   稳态达到上限时，返回最后完整密度、已完成迭代数和相应诊断；
   这些可用于排查，但不能报告为已收敛解。
   其他中途失败应按具体调用阶段判断输出是否有效。

   J03 当前没有返回失败单元索引或速度方向的接口，
   错误说明也不会自动定位到某个面。排查几何或负输入时，应用应检查原输入数组，
   不能期待这里产生粒子跟踪或扫描方向信息。

   .. rubric:: 3. 成功返回没有覆盖的检查

   - 初始化不全面检查参考场有限性、参考密度非负性和边界通量符号。
   - 单步不自动检查给定时间步是否小于稳定上限。
   - 关闭负值截断时，负输出不会由本次单步自动转换成错误。
   - 收支与残差过程主要检查形状，不代替输入物理验收。

   因此实际应用还应检查有限值、密度最小值和离散收支。
   这些限制是当前接口的事实，不应在文档中写成“成功返回即保证结果正确”。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``fun_J03_error_message(ierr)`` returns a 160-character message without printing,
   terminating or changing the field. Codes are:
   0 success, 101 shape, 102 geometry, 103 negative input, 104 face type/topology,
   105 options, and 106 steady iteration limit. Unknown codes include the integer value.

   Geometry checks allow zero-area physical axis faces but require positive matching internal areas.
   A steady iteration-limit result retains the last complete state and diagnostics, not a converged solution.
   Early failures may leave outputs unallocated. J03 does not return failed-cell or velocity indices.

   Success does not guarantee finite/nonnegative reference fields or correct incoming/outgoing signs.
   The step does not enforce its stable-time bound or report all negative outputs automatically.
   Callers must validate inputs and check finite values, minimum density and discrete balance.
