clc;
clear;
close all;

%% 1. Define data files and plotting parameters
file_paths = {'parameter_3_15_0.mat', 'parameter_3_15_0.005.mat', 'parameter_3_15_0.01.mat'};

% Decision-boundary styles. Keep the original plotting logic and marker use.
line_styles = {'k-', 'r--', 'b:'};
line_widths = {3, 3, 3};
marker_styles = {'p', 's', 'o'};
marker_colors = {'y', 'c', 'm'};

% Output path for paper figures.
baseDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(baseDir));
exportPath = 'D:\1432879259\WPS云盘\日本留学期间的研究\PES-LETTER\正文图_按图号整理_0629';
if ~exist(exportPath, 'dir')
    mkdir(exportPath);
end

% Load the first data file to define the plotting grid.
load(file_paths{1});
[xx1, xx2] = meshgrid(linspace(min(parameters(:, 1)) - 0.1, max(parameters(:, 1)) + 0.1, 100), ...
                      linspace(min(parameters(:, 2)) - 0.1, max(parameters(:, 2)) + 0.1, 100));
XGrid = [xx1(:), xx2(:)];
XGrid_py = py.numpy.array(XGrid);

models = cell(1, length(file_paths));
corrected_indices = cell(1, length(file_paths));
selected_point_idx = zeros(1, length(file_paths));

%% 2. Plot multiple decision boundaries and mark representative boundary points
fprintf('---- Start plotting decision boundaries and boundary points ----\n');
figure('Name', 'Decision Boundaries Comparison', 'Color', 'w', 'Position', [100 100 1000 500]);
hold on;
dsr_colors = [0.74 0.86 1.00; 0.42 0.66 0.95; 0.12 0.34 0.78];

for i = 1:length(file_paths)
    fprintf('Processing file: %s\n', file_paths{i});

    % Load data.
    load(file_paths{i});

    %% KNN-based mislabeled-sample correction
    % Unified parameters used in the correction analysis:
    %   K = round(rN), r = 0.0075; rho = 0.60.
    r = 0.0075;
    rho = 0.60;
    majority_ratio_threshold = rho;
    N = size(parameters, 1);
    K = round(N * r);

    [nearest_neighbors_indices, ~] = knnsearch(parameters, parameters, 'K', K + 1);
    nearest_neighbors_indices = nearest_neighbors_indices(:, 2:end);
    neighbor_labels = index(nearest_neighbors_indices);
    current_labels = index;
    is_same = (neighbor_labels == current_labels);
    num_opposite_label = sum(is_same == 0, 2);
    num_same_label = sum(is_same, 2);
    opposite_ratio = num_opposite_label ./ (num_opposite_label + num_same_label);
    opposite_ratio(isnan(opposite_ratio)) = 0;
    is_mislabeled = (opposite_ratio > majority_ratio_threshold) & (num_opposite_label > num_same_label);
    new_labels = mode(neighbor_labels(is_mislabeled, :), 2);
    corrected_index = index;
    corrected_index(is_mislabeled) = new_labels;

    fprintf('KNN correction completed. K = %d, rho = %.2f, corrected samples = %d.\n', ...
        K, rho, sum(is_mislabeled));

    % Train LightGBM and calculate the decision boundary.
    X_py = py.numpy.array(parameters);
    y_binary = double(corrected_index(:) == 1);
    y_py = py.numpy.asarray(y_binary).ravel();
    model = py.lightgbm.LGBMClassifier(pyargs( ...
        'objective', 'binary', ...
        'n_estimators', int32(500), ...
        'verbose', int32(-1)));
    model.fit(X_py, y_py);
    models{i} = model;
    corrected_indices{i} = corrected_index;

    prob = double(model.predict_proba(XGrid_py));
    predicted_grid = reshape(prob(:, 2), size(xx1));

    % Fill the learned DSR region. The boundary and marker logic below is unchanged.
    dsr_mask = double(predicted_grid >= 0.5);
    fill_image = cat(3, ...
        dsr_colors(i, 1) * ones(size(dsr_mask)), ...
        dsr_colors(i, 2) * ones(size(dsr_mask)), ...
        dsr_colors(i, 3) * ones(size(dsr_mask)));
    h_fill = image([min(xx1(:)), max(xx1(:))], [min(xx2(:)), max(xx2(:))], fill_image, ...
        'AlphaData', 0.22 * dsr_mask, ...
        'HandleVisibility', 'off');
    set(gca, 'YDir', 'normal');
    uistack(h_fill, 'bottom');

    % Plot the decision boundary.
    contour(xx1, xx2, predicted_grid, [0.5 0.5], line_styles{i}, ...
        'LineWidth', line_widths{i}, ...
        'DisplayName', ['Decision Boundary ' num2str(i)]);

    % Get the predicted probability of the original samples.
    prob_original = double(model.predict_proba(py.numpy.array(parameters)));

    % Find stable samples and mark the one closest to the 0.5 boundary.
    stable_indices = find(corrected_index == 1);

    if isempty(stable_indices)
        fprintf('No stable sample was found in case %d.\n', i);
    else
        [~, closest_to_boundary_local_idx] = min(abs(prob_original(stable_indices, 2) - 0.5));
        selected_point_idx(i) = stable_indices(closest_to_boundary_local_idx);
        selected_point_coords = parameters(selected_point_idx(i), :);

        plot(selected_point_coords(1), selected_point_coords(2), marker_styles{i}, ...
            'MarkerSize', 15, ...
            'MarkerFaceColor', marker_colors{i}, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 2, ...
            'DisplayName', ['Marked Stable Point on Boundary ' num2str(i)]);

        fprintf('Case %d: marked stable boundary point index = %d.\n', i, selected_point_idx(i));
        fprintf('Coordinates: GenP1 = %.6f, GenP2 = %.6f.\n', ...
            selected_point_coords(1), selected_point_coords(2));
    end
end

%% 3. Add figure labels and export
xlabel('P_{G2} (p.u.)', 'FontName', 'Times New Roman', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
ylabel('P_{G6} (p.u.)', 'FontName', 'Times New Roman', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
xlim([0, 1.4]);
ylim([0, 1]);
legend('\beta = 0', '\beta = 0 boundary point', ...
       '\beta = 0.005', '\beta = 0.005 boundary point', ...
       '\beta = 0.01', '\beta = 0.01 boundary point', ...
       'FontSize', 10, 'Interpreter', 'tex');
ax = gca;
ax.FontSize = 12;
ax.FontWeight = 'bold';
grid on;
hold off;

safeTitle = 'Fig8_DSR_thresholds';
fullBasePath = fullfile(exportPath, safeTitle);
fprintf('Exporting figures at 600 DPI...\n');

savefig(gcf, [fullBasePath '.fig']);
exportgraphics(gcf, [fullBasePath '.jpg'], 'Resolution', 600);
exportgraphics(gcf, [fullBasePath '.png'], 'Resolution', 600);
exportgraphics(gcf, [fullBasePath '.pdf'], 'ContentType', 'vector');
print(gcf, [fullBasePath '.eps'], '-depsc', '-r600');

fprintf('---- Export completed ----\n');

