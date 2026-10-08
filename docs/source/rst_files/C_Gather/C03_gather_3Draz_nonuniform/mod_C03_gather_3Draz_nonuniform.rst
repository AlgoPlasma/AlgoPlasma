mod_C03_gather_3Draz_nonuniform.f90
-----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块说明

   ``mod_C03_gather_3Draz_nonuniform`` 是本目录的统一入口。
   Fortran 的 module 可以把相关子程序组织在一起；其他程序写
   ``use mod_C03_gather_3Draz_nonuniform`` 后，就能调用模块开放的例程。
   这个文件本身不进行场插值，具体计算在它包含的子程序文件中。

   .. rubric:: 公开入口

   .. list-table::
      :header-rows: 1
      :widths: 30 30

      * - 入口
        - 什么时候使用
      * - :doc:`sub_C03_gather_3Draz_nonuniform`
        - 粒子已经保存在 par 数组中，要计算其中一个粒子处的场。
      * - :doc:`sub_C03_gather_3Draz_nonuniform_point`
        - 已经有一个位置向量 x(3)，直接求该位置的场。
      * - :doc:`sub_C03_check_grid <sub_C03_gather_helpers>`
        - 网格构造完成后，检查单个方向的坐标与宽度是否一致。

   .. rubric:: 源码组织方式

   .. code-block:: fortran

      private
      public :: sub_C03_gather_3Draz_nonuniform
      public :: sub_C03_gather_3Draz_nonuniform_point
      public :: sub_C03_check_grid

      contains
      #include "sub_C03_gather_helpers.f90"
      #include "sub_C03_gather_3Draz_nonuniform_point.f90"
      #include "sub_C03_gather_3Draz_nonuniform.f90"

   ``private`` 使例程默认只在模块内部可见；后面的 ``public`` 单独开放三个入口。
   ``contains`` 后面放模块的子程序。``#include`` 在编译前把对应文件的内容放到这里，
   因此 helpers、point 和粒子数组入口实际属于同一个模块，可以互相调用。

   .. rubric:: 编译与使用

   只编译 ``mod_C03_gather_3Draz_nonuniform.f90`` 入口文件，并启用 C 预处理
   （例如 ``gfortran -cpp``）；被 include 的文件不需要单独编译。
   源码使用默认 ``real``。如果选择 ``-fdefault-real-8``，模块和调用方要使用一致的精度选项。
   模块不保存上一次调用的粒子或场数据，每次调用都从实参获得所需信息。

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Description

   ``mod_C03_gather_3Draz_nonuniform`` is the module entry for this directory.
   A Fortran module groups related routines; another program can access its public
   routines with use mod_C03_gather_3Draz_nonuniform. This file does not perform
   interpolation itself; calculations reside in the included routine files.

   .. rubric:: Public Entries

   .. list-table::
      :header-rows: 1
      :widths: 30 30

      * - Entry
        - When to use it
      * - :doc:`sub_C03_gather_3Draz_nonuniform`
        - Particles are stored in par and one particle needs fields.
      * - :doc:`sub_C03_gather_3Draz_nonuniform_point`
        - A position vector x(3) is already available.
      * - :doc:`sub_C03_check_grid <sub_C03_gather_helpers>`
        - After mesh construction, check one axis's coordinates and widths.

   .. rubric:: How the Source Is Organized

   .. code-block:: fortran

      private
      public :: sub_C03_gather_3Draz_nonuniform
      public :: sub_C03_gather_3Draz_nonuniform_point
      public :: sub_C03_check_grid

      contains
      #include "sub_C03_gather_helpers.f90"
      #include "sub_C03_gather_3Draz_nonuniform_point.f90"
      #include "sub_C03_gather_3Draz_nonuniform.f90"

   private makes routines internal by default; public exposes the three named
   entries. contains introduces module procedures. Before compilation, #include
   inserts each file here, so the helpers, point routine, and particle-array entry
   belong to the same module and can call each other.

   .. rubric:: Compilation and Use

   Compile only mod_C03_gather_3Draz_nonuniform.f90 with preprocessing enabled
   (for example, gfortran -cpp). Included files should not be compiled separately.
   The source uses default real; if using -fdefault-real-8, apply consistent precision
   options to module and caller. No particle or field state is retained between
   calls; each call receives its data through arguments.

   .. rubric:: Generated API

   .. doxygenfile:: mod_C03_gather_3Draz_nonuniform.f90
