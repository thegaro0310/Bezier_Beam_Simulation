function ftar = func_elements_CPE4R(GAP, UPPER, LOWER, pointsxU, pointsyU, pointsxL, pointsyL, YOUNG, NUXY, DENS, OPDIM, IPDIMU, IPDIML, DELTATH, INCREME, INCREMEINI)
format long;

% Adjust lower beam by GAP
pointsyL = pointsyL - GAP;

% Initialize node and element arrays
nodes = [];
elems = [];
node_id = 1;
elem_id = 1;

% Create sets to store node IDs
upper_nodes = struct('top', [], 'bot', []);
lower_nodes = struct('top', [], 'bot', []);

%% Create mesh for upper beam
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
    nodes = [nodes; node_id, top_node(1), top_node(2)];
    upper_nodes.top(i) = node_id;
    node_id = node_id + 1;
    
    nodes = [nodes; node_id, bot_node(1), bot_node(2)];
    upper_nodes.bot(i) = node_id;
    node_id = node_id + 1;
end

%% Create mesh for lower beam
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
    nodes = [nodes; node_id, top_node(1), top_node(2)];
    lower_nodes.top(i) = node_id;
    node_id = node_id + 1;
    
    nodes = [nodes; node_id, bot_node(1), bot_node(2)];
    lower_nodes.bot(i) = node_id;
    node_id = node_id + 1;
end

%% Create elements with proper connectivity
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

%% Identify boundary nodes
% Left-end anchors (first point of both beams)
fix_nodes = [upper_nodes.top(1), upper_nodes.bot(1), ...
             lower_nodes.top(1), lower_nodes.bot(1)];

% Right-end shuttle (last point of both beams)
disp_nodes = [upper_nodes.top(end), upper_nodes.bot(end), ...
              lower_nodes.top(end), lower_nodes.bot(end)];

%% Write to .inp file with improved formatting
fid = fopen('sb_cpe4r.inp', 'w');
fprintf(fid, '*Heading\n');
fprintf(fid, '** Generated with CPE4R elements\n');
fprintf(fid, '** Smooth beam mesh with gap\n\n');

% Write nodes
fprintf(fid, '*Node\n');
for i = 1:size(nodes,1)
    fprintf(fid, '%d, %.8f, %.8f\n', nodes(i,1), nodes(i,2), nodes(i,3));
end

% Write elements
fprintf(fid, '\n*Element, type=CPE4R\n');
for i = 1:size(elems,1)
    fprintf(fid, '%d, %d, %d, %d, %d\n', elems(i,1), elems(i,2), elems(i,3), elems(i,4), elems(i,5));
end

% Create element set
fprintf(fid, '\n*Elset, elset=all\n');
fprintf(fid, '');
for i = 1:size(elems,1)
    if mod(i,16) == 0  % 16 elements per line
        fprintf(fid, '\n');
    end
    fprintf(fid, '%d,', elems(i,1));
end
fprintf(fid, '\n');

% Material definition
fprintf(fid, '\n*Material, name=POM\n');
fprintf(fid, '*Elastic\n');
fprintf(fid, '%.6f, %.6f\n', YOUNG, NUXY);
fprintf(fid, '*Density\n');
fprintf(fid, '%.6f\n', DENS);

% Section assignment
fprintf(fid, '\n*Solid Section, elset=all, material=POM\n');
fprintf(fid, '%.2f\n', OPDIM);  % Out-of-plane thickness

% Boundary conditions
fprintf(fid, '\n*Nset, nset=fix_nodes\n');
fprintf(fid, '%d, %d, %d, %d\n', fix_nodes);

fprintf(fid, '\n*Nset, nset=disp_nodes\n');
fprintf(fid, '%d, %d, %d, %d\n', disp_nodes);

fprintf(fid, '\n*Boundary\n');
fprintf(fid, 'fix_nodes, 1, 1, 0.0\n');   % Fix X-direction
fprintf(fid, 'fix_nodes, 2, 2, 0.0\n');   % Fix Y-direction

% Step definition
fprintf(fid, '\n*Step, name=displacement_step, nlgeom=YES\n');
fprintf(fid, '*Static\n');
fprintf(fid, '%.6f, 1.0, %.6f, %.6f\n', INCREMEINI, INCREME, INCREME);

% Apply displacement
fprintf(fid, '\n*Boundary, op=NEW\n');
fprintf(fid, 'disp_nodes, 2, 2, %.6f\n', DELTATH);

% Output requests
fprintf(fid, '\n*Output, field\n');
fprintf(fid, '*Node Output\n');
fprintf(fid, 'U, RF\n');
fprintf(fid, '*Element Output\n');
fprintf(fid, 'S, E\n');
fprintf(fid, '*End Step\n');

fclose(fid);

fprintf('Created beam element CPE4R .inp file written to sb_cpe4r.inp\n');
ftar = 1;

end