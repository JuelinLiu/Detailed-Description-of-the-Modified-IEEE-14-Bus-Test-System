clc;
clear;
close all;

%% ML-based DSR construction and test-set assessment
% This script separates two different meanings of accuracy:
%   1) Learning accuracy: ML prediction vs. corrected KMD-derived labels.
%   2) Benchmark accuracy: ML prediction vs. independent TDS benchmark labels.
%
% The ML comparison is used to verify that corrected labels can be learned
% and to select a representative DSR model, not to establish a universal
% ranking of machine-learning algorithms.

fprintf('---- ML-based DSR construction and test-set assessment ----\n');

baseDir = fileparts(mfilename('fullpath'));
dataDir = baseDir;
projectRoot = fileparts(fileparts(baseDir));
outputDir = fullfile(projectRoot, 'PES-LETTER', 'ML_DSR_test_assessment_0625');
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
testRatio = 0.20;
rng(20250625, 'twister');

benchmarkData = load(fullfile(dataDir, benchmarkFile));
parameters = benchmarkData.parameters;
benchmarkLabels = benchmarkData.index0(:);
benchmarkValid = benchmarkLabels == 0 | benchmarkLabels == 1;

nCases = size(cases, 1);
models = cell(nCases, 1);
gridProbabilities = cell(nCases, 1);
testMasks = cell(nCases, 1);
predictionSets = cell(nCases, 1);
correctedLabelSets = cell(nCases, 1);

Condition = strings(nCases, 1);
ObservationWindow_s = zeros(nCases, 1);
NoiseLevel_percent = zeros(nCases, 1);
TrainingSamples = zeros(nCases, 1);
TestSamples = zeros(nCases, 1);
CorrectedSamples = zeros(nCases, 1);
LearningAccuracy_percent = zeros(nCases, 1);
BenchmarkAccuracy_percent = zeros(nCases, 1);
BenchmarkUnsafeRecall_percent = zeros(nCases, 1);
BenchmarkFalseSecure = zeros(nCases, 1);
BenchmarkFalseUnsafe = zeros(nCases, 1);
InferenceTimePerSample_ms = zeros(nCases, 1);

xLimits = paddedLimits(parameters(:, 1), 0.02);
yLimits = paddedLimits(parameters(:, 2), 0.02);
[xx1, xx2] = meshgrid( ...
    linspace(xLimits(1), xLimits(2), 220), ...
    linspace(yLimits(1), yLimits(2), 220));
gridPoints = [xx1(:), xx2(:)];

for caseIndex = 1:nCases
    caseName = cases{caseIndex, 1};
    caseFile = cases{caseIndex, 4};
    caseData = load(fullfile(dataDir, caseFile));
    validateAlignment(parameters, caseData.parameters, benchmarkFile, caseFile);

    rawLabels = caseData.index(:);
    validMask = benchmarkValid & (rawLabels == 0 | rawLabels == 1);
    [correctedLabels, correctedMask, correctionInfo] = correctLabelsByKNNMajority( ...
        parameters, rawLabels, neighborFraction, majorityRatioThreshold);

    trainMask = false(size(validMask));
    testMask = false(size(validMask));
    validIndex = find(validMask);
    safeIndex = validIndex(correctedLabels(validIndex) == 1);
    unsafeIndex = validIndex(correctedLabels(validIndex) == 0);
    safeTest = sampleTestIndices(safeIndex, testRatio);
    unsafeTest = sampleTestIndices(unsafeIndex, testRatio);
    testMask([safeTest; unsafeTest]) = true;
    trainMask(validMask & ~testMask) = true;

    model = trainLightGBMOrFallback(parameters(trainMask, 1:2), correctedLabels(trainMask));

    tic;
    testPredicted = predictModelLabels(model, parameters(testMask, 1:2));
    inferenceTime = toc;

    gridProbability = predictModelSafeProbability(model, gridPoints);
    gridProbabilities{caseIndex} = reshape(gridProbability, size(xx1));
    models{caseIndex} = model;
    testMasks{caseIndex} = testMask;
    predictionSets{caseIndex} = testPredicted;
    correctedLabelSets{caseIndex} = correctedLabels;

    correctedTestLabels = correctedLabels(testMask);
    benchmarkTestLabels = benchmarkLabels(testMask);
    learningAccuracy = 100 * mean(testPredicted == correctedTestLabels);
    benchmarkMetrics = calculateBinaryMetrics(benchmarkTestLabels, testPredicted);

    Condition(caseIndex) = string(caseName);
    ObservationWindow_s(caseIndex) = cases{caseIndex, 2};
    NoiseLevel_percent(caseIndex) = cases{caseIndex, 3};
    TrainingSamples(caseIndex) = sum(trainMask);
    TestSamples(caseIndex) = sum(testMask);
    CorrectedSamples(caseIndex) = sum(correctedMask);
    LearningAccuracy_percent(caseIndex) = learningAccuracy;
    BenchmarkAccuracy_percent(caseIndex) = benchmarkMetrics.Accuracy_percent;
    BenchmarkUnsafeRecall_percent(caseIndex) = benchmarkMetrics.UnsafeRecall_percent;
    BenchmarkFalseSecure(caseIndex) = benchmarkMetrics.FalseSecure;
    BenchmarkFalseUnsafe(caseIndex) = benchmarkMetrics.FalseUnsafe;
    InferenceTimePerSample_ms(caseIndex) = 1000 * inferenceTime / sum(testMask);

    fprintf(['%s: K = %d, corrected = %d, learning acc = %.2f%%, ' ...
        'benchmark acc = %.2f%%, FS = %d, FU = %d.\n'], ...
        caseName, correctionInfo.K, CorrectedSamples(caseIndex), ...
        LearningAccuracy_percent(caseIndex), BenchmarkAccuracy_percent(caseIndex), ...
        BenchmarkFalseSecure(caseIndex), BenchmarkFalseUnsafe(caseIndex));
