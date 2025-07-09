% N, mm, tonne, sec, MPa
% 7pt:  7 Bezier curve control points
% N 40: N=NINNER=NOUTER
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
CHKEXIT = 9999999;
ALSDTOL = 0.05;                 %  maximum allowable ratio of the stabilization energy to the total strain energy default: 0.05
STABLIZ = 2e-2;
INCREMEINI = 1e-4;
INCREME = 0.01;                 % 0.01 increment of abaqus 

L1 = 35;    % mm
H1 = 50;    % mm
L2 = 70;    % mm
H2 = 100;   % mm

% --------------------------------------------------------------
NINNER = 40;            % number of elements of inner beam
NOUTER = 40;            % number of elements of outer beam
YOUNG = 3.5e+3;         % 3.5e+3 [MPa] Young's modulus
NUXY = 0.38;
DENS = 1.400000e-06;    % tonne/mm^3
OPDIM = 3;              % 5.5 [mm] beam out of plane dimension
IPDIM = 0.8;            % [mm] 0.3 inner beam inplane dimension
IPDIMOU = 0.8;          % [mm] 0.35 outer beam inplane dimension
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

B2X = pop(1);
B2Y = pop(2);  
B3X = pop(3);
B3Y = pop(4);
B4X = pop(5);
B4Y = pop(6); 
B5X = pop(7);
B5Y = pop(8);
B6X = pop(7);
B6Y = pop(8);

B12X = pop(9);
B12Y = pop(10);  
B11X = pop(11);
B11Y = pop(12);
B10X = pop(13);
B10Y = pop(14); 
B9X = pop(15);
B9Y = pop(16);
B8X = pop(17);
B8Y = pop(18);

L1 = pop(19);
H1 = pop(20);

% Coordinates of seven control points for upper beam
BxU = [0  B2X B3X B4X B5X B6X L1]';
ByU = [H1 B2Y B3Y B4Y B5Y B6Y H1]';
dummy = [1 1 1 1 1 1 1]';

% Calculate point coordinates for Bezier upper beam
[xU_1 yU_1 temp] = Bezierauto(BxU,ByU,dummy,NINNER);

% Point coordinates for Bezier upper beam
pointsxU = [xU_1(1:end)];
pointsyU = [yU_1(1:end)];

%%%%%%%%%%%%%%%%%%%%
%
% Lower bezier beams
%
%%%%%%%%%%%%%%%%%%%%

B5X = pop(end,7); %50;
B5Y = pop(end,8); %25;

B6X = pop(end,5); %35;
B6Y = pop(end,6); %5;

% coordinates of seven control points for lower beam
BxL = [0 B12X B11X B10X B9X B8X L1]';
ByL = [0 B12Y B11Y B10Y B9Y B8Y H1]';

dummy = [1 1 1 1 1 1 1]';

% Calculate point coordinates for Bezier lower beam
[xL_1 yL_1 temp] = Bezierauto(BxL,ByL,dummy,NOUTER);

% Point coordinates for Bezier lower beam 
pointsxL = [xL_1(1:end)];
pointsyL = [yL_1(1:end)];

% ---------------------------------------
% Initial shape of upper beam, lower beam
% ---------------------------------------
LW = 2;                % Plot line width
FSLABEL = 12;          % Plot font size
FSTEXT = 12;           % Plot text size
FSLEGEND = 12;         % Plot legend size
MS = 4;                % Plot marker size
FNAME = "Helvetica";   % Plot font name

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
func_sb_gap(GAP,NINNER,NOUTER,pointsxU,pointsyU,pointsxL,pointsyL,YOUNG,NUXY,DENS,OPDIM,IPDIM,IPDIMOU,DELTATH,INCREME,INCREMEINI,STABLIZ,ALSDTOL);

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