# Compliant Mechanism

The main code is "sb7pt_N40_gap_between_upper_lower.m", in which it invokes:
- "Bezierauto.m" for generating the smooth beam shape (geometry) using a Bezier curve, based on a set of control points (plot 100).
- "func_sb_gap.m" for simulating the structural behavior of a dual-Bézier-beam actuator (upper & lower beams) using Abaqus, and then extract meaningful mechanical performance data from the simulation (plot 1, 2, 3).
- "func_elements_CPE4R.m" for construct CPE4R element type node IDs, then the generated inp file will be loaded in Hypermesh for further work.

"sb_cpe4r.inp" is used to load the CPE4R elements type to Hypermesh (student's code)
"sb_cpe4r.odb" is used to load the CPE4R elements type to Abaqus
"sb_cpe4r_fea.txt" is extracted data used to plot the reaction force and displacement for beam element type

"sb.inp" is used to load the beam elements (B21H) type to Hypermesh (prof's code)
"sb.odb" is used to load the beam elements (B21H) type to Abaqus
"sb_fea.txt" is extracted data used to plot the reaction force and displacement for beam element type