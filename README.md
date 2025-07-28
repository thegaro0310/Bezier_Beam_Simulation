# Bezier Beam Simulation
<div align="center">
<img width="560" height="420" alt="firgure_100_7pt_se8" src="https://github.com/user-attachments/assets/9f99cddd-9704-43ae-b3d3-5d20ef09be4b" />
</div>

## The main code is "sb7pt_N40.m", in which it invokes:
- "Bezierauto.m" for generating the smooth beam shape (geometry) using a Bezier curve, based on a set of control points (plot 100).
- "func_beam_elements.m" for simulating the structural behavior of a dual-Bézier-beam actuator (upper & lower beams) using Abaqus, and then extract meaningful mechanical performance data from the simulation (plot 1, 2, 3), this is professor original code.
- "func_CPE4R_elements.m" to construct CPE4R element type node IDs, then the generated inp file will be loaded in Hypermesh for further work.
- "extract_and_plot_fea.m" to extract data from *.dat file to *_fea.txt file, then from *_fea.txt, we will plot the figures.

## Important find to take note
- "sb_cpe4r.inp" is used to load the CPE4R elements type to Hypermesh (student's code)
- "sb_cpe4r.odb" is used to load the CPE4R elements type to Abaqus
- "sb_cpe4r_fea.txt" is extracted data used to plot the reaction force and displacement for beam element type
- "sb.inp" is used to load the beam elements (B21H) type to Hypermesh (prof's code)
- "sb.odb" is used to load the beam elements (B21H) type to Abaqus
- "sb_fea.txt" is extracted data used to plot the reaction force and displacement for beam element type

## Proper style to write sb_cpe4r.inp 
An inp file should be like this (This is critical, take many times to figure it out):
Reason? Because this affects the format of the *.dat file directly, change single line could accordingly change the style of *.dat file and the code (in extract_and_plot_fea.m) cannot extract the data correctly.

**These are the header of the inp file**

    ***RESTART,WRITE,FREQUENCY=9999,overlay
    *Heading
    By Dung-An Wang
    Create: June 17th, 2025
    Modified:

**This is the abaqus job command**

    abaqus job=sb_cpe4r interactive
    gawk -f oh.awk sb_cpe4r.dat > sb_cpe4r_fea.txt

**This includes the data file exported from Hypermesh**

    *INCLUDE,input=sb_cpe4r.inut

**This is the main content of the inp file, should be kept like this**

    *ELSET,ELSET=elset_beam
    elset_all
    *MATERIAL,NAME=POM
    *ELASTIC
    3.500000e+03
    *DENSITY
    1.400000e-06
    *SOLID SECTION,ELSET=elset_all,MATERIAL=POM
    3.000000
    *STEP,INC=9999,NLGEOM,unsymm=yes
    step 1 
    *STATIC 
    0.000100,1.0,1e-10,0.010000 
    *BOUNDARY,op=new
    nset_anchor_upper,1,3,0 
    nset_anchor_lower,1,3,0
    nset_end,1,1,0
    nset_end,2,2,-1.000000e+01
    *monitor,dof=2,node=nset_monitor,frequency=1
    *NODE PRINT,NSET=nset_anchor,TOTALS=YES,FREQUENCY=1,summary=no
    RF,
    *NODE PRINT,NSET=nset_monitor,TOTALS=No,FREQUENCY=1,summary=no
    U,RF,
    *NODE PRINT,NSET=nset_upper,TOTALS=YES,FREQUENCY=1,summary=yes
    coord,u
    *EL PRINT,ELSET=elset_beam,FREQUENCY=1,totals=no,summary=yes
    S11,S12,S13
    ** S12: Shear stress along the second cross-section axis 
    ** S13: Shear stress along the first cross-section axis
    *ENERGY PRINT,elset=elset_beam,FREQUENCY=1
    *OUTPUT,field,frequency=1
    *ELEMENT OUTPUT
    S,E
    *NODE output,nset=nset_all
    U,RF
    *END STEP

## How to do step by step to do beam simulation:
1.Codes to construct bezier curve equation to bezier beam, this is the shape of the beam. Need to undestand the code logic if you have no experience. At this stage, there are 3 files you need to take in mind:
* sb.inp, this is input for abaqus to generate sb.odb and sb.dat, this can also be use in Hypermesh later to figure out the sets of the beam.
* sb.dat, this is data file, contains infromation needed to plot the figures.
* sb_fea.txt, this is the extracted data from sb.dat, the matlab code will import data from here.

2.The code original just to simulate beam elements, to do simulation for CPE4R elements, we should take care of the logic to mesh the beam in CPE4R. The original code do it for B21H beam elements. So we need to construct a code to do in CPE4R.

3.Then something like sb_cpe4r.inp will be generated, import this one to Hypermesh and do the meshing, validating and construct the beam sets (follow the sb.inp file).

4.After that, export the data file (give it an meaningless extension, in our case, it’s *.inut), then from our sb_cpe4r.inp, include that data file and make sure it in the correct format so our *.dat file could be written and extracted perfectly.

5.Now run it with abaqus command and *.dat file will be generated, run the extract_and_plot_fea.m in matlab, the figures now will be plotted.
