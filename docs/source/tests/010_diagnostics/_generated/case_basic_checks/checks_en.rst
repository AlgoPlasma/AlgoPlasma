:orphan:

.. checks-overview-start

Tables are generated from the same run, showing eight significant digits; the numerical report retains full precision.

.. checks-overview-end

.. checks-spectrum-start

**This run: PASS**

.. list-table::
   :header-rows: 1
   :widths: 22 16 16 12 24 10

   * - Quantity
     - Expected
     - Actual
     - Max absolute difference
     - Comparison rule
     - Status
   * - Boxcar integrated power
     - 0.87633965
     - 0.87633965
     - 1.110223e-16
     - atol=0; rtol=9.094947e-13
     - PASS
   * - Hann integrated power
     - 0.78909869
     - 0.78909869
     - 0
     - atol=0; rtol=9.094947e-13
     - PASS
   * - Off-bin phase: direct DFT / °
     - -51.38807
     - -51.38807
     - 1.2722219e-14
     - atol=3.2741809e-10; rtol=0
     - PASS
   * - On-bin phase: direct DFT / °
     - -45.836624
     - -45.836624
     - 0
     - atol=3.2741809e-10; rtol=0
     - PASS
   * - On-bin phase: analytic / °
     - -45.836624
     - -45.836624
     - 1.2722219e-14
     - atol=3.2741809e-10; rtol=0
     - PASS

**Conclusion:** Window-power normalization and cross phases agree with the references for these inputs.

Bias relative to the input phase difference: 5.5514466° for 1.25 cycles and 1.2722219e-14° for 2 cycles. These observations are not pass/fail thresholds.

.. checks-spectrum-end

.. checks-phase-start

**This run: PASS**

.. list-table::
   :header-rows: 1
   :widths: 22 16 16 12 24 10

   * - Quantity
     - Expected
     - Actual
     - Max absolute difference
     - Comparison rule
     - Status
   * - Case A: modal bin center / °
     - 3
     - 3
     - 8.348956e-15
     - atol=5.1159077e-12; rtol=0
     - PASS
   * - Case A: sample variance / °²
     - 35.509022
     - 35.509022
     - 0
     - atol=1.8417268e-09; rtol=1.4210855e-14
     - PASS
   * - Case B: modal bin center / °
     - 177
     - 177
     - 2.5444437e-14
     - atol=5.1159077e-12; rtol=0
     - PASS
   * - Case B: sample variance / °²
     - 1.5833333
     - 1.5833333
     - 1.4592826e-14
     - atol=1.8417268e-09; rtol=1.4210855e-14
     - PASS

**Conclusion:** Modal bin centers and sample variances match the hand calculations, including the branch-cut case.

.. checks-phase-end

.. checks-beall-start

**This run: PASS**

.. list-table::
   :header-rows: 1
   :widths: 22 16 16 12 24 10

   * - Quantity
     - Expected
     - Actual
     - Max absolute difference
     - Comparison rule
     - Status
   * - Required weight: mean auto-power
     - [50.005, 4]
     - [50.005, 4]
     - 0
     - atol=0; rtol=1.4210855e-14
     - PASS
   * - Required weight: bin values
     - [25.0025, 2]
     - [25.0025, 2]
     - 0
     - atol=0; rtol=1.4210855e-14
     - PASS
   * - Required weight: peak / rad m⁻¹
     - -0.5
     - -0.5
     - 0
     - Equal
     - PASS
   * - Misuse control: bin values
     - [0.5, 2]
     - [0.5, 2]
     - 0
     - atol=0; rtol=1.4210855e-14
     - PASS
   * - Misuse control: peak / rad m⁻¹
     - 0.5
     - 0.5
     - 0
     - Equal
     - PASS

**Conclusion:** The required weight gives the reference spectrum and peak; the misuse control gives a different peak matching its own reference.

.. checks-beall-end
