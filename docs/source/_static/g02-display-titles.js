// G02 display titles; callable identifiers and source filenames stay unchanged.
(function () {
  "use strict";
  var titles = {
  "references": {
    "zh": "MCC 方法与验证文献",
    "en": "MCC methods and verification references"
  },
  "fun_G02_mcc_batch": {
    "zh": "MccStepper：批量碰撞步进器",
    "en": "MccStepper: batch collision stepper"
  },
  "fun_G02_mcc_engine": {
    "zh": "MccEngine：碰撞抽样与事件处理",
    "en": "MccEngine: collision sampling and events"
  },
  "fun_G02_mcc_model": {
    "zh": "模型加载与校验：读取 CSV 反应数据",
    "en": "Model loading and validation: CSV reaction data"
  },
  "fun_G02_mcc_kinematics": {
    "zh": "碰撞运动学：计算碰后速度",
    "en": "Collision kinematics: outgoing velocities"
  },
  "group_foundation": {
    "zh": "Basics",
    "en": "Basics"
  },
  "mcc": {
    "zh": "mcc.hpp：C++ 总入口头文件",
    "en": "mcc.hpp: C++ umbrella header"
  },
  "common": {
    "zh": "common.hpp：基础类型、向量与物理常数",
    "en": "common.hpp: Basic types, vectors and physical constants"
  },
  "rng": {
    "zh": "rng.hpp：可复现的随机数",
    "en": "rng.hpp: Reproducible random numbers"
  },
  "group_model_data": {
    "zh": "Model",
    "en": "Model"
  },
  "csv": {
    "zh": "csv.hpp：CSV 读取接口与数据容器",
    "en": "csv.hpp: CSV interfaces and containers"
  },
  "fun_G02_mcc_csv": {
    "zh": "fun_G02_mcc_csv.cpp：解析 CSV 文本与报告格式错误",
    "en": "fun_G02_mcc_csv.cpp: Parse CSV text and report format errors"
  },
  "table": {
    "zh": "table.hpp：数据表、插值和越界策略接口",
    "en": "table.hpp: Tables, interpolation and domain policies"
  },
  "fun_G02_mcc_table": {
    "zh": "fun_G02_mcc_table.cpp：执行插值与计算区间上界",
    "en": "fun_G02_mcc_table.cpp: Interpolate and bound table segments"
  },
  "model": {
    "zh": "model.hpp：描述物种、内部态和反应网络",
    "en": "model.hpp: Describe species, states and reactions"
  },
  "compile": {
    "zh": "compile.hpp：模型编译接口与运行时数据",
    "en": "compile.hpp: Model compilation and runtime data"
  },
  "fun_G02_mcc_compile": {
    "zh": "fun_G02_mcc_compile.cpp：检查物理约束并准备抽样数据",
    "en": "fun_G02_mcc_compile.cpp: Check physical constraints and prepare sampling data"
  },
  "group_collision": {
    "zh": "Collision",
    "en": "Collision"
  },
  "engine": {
    "zh": "engine.hpp：单粒子碰撞引擎与结果类型",
    "en": "engine.hpp: Single-particle engine and outcome types"
  },
  "kinematics": {
    "zh": "kinematics.hpp：碰后速度计算接口",
    "en": "kinematics.hpp: Outgoing-velocity interfaces"
  },
  "batch": {
    "zh": "batch.hpp：粒子容器适配与整批推进接口",
    "en": "batch.hpp: Particle adapters and batch interfaces"
  },
  "group_mpi_interface": {
    "zh": "MPI",
    "en": "MPI"
  },
  "mpi": {
    "zh": "mpi.hpp：分布式批量推进接口",
    "en": "mpi.hpp: Distributed batch-stepping interface"
  },
  "fun_G02_mcc_mpi": {
    "zh": "fun_G02_mcc_mpi.cpp：协调多进程推进与新粒子编号",
    "en": "fun_G02_mcc_mpi.cpp: Coordinate distributed steps and child IDs"
  },
  "csv_format": {
    "zh": "CSV 数据格式与填写",
    "en": "CSV model format and preparation"
  }
};
  var sidebarNames = {"references": {"zh": "方法与文献", "en": "References"}, "group_foundation": "Basics", "mcc": "mcc.hpp", "common": "common.hpp", "rng": "rng.hpp", "group_model_data": "Model", "csv": "csv.hpp", "fun_G02_mcc_csv": "fun_G02_mcc_csv.cpp", "table": "table.hpp", "fun_G02_mcc_table": "fun_G02_mcc_table.cpp", "model": "model.hpp", "fun_G02_mcc_model": "fun_G02_mcc_model.cpp", "compile": "compile.hpp", "fun_G02_mcc_compile": "fun_G02_mcc_compile.cpp", "group_collision": "Collision", "engine": "engine.hpp", "fun_G02_mcc_engine": "fun_G02_mcc_engine.cpp", "kinematics": "kinematics.hpp", "fun_G02_mcc_kinematics": "fun_G02_mcc_kinematics.cpp", "batch": "batch.hpp", "fun_G02_mcc_batch": "fun_G02_mcc_batch.cpp", "group_mpi_interface": "MPI", "mpi": "mpi.hpp", "fun_G02_mcc_mpi": "fun_G02_mcc_mpi.cpp", "csv_format": "CSV format"};
  function pageKey(url) {
    var path = new URL(url, window.location.href).pathname;
    var match = path.match(/\/G02_MCC_network\/([^/]+)\.html$/);
    return match && titles[match[1]] ? match[1] : null;
  }
  function replaceLabel(element, value) {
    // Preserve the Sphinx permalink and sidebar expand controls.
    Array.prototype.forEach.call(element.childNodes, function (node) {
      if (node.nodeType === 3 && node.textContent.trim()) node.textContent = value;
    });
  }
  function update() {
    var lang = document.documentElement.getAttribute("data-ap-lang") === "en" ? "en" : "zh";
    document.querySelectorAll("a[href]").forEach(function (link) {
      var key = pageKey(link.href);
      if (!key) return;
      if (link.closest(".wy-menu-vertical")) {
        var label = sidebarNames[key];
        replaceLabel(link, typeof label === "string" ? label : label[lang]);
        return;
      }
      var text = link.textContent.trim();
      if (text === titles[key].zh || text === titles[key].en) replaceLabel(link, titles[key][lang]);
    });
    var key = pageKey(window.location.href);
    if (key) {
      var heading = document.querySelector(".ap-g02-reference h1");
      if (heading) replaceLabel(heading, titles[key][lang]);
      var breadcrumb = document.querySelector(".wy-breadcrumbs .breadcrumb-item.active");
      if (breadcrumb) replaceLabel(breadcrumb, titles[key][lang]);
      var suffix = document.title.indexOf(" — ");
      document.title = titles[key][lang] + (suffix >= 0 ? document.title.slice(suffix) : "");
    }
  }
  document.addEventListener("DOMContentLoaded", function () {
    update();
    new MutationObserver(update).observe(document.documentElement, {
      attributes: true, attributeFilter: ["data-ap-lang"]
    });
  });
})();
