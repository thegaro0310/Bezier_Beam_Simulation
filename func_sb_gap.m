function ftar = func_sb_gap(GAP,UPPER,LOWER,pointsxU,pointsyU,pointsxL,pointsyL,YOUNG,NUXY,DENS,OPDIM,IPDIMU,IPDIML,DELTATH,INCREME,INCREMEINI,STABLIZ,ALSDTOL)
% calculate objective
% N, mm, tonne, sec, MPa
format long

% upper beam
%pointsxU = [xL_1b(1:end)];
%pointsyU = [yL_1b(1:end)];   % 

% lower beam
%pointsxL = [xL_1a(1:end)];
%pointsyL = [yL_1a(1:end)];   % 
pointsyL = pointsyL - GAP;   

%% static analysis
plane_file = fopen('sb.inp','w+');

fprintf (plane_file , '***RESTART,WRITE,FREQUENCY = 9999,overlay \n');
fprintf (plane_file , '*HEADING\n');
fprintf (plane_file , 'By Dung-An Wang\n');
fprintf (plane_file , 'Create: June 17th, 2025\n');
fprintf (plane_file , 'Modified: \n');
fprintf (plane_file , 'abaqus job=sb interactive\n');
fprintf (plane_file , 'gawk -f oh.awk sb.dat > sb_fea.txt\n');
% Print out the set for upper nodes
fprintf (plane_file , '*NODE, nset=nset_upper\n');
for i = 1:size(pointsxU,1)           % Create nodes of inner beam
    fprintf (plane_file , '%d , %6e , %6e, 0\n' , i , pointsxU(i) , pointsyU(i));
end
% Print out the set for lower nodes
fprintf (plane_file , '*NODE, nset=nset_lower\n');
for i = 1:size(pointsxL,1)           % Create the 1st node to next to the last node of outer beam
    fprintf (plane_file , '%d , %6e , %6e, 0\n' , size(pointsxU,1)+i , pointsxL(i), pointsyL(i));
end
fprintf (plane_file , '*NSET, NSET=nset_anchor_upper\n');
fprintf (plane_file , '%d,\n', 1);
fprintf (plane_file , '*NSET, NSET=nset_end\n');
fprintf (plane_file , '%d,%d \n', size(pointsxU,1),size(pointsxU,1)+size(pointsxL,1));
fprintf (plane_file , '*NSET, NSET=nset_monitor\n');
fprintf (plane_file , '%d, \n', size(pointsxU,1));
fprintf (plane_file , '*NSET, NSET=nset_anchor_lower\n');
fprintf (plane_file , '%d,\n', size(pointsxU,1)+1);
fprintf (plane_file , '*NSET, NSET=nset_anchor\n');
fprintf (plane_file , '%d,%d \n', 1,size(pointsxU,1)+1);
fprintf (plane_file , '*NSET, NSET=nset_all\n');
fprintf (plane_file , 'nset_upper,nset_lower \n');

fprintf (plane_file , '** --- Mesh the beam --- \n');
fprintf (plane_file , '*ELEMENT,TYPE=B21H,ELSET=elset_beamIN\n');
for i = 1:UPPER  % upper beam
    fprintf (plane_file , '%d , %d , %d\n', i, i, i+1);
end
fprintf (plane_file , '*ELEMENT,TYPE=B21H,ELSET=elset_beamOU\n');
for i = 1:LOWER  % lower beam
    fprintf (plane_file , '%d , %d , %d\n', UPPER+i, size(pointsxU,1)+i, size(pointsxU,1)+i+1);
end

fprintf (plane_file , '*ELSET,ELSET=elset_beam\n');
fprintf (plane_file , 'elset_beamOU,elset_beamIN \n');

fprintf (plane_file , '*MATERIAL,NAME = POM\n');
fprintf (plane_file , '*ELASTIC\n');
fprintf (plane_file , '%6e\n',YOUNG);
fprintf (plane_file , '*DENSITY\n');
fprintf (plane_file , '%6e\n',DENS);

