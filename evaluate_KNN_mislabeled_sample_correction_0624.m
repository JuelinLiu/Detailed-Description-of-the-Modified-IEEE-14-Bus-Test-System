clc;
clear;
close all;

%% KNN-based mislabeled-sample correction and corrected error map
% Class convention:
%   0 = damping requirement violated / outside DSR
%   1 = damping requirement satisfied / inside DSR

fprintf('---- 1. Start KNN mislabeled-sample correction ----\n');

baseDir = fileparts(mfilename('fullpath'));
outputDir = fullfile(baseDir, 'KNN_correction_support_0624');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

benchmarkFile = 'parameter_30_50.mat';
cases = {
    '50 s, noise-free', 50, 0,  'parameter_3_50_0.mat';
    '50 s, \eta = 50%', 50, 50, 'parameter_3_noise_0.5_50.mat';
    '15 s, noise-free', 15, 0,  'parameter_3_15_0.mat';
    '15 s, \eta = 50%', 15, 50, 'parameter_3_noise_0.5_15.mat'
};

neighborFraction = 0.0075;
majorityRatioThreshold = 0.60;

benchmarkData = loadRequiredMat(baseDir, benchmarkFile);
requireVariables(benchmarkData, {'parameters', 'index0'}, benchmarkFile);
parameters = benchmarkData.parameters;
benchmarkLabels = benchmarkData.index0(:);
benchmarkValid = benchmarkLabels == 0 | benchmarkLabels == 1;

nCases = size(cases, 1);
correctedLabels = cell(nCases, 1);
validMasks = cell(nCases, 1);

Condition = strings(nCases, 1);
ObservationWindow_s = zeros(nCases, 1);
NoiseLevel_percent = zeros(nCases, 1);
EvaluatedSamples = zeros(nCases, 1);
CorrectedSamples = zeros(nCases, 1);
StableToUnstable = zeros(nCases, 1);
UnstableToStable = zeros(nCases, 1);
CorrectionTime_s = zeros(nCases, 1);
AccuracyBefore_percent = zeros(nCases, 1);
AccuracyAfter_percent = zeros(nCases, 1);
UnsafeRecallBefore_percent = zeros(nCases, 1);
UnsafeRecallAfter_percent = zeros(nCases, 1);
FalseSecureBefore = zeros(nCases, 1);
FalseSecureAfter = zeros(nCases, 1);
FalseUnsafeBefore = zeros(nCases, 1);
FalseUnsafeAfter = zeros(nCases, 1);
FalseSecureBefore_percent = zeros(nCases, 1);
FalseSecureAfter_percent = zeros(nCases, 1);

for caseIndex = 1:nCases
    caseName = cases{caseIndex, 1};
    caseFile = cases{caseIndex, 4};
    caseData = loadRequiredMat(baseDir, caseFile);
    requireVariables(caseData, {'parameters', 'index'}, caseFile);
    validateAlignment(parameters, caseData.parameters, benchmarkFile, caseFile);

    rawLabels = caseData.index(:);
    validMask = rawLabels == 0 | rawLabels == 1;

    tic;
    [labelsAfter, isMislabeled, correctionInfo] = correctLabelsByKNNMajority( ...
        parameters, rawLabels, neighborFraction, majorityRatioThreshold);
    correctionTime = toc;

    beforeMetrics = calculateBenchmarkMetrics( ...
        benchmarkLabels, rawLabels, benchmarkValid & validMask);
    afterMetrics = calculateBenchmarkMetrics( ...
        benchmarkLabels, labelsAfter, benchmarkValid & validMask);

    correctedLabels{caseIndex} = labelsAfter;
    validMasks{caseIndex} = validMask;

    Condition(caseIndex) = string(caseName);
    ObservationWindow_s(caseIndex) = cases{caseIndex, 2};
    NoiseLevel_percent(caseIndex) = cases{caseIndex, 3};
    EvaluatedSamples(caseIndex) = sum(validMask);
    CorrectedSamples(caseIndex) = sum(isMislabeled);
    StableToUnstable(caseIndex) = ...
        sum(isMislabeled & rawLabels == 1 & labelsAfter == 0);
    UnstableToStable(caseIndex) = ...
        sum(isMislabeled & rawLabels == 0 & labelsAfter == 1);
    CorrectionTime_s(caseIndex) = correctionTime;
    AccuracyBefore_percent(caseIndex) = beforeMetrics.Accuracy_percent;
    AccuracyAfter_percent(caseIndex) = afterMetrics.Accuracy_percent;
    UnsafeRecallBefore_percent(caseIndex) = beforeMetrics.UnsafeRecall_percent;
    UnsafeRecallAfter_percent(caseIndex) = afterMetrics.UnsafeRecall_percent;
    FalseSecureBefore(caseIndex) = beforeMetrics.FalseSecure;
    FalseSecureAfter(caseIndex) = afterMetrics.FalseSecure;
    FalseUnsafeBefore(caseIndex) = beforeMetrics.FalseUnsafe;
    FalseUnsafeAfter(caseIndex) = afterMetrics.FalseUnsafe;
    FalseSecureBefore_percent(caseIndex) = beforeMetrics.FalseSecureRate_percent;
    FalseSecureAfter_percent(caseIndex) = afterMetrics.FalseSecureRate_percent;

    fprintf(['%s: K = %d, corrected %d points, ' ...
        'false-secure before/after = %d/%d.\n'], ...
        caseName, correctionInfo.K, CorrectedSamples(caseIndex), ...
        FalseSecureBefore(caseIndex), ...
        FalseSecureAfter(caseIndex));