end

resultsTable = table( ...
    Condition, ObservationWindow_s, NoiseLevel_percent, ...
    TrainingSamples, TestSamples, CorrectedSamples, ...
    LearningAccuracy_percent, BenchmarkAccuracy_percent, ...
    BenchmarkUnsafeRecall_percent, BenchmarkFalseSecure, BenchmarkFalseUnsafe, ...
    InferenceTimePerSample_ms);

disp(resultsTable);
writetable(resultsTable, fullfile(outputDir, 'ML_DSR_test_assessment_metrics.csv'));
writetable(resultsTable, fullfile(outputDir, 'ML_DSR_test_assessment_metrics.xlsx'));
save(fullfile(outputDir, 'ML_DSR_test_assessment_results.mat'), ...
    'resultsTable', 'models', 'parameters', 'benchmarkLabels', ...
    'correctedLabelSets', ...
    'gridProbabilities', 'testMasks', 'predictionSets', ...
    'neighborFraction', 'majorityRatioThreshold', 'testRatio');

plotLearnedDSRBoundaries( ...
    parameters, benchmarkLabels, cases(:, 1), correctedLabelSets, ...
    testMasks, predictionSets, gridProbabilities, xx1, xx2, ...
    xLimits, yLimits, resultsTable, outputDir);

fprintf('Results exported to:\n%s\n', outputDir);

function testIndex = sampleTestIndices(indices, testRatio)
nTest = max(1, round(numel(indices) * testRatio));
order = randperm(numel(indices));
testIndex = indices(order(1:nTest));
end

