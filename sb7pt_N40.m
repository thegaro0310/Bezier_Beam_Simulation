% N, mm, tonne, sec, MPa
% 7pt:  7 Bezier curve control points
% N 40: N=UPPER=LOWER
%
% gap between the upper and lower beam for the actuation shuttle
% force outputs at the anchors for the gap case  
% is nearly the same as the case without gap 
%
% !abaqus job=rbmu18 interactive
% !gawk -f oh.awk rbmu18.dat > rbmb.txt

clear all;
close all;
clc

delete *.lck      % delete lock file of abaqus
delete *.dat      % delete dat file of abaqus

format long
fitall_sa = zeros(1000,7);      % monitor iteration don't change row #  (1000),  column #: design variable #+1, see myoutSA.m
% CHKEXIT = 9999999;
ALSDTOL = 0.05;                 %  maximum allowable ratio of the stabilization energy to the total strain energy default: 0.05
STABLIZ = 2e-2;
INCREMEINI = 1e-4;
INCREME = 0.01;                 % 0.01 increment of abaqus 

% L1 = 35;    % mm
% H1 = 50;    % mm
% L2 = 70;    % mm
% H2 = 100;   % mm

% --------------------------------------------------------------
UPPER = 40;             % number of elements of upper beam
LOWER = 40;             % number of elements of lower beam
YOUNG = 3.5e+3;         % 3.5e+3 [MPa] Young's modulus
NUXY = 0.38;
DENS = 1.400000e-06;    % tonne/mm^3
OPDIM = 3;              % 3 [mm] beam out of plane dimension
IPDIMU = 0.8;           % 0.8 [mm] upper beam inplane dimension
IPDIML = 0.8;           % 0.8 [mm] lower beam inplane dimension
GAP = 5;                % gap between the upper and lower beam for the actuation shuttle
% --------------------------------------------------------------

% Loads the optimized Bezier design data 
load -ascii iters7pt_se6.txt
% Selects the last row for the current simulation
pop=iters7pt_se6(end,:);

%%%%%%%%%%%%%%%%%%%%
%
% Upper bezier beams
%
%%%%%%%%%%%%%%%%%%%%
L1 = pop(19);
H1 = pop(20);

% Coordinates of seven control points for upper beam
BxU = [0  pop(1) pop(3) pop(5) pop(7) pop(7) L1]';
ByU = [H1 pop(2) pop(4) pop(6) pop(8) pop(8) H1]';
dummy = [1 1 1 1 1 1 1]';

% Calculate point coordinates for Bezier upper beam
[xU yU temp] = Bezierauto(BxU,ByU,dummy,UPPER);

% Point coordinates for Bezier upper beam
pointsxU = [xU(1:end)];
pointsyU = [yU(1:end)];

%%%%%%%%%%%%%%%%%%%%
%
% Lower bezier beams
%
%%%%%%%%%%%%%%%%%%%%

% coordinates of seven control points for lower beam
BxL = [0 pop(9) pop(11) pop(13) pop(15) pop(17) L1]';
ByL = [0 pop(10) pop(12) pop(14) pop(16) pop(18) H1]';
dummy = [1 1 1 1 1 1 1]';

% Calculate point coordinates for Bezier lower beam
[xL yL temp] = Bezierauto(BxL,ByL,dummy,LOWER);

% Point coordinates for Bezier lower beam 
pointsxL = [xL(1:end)];
pointsyL = [yL(1:end)];

% ---------------------------------------
% Initial shape of upper beam, lower beam
% ---------------------------------------
LW = 2;                % Plot line width
FSLABEL = 12;          % Plot font size
FSTEXT = 12;           % Plot text size
FSLEGEND = 12;         % Plot legend size
MS = 4;                % Plot marker size
FNAME = "Helvetica";   % Plot font name

% Plot the figure
figure(100);
hnd1 = plot(pointsxU,pointsyU,'-ob',pointsxL,pointsyL,'-or',BxU,ByU,'dm',BxL,ByL,'xk');
set(hnd1,'LineWidth',LW,'MarkerSize',MS);
%legend("Undeformed shape");
%legend('boxoff');
set(gca,'FontSize',FSTEXT,'fontname',FNAME)
xlabel('X [mm]','FontSize',FSLABEL,'fontname',FNAME);
ylabel('Y [mm]','FontSize',FSLABEL,'fontname',FNAME);
axis equal
grid on;

DELTATH = -10;  % in -y direction 

% Caculate gap between the upper and lower beam
func_sb_gap(GAP,UPPER,LOWER,pointsxU,pointsyU,pointsxL,pointsyL,YOUNG,NUXY,DENS,OPDIM,IPDIMU,IPDIML,DELTATH,INCREME,INCREMEINI,STABLIZ,ALSDTOL);

% Calculate the elements set for CPE4R
% func_elements_CPE4R(GAP,UPPER,LOWER,pointsxU,pointsyU,pointsxL,pointsyL,YOUNG,NUXY,DENS,OPDIM,IPDIMU,IPDIML,DELTATH,INCREME,INCREMEINI);

% --- Delete Abaqus redudant files ---
delete *.com
delete *.fil
delete *.mdl
delete *.res
delete *.stt
delete *.prt
delete *.sim
delete *.SMABulk
delete *.SMAFocus
delete *.msg
delete *.sta
delete *.env
delete *.rpy*   