end

resultsTable = table( ...
    Condition, ObservationWindow_s, NoiseLevel_percent, EvaluatedSamples, ...
    CorrectedSamples, StableToUnstable, UnstableToStable, CorrectionTime_s, ...
    AccuracyBefore_percent, AccuracyAfter_percent, ...
    UnsafeRecallBefore_percent, UnsafeRecallAfter_percent, ...
    FalseSecureBefore, FalseSecureAfter, ...
    FalseUnsafeBefore, FalseUnsafeAfter, ...
    FalseSecureBefore_percent, FalseSecureAfter_percent);

disp(resultsTable);
writetable(resultsTable, fullfile(outputDir, ...
    'KNN_correction_support_metrics.csv'));
writetable(resultsTable, fullfile(outputDir, ...
    'KNN_correction_support_metrics.xlsx'));
save(fullfile(outputDir, 'KNN_correction_support_results.mat'), ...
    'resultsTable', 'parameters', 'benchmarkLabels', 'correctedLabels', ...
    'validMasks', 'neighborFraction', 'majorityRatioThreshold');

removeOldFigures(outputDir);
plotCorrectedBenchmarkErrorMap( ...
    parameters, benchmarkLabels, benchmarkValid, correctedLabels, ...
    validMasks, resultsTable, cases(:, 1), outputDir);

fprintf('---- KNN correction finished. Results exported to: ----\n%s\n', outputDir);

function [labelsAfter, isMislabeled, info] = correctLabelsByKNNMajority( ...
        parameters, labelsBefore, neighborFraction, majorityRatioThreshold)
labelsAfter = labelsBefore(:);
validMask = labelsAfter == 0 | labelsAfter == 1;
validIndex = find(validMask);
validParameters = parameters(validMask, 1:2);
validLabels = labelsAfter(validMask);

nValid = numel(validIndex);
K = max(1, round(nValid * neighborFraction));

[nearestNeighbors, ~] = knnsearch(validParameters, validParameters, 'K', K + 1);
nearestNeighbors = nearestNeighbors(:, 2:end);

neighborLabels = validLabels(nearestNeighbors);
currentLabels = validLabels;
isSame = neighborLabels == currentLabels;
numOppositeLabel = sum(~isSame, 2);
numSameLabel = sum(isSame, 2);
oppositeRatio = numOppositeLabel ./ (numOppositeLabel + numSameLabel);
oppositeRatio(isnan(oppositeRatio)) = 0;

localMislabeled = ...
    oppositeRatio > majorityRatioThreshold & ...
    numOppositeLabel > numSameLabel;

newLabels = mode(neighborLabels(localMislabeled, :), 2);
validLabelsAfter = validLabels;
validLabelsAfter(localMislabeled) = newLabels;
labelsAfter(validIndex) = validLabelsAfter;

isMislabeled = false(size(labelsAfter));
isMislabeled(validIndex(localMislabeled)) = true;