function model = trainLightGBMOrFallback(X, y)
try
    X_py = py.numpy.array(X);
    y_py = py.numpy.array(y(:)');
    modelPy = py.lightgbm.LGBMClassifier(pyargs( ...
        'objective', 'binary', ...
        'n_estimators', int32(300), ...
        'learning_rate', 0.05, ...
        'num_leaves', int32(31), ...
        'verbose', int32(-1)));
    modelPy.fit(X_py, y_py);
    model = struct('Type', 'LightGBM', 'Model', modelPy);
catch ME
    warning('LightGBM unavailable (%s). Falling back to MATLAB bagged trees.', ME.message);
    treeTemplate = templateTree('MaxNumSplits', 30);
    modelMat = fitcensemble(X, y, ...
        'Method', 'Bag', ...
        'NumLearningCycles', 100, ...
        'Learners', treeTemplate);
    model = struct('Type', 'BaggedTrees', 'Model', modelMat);
end
end

function labels = predictModelLabels(model, X)
if strcmp(model.Type, 'LightGBM')
    predPy = model.Model.predict(py.numpy.array(X));
    labels = double(predPy);
    labels = labels(:);
else
    labels = predict(model.Model, X);
    labels = labels(:);
end
end

function probability = predictModelSafeProbability(model, X)
if strcmp(model.Type, 'LightGBM')
    probPy = model.Model.predict_proba(py.numpy.array(X));
    prob = double(probPy);
    probability = prob(:, 2);
else
    [~, score] = predict(model.Model, X);
    classNames = model.Model.ClassNames;
    safeColumn = find(classNames == 1, 1);
    probability = score(:, safeColumn);
end
probability = probability(:);
end

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

localMislabeled = oppositeRatio > majorityRatioThreshold & ...
    numOppositeLabel > numSameLabel;

newLabels = mode(neighborLabels(localMislabeled, :), 2);
validLabelsAfter = validLabels;
validLabelsAfter(localMislabeled) = newLabels;
labelsAfter(validIndex) = validLabelsAfter;

isMislabeled = false(size(labelsAfter));
isMislabeled(validIndex(localMislabeled)) = true;
info = struct('K', K);
end

function metrics = calculateBinaryMetrics(referenceLabels, predictedLabels)
correctUnsafe = referenceLabels == 0 & predictedLabels == 0;
correctSafe = referenceLabels == 1 & predictedLabels == 1;
falseSecure = referenceLabels == 0 & predictedLabels == 1;
falseUnsafe = referenceLabels == 1 & predictedLabels == 0;
nUnsafe = sum(referenceLabels == 0);
metrics.Accuracy_percent = 100 * mean(referenceLabels == predictedLabels);
metrics.UnsafeRecall_percent = 100 * sum(correctUnsafe) / nUnsafe;
metrics.FalseSecure = sum(falseSecure);
metrics.FalseUnsafe = sum(falseUnsafe);
metrics.CorrectSafe = sum(correctSafe);
metrics.CorrectUnsafe = sum(correctUnsafe);
end

function plotLearnedDSRBoundaries( ...
        parameters, benchmarkLabels, caseNames, correctedLabelSets, ...
        testMasks, predictionSets, gridProbabilities, xx1, xx2, ...
        xLimits, yLimits, resultsTable, outputDir)
safeRegionColor = [0.72, 0.86, 0.95];
unsafeRegionColor = [0.86, 0.86, 0.82];
boundaryColor = [0.00, 0.00, 0.00];

fig = figure('Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [80, 50, 1120, 880], ...
    'PaperPositionMode', 'auto', ...
    'Renderer', 'painters');
tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
legendHandles = gobjects(3, 1);
panelLabels = {'(a)', '(b)', '(c)', '(d)'};

for caseIndex = 1:numel(caseNames)
    ax = nexttile;
    hold(ax, 'on');

    learnedSafeRegion = gridProbabilities{caseIndex} >= 0.5;
    contourf(ax, xx1, xx2, double(learnedSafeRegion), ...
        [-0.5, 0.5, 1.5], 'LineStyle', 'none');
    colormap(ax, [unsafeRegionColor; safeRegionColor]);

    contour(ax, xx1, xx2, gridProbabilities{caseIndex}, [0.5, 0.5], ...
        'Color', boundaryColor, 'LineWidth', 2.0);
    contour(ax, xx1, xx2, gridProbabilities{caseIndex}, [0.4, 0.6], ...
        'Color', [0.35, 0.35, 0.35], 'LineStyle', '--', 'LineWidth', 0.8);

    hUnsafeRegion = patch(ax, nan, nan, unsafeRegionColor, ...
        'EdgeColor', 'none');
    hSafeRegion = patch(ax, nan, nan, safeRegionColor, ...
        'EdgeColor', 'none');
    hBoundary = plot(ax, nan, nan, '-', 'Color', boundaryColor, 'LineWidth', 2.0);

    title(ax, sprintf('%s %s', panelLabels{caseIndex}, caseNames{caseIndex}), ...
        'FontName', 'Times New Roman', 'FontSize', 12, ...
        'FontWeight', 'bold', 'Interpreter', 'tex');
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
        'Label acc.: %.2f%%\\newlineBenchmark acc.: %.2f%%\\newlineFalse-secure: %d', ...
        resultsTable.LearningAccuracy_percent(caseIndex), ...
        resultsTable.BenchmarkAccuracy_percent(caseIndex), ...
        resultsTable.BenchmarkFalseSecure(caseIndex));
    text(ax, 0.98, 0.97, summaryText, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 9.3, ...
        'BackgroundColor', 'white', ...
        'EdgeColor', [0.40, 0.40, 0.40], ...
        'Margin', 5);
    hold(ax, 'off');

    if caseIndex == 1
        legendHandles = [hSafeRegion; hUnsafeRegion; hBoundary];
    end
end

lgd = legend(legendHandles, ...
    {'Learned DSR (secure region)', ...
     'Predicted insecure region', ...
     'Learned DSR boundary'}, ...
    'Orientation', 'horizontal', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 10.5, ...
    'Box', 'off');
lgd.Layout.Tile = 'south';

baseName = fullfile(outputDir, 'ML_DSR_learned_regions_with_benchmark_metrics');
savefig(fig, [baseName, '.fig']);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperSize', [10.8, 8.5]);
set(fig, 'PaperPosition', [0, 0, 10.8, 8.5]);
print(fig, [baseName, '.png'], '-dpng', '-r600');
print(fig, [baseName, '.pdf'], '-dpdf', '-painters');
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

function validateAlignment(referenceParameters, caseParameters, referenceFile, caseFile)
if ~isequal(size(referenceParameters), size(caseParameters)) || ...
        max(abs(referenceParameters(:) - caseParameters(:))) > 1e-12
    error('Operating points in %s and %s are not aligned.', ...
        referenceFile, caseFile);
end
end
