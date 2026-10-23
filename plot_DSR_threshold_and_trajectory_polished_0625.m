clc;
clear;
close all;

%% Polished figures for DSRs under different damping requirements
% This script keeps the logic of:
%   1) testforknnlightGBthreshold.m
%   2) pfdatatestHankelparameter_threshold1208.m
% and only unifies paths, KNN correction parameters, and figure style.

dataDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(dataDir));
outputDir = fullfile(projectRoot, 'PES-LETTER', 'DSR_threshold_polished_0625');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

betaValues = [0, 0.005, 0.01];
betaLabels = {'\beta = 0', '\beta = 0.005', '\beta = 0.01'};
filePaths = {'parameter_3_15_0.mat', 'parameter_3_15_0.005.mat', 'parameter_3_15_0.01.mat'};

neighborFraction = 0.0075;
rho = 0.60;

%% Fig. 1: DSR boundaries under different damping thresholds
fprintf('---- Plotting DSR boundaries under different damping thresholds ----\n');

load(fullfile(dataDir, filePaths{1}), 'parameters');
[xx1, xx2] = meshgrid(linspace(0, 1.4, 180), linspace(0, 1.0, 180));
XGrid = [xx1(:), xx2(:)];
XGridPy = py.numpy.array(XGrid);

lineStyles = {'-', '--', ':'};
lineColors = [0.08 0.08 0.08; 0.86 0.22 0.20; 0.16 0.28 0.85];
markerStyles = {'p', 's', 'o'};
markerFaceColors = [1.00 0.86 0.10; 0.10 0.78 0.82; 0.85 0.10 0.80];

fig1 = figure('Color', 'w', 'Units', 'pixels', 'Position', [120, 100, 820, 560]);
ax = axes(fig1);
hold(ax, 'on');

selectedPointIndex = zeros(numel(filePaths), 1);
secureCounts = zeros(numel(filePaths), 1);
correctedCounts = zeros(numel(filePaths), 1);

for i = 1:numel(filePaths)
    fprintf('Processing %s\n', filePaths{i});
    load(fullfile(dataDir, filePaths{i}), 'parameters', 'index');

    [correctedIndex, isMislabeled, K] = correctLabelsByKNN(parameters, index, neighborFraction, rho);
    correctedCounts(i) = sum(isMislabeled);
    secureCounts(i) = sum(correctedIndex == 1);

    XPy = py.numpy.array(parameters);
    yBinary = double(correctedIndex(:) == 1);
    yPy = py.numpy.asarray(yBinary).ravel();

    model = py.lightgbm.LGBMClassifier(pyargs( ...
        'objective', 'binary', ...
        'n_estimators', int32(500), ...
        'learning_rate', 0.04, ...
        'num_leaves', int32(31), ...
        'verbose', int32(-1)));
    model.fit(XPy, yPy);

    probGrid = double(model.predict_proba(XGridPy));
    predictedGrid = reshape(probGrid(:, 2), size(xx1));

    contour(ax, xx1, xx2, predictedGrid, [0.5 0.5], ...
        'LineStyle', lineStyles{i}, ...
        'Color', lineColors(i, :), ...
        'LineWidth', 2.4, ...
        'DisplayName', betaLabels{i});

    probOriginal = double(model.predict_proba(py.numpy.array(parameters)));
    stableIndices = find(correctedIndex == 1);
    [~, localIndex] = min(abs(probOriginal(stableIndices, 2) - 0.5));
    selectedPointIndex(i) = stableIndices(localIndex);
    selectedPoint = parameters(selectedPointIndex(i), :);

    plot(ax, selectedPoint(1), selectedPoint(2), markerStyles{i}, ...
        'MarkerSize', 9.0, ...
        'MarkerFaceColor', markerFaceColors(i, :), ...
        'MarkerEdgeColor', [0.05 0.05 0.05], ...
        'LineWidth', 1.2, ...
        'DisplayName', [betaLabels{i}, ' boundary point']);

    fprintf('%s: K = %d, corrected = %d, secure samples = %d, marked sample = %d.\n', ...
        betaLabels{i}, K, correctedCounts(i), secureCounts(i), selectedPointIndex(i));
end