info = struct( ...
    'K', K, ...
    'OppositeRatio', oppositeRatio, ...
    'NumOppositeLabel', numOppositeLabel, ...
    'NumSameLabel', numSameLabel);
end

function metrics = calculateBenchmarkMetrics(referenceLabels, predictedLabels, evaluationMask)
correctUnsafe = evaluationMask & referenceLabels == 0 & predictedLabels == 0;
correctSafe = evaluationMask & referenceLabels == 1 & predictedLabels == 1;
falseSecure = evaluationMask & referenceLabels == 0 & predictedLabels == 1;
falseUnsafe = evaluationMask & referenceLabels == 1 & predictedLabels == 0;

nEvaluated = sum(evaluationMask);
nUnsafe = sum(correctUnsafe) + sum(falseSecure);

metrics.Accuracy_percent = 100 * (sum(correctUnsafe) + sum(correctSafe)) / nEvaluated;
metrics.UnsafeRecall_percent = 100 * sum(correctUnsafe) / nUnsafe;
metrics.FalseSecure = sum(falseSecure);
metrics.FalseUnsafe = sum(falseUnsafe);
metrics.FalseSecureRate_percent = 100 * sum(falseSecure) / nUnsafe;
end

function plotCorrectedBenchmarkErrorMap( ...
        parameters, benchmarkLabels, benchmarkValid, correctedLabels, ...
        validMasks, resultsTable, caseNames, outputDir)
correctSafeColor = [0.66, 0.82, 0.92];
correctUnsafeColor = [0.76, 0.76, 0.72];
falseSecureColor = [0.70, 0.00, 0.08];
falseUnsafeColor = [0.95, 0.50, 0.02];

xLimits = paddedLimits(parameters(:, 1), 0.02);
yLimits = paddedLimits(parameters(:, 2), 0.02);

fig = figure( ...
    'Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [70, 50, 980, 760], ...
    'PaperPositionMode', 'auto', ...
    'Renderer', 'painters');

tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
legendHandles = gobjects(4, 1);
panelLabels = {'(a)', '(b)', '(c)', '(d)'};

for caseIndex = 1:numel(caseNames)
    ax = nexttile;
    evaluationMask = benchmarkValid & validMasks{caseIndex};
    h = drawBenchmarkErrorPanel( ...
        ax, parameters, benchmarkLabels, correctedLabels{caseIndex}, ...
        evaluationMask, xLimits, yLimits, correctSafeColor, ...
        correctUnsafeColor, falseSecureColor, falseUnsafeColor, ...
        sprintf('%s %s', panelLabels{caseIndex}, caseNames{caseIndex}), ...
        resultsTable.AccuracyAfter_percent(caseIndex), ...
        resultsTable.UnsafeRecallAfter_percent(caseIndex), ...
        resultsTable.FalseSecureAfter(caseIndex));
    if caseIndex == 1
        legendHandles = h;
    end
end

lgd = legend(legendHandles, ...
    {'Correct safe', 'Correct unsafe', ...
     'False-secure (unsafe classified as safe)', ...
     'False-unsafe (safe classified as unsafe)'}, ...
    'Orientation', 'horizontal', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 10.5, ...
    'Box', 'off');
lgd.Layout.Tile = 'south';

baseName = fullfile(outputDir, 'KNN_corrected_error_map');
savefig(fig, [baseName, '.fig']);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [9.8, 7.6]);
set(fig, 'PaperPosition', [0, 0, 9.8, 7.6]);
print(fig, [baseName, '.png'], '-dpng', '-r600');
print(fig, [baseName, '.pdf'], '-dpdf', '-painters');
end

function legendHandles = drawBenchmarkErrorPanel( ...
        ax, parameters, benchmarkLabels, predictedLabels, evaluationMask, ...
        xLimits, yLimits, correctSafeColor, correctUnsafeColor, ...
        falseSecureColor, falseUnsafeColor, panelTitle, accuracyPercent, ...
        unsafeRecallPercent, falseSecureCount)
correctSafe = evaluationMask & benchmarkLabels == 1 & predictedLabels == 1;
correctUnsafe = evaluationMask & benchmarkLabels == 0 & predictedLabels == 0;
falseSecure = evaluationMask & benchmarkLabels == 0 & predictedLabels == 1;
falseUnsafe = evaluationMask & benchmarkLabels == 1 & predictedLabels == 0;

