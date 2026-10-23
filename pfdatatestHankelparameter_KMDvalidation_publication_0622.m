clc;
clear;
close all;

%% Representative KMD validation near damping-threshold boundaries
% This script extends pfdatatestHankelparameter_threshold1208.m.
% It produces:
%   1) normalized representative trajectories;
%   2) continuous-time Koopman eigenvalue spectra;
%   3) the critical oscillatory eigenvalue pair;
%   4) oscillation frequency, damping ratio, threshold, and label;
%   5) an editable CSV/XLSX summary table and publication-quality figures.

dataFile = fullfile(fileparts(mfilename('fullpath')), ...
    'simulation_data_14_493_breaker_1003_2.mat');
outputDir = fullfile(fileparts(mfilename('fullpath')), ...
    'KMD_representative_validation_publication_0622');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Representative cases ordered from unstable to sufficiently damped.
sampleIndex = [703, 4571, 6756];%图1
% sampleIndex =[4571 9402	6756];%图2
beta = [0, 0, 0.01];
caseType = ["Oscillatory unstable", ...
    "Poorly damped stable", "Sufficiently damped stable"];

% Hankel-DMD settings used in the original study. 
observationWindow = 50;
samplingInterval = 0.05;
truncationRank = 25;
hankelDelays = 60;

fprintf('Loading simulation data from:\n%s\n', dataFile);
load(dataFile, 'Saveopt', 'time_set1', 'delta_set1', 'omega_set1', 'nsw');

parameters = Saveopt.Gen_P([2, 3], :)';
nCases = numel(sampleIndex);

results = struct([]);

fig = figure('Name', 'Representative KMD Validation - Publication', ...
    'Color', 'w', 'Units', 'pixels', 'Position', [80, 40, 1800, 1350]);
