Developer Quick Start
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-onboarding

   .. container:: ap-onboarding-hero

      .. rubric:: 开发者快速入门

      这条路线面向要参与 AlgoPlasma 维护和开发的新人。目标是先安全地改一个小地方，而不是一上来理解完整程序体系。

      .. raw:: html

         <div class="ap-onboarding-path" aria-label="Developer quick start path">
           <span>看目录结构</span>
           <span>读一个模块</span>
           <span>跑对应测试</span>
           <span>做一个小贡献</span>
         </div>

   .. container:: ap-onboarding-done

      .. rubric:: 完成标准

      - 能指出 A01 的 README、源码入口、核心子程序和测试主程序分别在哪里。
      - 能说清 ``sub_A01_Boris_3Dxyz(v, E, B, k)`` 的输入输出。
      - 能完成一个只影响单个模块或单个测试目录的小修改。
      - 能搭起文档构建环境，知道 ``git status``、``git diff``、``git add``、``git commit`` 分别在做什么。

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 1. 先知道目录怎么分

      开发者先记住这些目录就够了：

      .. list-table::
         :header-rows: 1
         :widths: 24 46 30

         * - 目录
           - 做什么
           - 新人怎么用
         * - ``A_Pusher``
           - 粒子推进器。
           - 最先看，推荐从 ``A01_Boris_3Dxyz`` 开始。
         * - ``B_Scatter``
           - 粒子到网格沉积。
           - 看完 A01 后再看。
         * - ``C_Gather``
           - 网格到粒子插值。
           - 和 B_Scatter 放在一起理解。
         * - ``D_Poisson`` / ``E_Maxwell`` / ``H_MPI_Exchange``
           - 场求解和并行交换。
           - 有基础后再看，第一次不要从这里开始。
         * - ``tests``
           - 测试和验证算例。
           - 修改模块后先跑对应测试。
         * - ``docs``
           - Sphinx + Doxygen 文档。
           - 查公式、接口说明、测试文档和维护说明。

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 2. 第一次只读一个模块

      推荐先读 ``A_Pusher/A01_Boris_3Dxyz``，顺序固定成这样：

      .. code-block:: text

         A_Pusher/A01_Boris_3Dxyz/README.zh-CN.md
         -> A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90
         -> A_Pusher/A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz.f90
         -> tests/002_pusher/A01_Boris_3Dxyz/source_f90/main.f90
         -> tests/002_pusher/A01_Boris_3Dxyz/make.sh
         -> tests/002_pusher/A01_Boris_3Dxyz/run.sh

      读的时候只回答三个问题：

      - 公开子程序叫什么？
      - 输入、输出数组是什么形状？
      - 测试程序是怎么准备参数并调用它的？

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 3. 跑对应测试

      修改一个模块前后，都先跑对应的局部测试。A01 的最小命令是：

      .. code-block:: bash

         cd tests/002_pusher/A01_Boris_3Dxyz
         ./clean.sh
         ./make.sh
         ./run.sh

      如果改的是文档，再构建一次 Sphinx：

      .. code-block:: bash

         cd docs
         ./make.sh

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 4. 补充说明：环境、Git、Sphinx

      下面这些内容第一次不用全部背下来。先按命令跑通，需要查的时候再展开看。

      .. raw:: html

         <details class="ap-details">
           <summary>需要的基础环境</summary>
           <p>最小开发环境先满足能编译 A01、能构建文档即可：</p>
           <ul>
             <li><code>git</code>：获取代码、查看修改、提交修改。</li>
             <li><code>make</code> 和 Fortran 编译器：先用 <code>gfortran</code>，有 MPI 测试时再用 <code>mpifort</code>。</li>
             <li><code>python3</code>、<code>venv</code>、<code>pip</code>：安装 Sphinx 相关 Python 包。</li>
             <li><code>doxygen</code>：从 Fortran 源码注释生成 API XML。</li>
             <li><code>graphviz</code>：让 Sphinx 里的流程图、结构图能正常生成。</li>
           </ul>
           <p>注意：当前不少 Fortran 程序直接使用默认 <code>real</code>。如果需要按双精度编译，通常要在编译命令里加对应选项，例如 <code>gfortran -fdefault-real-8</code> 或 <code>ifx -real-size 64</code>；测试目录里的 <code>make.sh</code> 若已经写入该选项，直接按脚本运行即可。</p>
           <p>先用这些命令确认环境是否已经可用：</p>
           <pre><code>git --version
         make --version
         gfortran --version
         python3 --version
         doxygen --version
         dot -V</code></pre>
           <p>MPI、HDF5、HYPRE、OpenMP 属于模块级依赖，不是第一次阅读 A01 必须装的内容；用到对应模块时再看测试目录里的说明。</p>
         </details>

         <details class="ap-details">
           <summary>环境怎么安装</summary>
           <p>在 Ubuntu 或 WSL 上，先装系统工具：</p>
           <pre><code>sudo apt update
         sudo apt install -y git make gfortran python3 python3-venv python3-pip doxygen graphviz</code></pre>
           <p>再在仓库根目录创建 Python 虚拟环境并安装文档依赖：</p>
           <pre><code>python3 -m venv .venv
         source .venv/bin/activate
         pip install -r docs/requirements.txt</code></pre>
           <p>之后如果需要重新激活这个虚拟环境，在仓库根目录运行：</p>
           <pre><code>source .venv/bin/activate</code></pre>
           <p>退出虚拟环境时运行：</p>
           <pre><code>deactivate</code></pre>
           <p>如果只跑 A01 的 Fortran 测试，不需要先激活虚拟环境；如果构建 Sphinx 文档，就建议先激活它。</p>
         </details>

         <details class="ap-details">
           <summary>Git 第一次上手</summary>
           <p>Git 可以先理解成“给代码拍快照并同步到远程仓库”的工具。第一次只需要记住这几个词：</p>
           <ul>
             <li><code>working tree</code>：工作区，也就是你正在编辑的文件。</li>
             <li><code>stage</code>：暂存区，也就是这次准备提交哪些改动。</li>
             <li><code>commit</code>：一次本地快照，提交后还没有自动上传。</li>
             <li><code>branch</code>：分支，用来把自己的修改和主线隔开。</li>
             <li><code>remote</code>：远程仓库，<code>origin</code> 和 <code>upstream</code> 都只是远程仓库的名字。</li>
           </ul>
           <p>这张图可以先看作一次修改在 Git 里的流向：</p>
           <div class="ap-git-visual" role="img" aria-label="一次 Git 修改从工作区到远程分支的流程">
             <div class="ap-git-track">
               <div class="ap-git-node ap-git-node-work">
                 <strong>工作区</strong>
                 <span>编辑文件，改动还只在本地文件里。</span>
                 <code>git diff</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-stage">
                 <strong>暂存区</strong>
                 <span>选择这次要提交的文件。</span>
                 <code>git add</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-commit">
                 <strong>本地提交</strong>
                 <span>生成一次本地快照。</span>
                 <code>git commit</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-remote">
                 <strong>远程分支</strong>
                 <span>把本地提交上传给别人看。</span>
                 <code>git push</code>
               </div>
             </div>
             <p class="ap-git-caption">新手先记住这条线：改文件后先看差异，再 add，确认暂存区内容，commit，最后 push。</p>
           </div>
           <p>第一次在电脑上使用 Git，先配置姓名和邮箱，这会写进提交记录：</p>
           <pre><code>git config --global user.name "Your Name"
         git config --global user.email "your.email@example.com"</code></pre>
           <p>如果还没有代码，先克隆仓库；如果已经有仓库，可以跳过这一步：</p>
           <pre><code>git clone &lt;repo-url&gt; algoplasma
         cd algoplasma</code></pre>
           <p>进入仓库后，先看当前分支、远程仓库和本地修改：</p>
           <pre><code>git branch -vv
         git remote -v
         git status</code></pre>
           <p>最推荐的新手开发流程是：从最新的 <code>master/develop</code> 拉一个自己的小分支，然后只在这个分支上改。</p>
           <pre><code>git switch master
         git pull --ff-only origin master
         # 如果仓库使用 develop 作为主线，把 master 换成 develop。
         git switch -c docs/onboarding-notes</code></pre>
           <p>改完文件后，按这个顺序检查并提交：</p>
           <pre><code>git status
         git diff
         git add docs/source/developer_quick_start.rst
         git diff --cached
         git commit -m "Update developer quick start"</code></pre>
           <ul>
             <li><code>git status</code> 看哪些文件被改了。</li>
             <li><code>git diff</code> 看还没有放进暂存区的具体改动。</li>
             <li><code>git add</code> 选择这次要提交的文件，不等于上传。</li>
             <li><code>git diff --cached</code> 看这次提交将包含哪些内容。</li>
             <li><code>git commit</code> 生成本地快照，不等于上传。</li>
           </ul>
           <p>确认提交没有问题后，再推送到远程仓库：</p>
           <pre><code>git push origin docs/onboarding-notes</code></pre>
           <p>如果暂时要收起本地修改，用 <code>stash</code>；它只适合临时保存，不适合长期备份：</p>
           <pre><code>git stash push -m "work in progress"
         git stash pop</code></pre>
           <p>第一次使用 Git 时，先不要用 <code>git push --force</code>、<code>git reset --hard</code> 这类会改远程历史或丢弃本地修改的命令。</p>
         </details>

         <details class="ap-details">
           <summary>Sphinx 文档怎么改</summary>
           <p>这个仓库的文档由 Sphinx、Doxygen 和 Breathe 一起生成：Sphinx 把 RST 页面转成 HTML，Doxygen 从 Fortran 源码注释生成 API XML，Breathe 再把这些 API 信息接进 Sphinx 页面。</p>
           <ul>
             <li><code>docs/source/*.rst</code> 是主要文档源文件。</li>
             <li><code>docs/source/images/</code> 放文档图片。</li>
             <li><code>docs/source/_static/custom.css</code> 放页面样式。</li>
             <li><code>docs/build/html/</code> 是生成结果，不要手动改这里。</li>
           </ul>
           <p>改完文档后从仓库根目录运行：</p>
           <pre><code>source .venv/bin/activate
         cd docs
         ./make.sh</code></pre>
           <p>如果构建失败，优先看终端最后的 warning 或 error。常见原因是缺 Python 包、缺 Doxygen、缺 Graphviz，或者 RST 标题层级和缩进写错。</p>
         </details>

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: 第一次贡献做什么

         第一次不要直接改核心算法。推荐做小而清楚的改动：

         - 给 README 补一个参数说明。
         - 给测试文档补运行命令或输出解释。
         - 给已有测试补一句验证标准。
         - 给 Sphinx 页面补一个链接，让测试页和算法页互相能找到。

      .. container:: ap-onboarding-note

         .. rubric:: 提交前检查

         - 修改范围是不是只围绕一个模块或一个测试目录？
         - 公开接口、数组形状、单位或边界约定有没有说清楚？
         - 对应测试有没有跑过？
         - 有没有无意中加新的编译依赖？
         - 如果改了 Sphinx 文档，能不能重新构建文档？

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: 常见卡点

         - ``run.sh`` 报找不到 ``build``：先运行 ``./make.sh``。
         - ``make.sh`` 编译失败：先确认本机有 ``gfortran``，并从测试目录运行脚本。
         - ``plot.sh`` 失败：不影响第一次开发入门，先确认 ``build/case*.dat`` 已生成。
         - 文档构建失败：先记录缺的工具或 Python 包，再继续做代码阅读。

      .. container:: ap-onboarding-note ap-onboarding-route

         .. rubric:: 后续学习路线

         .. code-block:: text

            A01_Boris_3Dxyz
            -> B01_scatter_3Dxyz
            -> C01_gather_3Dxyz
            -> E_Maxwell 或 D_Poisson
            -> H_MPI_Exchange

         这样走是先掌握“粒子推进、沉积、插值”这条最直观的链路，再进入场求解和并行交换。

.. container:: ap-lang ap-lang-en ap-onboarding

   .. container:: ap-onboarding-hero

      .. rubric:: Developer Quick Start

      This route is for new contributors who want to maintain or extend AlgoPlasma. The goal is to make one small safe change first, not to understand a full PIC program immediately.

      .. raw:: html

         <div class="ap-onboarding-path" aria-label="Developer quick start path">
           <span>Scan layout</span>
           <span>Read one module</span>
           <span>Run its tests</span>
           <span>Make one small contribution</span>
         </div>

   .. container:: ap-onboarding-done

      .. rubric:: The First Pass Is Done When

      - You can point to the A01 README, module entry, core subroutine, and test main program.
      - You can explain the inputs and outputs of ``sub_A01_Boris_3Dxyz(v, E, B, k)``.
      - You can finish one small change limited to one module or one test directory.
      - You can build the documentation environment and understand what ``git status``, ``git diff``, ``git add``, and ``git commit`` do.

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 1. Know The Main Directories

      New developers only need this first-pass map:

      .. list-table::
         :header-rows: 1
         :widths: 24 46 30

         * - Directory
           - Role
           - First-use advice
         * - ``A_Pusher``
           - Particle pushers.
           - Start here, preferably with ``A01_Boris_3Dxyz``.
         * - ``B_Scatter``
           - Particle-to-grid deposition.
           - Read after A01.
         * - ``C_Gather``
           - Grid-to-particle interpolation.
           - Learn together with B_Scatter.
         * - ``D_Poisson`` / ``E_Maxwell`` / ``H_MPI_Exchange``
           - Field solvers and parallel exchange.
           - Read later; do not start here.
         * - ``tests``
           - Tests and validation cases.
           - Run the relevant tests after changing a module.
         * - ``docs``
           - Sphinx + Doxygen documentation.
           - Use for formulas, interface notes, tests, and maintenance notes.

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 2. Read One Module First

      Stay with ``A_Pusher/A01_Boris_3Dxyz`` for the first read:

      .. code-block:: text

         A_Pusher/A01_Boris_3Dxyz/README.en.md
         -> A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90
         -> A_Pusher/A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz.f90
         -> tests/002_pusher/A01_Boris_3Dxyz/source_f90/main.f90
         -> tests/002_pusher/A01_Boris_3Dxyz/make.sh
         -> tests/002_pusher/A01_Boris_3Dxyz/run.sh

      Answer only three questions while reading:

      - What is the public subroutine name?
      - What are the input and output array shapes?
      - How does the test program prepare parameters and call the routine?

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 3. Run The Relevant Tests

      Before and after changing a module, run the local tests first. For A01:

      .. code-block:: bash

         cd tests/002_pusher/A01_Boris_3Dxyz
         ./clean.sh
         ./make.sh
         ./run.sh

      If documentation changed, build Sphinx too:

      .. code-block:: bash

         cd docs
         ./make.sh

   .. container:: ap-onboarding-step ap-onboarding-dev

      .. rubric:: 4. Extra Notes: Environment, Git, Sphinx

      You do not need to memorize these on day one. First run the commands, then open these notes when something gets stuck.

      .. raw:: html

         <details class="ap-details">
           <summary>Required environment</summary>
           <p>The minimal contributor environment only needs to compile A01 and build the docs:</p>
           <ul>
             <li><code>git</code>: fetch code, inspect changes, and commit changes.</li>
             <li><code>make</code> and a Fortran compiler: start with <code>gfortran</code>; use <code>mpifort</code> when running MPI tests.</li>
             <li><code>python3</code>, <code>venv</code>, and <code>pip</code>: install the Sphinx Python packages.</li>
             <li><code>doxygen</code>: generate API XML from Fortran source comments.</li>
             <li><code>graphviz</code>: render diagrams used by Sphinx pages.</li>
           </ul>
           <p>Note: many Fortran programs currently use default <code>real</code>. If double precision is required, add the corresponding compiler option, such as <code>gfortran -fdefault-real-8</code> or <code>ifx -real-size 64</code>. If a test directory's <code>make.sh</code> already contains that option, run the script as written.</p>
           <p>Check the environment first:</p>
           <pre><code>git --version
         make --version
         gfortran --version
         python3 --version
         doxygen --version
         dot -V</code></pre>
           <p>MPI, HDF5, HYPRE, and OpenMP are module-level dependencies. They are not required for the first A01 read; install them when the relevant test page asks for them.</p>
         </details>

         <details class="ap-details">
           <summary>Install the environment</summary>
           <p>On Ubuntu or WSL, install the system tools first:</p>
           <pre><code>sudo apt update
         sudo apt install -y git make gfortran python3 python3-venv python3-pip doxygen graphviz</code></pre>
           <p>Then create a Python virtual environment at the repository root and install the documentation dependencies:</p>
           <pre><code>python3 -m venv .venv
         source .venv/bin/activate
         pip install -r docs/requirements.txt</code></pre>
           <p>Later, activate this virtual environment from the repository root with:</p>
           <pre><code>source .venv/bin/activate</code></pre>
           <p>To leave the virtual environment, run:</p>
           <pre><code>deactivate</code></pre>
           <p>You do not need the virtual environment to run the A01 Fortran test. Use it when building the Sphinx documentation.</p>
         </details>

         <details class="ap-details">
           <summary>First-time Git workflow</summary>
           <p>You can first think of Git as a tool for saving code snapshots and syncing them to a remote repository. On day one, remember these terms:</p>
           <ul>
             <li><code>working tree</code>: the files you are editing.</li>
             <li><code>stage</code>: the selected changes for the next commit.</li>
             <li><code>commit</code>: a local snapshot; it is not uploaded automatically.</li>
             <li><code>branch</code>: a separate line of work away from the main branch.</li>
             <li><code>remote</code>: a repository on a server; <code>origin</code> and <code>upstream</code> are just remote names.</li>
           </ul>
           <p>This diagram shows where one change moves in Git:</p>
           <div class="ap-git-visual" role="img" aria-label="Git change flow from working tree to remote branch">
             <div class="ap-git-track">
               <div class="ap-git-node ap-git-node-work">
                 <strong>Working tree</strong>
                 <span>Edit files; changes only exist in local files.</span>
                 <code>git diff</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-stage">
                 <strong>Stage</strong>
                 <span>Select files for the next commit.</span>
                 <code>git add</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-commit">
                 <strong>Local commit</strong>
                 <span>Create one local snapshot.</span>
                 <code>git commit</code>
               </div>
               <div class="ap-git-arrow" aria-hidden="true">-&gt;</div>
               <div class="ap-git-node ap-git-node-remote">
                 <strong>Remote branch</strong>
                 <span>Upload the local commit for others to see.</span>
                 <code>git push</code>
               </div>
             </div>
             <p class="ap-git-caption">For the first pass, remember this line: edit files, inspect diff, add, check staged content, commit, then push.</p>
           </div>
           <p>On a new machine, configure the name and email that will appear in commit records:</p>
           <pre><code>git config --global user.name "Your Name"
         git config --global user.email "your.email@example.com"</code></pre>
           <p>If the repository is not cloned yet, clone it first. If it already exists locally, skip this step:</p>
           <pre><code>git clone &lt;repo-url&gt; algoplasma
         cd algoplasma</code></pre>
           <p>Inside the repository, inspect the current branch, remotes, and local changes first:</p>
           <pre><code>git branch -vv
         git remote -v
         git status</code></pre>
           <p>The safest beginner workflow is to start from the latest <code>master/develop</code>, create a small personal branch, and edit only on that branch.</p>
           <pre><code>git switch master
         git pull --ff-only origin master
         # If the repository uses develop as the main branch, replace master with develop.
         git switch -c docs/onboarding-notes</code></pre>
           <p>After editing files, check and commit in this order:</p>
           <pre><code>git status
         git diff
         git add docs/source/developer_quick_start.rst
         git diff --cached
         git commit -m "Update developer quick start"</code></pre>
           <ul>
             <li><code>git status</code> shows which files changed.</li>
             <li><code>git diff</code> shows changes that are not staged yet.</li>
             <li><code>git add</code> selects files for the next commit; it does not upload anything.</li>
             <li><code>git diff --cached</code> shows what the next commit will contain.</li>
             <li><code>git commit</code> creates a local snapshot; it does not upload anything.</li>
           </ul>
           <p>When the commit looks right, push the branch to the remote repository:</p>
           <pre><code>git push origin docs/onboarding-notes</code></pre>
           <p>Use <code>stash</code> only to temporarily put local changes aside, not as long-term backup:</p>
           <pre><code>git stash push -m "work in progress"
         git stash pop</code></pre>
           <p>For a first Git pass, avoid commands like <code>git push --force</code> and <code>git reset --hard</code>, because they can rewrite remote history or discard local changes.</p>
         </details>

         <details class="ap-details">
           <summary>How to edit Sphinx docs</summary>
           <p>This repository builds documentation with Sphinx, Doxygen, and Breathe: Sphinx turns RST pages into HTML, Doxygen generates API XML from Fortran source comments, and Breathe brings that API data into Sphinx pages.</p>
           <ul>
             <li><code>docs/source/*.rst</code> contains the main documentation sources.</li>
             <li><code>docs/source/images/</code> stores documentation images.</li>
             <li><code>docs/source/_static/custom.css</code> stores page styles.</li>
             <li><code>docs/build/html/</code> is generated output; do not edit it by hand.</li>
           </ul>
           <p>After editing docs, run this from the repository root:</p>
           <pre><code>source .venv/bin/activate
         cd docs
         ./make.sh</code></pre>
           <p>If the build fails, read the last warning or error first. Common causes are missing Python packages, missing Doxygen, missing Graphviz, or an RST heading or indentation mistake.</p>
         </details>

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: Good First Contributions

         Do not start by changing the core algorithm. Prefer a small, clear change:

         - Add a missing parameter note to a README.
         - Add run commands or output notes to a test page.
         - Add one validation criterion to an existing test.
         - Add a Sphinx link between a test page and an algorithm page.

      .. container:: ap-onboarding-note

         .. rubric:: Before Submitting

         - Is the change limited to one module or one test directory?
         - Are public interfaces, array shapes, units, and boundary conventions clear?
         - Did the relevant test run?
         - Did the change add any unexpected dependency?
         - If Sphinx documentation changed, does the documentation still build?

   .. container:: ap-onboarding-grid

      .. container:: ap-onboarding-note

         .. rubric:: Common Sticking Points

         - If ``run.sh`` cannot find ``build``, run ``./make.sh`` first.
         - If ``make.sh`` fails to compile, check that ``gfortran`` exists and run the script from the test directory.
         - If ``plot.sh`` fails, ignore it for the first developer pass and confirm that ``build/case*.dat`` exists.
         - If documentation build fails, record the missing tool or Python package before continuing code reading.

      .. container:: ap-onboarding-note ap-onboarding-route

         .. rubric:: What To Read Next

         .. code-block:: text

            A01_Boris_3Dxyz
            -> B01_scatter_3Dxyz
            -> C01_gather_3Dxyz
            -> E_Maxwell or D_Poisson
            -> H_MPI_Exchange

         This starts with the particle pusher, deposition, and interpolation
         chain, then moves into field solvers and parallel exchange.