hold(ax, 'on');
hCorrectSafe = scatter(ax, parameters(correctSafe, 1), parameters(correctSafe, 2), ...
    8, correctSafeColor, 'o', 'filled', 'MarkerEdgeColor', 'none');
hCorrectUnsafe = scatter(ax, parameters(correctUnsafe, 1), parameters(correctUnsafe, 2), ...
    8, correctUnsafeColor, 'o', 'filled', 'MarkerEdgeColor', 'none');
hFalseSecure = scatter(ax, parameters(falseSecure, 1), parameters(falseSecure, 2), ...
    34, falseSecureColor, 'd', 'filled', ...
    'MarkerEdgeColor', [0.35, 0.00, 0.03], 'LineWidth', 0.7);
hFalseUnsafe = scatter(ax, parameters(falseUnsafe, 1), parameters(falseUnsafe, 2), ...
    34, falseUnsafeColor, '^', 'filled', ...
    'MarkerEdgeColor', [0.38, 0.18, 0.00], 'LineWidth', 0.7);

title(ax, panelTitle, 'FontName', 'Times New Roman', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'tex');
xlabel(ax, '$P_{G6}$ (p.u.)', 'Interpreter', 'latex', ...
    'FontName', 'Times New Roman', 'FontSize', 12);
ylabel(ax, '$P_{G8}$ (p.u.)', 'Interpreter', 'latex', ...
    'FontName', 'Times New Roman', 'FontSize', 12);
xlim(ax, xLimits);
ylim(ax, yLimits);
grid(ax, 'on');
box(ax, 'on');
axis(ax, 'square');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, ...
    'LineWidth', 1.0, 'TickDir', 'out', 'Layer', 'top', ...
    'TickLabelInterpreter', 'tex');

summaryText = sprintf( ...
    'Accuracy: %.2f%%\\newlineUnsafe recall: %.2f%%\\newlineFalse-secure: %d', ...
    accuracyPercent, unsafeRecallPercent, falseSecureCount);
text(ax, 0.98, 0.97, summaryText, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 9.5, ...
    'BackgroundColor', 'white', ...
    'EdgeColor', [0.40, 0.40, 0.40], ...
    'Margin', 5);
hold(ax, 'off');

legendHandles = [hCorrectSafe; hCorrectUnsafe; hFalseSecure; hFalseUnsafe];
end

function limits = paddedLimits(values, paddingRatio)
valueMin = min(values);
valueMax = max(values);
padding = paddingRatio * (valueMax - valueMin);
if padding == 0
    padding = 0.01;
end
limits = [valueMin - padding, valueMax + padding];
end

function removeOldFigures(outputDir)
oldPatterns = {
    'KNN_corrected_error_map.*';
    'KNN_correction_summary_bar.*';
    'KNN_correction_summary*.*';
    'KNN_correction_label_boundary_comparison*.*';
    'KNN_correction_error_map_comparison*.*';
    'KNN_correction_distribution_*.*';
    'KNN_correction_changed_samples_distribution*.*'
};
for patternIndex = 1:numel(oldPatterns)
    oldFiles = dir(fullfile(outputDir, oldPatterns{patternIndex}));
    for fileIndex = 1:numel(oldFiles)
        delete(fullfile(oldFiles(fileIndex).folder, oldFiles(fileIndex).name));
    end
end
end

function data = loadRequiredMat(baseDir, fileName)
filePath = fullfile(baseDir, fileName);
if ~exist(filePath, 'file')
    error('Required file not found: %s', filePath);
end
data = load(filePath);
end

function requireVariables(data, requiredVariables, fileName)
for k = 1:numel(requiredVariables)
    if ~isfield(data, requiredVariables{k})
        error('File %s does not contain variable "%s".', ...
            fileName, requiredVariables{k});
    end
end
end

function validateAlignment(referenceParameters, caseParameters, referenceFile, caseFile)
if ~isequal(size(referenceParameters), size(caseParameters)) || ...
        max(abs(referenceParameters(:) - caseParameters(:))) > 1e-12
    error('Operating points in %s and %s are not aligned.', ...
        referenceFile, caseFile);
end
end