xlabel(ax, 'GenP1 (p.u.)', 'FontName', 'Times New Roman', 'FontSize', 11);
ylabel(ax, 'GenP2 (p.u.)', 'FontName', 'Times New Roman', 'FontSize', 11);
xlim(ax, [0, 1.4]);
ylim(ax, [0, 1.0]);
grid(ax, 'on');
box(ax, 'on');
set(ax, 'FontName', 'Times New Roman', ...
    'FontSize', 10.5, ...
    'LineWidth', 1.0, ...
    'TickDir', 'out', ...
    'Layer', 'top');

legend(ax, 'Location', 'northeast', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 8.5, ...
    'Box', 'on', ...
    'NumColumns', 2, ...
    'Interpreter', 'tex');

title(ax, 'DSR boundaries under different damping requirements', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 11.5, ...
    'FontWeight', 'bold');

summaryTable = table(betaValues(:), secureCounts, correctedCounts, selectedPointIndex, ...
    'VariableNames', {'Beta', 'SecureSamplesAfterCorrection', 'CorrectedSamples', 'MarkedSampleIndex'});
writetable(summaryTable, fullfile(outputDir, 'DSR_threshold_boundary_summary.csv'));
writetable(summaryTable, fullfile(outputDir, 'DSR_threshold_boundary_summary.xlsx'));

savePublicationFigure(fig1, fullfile(outputDir, 'Fig_DSR_threshold_boundaries_polished'), [7.2, 4.8]);

%% Fig. 2: Dynamic trajectories of representative points near each boundary
fprintf('---- Plotting representative dynamic trajectories ----\n');

load(fullfile(dataDir, 'simulation_data_14_493_breaker_1003_2.mat'), ...
    'time_set1', 'delta_set1', 'omega_set1', 'nsw');

representativeSamples = [703, 4571, 6756];
trajectoryColors = [0.08 0.30 0.52; 0.75 0.18 0.16; 0.15 0.25 0.78];

