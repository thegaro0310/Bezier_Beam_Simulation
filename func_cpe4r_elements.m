function ftar = func_cpe4r_elements(GAP, UPPER, LOWER, pointsxU, pointsyU, pointsxL, pointsyL, YOUNG, NUXY, DENS, OPDIM, IPDIMU, IPDIML, DELTATH, INCREME, INCREMEINI)
    % Calculate objective
    % N, mm, tonne, sec, MPa
    format long;
    currentDateTime = datetime('now');
    baseName = 'sb_cpe4r';

    % Upper beam
    %pointsxU = [xL_1b(1:end)];
    %pointsyU = [yL_1b(1:end)];

    % Lower beam
    %pointsxL = [xL_1a(1:end)];
    %pointsyL = [yL_1a(1:end)];
    % Adjust lower beam by GAP
    pointsyL = pointsyL - GAP;

    % =================================
    % Call the mesh generation function
    % =================================
    [nodes, elems, fix_nodes, disp_nodes] = generate_CPE4R_mesh(pointsxU, pointsyU, pointsxL, pointsyL, IPDIMU, IPDIML);

    % =============================
    % ------ STATIC ANALYSIS ------
    % =============================
    inputFileName = sprintf('%s.inp', baseName);
    plane_file = fopen(inputFileName, 'w');
    fprintf(plane_file, '***RESTART,WRITE,FREQUENCY = 9999,overlay \n');
    fprintf(plane_file, '*HEADING\n');
    fprintf(plane_file, 'By Tran Pham Anh Khoi\n');
    fprintf(plane_file, 'Create: July 1st, 2025\n');
    fprintf(plane_file, 'Modified: %s\n', currentDateTime);
    fprintf(plane_file, 'abaqus job=%s interactive\n', baseName);
    fprintf(plane_file, 'gawk -f oh.awk %s.dat > %s_fea.txt\n', baseName, baseName);
    % Write nodes
    fprintf(plane_file, '*Node\n');
    for i = 1 : size(nodes, 1)
        fprintf(plane_file, '%d, %.8f, %.8f\n', nodes(i, 1), nodes(i, 2), nodes(i, 3));
    end
    % Write elements
    fprintf(plane_file, '\n*Element, type=CPE4R\n');
    for i = 1 : size(elems, 1)
        fprintf(plane_file, '%d, %d, %d, %d, %d\n', elems(i, 1), elems(i, 2), elems(i, 3), elems(i, 4), elems(i, 5));
    end
    % Create element set
    fprintf(plane_file, '\n*Elset, elset=all\n');
    fprintf(plane_file, '');
    for i = 1 : size(elems, 1)
        if mod(i, 16) == 0  % 16 elements per line
            fprintf(plane_file, '\n');
        end
        fprintf(plane_file, '%d,', elems(i, 1));
    end
    fprintf(plane_file, '\n');
    % Material definition
    fprintf(plane_file, '\n*Material, name=POM\n');
    fprintf(plane_file, '*Elastic\n');
    fprintf(plane_file, '%.6f, %.6f\n', YOUNG, NUXY);
    fprintf(plane_file, '*Density\n');
    fprintf(plane_file, '%.6f\n', DENS);
    % Section assignment
    fprintf(plane_file, '\n*Solid Section, elset=all, material=POM\n');
    fprintf(plane_file, '%.2f\n', OPDIM);  % Out-of-plane thickness
    % Boundary conditions
    fprintf(plane_file, '\n*Nset, nset=fix_nodes\n');
    fprintf(plane_file, '%d, %d, %d, %d\n', fix_nodes);
    fprintf(plane_file, '\n*Nset, nset=disp_nodes\n');
    fprintf(plane_file, '%d, %d, %d, %d\n', disp_nodes);
    fprintf(plane_file, '\n*Boundary\n');
    fprintf(plane_file, 'fix_nodes, 1, 1, 0.0\n');   % Fix X-direction
    fprintf(plane_file, 'fix_nodes, 2, 2, 0.0\n');   % Fix Y-direction
    % Step definition
    fprintf(plane_file, '\n*Step, name=displacement_step, nlgeom=YES\n');
    fprintf(plane_file, '*Static\n');
    fprintf(plane_file, '%.6f, 1.0, %.6f, %.6f\n', INCREMEINI, INCREME, INCREME);
    % Apply displacement
    fprintf(plane_file, '\n*Boundary, op=NEW\n');
    fprintf(plane_file, 'disp_nodes, 2, 2, %.6f\n', DELTATH);
    % Output requests
    fprintf(plane_file, '\n*Output, field\n');
    fprintf(plane_file, '*Node Output\n');
    fprintf(plane_file, 'U, RF\n');
    fprintf(plane_file, '*Element Output\n');
    fprintf(plane_file, 'S, E\n');
    fprintf(plane_file, '*End Step\n');
    fclose(plane_file);
    fprintf('Created beam elements CPE4R .inp file written to %s.inp\n', baseName);

    ftar = 1;
end

