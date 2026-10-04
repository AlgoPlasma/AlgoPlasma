The allowed-values table lists recommended canonical spellings. The parser also accepts compatibility aliases such as elastic, reservoir and phase_space; see source for the complete aliases. G02 algorithm C01 is the sampling procedure, not a reactions.algorithm value.

.. list-table:: Allowed values
   :header-rows: 1
   :widths: 43 57

   * - Field / key
     - Rule
   * - ``species.representation``
     - kinetic / background
   * - ``reactants.role``
     - projectile / background
   * - ``reactions.algorithm``
     - C02–C08 (write C02, etc. in CSV; omit the prose prefix)
   * - ``reactions.angular_model``
     - isotropic / cone / identity_exchange
   * - ``reactions.energy_model``
     - n_body_phase_space / equal_share
   * - ``rate_laws.kind``
     - cross_section / rate_coefficient
   * - ``rate_laws.x_source``
     - relative_energy_ev (cross sections) / temperature_k (rate coefficients)
   * - ``datasets.x_axis; x_unit; y_unit``
     - energy; eV; m2 or temperature; K; m3/s (two-body) / m6/s (three-body)
   * - ``datasets.interpolation``
     - linear / log-linear / log-log
   * - ``datasets.below_min_policy / above_max_policy``
     - error / zero / clamp
   * - ``enabled / is_ground``
     - true/1/yes/on: true; false/0/no/off/empty: false; case-insensitive

.. list-table:: Required keys: manifest.csv
   :header-rows: 1
   :widths: 43 57

   * - Field / key
     - Rule
   * - ``format``
     - Must be g02-mcc-model-package
   * - ``format_version``
     - Must be 1
   * - ``name / version``
     - Nonempty model name and version
   * - ``species / states / reactions``
     - Required relative paths to the three CSV files
   * - ``reactants / products / rate_laws / datasets``
     - Required relative paths to the four CSV files
   * - ``composition``
     - Optional; absent/empty skips the composition table
   * - ``checksum.<relative path>``
     - Optional; supplied entries verify the file using a 16-digit hexadecimal FNV-1a 64 checksum

.. list-table:: Empty-value defaults
   :header-rows: 1
   :widths: 43 57

   * - Field / key
     - Rule
   * - ``states.energy_ev; reactions.ker_min_ev / radiated_energy_ev``
     - Empty or absent column → 0 eV
   * - ``reactants.state / products.state``
     - Empty or absent column → the declared ground state (not necessarily named ground)
   * - ``reactions.angular_model``
     - Empty or absent column → isotropic
   * - ``reactions.energy_model``
     - Empty or absent column → n_body_phase_space
   * - ``reactions.angular_cos_min / angular_cos_max``
     - Empty or absent column → 0; explicitly set the desired cone range
   * - ``reactions.enabled / states.is_ground``
     - Empty → false; absent column is an error. Each species still needs exactly one ground state
   * - ``datasets.source / version / license / notes``
     - Empty or absent column → empty string; research data should supply provenance and licensing
   * - ``rate_laws.x_species``
     - Empty or absent column → empty string; temperature_k laws require a valid background species
   * - ``composition（manifest 键）``
     - Empty/absent key → no composition table; undeclared species do not contribute to element inventory
   * - ``其他必需数值/字段``
     - Masses, IDs, stoichiometry, threshold_ev, q_value_ev and x/y have no generic defaults; obey model constraints

Use the complete column list when creating headers. A missing column and an empty cell are distinct and do not always have the same behavior. Allowed values do not imply every combination is valid: equal_share requires two products; identity_exchange requires strict resonance.