fprintf (plane_file , '*BEAM SECTION,SECTION=RECT,ELSET=elset_beamIN,MATERIAL=POM\n');
fprintf (plane_file , '%f,%f\n',OPDIM,IPDIMU);
fprintf (plane_file , '** dimension along the first beam section axis, dimension along the second beam section axis\n');
fprintf (plane_file , '%d,%d,%d\n',0,0,-1);
fprintf (plane_file , '** First, second, third direction cosine of the first beam section axis \n');
fprintf (plane_file , '*BEAM SECTION,SECTION=RECT,ELSET=elset_beamOU,MATERIAL=POM\n');
fprintf (plane_file , '%f,%f\n',OPDIM,IPDIML);
fprintf (plane_file , '** dimension along the first beam section axis, dimension along the second beam section axis\n');
fprintf (plane_file , '%d,%d,%d\n',0,0,-1);
fprintf (plane_file , '** First, second, third direction cosine of the first beam section axis \n');

fprintf (plane_file , '*STEP,INC=9999,NLGEOM,unsymm=yes\n');
fprintf (plane_file , 'step 1 \n');
%fprintf (plane_file , '*STATIC,ALLSDTOL=%f,stabilize=%e, CONTINUE=YES \n',ALSDTOL,STABLIZ);
fprintf (plane_file , '*STATIC \n');
fprintf (plane_file , '%f , 1.0,1e-10 , %f \n',INCREMEINI,INCREME);
%fprintf (plane_file , '*controls, analysis=discontinuous\n');
fprintf (plane_file , '*BOUNDARY,op=new\n');
fprintf (plane_file , 'nset_anchor_upper,1,6,0 \n');
fprintf (plane_file , 'nset_anchor_lower,1,6,0\n');
fprintf (plane_file , 'nset_end,1,1,0\n');
fprintf (plane_file , 'nset_end,2,2,%e \n',DELTATH);
fprintf (plane_file , 'nset_end,6,6,0 \n');
fprintf (plane_file , '*monitor,  dof=2, node=nset_monitor, frequency=1\n');
fprintf (plane_file , '*NODE PRINT,NSET=nset_anchor,TOTALS=YES,FREQUENCY=1,summary=no\n');
fprintf (plane_file , 'RF,\n');
fprintf (plane_file , '*NODE PRINT,NSET=nset_monitor,TOTALS=No,FREQUENCY=1,summary=no\n');
fprintf (plane_file , 'U,RF,\n');
fprintf (plane_file , '*NODE PRINT,NSET=nset_upper,TOTALS=YES,FREQUENCY=1,summary=yes\n');
fprintf (plane_file , 'coord,u\n');
fprintf (plane_file , '*EL PRINT,ELSET=elset_beam,FREQUENCY=1,totals=no,summary=yes\n');
fprintf (plane_file , 'S11,S12,S13\n');
fprintf (plane_file , '** S12: Shear stress along the second cross-section axis \n');
fprintf (plane_file , '** S13: Shear stress along the first cross-section axis\n');
fprintf (plane_file , '*ENERGY PRINT,elset=elset_beam,FREQUENCY=1\n');
fprintf (plane_file , '*OUTPUT,field, frequency=1\n');
fprintf (plane_file , '*ELEMENT OUTPUT\n');
fprintf (plane_file , 'S,E\n');
fprintf (plane_file , '*NODE output,nset=nset_all\n');
fprintf (plane_file , 'U,RF\n');
fprintf (plane_file , '*END STEP\n');
fclose(plane_file);
% Execute Abaqus
! abaqus job=sb interactive
% Open the file
fidw = fopen('sb_fea.txt', 'w');
fid = fopen('sb.dat', 'r');
if fid == -1
    error('Cannot open file.');
end

% Read all lines into a cell array
lines = {};
tline = fgetl(fid);
while ischar(tline)
    lines{end+1} = tline; %#ok<AGROW>
    tline = fgetl(fid);
end
fclose(fid);