function [nodes, elems, fix_nodes, disp_nodes] = generate_CPE4R_mesh(pointsxU, pointsyU, pointsxL, pointsyL, IPDIMU, IPDIML)
    % Initialize node and element arrays
    nodes = [];
    elems = [];
    
    % Initialize node and element IDs
    node_id = 1;
    elem_id = 1;

    % Create sets to store node IDs
    upper_nodes = struct('top', [], 'bot', []);
    lower_nodes = struct('top', [], 'bot', []);

    % ==========================
    % Create mesh for upper beam
    % ==========================
    for i = 1:length(pointsxU)
        % Calculate segment direction vectors
        if i == 1
            % First point - use next segment
            dx = pointsxU(2) - pointsxU(1);
            dy = pointsyU(2) - pointsyU(1);
        elseif i == length(pointsxU)
            % Last point - use previous segment
            dx = pointsxU(end) - pointsxU(end-1);
            dy = pointsyU(end) - pointsyU(end-1);
        else
            % Internal points - average adjacent segments
            dx1 = pointsxU(i) - pointsxU(i-1);
            dy1 = pointsyU(i) - pointsyU(i-1);
            dx2 = pointsxU(i+1) - pointsxU(i);
            dy2 = pointsyU(i+1) - pointsyU(i);
            dx = (dx1 + dx2)/2;
            dy = (dy1 + dy2)/2;
        end
        % Calculate perpendicular vector (normalized)
        L = sqrt(dx^2 + dy^2);
        if L > 0
            nx = -dy/L;
            ny = dx/L;
        else
            nx = 0;
            ny = 1;
        end
        % Create top and bottom nodes for this point
        top_node = [pointsxU(i) + 0.5*IPDIMU*nx, pointsyU(i) + 0.5*IPDIMU*ny];
        bot_node = [pointsxU(i) - 0.5*IPDIMU*nx, pointsyU(i) - 0.5*IPDIMU*ny];
        % Store node IDs
        % Top node
        nodes = [nodes; node_id, top_node(1), top_node(2)];
        upper_nodes.top(i) = node_id;
        node_id = node_id + 1;
        % Bot node        
        nodes = [nodes; node_id, bot_node(1), bot_node(2)];
        upper_nodes.bot(i) = node_id;
        node_id = node_id + 1;
    end

    % ========================== 
    % Create mesh for lower beam
    % ========================== 
    for i = 1:length(pointsxL)
        % Calculate segment direction vectors
        if i == 1
            dx = pointsxL(2) - pointsxL(1);
            dy = pointsyL(2) - pointsyL(1);
        elseif i == length(pointsxL)
            dx = pointsxL(end) - pointsxL(end-1);
            dy = pointsyL(end) - pointsyL(end-1);
        else
            dx1 = pointsxL(i) - pointsxL(i-1);
            dy1 = pointsyL(i) - pointsyL(i-1);
            dx2 = pointsxL(i+1) - pointsxL(i);
            dy2 = pointsyL(i+1) - pointsyL(i);
            dx = (dx1 + dx2)/2;
            dy = (dy1 + dy2)/2;
        end
        % Calculate perpendicular vector (normalized)
        L = sqrt(dx^2 + dy^2);
        if L > 0
            nx = -dy/L;
            ny = dx/L;
        else
            nx = 0;
            ny = 1;
        end
        % Create top and bottom nodes for this point
        top_node = [pointsxL(i) + 0.5*IPDIML*nx, pointsyL(i) + 0.5*IPDIML*ny];
        bot_node = [pointsxL(i) - 0.5*IPDIML*nx, pointsyL(i) - 0.5*IPDIML*ny];
        % Store node IDs
        % Top node
        nodes = [nodes; node_id, top_node(1), top_node(2)];
        lower_nodes.top(i) = node_id;
        node_id = node_id + 1;
        % Bot node        
        nodes = [nodes; node_id, bot_node(1), bot_node(2)];
        lower_nodes.bot(i) = node_id;
        node_id = node_id + 1;
    end

    % Create elements with proper connectivity
    % Upper beam elements
    for i = 1:length(pointsxU)-1
        elems = [elems; elem_id, ...
            upper_nodes.top(i), ...
            upper_nodes.top(i+1), ...
            upper_nodes.bot(i+1), ...
            upper_nodes.bot(i)];
        elem_id = elem_id + 1;
    end

    % Lower beam elements
    for i = 1:length(pointsxL)-1
        elems = [elems; elem_id, ...
            lower_nodes.top(i), ...
            lower_nodes.top(i+1), ...
            lower_nodes.bot(i+1), ...
            lower_nodes.bot(i)];
        elem_id = elem_id + 1;
    end

    % Identify boundary nodes
    % Left-end anchors (first point of both beams)
    fix_nodes = [upper_nodes.top(1), upper_nodes.bot(1), ...
                 lower_nodes.top(1), lower_nodes.bot(1)];

    % Right-end shuttle (last point of both beams)
    disp_nodes = [upper_nodes.top(end), upper_nodes.bot(end), ...
                  lower_nodes.top(end), lower_nodes.bot(end)];
end
