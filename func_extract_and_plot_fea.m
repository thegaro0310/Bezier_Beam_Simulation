function func_extract_and_plot_fea()
    clc;
    clear all;
    close all;
    % delete lock file of abaqus
    delete *.lck;
    
    % ============================
    % ------ Run abaqus job ------
    % ============================
    fprintf('Running abaqus jobs\n');
    % !abaqus job=sb interactive
    !abaqus job=sb_cpe4r_designed interactive

    % ==================================================
    % Step 1: Read sb.dat, sb_cpe4r.dat and extract data
    % ==================================================
    % lines = read_data_sb('sb.dat');
    lines_cpe4r = read_data_sb_cpe4r('sb_cpe4r_designed.dat');

    % =======================================================================
    % Step 2: Parse and extract results (open text file and write data to it)
    % =======================================================================
    % extract_data_beam_elements(lines, 'sb_fea.txt');
    extract_data_CPE4R_elements(lines_cpe4r, 'sb_cpe4r_designed_fea.txt');

    % =============================
    % Step 3: Load and plot results
    % =============================
    sb_fea = load('sb_fea.txt');
    sb_cpe4r_fea = load('sb_cpe4r_designed_fea.txt');
    LW = 2; FSLABEL = 12; FSLEGEND = 12;

    % Plot 1: Reaction Force vs Displacement
    figure(1)
    % plot(-sb_fea(:,1), sb_fea(:,3), 'b-', -sb_fea(:,1), sb_fea(:,4), 'r-', 'LineWidth', LW);
    plot(-sb_fea(:,1), sb_fea(:,2), 'b-', -sb_fea(:,1), sb_fea(:,3), 'r-', -sb_cpe4r_fea(:,1), sb_cpe4r_fea(:,2), 'b--', -sb_cpe4r_fea(:,1), sb_cpe4r_fea(:,3), 'r--', 'LineWidth', LW);
    xlabel('Displacement (mm)', 'FontSize', FSLABEL);
    ylabel('Force (N)', 'FontSize', FSLABEL);
    lgd = legend('RF1-B21H', 'RF2-B21H','RF1-CPE4R','RF2-CPE4R', 'Location', 'best');
    set(lgd, 'FontSize', FSLEGEND);
    % axis([0 inf 0 0.1]);
    grid on;

    % Plot 2: Max Stress vs Displacement
    figure(2)
    % plot(-sb_fea(:,1), abs(sb_fea(:,5)), 'k-', 'LineWidth', LW);
    plot(-sb_fea(:,1), abs(sb_fea(:,4)), 'k-', -sb_cpe4r_fea(:,1), abs(sb_cpe4r_fea(:,4)), 'k--', 'LineWidth', LW);
    lgd = legend('S-B21H', 'S-CPE4R', 'Location', 'best');
    set(lgd, 'FontSize', FSLEGEND);
    xlabel('Displacement (mm)', 'FontSize', FSLABEL);
    ylabel('Maximum Stress (MPa)', 'FontSize', FSLABEL);
    grid on;

    % Plot 3: Strain Energy vs Displacement
    figure(3)
    % plot(-sb_fea(:,1), sb_fea(:,10), 'g-', 'LineWidth', LW);
    plot(-sb_fea(:,1), sb_fea(:,9), 'g-', -sb_cpe4r_fea(:,1), sb_cpe4r_fea(:,9), 'g--','LineWidth', LW);
    lgd = legend('ENERGY-B21H', 'ENERGY-CPE4R', 'Location', 'best');
    set(lgd, 'FontSize', FSLEGEND);
    xlabel('Displacement (mm)', 'FontSize', FSLABEL);
    ylabel('Strain Energy (N.mm)', 'FontSize', FSLABEL);
    grid on;

    fprintf('Extraction complete. Plots generated.\n');

    % ========================================
    % ----- Delete Abaqus redudant files -----
    % ========================================
    delete_abaqus_redundant_files();
end

function lines = read_data_sb(filename)
    fprintf('Reading file %s. \n', filename);
    % Read sb.dat
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open %s file.', filename);
    end

    lines = {};
    tline = fgetl(fid);
    while ischar(tline)
        lines{end+1} = tline; %#ok<AGROW>
        tline = fgetl(fid);
    end
    fclose(fid);
end

function lines_cpe4r = read_data_sb_cpe4r(filename)
    fprintf('Reading file %s. \n', filename);    
    % Read sb_cpe4r.dat
    fid_cpe4r = fopen(filename, 'r');
    if fid_cpe4r == -1
        error('Cannot open %s file.', filename);
    end

    lines_cpe4r = {};
    tline_cpe4r = fgetl(fid_cpe4r);
    while ischar(tline_cpe4r)
        lines_cpe4r{end+1} = tline_cpe4r; %#ok<AGROW>
        tline_cpe4r = fgetl(fid_cpe4r);
    end
    fclose(fid_cpe4r);
end

