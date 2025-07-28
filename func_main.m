function main()
    clc;
    clear all;
    close all;
    delete *.lck;
    format long;

    % ======================================
    % Loads the optimized Bezier design data 
    % ======================================    
    STABLIZ         = 2e-2;
    INCREMEINI      = 1e-4;
    ALSDTOL         = 0.05;                 % maximum allowable ratio of the stabilization energy to the total strain energy default: 0.05
    INCREME         = 0.01;                 % 0.01 increment of abaqus 
    SCALED_FACTOR   = 1;                    % scaled factor apply to beam elements
    % L1 = 35;                              % mm
    % H1 = 50;                              % mm
    % L2 = 70;                              % mm
    % H2 = 100;                             % mm
    % CHKEXIT = 9999999;
    
    % ======================================
    % Loads the optimized Bezier design data 
    % ======================================
    UPPER = 40; LOWER = 40;     % number of elements for upper and lower beams
    [pointsxU, pointsyU, pointsxL, pointsyL] = func_bezier_beam_shape(UPPER, LOWER, SCALED_FACTOR);

    % ===========================================
    % Configuration for beam elements calculation
    % ===========================================
    NUXY    = 0.38;
    YOUNG   = 3.5e+3;           % 3.5e+3 [MPa] Young's modulus
    DENS    = 1.400000e-06;     % tonne/mm^3
    OPDIM   = 3;                % 3 [mm] beam out of plane dimension
    IPDIMU  = 0.8;              % 0.8 [mm] upper beam inplane dimension
    IPDIML  = 0.8;              % 0.8 [mm] lower beam inplane dimension
    GAP     = 5;                % gap between the upper and lower beam for the actuation shuttle
    DELTATH = -10;              % in -y direction 

    % =======================================
    % ------- Calculate beam elements -------
    % =======================================    
    % Apply scaled factor to only B21H beam elements
    % CPE4R beam elements would be scaled and optimized in other tools
    func_beam_elements(GAP,UPPER,LOWER, ...
                       pointsxU.*SCALED_FACTOR,pointsyU.*SCALED_FACTOR, ...
                       pointsxL.*SCALED_FACTOR,pointsyL.*SCALED_FACTOR, ...
                       YOUNG,NUXY,DENS,OPDIM, ...
                       IPDIMU.*SCALED_FACTOR,IPDIML.*SCALED_FACTOR, ...
                       DELTATH,INCREME,INCREMEINI,STABLIZ,ALSDTOL);

    % ========================================
    % ------- Calculate CPE4R elements -------
    % ========================================
    % func_cpe4r_elements(GAP,UPPER,LOWER, ...
    %                     pointsxU,pointsyU, ...
    %                     pointsxL,pointsyL, ...
    %                     YOUNG,NUXY,DENS,OPDIM, ...
    %                     IPDIMU,IPDIML, ...
    %                     DELTATH,INCREME,INCREMEINI);

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
end

function [pointsxU, pointsyU, pointsxL, pointsyL] = func_bezier_beam_shape(UPPER, LOWER, SCALED_FACTOR)
    % ======================================
    % Loads the optimized Bezier design data 
    % ======================================
    load -ascii iters7pt_se8.txt
    pop = iters7pt_se8(end,:);

    % ======================================
    % --------- Upper bezier beams ---------
    % ======================================
    % Coordinates of seven control points for upper beam
    L1 = pop(19);
    H1 = pop(20);
    BxU = [0  pop(1) pop(3) pop(5) pop(7) pop(7) L1]';
    ByU = [H1 pop(2) pop(4) pop(6) pop(8) pop(8) H1]';
    dummy = [1 1 1 1 1 1 1]';
    % Calculate point coordinates for Bezier upper beam
    [xU yU temp] = func_bezier_berstein_form(BxU,ByU,dummy,UPPER);
    % Point coordinates for Bezier upper beam
    pointsxU = [xU(1:end)];
    pointsyU = [yU(1:end)];

    % ======================================
    % --------- Lower bezier beams ---------
    % ======================================
    % coordinates of seven control points for lower beam
    BxL = [0 pop(9)  pop(11) pop(13) pop(15) pop(17) L1]';
    ByL = [0 pop(10) pop(12) pop(14) pop(16) pop(18) H1]';
    dummy = [1 1 1 1 1 1 1]';
    % Calculate point coordinates for Bezier lower beam
    [xL yL temp] = func_bezier_berstein_form(BxL,ByL,dummy,LOWER);
    % Point coordinates for Bezier lower beam 
    pointsxL = [xL(1:end)];
    pointsyL = [yL(1:end)];

    % =======================================
    % Initial shape of upper beam, lower beam
    % =======================================
    LW          = 2;            % Plot line width
    FSLABEL     = 12;           % Plot font size
    FSTEXT      = 12;           % Plot text size
    FSLEGEND    = 12;           % Plot legend size
    MS          = 4;            % Plot marker size
    FNAME       = "Helvetica";  % Plot font name

    % =======================================
    % ---- Plot the shape of Bezier beam ----
    % =======================================
    fprintf('Plot the shape of Bezier beam\n');
    figure(100);
    title('Bezier Beam Shape');
    hnd1 = plot(pointsxU.*SCALED_FACTOR,pointsyU.*SCALED_FACTOR,'-ob',pointsxL.*SCALED_FACTOR,pointsyL.*SCALED_FACTOR,'-or',BxU,ByU,'dm',BxL,ByL,'xk');
    set(hnd1,'LineWidth',LW,'MarkerSize',MS);
    %legend("Undeformed shape");
    %legend('boxoff');
    set(gca,'FontSize',FSTEXT,'fontname',FNAME)
    xlabel('X [mm]','FontSize',FSLABEL,'fontname',FNAME);
    ylabel('Y [mm]','FontSize',FSLABEL,'fontname',FNAME);
    axis equal
    grid on;
end