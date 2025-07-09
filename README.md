# Compliant Mechanism

The main code is "sb7pt_N40_gap_between_upper_lower.m", in which it invokes:
- "Bezierauto.m" for generating the smooth beam shape (geometry) using a Bezier curve, based on a set of control points (plot 100).
- "func_sb_gap.m" for simulating the structural behavior of a dual-Bézier-beam actuator (upper & lower beams) using Abaqus, and then extract meaningful mechanical performance data from the simulation (plot 1, 2, 3).