% Initialize index
i = 1;
while i <= length(lines)
    line = strtrim(lines{i});
    % Check if line contains ELSET_BEAM
    if contains(line, 'ELSET_BEAM')
        % Find MAXIMUM stress value
        s11_out = NaN;
        while i <= length(lines)
            if contains(lines{i}, 'MAXIMUM')                             
                tokens = strsplit(strtrim(lines{i}));
                if numel(tokens) >= 2
                    s11_out = str2double(tokens{2});					
                end
				% Skip 3 lines to get to the data
                i = i + 3;
				tokens = strsplit(strtrim(lines{i}));
                if numel(tokens) >= 2
                    s11_out1 = str2double(tokens{2});
                    if abs(s11_out1) > s11_out
					    s11_out = abs(s11_out1);
					end
                end
                break;
            end
            i = i + 1;
        end
		while i <= length(lines)
            if contains(lines{i}, 'RECOVERABLE')                             
                tokens = strsplit(strtrim(lines{i}));
                if numel(tokens) >= 4
                    allse = str2double(tokens{4});					
                end
                break;
            end
            i = i + 1;
        end
        % Find NSET_ANCHOR data
        rf1 = NaN;
        rf2 = NaN;
        while i <= length(lines)
            if contains(lines{i}, 'NSET_ANCHOR')
                % Skip 8 lines to get to the data
                i = i + 8;
                if i > length(lines), break; end
                tokens = strsplit(strtrim(lines{i}));
                if numel(tokens) >= 4
                    rf1 = str2double(tokens{2});
                    rf2 = str2double(tokens{3});	
                end
                break;
            end
            i = i + 1;
        end
        % Find NSET_END data
        input_u2 = NaN;
        monitor_rf2 = NaN;
        while i <= length(lines)
            if contains(lines{i}, 'NSET_MONITOR')
                % Skip 5 lines to get to the data
                i = i + 5;
                if i > length(lines), break; end
                tokens = strsplit(strtrim(lines{i}));
                if numel(tokens) >= 6
                    input_u2 = str2double(tokens{3});
                    monitor_rf2 = str2double(tokens{6});
                end
                break;
            end
            i = i + 1;
        end
        % Find NSET_UPPER MAXIMUM coordinates
        upper_coor1_max = NaN;
        upper_coor2_max = NaN;
        while i <= length(lines)
            if contains(lines{i}, 'NSET_UPPER')
                % Find MAXIMUM line
                while i <= length(lines)
                    if contains(lines{i}, 'MAXIMUM')
                        if i > length(lines), break; end
                        tokens = strsplit(strtrim(lines{i}));
                        if numel(tokens) >= 3
                            upper_coor1_max = str2double(tokens{2});
                            upper_coor2_max = str2double(tokens{3});
							upper_u1_max = str2double(tokens{4});
                            upper_u2_max = str2double(tokens{5});
                        end
                        break;
                    end
                    i = i + 1;
                end
                break;
            end
            i = i + 1;
        end
        fprintf(fidw, '%f %f %f %f %f %f %f %f %f %f\n', ...
                input_u2, monitor_rf2, rf1, rf2, s11_out, ...
                upper_coor1_max, upper_coor2_max,upper_u1_max, upper_u2_max,allse);
    end
    i = i + 1;
end

fclose(fidw);

load -ascii sb_fea.txt

LW=2;	% plot line width
FSLABEL=12;
FSTEXT=12;
FSLEGEND=12;

figure(1)
hndl=plot(-sb_fea(:,1),sb_fea(:,3),'b-',-sb_fea(:,1),sb_fea(:,4),'r--');
set( hndl, 'LineWidth', LW );
set(gca, 'linewidth', LW, 'fontsize', FSLABEL); % axis and tick label 
iniX1=legend('RF1','RF2','location','best');
legend('boxoff');
LEG = findobj(iniX1,'type','text');
set(LEG,'FontSize',FSLEGEND);
set(gcf,'resizefcn','');
xlabel('Displacement (mm)','Fontsize', FSLABEL);
ylabel('Force (N)','Fontsize', FSLABEL);
grid on;
%axis([-inf inf -50 100]);

figure(2)
hndl=plot(-sb_fea(:,1),abs(sb_fea(:,5)),'b-');
set( hndl, 'LineWidth', LW );
set(gca, 'linewidth', LW, 'fontsize', FSLABEL); % axis and tick label 
%iniX1=legend('RF1','RF2','location','best');
%legend('boxoff');
%LEG = findobj(iniX1,'type','text');
%set(LEG,'FontSize',FSLEGEND);
set(gcf,'resizefcn','');
xlabel('Displacement (mm)','Fontsize', FSLABEL);
ylabel('Maximum stress (MPa)','Fontsize', FSLABEL);
grid on;

figure(3)
hndl=plot(-sb_fea(:,1),sb_fea(:,10),'b-');
set( hndl, 'LineWidth', LW );
set(gca, 'linewidth', LW, 'fontsize', FSLABEL); % axis and tick label 
%iniX1=legend('RF1','RF2','location','best');
%legend('boxoff');
%LEG = findobj(iniX1,'type','text');
%set(LEG,'FontSize',FSLEGEND);
set(gcf,'resizefcn','');
xlabel('Displacement (mm)','Fontsize', FSLABEL);
ylabel('Strain energy (N.mm)','Fontsize', FSLABEL);
grid on;

ftar = 1;