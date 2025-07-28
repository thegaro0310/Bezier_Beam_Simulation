function ftar = func_beam_elements(GAP,UPPER,LOWER,pointsxU,pointsyU,pointsxL,pointsyL,YOUNG,NUXY,DENS,OPDIM,IPDIMU,IPDIML,DELTATH,INCREME,INCREMEINI,STABLIZ,ALSDTOL)
    % Calculate objective
    % N, mm, tonne, sec, MPa
    format long;
    currentDateTime = datetime('now');
    baseName = 'sb';

    % Upper beam
    %pointsxU = [xL_1b(1:end)];
    %pointsyU = [yL_1b(1:end)];

    % Lower beam
    %pointsxL = [xL_1a(1:end)];
    %pointsyL = [yL_1a(1:end)];
    % Adjust lower beam by GAP
    pointsyL = pointsyL - GAP;

    % =============================
    % ------ STATIC ANALYSIS ------
    % =============================
    inputFileName = sprintf('%s.inp', baseName);
    plane_file = fopen(inputFileName, 'w+');
    fprintf(plane_file, '***RESTART,WRITE,FREQUENCY = 9999, overlay\n');
    fprintf(plane_file, '*HEADING\n');
    fprintf(plane_file, 'By Dung-An Wang\n');
    fprintf(plane_file, 'Create: July 1st, 2025\n');
    fprintf(plane_file, 'Modified: %s\n', currentDateTime);
    fprintf(plane_file, 'abaqus job=%s interactive\n', baseName);
    fprintf(plane_file, 'gawk -f oh.awk %s.dat > %s_fea.txt\n', baseName, baseName);
    % Print out the set for upper nodes
    fprintf (plane_file, '*NODE,nset=nset_upper\n');
    % Create nodes of upper beam
    for i = 1 : size(pointsxU, 1)
        fprintf (plane_file,'%d,%6e,%6e,0\n', i, pointsxU(i), pointsyU(i));
    end
    % Print out the set for lower nodes
    fprintf (plane_file, '*NODE,nset=nset_lower\n');
    % Create the 1st node next to the last node of lower beam
    for i = 1 : size(pointsxL, 1)
        fprintf (plane_file,'%d ,%6e,%6e,0\n', size(pointsxU, 1) + i, pointsxL(i), pointsyL(i));
    end
    fprintf(plane_file, '*NSET, NSET=nset_anchor_upper\n');
    fprintf(plane_file, '%d,\n', 1);
    fprintf(plane_file, '*NSET, NSET=nset_end\n');
    fprintf(plane_file, '%d,%d\n', size(pointsxU, 1), size(pointsxU, 1) + size(pointsxL, 1));
    fprintf(plane_file, '*NSET, NSET=nset_monitor\n');
    fprintf(plane_file, '%d,\n', size(pointsxU, 1));
    fprintf(plane_file, '*NSET, NSET=nset_anchor_lower\n');
    fprintf(plane_file, '%d,\n', size(pointsxU, 1) + 1);
    fprintf(plane_file, '*NSET, NSET=nset_anchor\n');
    fprintf(plane_file, '%d,%d\n', 1, size(pointsxU, 1) + 1);
    fprintf(plane_file, '*NSET, NSET=nset_all\n');
    fprintf(plane_file, 'nset_upper,nset_lower\n');
    fprintf(plane_file, '** --- Mesh the beam ---\n');
    fprintf(plane_file, '*ELEMENT,TYPE=B21H,ELSET=elset_beamU\n');
    % Element set for upper beam
    for i = 1 : UPPER
        fprintf(plane_file,'%d,%d,%d\n', i, i, i + 1);
    end
    fprintf(plane_file , '*ELEMENT,TYPE=B21H,ELSET=elset_beamL\n');
    % Element set for lower beam
    for i = 1 : LOWER
        fprintf(plane_file,'%d,%d,%d\n', UPPER + i, size(pointsxU, 1) + i, size(pointsxU, 1) + i + 1);
    end
    fprintf(plane_file, '*ELSET,ELSET=elset_beam\n');
    fprintf(plane_file, 'elset_beamL,elset_beamU\n');
    fprintf(plane_file, '*MATERIAL,NAME = POM\n');
    fprintf(plane_file, '*ELASTIC\n');
    fprintf(plane_file, '%6e\n', YOUNG);
    fprintf(plane_file, '*DENSITY\n');
    fprintf(plane_file, '%6e\n', DENS);
    fprintf(plane_file, '*BEAM SECTION,SECTION=RECT,ELSET=elset_beamU,MATERIAL=POM\n');
    fprintf(plane_file, '%f,%f\n', OPDIM, IPDIMU);
    fprintf(plane_file, '** dimension along the first beam section axis, dimension along the second beam section axis\n');
    fprintf(plane_file, '%d,%d,%d\n', 0, 0, -1);
    fprintf(plane_file, '** First, second, third direction cosine of the first beam section axis \n');
    fprintf(plane_file, '*BEAM SECTION,SECTION=RECT,ELSET=elset_beamL,MATERIAL=POM\n');
    fprintf(plane_file, '%f,%f\n', OPDIM, IPDIML);
    fprintf(plane_file, '** dimension along the first beam section axis, dimension along the second beam section axis\n');
    fprintf(plane_file, '%d,%d,%d\n', 0, 0, -1);
    fprintf(plane_file, '** First, second, third direction cosine of the first beam section axis \n');
    fprintf(plane_file, '*STEP,INC=9999,NLGEOM,unsymm=yes\n');
    fprintf(plane_file, 'step 1\n');
    %fprintf (plane_file, '*STATIC,ALLSDTOL=%f,stabilize=%e, CONTINUE=YES \n',ALSDTOL,STABLIZ);
    fprintf(plane_file, '*STATIC\n');
    fprintf(plane_file, '%f,1.0,1e-10,%f\n', INCREMEINI, INCREME);
    %fprintf (plane_file, '*controls, analysis=discontinuous\n');
    fprintf(plane_file, '*BOUNDARY,op=new\n');
    fprintf(plane_file, 'nset_anchor_upper,1,6,0\n');
    fprintf(plane_file, 'nset_anchor_lower,1,6,0\n');
    fprintf(plane_file, 'nset_end,1,1,0\n');
    fprintf(plane_file, 'nset_end,2,2,%e\n', DELTATH);
    fprintf(plane_file, 'nset_end,6,6,0\n');
    fprintf(plane_file, '*monitor,dof=2,node=nset_monitor,frequency=1\n');
    fprintf(plane_file, '*NODE PRINT,NSET=nset_anchor,TOTALS=YES,FREQUENCY=1,summary=no\n');
    fprintf(plane_file, 'RF,\n');
    fprintf(plane_file, '*NODE PRINT,NSET=nset_monitor,TOTALS=No,FREQUENCY=1,summary=no\n');
    fprintf(plane_file, 'U,RF,\n');
    fprintf(plane_file, '*NODE PRINT,NSET=nset_upper,TOTALS=YES,FREQUENCY=1,summary=yes\n');
    fprintf(plane_file, 'coord,u\n');
    fprintf(plane_file, '*EL PRINT,ELSET=elset_beam,FREQUENCY=1,totals=no,summary=yes\n');
    fprintf(plane_file, 'S11,S12,S13\n');
    fprintf(plane_file, '** S12: Shear stress along the second cross-section axis\n');
    fprintf(plane_file, '** S13: Shear stress along the first cross-section axis\n');
    fprintf(plane_file, '*ENERGY PRINT,elset=elset_beam,FREQUENCY=1\n');
    fprintf(plane_file, '*OUTPUT,field,frequency=1\n');
    fprintf(plane_file, '*ELEMENT OUTPUT\n');
    fprintf(plane_file, 'S,E\n');
    fprintf(plane_file, '*NODE output,nset=nset_all\n');
    fprintf(plane_file, 'U,RF\n');
    fprintf(plane_file, '*END STEP\n');
    fclose(plane_file);
    fprintf('Created beam elements B21H .inp file written to %s.inp\n', baseName);

    ftar = 1;
end