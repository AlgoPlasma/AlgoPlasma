.. rst-class:: ap-home-document-title

==========
AlgoPlasma
==========

.. toctree::
    :caption: Subroutines (by ID)
    :maxdepth: 1
    :glob:
    :includehidden:
    :hidden:

    ./rst_files/*

.. toctree::
    :caption: Tests
    :maxdepth: 1
    :hidden:

    ./tests/index

.. toctree::
    :caption: Examples
    :maxdepth: 1
    :hidden:

    ./examples/index

.. toctree::
    :caption: Reference
    :maxdepth: 1
    :hidden:

    ./developer_onboarding
    ./glossary
    ./maintenance_checklist

.. image:: images/algoplasma-logo-transparent.png
   :class: ap-home-preload
   :alt: AlgoPlasma logo

.. raw:: html

   <div class="ap-language-switch ap-home-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

   <div class="ap-home ap-lang ap-lang-zh">
     <section class="ap-home-hero">
       <div class="ap-home-hero-image" aria-hidden="true"></div>
       <img class="ap-home-logo" src="_images/algoplasma-logo-transparent.png" alt="AlgoPlasma logo" width="1286" height="946">
       <div class="ap-home-hero-content">
         <p class="ap-home-eyebrow">Open Algorithms for Plasma Modeling</p>
         <h1>AlgoPlasma</h1>
         <p class="ap-home-lead">
          AlgoPlasma 致力于把等离子体建模中分散、重复实现的核心算法，
          沉淀为开放、可复用、可测试、可解释的算法库。
         </p>
         <div class="ap-home-actions">
           <a class="ap-home-action ap-home-action-primary" href="developer_onboarding.html">快速入门</a>
           <a class="ap-home-action" href="examples/index.html">查看示例</a>
           <a class="ap-home-action" href="tests/index.html">查看测试</a>
           <a class="ap-home-action" href="glossary.html">术语表</a>
           <a class="ap-home-action" href="https://github.com/AlgoPlasma/AlgoPlasma" target="_blank" rel="noopener noreferrer">GitHub 源码</a>
           <a class="ap-home-action" href="https://e.gitee.com/algoplasma/repos/algoplasma/algoplasma/sources" target="_blank" rel="noopener noreferrer">Gitee 源码</a>
         </div>
       </div>
       <p class="ap-home-caption">
        配图来自基于 AlgoPlasma 搭建的 AP-PIC-HET-3D 程序。<br>
         <a href="https://arxiv.org/abs/2603.14849v1" target="_blank" rel="noopener noreferrer">arXiv: 2603.14849v1</a>, 16 Mar 2026.
       </p>
     </section>

     <section class="ap-home-section">
       <div class="ap-home-section-heading">
        <h2>算法模块</h2>
         <a href="genindex.html">API 索引</a>
       </div>
       <div class="ap-home-module-grid">
         <a class="ap-module-card" style="--accent:#2c7be5" href="rst_files/A_Pusher.html"><strong>A_Pusher</strong><span>粒子推进</span></a>
         <a class="ap-module-card" style="--accent:#00a887" href="rst_files/B_Scatter.html"><strong>B_Scatter</strong><span>粒子到网格沉积</span></a>
         <a class="ap-module-card" style="--accent:#7b61ff" href="rst_files/C_Gather.html"><strong>C_Gather</strong><span>网格到粒子插值</span></a>
         <a class="ap-module-card" style="--accent:#d9822b" href="rst_files/D_Poisson.html"><strong>D_Poisson</strong><span>Poisson 求解</span></a>
         <a class="ap-module-card" style="--accent:#1f9bb4" href="rst_files/E_Maxwell.html"><strong>E_Maxwell</strong><span>Maxwell</span></a>
         <a class="ap-module-card" style="--accent:#5964d8" href="rst_files/F_IO.html"><strong>F_IO</strong><span>数据输入输出</span></a>
         <a class="ap-module-card" style="--accent:#c94c4c" href="rst_files/G_collision.html"><strong>G_collision</strong><span>碰撞模型</span></a>
         <a class="ap-module-card" style="--accent:#178f66" href="rst_files/H_MPI_Exchange.html"><strong>H_MPI_Exchange</strong><span>MPI 数据交换</span></a>
         <a class="ap-module-card" style="--accent:#b7791f" href="rst_files/I_Initializer.html"><strong>I_Initializer</strong><span>初始化</span></a>
         <a class="ap-module-card" style="--accent:#4a78a6" href="rst_files/J_Fluid.html"><strong>J_Fluid</strong><span>流体算法</span></a>
       </div>
     </section>

     <section class="ap-home-section">
       <div class="ap-home-info-grid">
         <article class="ap-home-panel">
           <h2>测试文档</h2>
           <p>测试位于 <code>tests/</code>，包含编译、运行、清理脚本和验证说明。修改算法后建议先运行对应局部测试。</p>
           <a class="ap-home-text-link" href="tests/index.html">进入 Tests 总览</a>
         </article>
         <article class="ap-home-panel">
           <h2>术语与维护</h2>
           <p>术语表统一网格、粒子和并行词汇；维护清单用于检查语言切换、API 包裹和 Sphinx warning。</p>
           <a class="ap-home-text-link" href="maintenance_checklist.html">打开维护清单</a>
         </article>
         <article class="ap-home-panel">
           <h2>文档构建</h2>
           <p>文档基于 Sphinx、Doxygen 和 Breathe 构建，源文件位于 <code>docs/source/</code>。</p>
           <pre><code>cd docs
   ./make.sh</code></pre>
           <p>默认自动选择并行编译线程。</p>
         </article>
       </div>
     </section>

     <section class="ap-home-footer-band">
      <p>欢迎贡献服务于等离子体科学的算法实现、案例测试、文档说明和结果验证。</p>
      <p class="ap-home-license">本项目采用 <a href="LICENSE">Apache License 2.0</a> 开源许可证；版权和归属信息见 <a href="NOTICE">NOTICE</a>。</p>
      <p class="ap-home-contact">发起人：赵隐剑 · contact@algoplasma.com · <a href="https://homepage.hit.edu.cn/zhaoyinjian" target="_blank" rel="noopener noreferrer">Homepage</a></p>
     </section>
   </div>

   <div class="ap-home ap-lang ap-lang-en">
     <section class="ap-home-hero">
       <div class="ap-home-hero-image" aria-hidden="true"></div>
       <img class="ap-home-logo" src="_images/algoplasma-logo-transparent.png" alt="AlgoPlasma logo" width="1286" height="946">
       <div class="ap-home-hero-content">
         <p class="ap-home-eyebrow">Open Algorithms for Plasma Modeling</p>
         <h1>AlgoPlasma</h1>
         <p class="ap-home-lead">
          AlgoPlasma turns scattered and repeatedly reimplemented core algorithms for plasma modeling into
          an open, reusable, tested, and explainable algorithm library.
         </p>
         <div class="ap-home-actions">
           <a class="ap-home-action ap-home-action-primary" href="developer_onboarding.html">Quick Start</a>
           <a class="ap-home-action" href="examples/index.html">View Examples</a>
           <a class="ap-home-action" href="tests/index.html">View Tests</a>
           <a class="ap-home-action" href="glossary.html">Glossary</a>
           <a class="ap-home-action" href="https://github.com/AlgoPlasma/AlgoPlasma" target="_blank" rel="noopener noreferrer">GitHub Source</a>
           <a class="ap-home-action" href="https://e.gitee.com/algoplasma/repos/algoplasma/algoplasma/sources" target="_blank" rel="noopener noreferrer">Gitee Source</a>
         </div>
       </div>
       <p class="ap-home-caption">
        Image rendered from an AP-PIC-HET-3D program built on AlgoPlasma.<br>
         <a href="https://arxiv.org/abs/2603.14849v1" target="_blank" rel="noopener noreferrer">arXiv: 2603.14849v1</a>, 16 Mar 2026.
       </p>
     </section>

     <section class="ap-home-section">
       <div class="ap-home-section-heading">
        <h2>Algorithm Modules</h2>
         <a href="genindex.html">API Index</a>
       </div>
       <div class="ap-home-module-grid">
         <a class="ap-module-card" style="--accent:#2c7be5" href="rst_files/A_Pusher.html"><strong>A_Pusher</strong><span>Particle pushers</span></a>
         <a class="ap-module-card" style="--accent:#00a887" href="rst_files/B_Scatter.html"><strong>B_Scatter</strong><span>Particle-to-grid deposition</span></a>
         <a class="ap-module-card" style="--accent:#7b61ff" href="rst_files/C_Gather.html"><strong>C_Gather</strong><span>Grid-to-particle interpolation</span></a>
         <a class="ap-module-card" style="--accent:#d9822b" href="rst_files/D_Poisson.html"><strong>D_Poisson</strong><span>Poisson solvers</span></a>
         <a class="ap-module-card" style="--accent:#1f9bb4" href="rst_files/E_Maxwell.html"><strong>E_Maxwell</strong><span>Maxwell</span></a>
         <a class="ap-module-card" style="--accent:#5964d8" href="rst_files/F_IO.html"><strong>F_IO</strong><span>Data input and output</span></a>
         <a class="ap-module-card" style="--accent:#c94c4c" href="rst_files/G_collision.html"><strong>G_collision</strong><span>Collision models</span></a>
         <a class="ap-module-card" style="--accent:#178f66" href="rst_files/H_MPI_Exchange.html"><strong>H_MPI_Exchange</strong><span>MPI data exchange</span></a>
         <a class="ap-module-card" style="--accent:#b7791f" href="rst_files/I_Initializer.html"><strong>I_Initializer</strong><span>Initialization</span></a>
         <a class="ap-module-card" style="--accent:#4a78a6" href="rst_files/J_Fluid.html"><strong>J_Fluid</strong><span>Fluid algorithms</span></a>
       </div>
     </section>

     <section class="ap-home-section">
       <div class="ap-home-info-grid">
         <article class="ap-home-panel">
           <h2>Tests</h2>
           <p>Tests live under <code>tests/</code> and include build, run, clean scripts, and validation notes. After changing an algorithm, start with its local tests.</p>
           <a class="ap-home-text-link" href="tests/index.html">Open Tests Overview</a>
         </article>
         <article class="ap-home-panel">
           <h2>Terms and Maintenance</h2>
           <p>The glossary standardizes grid, particle, and parallel terms; the checklist covers language switches, API wrapping, and Sphinx warnings.</p>
           <a class="ap-home-text-link" href="maintenance_checklist.html">Open Checklist</a>
         </article>
         <article class="ap-home-panel">
           <h2>Documentation</h2>
           <p>The docs are built with Sphinx, Doxygen, and Breathe. Source files live under <code>docs/source/</code>.</p>
           <pre><code>cd docs
   ./make.sh</code></pre>
           <p>Uses automatic parallel build jobs by default.</p>
         </article>
       </div>
     </section>

     <section class="ap-home-footer-band">
      <p>Contributions are welcome for algorithm implementations, test cases, documentation, and result validation that serve plasma science.</p>
      <p class="ap-home-license">AlgoPlasma is licensed under the <a href="LICENSE">Apache License 2.0</a>; copyright and attribution information is available in <a href="NOTICE">NOTICE</a>.</p>
      <p class="ap-home-contact">Initiator: Yinjian ZHAO · contact@algoplasma.com · <a href="https://homepage.hit.edu.cn/zhaoyinjian" target="_blank" rel="noopener noreferrer">Homepage</a></p>
     </section>
   </div>