function extract_data_beam_elements(lines, filename)
    fprintf('Extracting data to file %s. \n', filename);
    % Extract for beam elements
    fidw = fopen(filename, 'w');
    i = 1;
    while i <= length(lines)
        line = strtrim(lines{i});
        if contains(line, 'ELSET_BEAM')
            s11_out = NaN; allse = NaN;
            rf1 = NaN; rf2 = NaN;
            input_u2 = NaN; 
            % monitor_rf2 = NaN;
            upper_coor1_max = NaN; upper_coor2_max = NaN;
            upper_u1_max = NaN; upper_u2_max = NaN;

            while i <= length(lines)
                if contains(lines{i}, 'MAXIMUM')
                    tokens = strsplit(strtrim(lines{i}));
                    if numel(tokens) >= 2
                        s11_out = str2double(tokens{2});
                    end
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

            while i <= length(lines)
                if contains(lines{i}, 'NSET_ANCHOR')
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

            while i <= length(lines)
                if contains(lines{i}, 'NSET_MONITOR')
                    i = i + 5;
                    if i > length(lines), break; end
                    tokens = strsplit(strtrim(lines{i}));
                    if numel(tokens) >= 6
                        input_u2 = str2double(tokens{3});
                        % monitor_rf2 = str2double(tokens{6});
                    end
                    break;
                end
                i = i + 1;
            end

            % while i <= length(lines)
            %     if contains(lines{i}, 'NSET_UPPER')
            %         while i <= length(lines)
            %             if contains(lines{i}, 'MAXIMUM')
            %                 tokens = strsplit(strtrim(lines{i}));
            %                 if numel(tokens) >= 5
            %                     upper_coor1_max = str2double(tokens{2});
            %                     upper_coor2_max = str2double(tokens{3});
            %                     upper_u1_max = str2double(tokens{4});
            %                     upper_u2_max = str2double(tokens{5});
            %                 end
            %                 break;
            %             end
            %             i = i + 1;
            %         end
            %         break;
            %     end
            %     i = i + 1;
            % end

            fprintf(fidw, '%f %f %f %f %f %f %f %f %f\n', ...
                input_u2, rf1, rf2, s11_out, ...
                upper_coor1_max, upper_coor2_max, upper_u1_max, upper_u2_max, allse);
        end
        i = i + 1;
    end
    fclose(fidw);
end

function extract_data_CPE4R_elements(lines_cpe4r, filename)
    fprintf('Extracting data to file %s. \n', filename);
    % Extract for CPE4R elements
    fidw_cpe4r = fopen(filename, 'w');
    i = 1;
    while i <= length(lines_cpe4r)
        line = strtrim(lines_cpe4r{i});
        if contains(line, 'ELSET_BEAM')
            s11_out = NaN; allse = NaN;
            rf1 = NaN; rf2 = NaN;
            input_u2 = NaN;
            % monitor_rf2 = NaN;
            upper_coor1_max = NaN; upper_coor2_max = NaN;
            upper_u1_max = NaN; upper_u2_max = NaN;

            while i <= length(lines_cpe4r)
                if contains(lines_cpe4r{i}, 'MAXIMUM')
                    tokens = strsplit(strtrim(lines_cpe4r{i}));
                    if numel(tokens) >= 2
                        s11_out = str2double(tokens{2});
                    end
                    i = i + 3;
                    tokens = strsplit(strtrim(lines_cpe4r{i}));
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

            while i <= length(lines_cpe4r)
                if contains(lines_cpe4r{i}, 'RECOVERABLE')
                    tokens = strsplit(strtrim(lines_cpe4r{i}));
                    if numel(tokens) >= 4
                        allse = str2double(tokens{4});
                    end
                    break;
                end
                i = i + 1;
            end

            while i <= length(lines_cpe4r)
                if contains(lines_cpe4r{i}, 'NSET_END')
                    % Find the TOTAL line
                    while i <= length(lines_cpe4r)
                        if contains(lines_cpe4r{i}, 'TOTAL')
                            tokens = regexp(lines_cpe4r{i}, 'TOTAL\s+([\d\.E+-]+)\s+([\d\.E+-]+)', 'tokens');
                            rf1 = str2double(tokens{1}{1});
                            rf2 = str2double(tokens{1}{2});
                            break;
                        end
                        i = i + 1;
                    end
                    break;
                end
                i = i + 1;
            end

            while i <= length(lines_cpe4r)
                if contains(lines_cpe4r{i}, 'NSET_MONITOR')
                    i = i + 5;
                    if i > length(lines_cpe4r), break; end
                    tokens = strsplit(strtrim(lines_cpe4r{i}));
                    if numel(tokens) >= 5
                        input_u2 = str2double(tokens{3});
                        % monitor_rf2 = str2double(tokens{6});
                    end
                    break;
                end
                i = i + 1;
            end

            % while i <= length(lines_cpe4r)
            %     if contains(lines_cpe4r{i}, 'NSET_UPPER')
            %         while i <= length(lines_cpe4r)
            %             if contains(lines_cpe4r{i}, 'MAXIMUM')
            %                 tokens = strsplit(strtrim(lines_cpe4r{i}));
            %                 if numel(tokens) >= 5
            %                     upper_coor1_max = str2double(tokens{2});
            %                     upper_coor2_max = str2double(tokens{3});
            %                     upper_u1_max = str2double(tokens{4});
            %                     upper_u2_max = str2double(tokens{5});
            %                 end
            %                 break;
            %             end
            %             i = i + 1;
            %         end
            %         break;
            %     end
            %     i = i + 1;
            % end

            fprintf(fidw_cpe4r, '%f %f %f %f %f %f %f %f %f\n', ...
                input_u2, -rf1, -rf2, s11_out, ...
                upper_coor1_max, upper_coor2_max, upper_u1_max, upper_u2_max, allse);
        end
        i = i + 1;
    end
    fclose(fidw_cpe4r);
end

function delete_abaqus_redundant_files()
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