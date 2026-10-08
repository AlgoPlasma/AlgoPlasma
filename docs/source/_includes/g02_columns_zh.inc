.. list-table:: 文件与列清单
   :header-rows: 1
   :widths: 22 78

   * - 文件
     - 列名
   * - ``species.csv``
     - ``id, name, mass_kg, charge_state, representation``
   * - ``states.csv``
     - ``id, species, label, energy_ev, degeneracy, is_ground``
   * - ``composition.csv``
     - ``species, element, count``
   * - ``reactions.csv``
     - ``id, name, algorithm, threshold_ev, q_value_ev, ker_min_ev, radiated_energy_ev, angular_model, angular_cos_min, angular_cos_max, energy_model, enabled``
   * - ``reactants.csv``
     - ``reaction_id, role, species, state, stoichiometry``
   * - ``products.csv``
     - ``reaction_id, species, state, stoichiometry``
   * - ``rate_laws.csv``
     - ``reaction_id, kind, dataset_id, x_source, x_species``
   * - ``datasets.csv``
     - ``dataset_id, path, x_axis, x_unit, y_unit, interpolation, below_min_policy, above_max_policy, source, version, license, notes``
   * - ``tables/*.csv``
     - ``x, y``