layout = tiledlayout(fig, nCases, 2, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

% Publication-oriented graphics defaults.
axisFontSize = 15;
labelFontSize = 16;
titleFontSize = 17;
annotationFontSize = 13;
trajectoryLineWidth = 1.15;
axisLineWidth = 1.15;
modeMarkerSize = 55;
criticalMarkerSize = 150;

for k = 1:nCases
    step = sampleIndex(k);
    fprintf('Processing representative sample %d (%d/%d)...\n', ...
        step, k, nCases);

    t = time_set1{step};
    if isempty(t)
        error('Sample %d has an empty time vector.', step);
    end
    if max(t) < observationWindow
        error('Sample %d is shorter than the specified %.1f-s window.', ...
            step, observationWindow);
    end

    [timeSelected, Xnormalized, eigContinuous, frequencies, ...
        dampingRatios, criticalIndex, reconstructionError] = ...
        hankelKMDRepresentative( ...
        t, observationWindow, delta_set1, omega_set1, step, nsw, ...
        truncationRank, hankelDelays, samplingInterval);

    criticalEig = eigContinuous(criticalIndex);
    criticalFrequency = frequencies(criticalIndex);
    criticalDamping = dampingRatios(criticalIndex);
    dampingLabel = double(criticalDamping >= beta(k));

    results(k).SampleIndex = step;
    results(k).PG6 = parameters(step, 1);
    results(k).PG8 = parameters(step, 2);
    results(k).Beta = beta(k);
    results(k).CriticalRealPart = real(criticalEig);
    results(k).CriticalImaginaryPart = imag(criticalEig);
    results(k).FrequencyHz = criticalFrequency;
    results(k).DampingRatio = criticalDamping;
    results(k).DampingLabel = dampingLabel;
    results(k).CaseType = caseType(k);
    results(k).RelativeReconstructionError = reconstructionError;

    %% Left column: normalized post-disturbance trajectory
    axTrajectory = nexttile(layout);
    nSignals = size(Xnormalized, 1);
    colors = lines(nSignals);
    hold(axTrajectory, 'on');
    for signalIndex = 1:nSignals
        plot(axTrajectory, timeSelected, Xnormalized(signalIndex, :), ...
            'LineWidth', trajectoryLineWidth, ...
            'Color', colors(signalIndex, :));
    end
    grid(axTrajectory, 'on');
    box(axTrajectory, 'on');
    xlim(axTrajectory, [0, observationWindow]);
    ylim(axTrajectory, [-1, 1]);
    xlabel(axTrajectory, 'Time (s)', ...
        'FontName', 'Times New Roman', 'FontSize', labelFontSize);
    ylabel(axTrajectory, 'Normalized amplitude', ...
        'FontName', 'Times New Roman', 'FontSize', labelFontSize);
    title(axTrajectory, sprintf('(%c) %s', char('a' + 2*(k-1)), caseType(k)), ...
        'FontName', 'Times New Roman', 'FontSize', titleFontSize, ...
        'FontWeight', 'bold');
    set(axTrajectory, 'FontName', 'Times New Roman', ...
        'FontSize', axisFontSize, 'LineWidth', axisLineWidth, ...
        'TickDir', 'out', 'Layer', 'top');
    axTrajectory.GridAlpha = 0.18;
    axTrajectory.MinorGridAlpha = 0.08;

    %% Right column: continuous-time Koopman eigenvalue spectrum
    axSpectrum = nexttile(layout);
    oscillatory = abs(imag(eigContinuous)) > 1e-6;
    scatter(axSpectrum, real(eigContinuous(~oscillatory)), ...
        imag(eigContinuous(~oscillatory)), modeMarkerSize, [0.55, 0.55, 0.55], ...
        'filled', 'DisplayName', 'Real modes');
    hold(axSpectrum, 'on');
    scatter(axSpectrum, real(eigContinuous(oscillatory)), ...
        imag(eigContinuous(oscillatory)), modeMarkerSize, [0.10, 0.42, 0.72], ...
        'filled', 'DisplayName', 'Oscillatory modes');
    scatter(axSpectrum, real(criticalEig), imag(criticalEig), criticalMarkerSize, ...
        [0.85, 0.20, 0.15], 'pentagram', 'filled', ...
        'MarkerEdgeColor', [0.55, 0.05, 0.05], ...
        'LineWidth', 1.0, 'DisplayName', 'Critical mode');
    scatter(axSpectrum, real(criticalEig), -imag(criticalEig), criticalMarkerSize, ...
        [0.85, 0.20, 0.15], 'pentagram', 'filled', ...
        'MarkerEdgeColor', [0.55, 0.05, 0.05], 'LineWidth', 1.0, ...
        'HandleVisibility', 'off');
    xline(axSpectrum, 0, '--', 'Color', [0.15, 0.15, 0.15], ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');
    grid(axSpectrum, 'on');
    box(axSpectrum, 'on');
    xlabel(axSpectrum, 'Real part, \sigma (s^{-1})', ...
        'FontName', 'Times New Roman', 'FontSize', labelFontSize);
    ylabel(axSpectrum, 'Imaginary part, \omega (rad/s)', ...
        'FontName', 'Times New Roman', 'FontSize', labelFontSize);
    title(axSpectrum, sprintf('(%c) Continuous-time KMD spectrum', ...
        char('b' + 2*(k-1))), ...
        'FontName', 'Times New Roman', 'FontSize', titleFontSize, ...
        'FontWeight', 'bold');
    set(axSpectrum, 'FontName', 'Times New Roman', ...
        'FontSize', axisFontSize, 'LineWidth', axisLineWidth, ...
        'TickDir', 'out', 'Layer', 'top');
    axSpectrum.GridAlpha = 0.18;

    % Keep modest margins around all modes while ensuring that the
    % stability boundary and critical mode remain visible.
    realValues = real(eigContinuous);
    imagValues = imag(eigContinuous);
    xMargin = max(0.05, 0.08 * range(realValues));
    yMargin = max(1, 0.08 * range(imagValues));
    xlim(axSpectrum, [min(realValues)-xMargin, ...
        max(max(realValues)+xMargin, 0.08)]);
    ylim(axSpectrum, [min(imagValues)-yMargin, ...
        max(imagValues)+yMargin]);

    infoText = sprintf(['P_{G2} = %.3f p.u.   P_{G6} = %.3f p.u.\\newline' ...
        'f = %.3f Hz   \\zeta = %.5f   label = %d'], ...
        parameters(step, 1), parameters(step, 2), ...
        criticalFrequency, criticalDamping, dampingLabel);
    text(axSpectrum, 0.03, 0.05, infoText, ...
        'Units', 'normalized', 'FontName', 'Times New Roman', ...
        'FontSize', annotationFontSize, 'VerticalAlignment', 'bottom', ...
        'BackgroundColor', [1, 1, 1], 'EdgeColor', [0.65, 0.65, 0.65]);

    % Show the legend only once to reduce visual repetition.
    if k == 1
        legend(axSpectrum, 'Location', 'northwest', ...
            'FontName', 'Times New Roman', ...
            'FontSize', annotationFontSize, 'Box', 'on');
    end
end

figureBase = fullfile(outputDir, ...
    'Representative_Stable_Unstable_KMD_Validation_Publication');
savefig(gcf, [figureBase, '.fig']);
exportgraphics(gcf, [figureBase, '.png'], 'Resolution', 600);
exportgraphics(gcf, [figureBase, '.pdf'], 'ContentType', 'vector');
print(gcf, [figureBase, '.eps'], '-depsc', '-r600');

%% Export the compact result table
resultTable = struct2table(results);
writetable(resultTable, fullfile(outputDir, ...
    'Representative_KMD_Results.csv'));
writetable(resultTable, fullfile(outputDir, ...
    'Representative_KMD_Results.xlsx'));
save(fullfile(outputDir, 'Representative_KMD_Results.mat'), ...
    'results', 'resultTable', 'sampleIndex', 'beta', ...
    'observationWindow', 'samplingInterval', ...
    'truncationRank', 'hankelDelays');

disp(resultTable);
fprintf('All representative KMD validation results were saved to:\n%s\n', ...
    outputDir);


function [timeSelected, Xnormalized, eigContinuous, frequencies, ...
    dampingRatios, criticalIndex, relativeError] = ...
    hankelKMDRepresentative(t, observationWindow, deltaSet, omegaSet, ...
    sampleIndex, referenceMachine, rankValue, delays, dt)

    selected = find(0.02 < t & t <= observationWindow);
    timeSelected = t(selected);

    deltaRaw = deltaSet{sampleIndex};
    omegaRaw = omegaSet{sampleIndex};

    % Use relative rotor angles and rotor-speed deviations as observables.
    omegaRelative = omegaRaw - omegaRaw(referenceMachine, :);
    deltaRelative = deltaRaw - deltaRaw(:, 1);
    omegaDeviation = omegaRelative - omegaRelative(:, 1);

    deltaWindow = deltaRelative(:, selected);
    omegaWindow = omegaDeviation(:, selected);

    deltaScale = max(abs(deltaWindow), [], 'all');
    omegaScale = max(abs(omegaWindow), [], 'all');
    if deltaScale == 0
        deltaScale = 1;
    end
    if omegaScale == 0
        omegaScale = 1;
    end

    deltaNormalized = deltaWindow / deltaScale;
    omegaNormalized = omegaWindow / omegaScale;

    % Remove the reference-machine channel.
    Xnormalized = [deltaNormalized(2:end, :); ...
        omegaNormalized(2:end, :)];

    [Xh, Yh] = constructHankel(Xnormalized, delays);
    [U, S, V] = svd(Xh, 'econ');

    retainedRank = min([rankValue, size(U, 2), size(V, 2)]);
    Ur = U(:, 1:retainedRank);
    Sr = S(1:retainedRank, 1:retainedRank);
    Vr = V(:, 1:retainedRank);

    Atilde = Ur' * Yh * Vr / Sr;
    [W, D] = eig(Atilde);
    eigDiscrete = diag(D);
    eigContinuous = log(eigDiscrete) / dt;

    sigma = real(eigContinuous);
    omega = imag(eigContinuous);
    naturalFrequency = sqrt(sigma.^2 + omega.^2);
    dampingRatios = -sigma ./ naturalFrequency;
    frequencies = abs(omega) / (2 * pi);

    % Select one member of each oscillatory conjugate pair. The critical
    % mode is the selected oscillatory mode with the minimum damping ratio.
    candidate = find(omega > 1e-6 & isfinite(dampingRatios));
    if isempty(candidate)
        error('No complex-conjugate oscillatory mode was identified.');
    end
    [~, localIndex] = min(dampingRatios(candidate));
    criticalIndex = candidate(localIndex);

    % Reconstruction error is included as a numerical quality indicator.
    Phi = Yh * Vr / Sr * W;
    b = pinv(Phi) * Xh(:, 1);
    nSnapshots = size(Xh, 2);
    Vandermonde = zeros(retainedRank, nSnapshots);
    for column = 1:nSnapshots
        Vandermonde(:, column) = eigDiscrete .^ (column - 1);
    end
    reconstructedHankel = Phi * diag(b) * Vandermonde;
    reconstructed = real(reconstructedHankel(1:size(Xnormalized, 1), :));
    original = Xnormalized(:, 1:nSnapshots);
    relativeError = norm(original - reconstructed, 'fro') / ...
        norm(original, 'fro');
end


function [Xh, Yh] = constructHankel(X, delays)
    [~, nSamples] = size(X);
    nColumns = nSamples - delays;
    if nColumns <= 0
        error('The observation window is too short for the selected delays.');
    end

    Xh = [];
    Yh = [];
    for delay = 1:delays
        Xh = [Xh; X(:, delay:nColumns + delay - 1)]; %#ok<AGROW>
        Yh = [Yh; X(:, delay + 1:nColumns + delay)]; %#ok<AGROW>
    end
end