fig2 = figure('Color', 'w', 'Units', 'pixels', 'Position', [120, 80, 900, 700]);
tiledlayout(fig2, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:numel(representativeSamples)
    sample = representativeSamples(i);
    t1 = time_set1{sample};

    tdmd = 50;
    rset = 25;
    Ded = 60;
    [~, ~, testIndex, ~, ~, X, ~, ~, dampingRatios] = Hankel( ...
        t1, tdmd, delta_set1, omega_set1, sample, nsw, rset, Ded);

    time = t1(testIndex);
    rmsEnvelope = sqrt(mean(X.^2, 1));
    rmsEnvelope = rmsEnvelope ./ max(rmsEnvelope);

    ax = nexttile;
    hold(ax, 'on');
    plot(ax, time, X', 'Color', [0.74 0.78 0.82], 'LineWidth', 0.38);
    plot(ax, time, rmsEnvelope, 'Color', trajectoryColors(i, :), 'LineWidth', 2.1);
    yline(ax, 0, 'Color', [0.35 0.35 0.35], 'LineWidth', 0.65);
    hold(ax, 'off');

    title(ax, sprintf('(%c) Representative point near %s boundary', char('a' + i - 1), betaLabels{i}), ...
        'FontName', 'Times New Roman', ...
        'FontSize', 10.5, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'tex');
    ylabel(ax, 'Amplitude', 'FontName', 'Times New Roman', 'FontSize', 10.5);
    if i == numel(representativeSamples)
        xlabel(ax, 'Time (s)', 'FontName', 'Times New Roman', 'FontSize', 10.5);
    end
    xlim(ax, [0, min(50, max(time))]);
    ylim(ax, [-1.05, 1.05]);
    grid(ax, 'on');
    box(ax, 'on');
    set(ax, 'FontName', 'Times New Roman', ...
        'FontSize', 9.8, ...
        'LineWidth', 1.0, ...
        'TickDir', 'out', ...
        'Layer', 'top');

    text(ax, 0.985, 0.86, sprintf('Sample %d\\newline%s', sample, betaLabels{i}), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 8.8, ...
        'BackgroundColor', 'white', ...
        'EdgeColor', [0.55 0.55 0.55], ...
        'Margin', 5, ...
        'Interpreter', 'tex');
end

legend({'Hankel-DMD observables', 'RMS envelope'}, ...
    'Orientation', 'horizontal', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 9.0, ...
    'Box', 'off', ...
    'Location', 'southoutside');

savePublicationFigure(fig2, fullfile(outputDir, 'Fig_threshold_boundary_trajectories_polished'), [7.2, 6.7]);

fprintf('All outputs saved to:\n%s\n', outputDir);

%% Local functions
function [correctedIndex, isMislabeled, K] = correctLabelsByKNN(parameters, index, neighborFraction, rho)
N = size(parameters, 1);
K = max(1, round(N * neighborFraction));
correctedIndex = index(:);

[nearestNeighbors, ~] = knnsearch(parameters, parameters, 'K', K + 1);
nearestNeighbors = nearestNeighbors(:, 2:end);
neighborLabels = correctedIndex(nearestNeighbors);
currentLabels = correctedIndex;

isSame = (neighborLabels == currentLabels);
numOpposite = sum(~isSame, 2);
numSame = sum(isSame, 2);
oppositeRatio = numOpposite ./ (numOpposite + numSame);
oppositeRatio(isnan(oppositeRatio)) = 0;

isMislabeled = (oppositeRatio > rho) & (numOpposite > numSame);
newLabels = mode(neighborLabels(isMislabeled, :), 2);
correctedIndex(isMislabeled) = newLabels;
end

function savePublicationFigure(fig, baseName, paperSize)
savefig(fig, [baseName, '.fig']);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', paperSize);
set(fig, 'PaperPosition', [0, 0, paperSize]);
print(fig, [baseName, '.png'], '-dpng', '-r600');
print(fig, [baseName, '.pdf'], '-dpdf', '-painters');
print(fig, [baseName, '.eps'], '-depsc', '-painters');
end

function [absb, abse, test_td, delta_ori, X0, X, X_dmd_approx, modal_energy, damping_ratios] = ...
        Hankel(t1, tdmd, delta_set1, omega_set1, step, nsw, rset, Ded)
test_td = find(0.02 < t1 & t1 <= tdmd);
delta_ori0 = delta_set1{step};
omega_ori0 = omega_set1{step};
omega_ori0 = omega_ori0 - omega_ori0(nsw, :);
delta_ori = delta_ori0 - delta_ori0(:, 1);
omega_ori = omega_ori0 - omega_ori0(:, 1);
delta = delta_ori(:, test_td) ./ max(max(abs(delta_ori(:, test_td))));
omega = omega_ori(:, test_td) ./ max(max(abs(omega_ori(:, test_td))));

X0 = [delta_ori0(2:end, :); omega_ori0(2:end, :)];
X1 = [delta(2:end, :); omega(2:end, :)];
X = X1;
n_ori = size(X, 1);

[X_h, Y_h] = construct_hankel(X, Ded);
[U, S, V] = svd(X_h, 'econ');
U_r = U(:, 1:rset);
S_r = S(1:rset, 1:rset);
V_r = V(:, 1:rset);

A_tilde = U_r' * Y_h * V_r / S_r;
[W, D] = eig(A_tilde);
eigvals = diag(D);
eigvals_t = log(eigvals) / 0.05;
sigma = real(eigvals_t);
omegaEig = imag(eigvals_t);
wn = sqrt(sigma.^2 + omegaEig.^2);
damping_ratios = -sigma ./ wn;

abse = abs(eigvals);
Phi = Y_h * V_r / S_r * W;
b = pinv(Phi) * X_h(:, 1);
absb = abs(b);

N = size(X_h, 2);
zdmd = diag(D);
Vand = zeros(rset, N);
for i = 1:N
    Vand(:, i) = zdmd.^(i - 1);
end
X_dmd_hankel = Phi * diag(b) * Vand;
X_dmd_approx = real(X_dmd_hankel(1:size(X, 1), :));

modal_energy = zeros(rset, 1);
for i = 1:rset
    time_response = b(i) * (zdmd(i).^(0:N-1));
    mode_i_full = Phi(:, i) * time_response;
    modal_energy(i) = norm(mode_i_full, 'fro')^2;
end
end

function [X_hankel, Y_hankel] = construct_hankel(X, delays)
[~, m] = size(X);
N = m - delays;
X_hankel = [];
Y_hankel = [];
for i = 1:delays
    X_hankel = [X_hankel; X(:, i:N+i-1)]; %#ok<AGROW>
    Y_hankel = [Y_hankel; X(:, i+1:N+i)]; %#ok<AGROW>
end
end
