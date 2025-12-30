% Uncertainty Quantification for PCIe 6.0 
% Quantities of interest: Eye Height (EH) and Eye Width (EW)
% Uncertainty sources: measured EH/EW for Upper, Center, Lower
% Propagation method: Monte Carlo

clear; clc; close all;

% PCIe 6.0 spec limits (UI at 64 GT/s = 15.625 ps)
UI = 15.625e-12;
spec.eyeHeight_min = 0.07;         % 70 mV minimum
spec.eyeWidth_min  = 0.25 * UI;    % 25% UI = 3.90625 ps

% Measured Data Columns correspond to: P0, P3, P5, P7, P9

EH_upper  = [4.96E-09, 0.0076, 0.017, 0.0126, 0.0123];
EH_center = [0.0024,   0.0076, 0.017, 0.0126, 0.0123];
EH_lower  = [4.96E-09, 0.0076, 0.017, 0.0126, 0.0123];

EW_upper  = [4.33E-05, 5.7576, 8.0801, 7.3097, 6.4982];
EW_center = [3.74,     6.2834, 8.4076, 7.5679, 6.6693];
EW_lower  = [4.33E-05, 5.7576, 8.0801, 7.3097, 6.4982];

preset_names = {'P0', 'P3', 'P5', 'P7', 'P9'};

% Monte Carlo settings
N = 1e5;  % number of trials

% For each preset, combine Upper, Center, Lower eye heights and widths,
% then sample N times *per preset* for a detailed preset-wise analysis.

EH_pass_prob = zeros(1,5);
EW_pass_prob = zeros(1,5);
EH_CI = zeros(2,5);
EW_CI = zeros(2,5);

figure('Name','Eye Height Distributions');
tiledlayout(2,3,'TileSpacing','Compact','Padding','Compact');
title('Monte Carlo Distributions for Eye Height');

for i = 1:5
    % Combine Upper, Center, Lower for EH and EW for this preset
    EH_data = [EH_upper(i), EH_center(i), EH_lower(i)];
    EW_data = [EW_upper(i), EW_center(i), EW_lower(i)];
    
    % Generate N samples by random sampling (with replacement)
    EH_samples = randsample(EH_data, N, true);
    EW_samples = randsample(EW_data, N, true);
    
    % Calculate pass probability
    EH_pass_prob(i) = mean(EH_samples >= spec.eyeHeight_min);
    EW_pass_prob(i) = mean(EW_samples >= spec.eyeWidth_min);
    
    % Calculate 95% confidence intervals
    EH_CI(:,i) = prctile(EH_samples, [2.5 97.5]);
    EW_CI(:,i) = prctile(EW_samples, [2.5 97.5]);
    
    % Plot EH histogram
    nexttile;
    histogram(EH_samples, 50, 'Normalization', 'pdf');
    title(sprintf('EH %s', preset_names{i}));
    xlabel('Eye Height (V)');
    ylabel('PDF');
    grid on;
end

figure('Name','Eye Width Distributions');
tiledlayout(2,3,'TileSpacing','Compact','Padding','Compact');
title('Monte Carlo Distributions for Eye Width');

for i = 1:5
    EW_data = [EW_upper(i), EW_center(i), EW_lower(i)];
    EW_samples = randsample(EW_data, N, true);
    
    % Plot EW histogram
    nexttile;
    histogram(EW_samples, 50, 'Normalization', 'pdf');
    title(sprintf('EW %s', preset_names{i}));
    xlabel('Eye Width (s)');
    ylabel('PDF');
    grid on;
end

% Identify worst-case preset (lowest pass probability)
[worst_EH_prob, worst_EH_idx] = min(EH_pass_prob);
[worst_EW_prob, worst_EW_idx] = min(EW_pass_prob);

fprintf('===== Monte Carlo UQ Results =====\n');
fprintf('PCIe 6.0 Eye Height spec: >= %.3f V\n', spec.eyeHeight_min);
fprintf('PCIe 6.0 Eye Width  spec: >= %.3e s\n\n', spec.eyeWidth_min);

for i = 1:5
    fprintf('Preset %s:\n', preset_names{i});
    fprintf('  Eye Height pass probability: %.4f\n', EH_pass_prob(i));
    fprintf('  Eye Height 95%% CI: [%.4f, %.4f]\n', EH_CI(1,i), EH_CI(2,i));
    fprintf('  Eye Width  pass probability: %.4f\n', EW_pass_prob(i));
    fprintf('  Eye Width  95%% CI: [%.3e, %.3e] s\n\n', EW_CI(1,i), EW_CI(2,i));
end

fprintf('Worst-case Eye Height preset: %s (pass prob = %.4f)\n', preset_names{worst_EH_idx}, worst_EH_prob);
fprintf('Worst-case Eye Width  preset: %s (pass prob = %.4f)\n', preset_names{worst_EW_idx}, worst_EW_prob);

% Correlation between EH and EW (using combined samples across all presets)
EH_all_samples = [];
EW_all_samples = [];
for i = 1:5
    EH_data = [EH_upper(i), EH_center(i), EH_lower(i)];
    EW_data = [EW_upper(i), EW_center(i), EW_lower(i)];
    EH_all_samples = [EH_all_samples, randsample(EH_data, N, true)];
    EW_all_samples = [EW_all_samples, randsample(EW_data, N, true)];
end

% Calculate Pearson correlation coefficient
corr_coeff = corr(EH_all_samples', EW_all_samples');

fprintf('\nCorrelation coefficient between Eye Height and Eye Width samples: %.4f\n', corr_coeff);