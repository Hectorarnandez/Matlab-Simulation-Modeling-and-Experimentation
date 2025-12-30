%% --- CTLE Response Plotting using NN Surrogate Model ---

% --- 1. Load Surrogate Model and Parameters ---

% Load the trained network object (assuming it was saved as 'net')
load('results.mat', 'results');

net = results.Network;
% Load the normalization factors and the original fixed parameters
load('CTLE_Surrogate_Dataset.mat', 'normalization_factors');

% Extract the min and max z2 values for denormalization
z2_min = normalization_factors(1);
z2_max = normalization_factors(2);

% --- 2. Define Fixed CTLE Parameters (Poles and Zeros from original script) ---
z1 = 250e6;
wz1 = 2*pi*z1;
p1 = 1.30 * z1;
wp1 = 2*pi*p1;
p2 = 7.7e9;
wp2 = 2*pi*p2;
p3 = 22.0e9;
wp3 = 2*pi*p3;
p4 = 28.0e9;
wp4 = 2*pi*p4;
p5 = 32.0e9;
wp5 = 2*pi*p5;
p6 = 32.0e9;
wp6 = 2*pi*p6;
z3 = 7.7e9;
wz3 = 2*pi*z3;

% Frequency vector for simulation (same as original script)
f = linspace(0, 50e9, 501); 
w = 2*pi*f;
s = 1j*w;

% Scaling Factor (rho, Equation 5)
rho = (wp1 * wp3 * wp4 * wp5 * wp6) / (wz1 * wz3);

disp('Loaded Network and Fixed CTLE Parameters.')
disp('--------------------------------------')


% --- 3. Generate NN Predictions for the Full DC Gain Range ---

% Define the range of DC Gain values to test (e.g., 11 discrete steps)
test_DCgain_dB = (5:1:15).'; % Make it a column vector [11x1]

% Use the NN to predict the normalized z2 for the entire range
z2_predicted_norm = net(test_DCgain_dB.'); % Pass the transpose of the input for efficiency

% Denormalize the predicted z2 values back to Hertz
z2_predicted_Hz = z2_predicted_norm * (z2_max - z2_min) + z2_min;

disp(['Predicted z2 range from NN: ' num2str(min(z2_predicted_Hz), '%e') ' to ' num2str(max(z2_predicted_Hz), '%e') ' Hz.'])
disp('--------------------------------------')


% --- 4. Calculate the Full 3-Stage H(s) using Predicted z2 ---

H_NN_Surrogate = zeros(length(test_DCgain_dB), length(f));

for ii = 1:length(test_DCgain_dB)
    
    current_wz2 = 2 * pi * z2_predicted_Hz(ii); % Use the NN-predicted zero
    
    % G1(s): Low-Frequency/LFEQ Stage (Equation 7)
    G1 = (s + wz1) ./ ((s + wp1) .* (s + wp6));
    
    % G2(s): Mid-Frequency Stage (Equation 8), using predicted wz2
    G2 = (s + current_wz2) ./ ((s + wp2) .* (s + wp4));
    
    % G3(s): High-Frequency Stage (Equation 9)
    G3 = (s + wz3) ./ ((s + wp3) .* (s + wp5));
    
    % Overall CTLE Transfer Function
    H_NN_Surrogate(ii,:) = rho .* G1 .* G2 .* G3;
end

disp('CTLE transfer functions calculated using NN surrogate output.')
disp('--------------------------------------')


% --- 5. Plots (Magnitude and Phase) ---

%% 5. Plots

% figure(2) % Use figure(2) to avoid overwriting figure(1) if you run the original script
% ax2(1) = subplot(211);
% semilogx(f, 20*log10(abs(H_NN_Surrogate)))
% grid on
% xlabel('Frequency (Hz)')
% ylabel('Magnitude (dB)')
% title(['3-Stage CTLE Model (LFEQ+CTLE) using NN Surrogate (Range: ', num2str(min(test_DCgain_dB)), ' dB to ', num2str(max(test_DCgain_dB)), ' dB)'])
% 
% ax2(2) = subplot(212);
% semilogx(f, rad2deg(unwrap(angle(H_NN_Surrogate))))
% grid on
% xlabel('Frequency (Hz)')
% ylabel('Phase (Degrees)')
% linkaxes(ax2, 'x')
% xlim([1e8, f(end)]) % Set frequency limits to start above 0 Hz
% 
% disp('Plots generated successfully.')

figure(1)

% --- Subplot 1: Original Analytical Model (Magnitude) ---
ax1(1) = subplot(4,1,1);
semilogx(f, 20*log10(abs(H_3stage)))
grid on
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('3-Stage CTLE Model (LFEQ+CTLE) for PCIe 6.0 (Analytical Model)')

% --- Subplot 2: NN Surrogate Model (Magnitude) ---
ax1(2) = subplot(4,1,2);
semilogx(f, 20*log10(abs(H_NN_Surrogate)))
grid on
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title(['CTLE Model Using NN Surrogate (DC Gain Range: ', ...
    num2str(min(test_DCgain_dB)), ' dB to ', num2str(max(test_DCgain_dB)), ' dB)'])

% --- Subplot 3: Analytical Model (Phase) ---
ax2(1) = subplot(4,1,3);
semilogx(f, rad2deg(unwrap(angle(H_3stage))))
grid on
xlabel('Frequency (Hz)')
ylabel('Phase (Degrees)')

% --- Subplot 4: NN Surrogate Model (Phase) ---
ax2(2) = subplot(4,1,4);
semilogx(f, rad2deg(unwrap(angle(H_NN_Surrogate))))
grid on
xlabel('Frequency (Hz)')
ylabel('Phase (Degrees)')

% --- Link Magnitude Axes ---
linkaxes(ax1, 'x')

% --- Link Phase Axes ---
linkaxes(ax2, 'x')

% --- Set frequency limits ---
xlim([1e8, f(end)])   % Applies to the last active subplot

