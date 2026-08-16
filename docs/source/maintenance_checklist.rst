Documentation Checklist
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 轻量检查清单

   这页给文档维护时使用，不替代完整 review。新增或重写一个模块后，至少检查以下几项：

   - 模块入口页、子模块概览页和 routine/API 页都包含 ``ap-language-switch``。
   - routine/API 页的 ``.. doxygenfile::`` 保持在英文语言块里，中文侧只写简短用途、接口和注意事项。
   - 需要双语 README 的模块目录不再残留旧的单文件 ``README.md``。
   - 模块页指向相关测试页，测试页反向指向算法/API 页；无独立测试时要明确说明状态。
   - Sphinx 构建不新增 warning，尤其是 title underline、重复 target、损坏引用和 Doxygen/Breathe warning。

   .. rubric:: 命令思路

   如果不确定本机文档环境如何启用，先询问维护者；如果确认使用 ``~/.venv``，可按下面检查：

   .. code-block:: bash

      cd docs
      source ~/.venv/bin/activate
      sphinx-build -b html source build/html -j 1 2>&1 | tee /tmp/ap-sphinx.log
      rg "WARNING|ERROR" /tmp/ap-sphinx.log

   查找没有语言切换的 RST 页面：

   .. code-block:: bash

      cd docs/..
      while IFS= read -r f; do
        rg -q "ap-language-switch" "$f" || echo "$f"
      done < <(rg --files docs/source -g "*.rst")

   查找 ``.. doxygenfile::`` 页面，并人工确认它位于英文语言块内：

   .. code-block:: bash

      rg -n "\\.\\. doxygen(file|function|class|struct)::" docs/source -g "*.rst"

   查找 D_Poisson 等文档化模块中是否残留旧 ``README.md``：

   .. code-block:: bash

      find A_Pusher B_Scatter C_Gather D_Poisson E_Maxwell F_IO G_Collision H_MPI_Exchange I_Initializer J_Fluid \
        -name README.md -print

   .. rubric:: 脚本化建议

   后续可以把这些检查收敛成一个只读脚本，例如 ``tools/check_docs_layout.py``。脚本只报告问题，不自动改文件；
   输出项建议包括缺失语言切换、Doxygen 指令位置、旧 README、孤立 tests 页面和 Sphinx warning 摘要。

.. container:: ap-lang ap-lang-en

   .. rubric:: Lightweight Checklist

   This page is for documentation maintenance and does not replace a full
   review. After adding or rewriting a module, check at least the following:

   - Module entry pages, submodule overview pages, and routine/API pages contain ``ap-language-switch``.
   - On routine/API pages, ``.. doxygenfile::`` stays inside the English language block; the Chinese side keeps only short purpose, interface, and notes.
   - Module directories that use bilingual READMEs no longer keep an old single-file ``README.md``.
   - Module pages link to related test pages, and test pages link back to algorithm/API pages; modules without standalone tests state that status explicitly.
   - Sphinx builds add no warnings, especially title-underlines, duplicate targets, broken references, and Doxygen/Breathe warnings.

   .. rubric:: Command Ideas

   If the local documentation environment is unknown, ask the maintainer first.
   If ``~/.venv`` is confirmed, the build check can be:

   .. code-block:: bash

      cd docs
      source ~/.venv/bin/activate
      sphinx-build -b html source build/html -j 1 2>&1 | tee /tmp/ap-sphinx.log
      rg "WARNING|ERROR" /tmp/ap-sphinx.log

   Find RST pages without a language switch:

   .. code-block:: bash

      cd docs/..
      while IFS= read -r f; do
        rg -q "ap-language-switch" "$f" || echo "$f"
      done < <(rg --files docs/source -g "*.rst")

   Find ``.. doxygenfile::`` pages, then manually confirm the directive is inside
   the English language block:

   .. code-block:: bash

      rg -n "\\.\\. doxygen(file|function|class|struct)::" docs/source -g "*.rst"

   Find old ``README.md`` files in documented module directories:

   .. code-block:: bash

      find A_Pusher B_Scatter C_Gather D_Poisson E_Maxwell F_IO G_Collision H_MPI_Exchange I_Initializer J_Fluid \
        -name README.md -print

   .. rubric:: Script Idea

   These checks can later be gathered into a read-only script such as
   ``tools/check_docs_layout.py``. The script should report issues without
   changing files; useful output includes missing language switches, Doxygen
   directive placement, old READMEs, orphan test pages, and a Sphinx warning
   summary.
