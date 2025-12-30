%% --- PCIe Gen6 CTLE Modeling
% Based on the PCIe Gen6 Base Specification and the proposed 3-stage design
% from the paper (Equations 4, 5, and 7-9).

% Adc defined as a range from -5 to -15dB in steps of 1dB for 64.0 GT/s Rx Equalization.
DCgain = 5:15; 
ADC = 10.^(-DCgain/20); % Convert gain in dB to linear voltage ratio

% Pole and Zero Frequencies (Hz) as defined in the specification
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

% Frequency vector for simulation
f = linspace(0, 50e9, 501); % Up to 50 GHz (Nyquist frequency is 32 GHz)
w = 2*pi*f;
s = 1j*w;

%% 2. 3-Stage CTLE Calculation (H(s) = rho * G1 * G2 * G3)

% Scaling Factor (rho, denoted as 'sigma' in the paper, Equation 5 [cite: 112])
% sigma = (wp1*wp3*wp4*wp5*wp6) / (wz1*wz3)
rho = (wp1 * wp3 * wp4 * wp5 * wp6) / (wz1 * wz3);

H_3stage = zeros(length(ADC), length(f));
z2 = zeros(length(ADC), 1); % Pre-allocate for the ADC-dependent zero z2

for ii = 1:length(ADC)
    % The DC gain (ADC(ii)) sets the second zero location: wz2 = wp2 * ADC(ii)
    wz2 = wp2 * ADC(ii);
    z2(ii) = wz2 / (2*pi);
    z2_transpose = z2.'; % This is needed for the nnstart app to make the surrogate model 

    % G1(s): Low-Frequency/LFEQ Stage (Equation 7 [cite: 119])
    % G1(s) = (s + wz1) / [(s + wp1)(s + wp6)]
    G1 = (s + wz1) ./ ((s + wp1) .* (s + wp6));

    % G2(s): Mid-Frequency Stage (Equation 8 [cite: 120])
    % G2(s) = (s + wp2*ADC) / [(s + wp2)(s + wp4)]
    G2 = (s + wz2) ./ ((s + wp2) .* (s + wp4));

    % G3(s): High-Frequency Stage (Equation 9 [cite: 121])
    % G3(s) = (s + wz3) / [(s + wp3)(s + wp5)]
    G3 = (s + wz3) ./ ((s + wp3) .* (s + wp5));

    % Overall CTLE Transfer Function (Equation 6 )
    H_3stage(ii,:) = rho .* G1 .* G2 .* G3;
end

%% 3. Define gpz Matrix for Simulation Tools

% Define gpz matrix [G, P1, Z1, P2, Z2, P3, Z3, P4, P5, P6]: (Adjusted columns for 6 poles/3 zeros)
% NOTE: The gpz structure in your original script only had 8 columns (P1-P4 + G, Z1, Z2),
%       which might be tool-specific. This definition assumes a full 6-pole, 3-zero structure.
gpz_full = zeros(length(ADC), 10);
gpz_full(:,1) = -DCgain;  % G (DC Gain in dB)
gpz_full(:,2) = -p1;      % P1
gpz_full(:,3) = -z1;      % Z1
gpz_full(:,4) = -p2;      % P2
gpz_full(:,5) = -z2;      % Z2
gpz_full(:,6) = -p3;      % P3
gpz_full(:,7) = -z3;      % Z3
gpz_full(:,8) = -p4;      % P4
gpz_full(:,9) = -p5;      % P5
gpz_full(:,10) = -p6;     % P6

%% 4. Export CTLE Response to CSV
% This section was created in case it was necessary to add the CTLE tap 
% values using a CSV. This is not needed because the table can be directly 
% imported from the Variables section.

% idx = 1; % Choose one CTLE curve to export (e.g., the 5 dB setting)
% freq = f(:);
% dbCol = 20*log10(abs(H_3stage(idx,:))).'; % Calculate dB magnitude
% phaseDeg = rad2deg(unwrap(angle(H_3stage(idx,:)))).'; % Calculate phase in degrees
% 
% % Create table
% T = table(freq, dbCol, phaseDeg);
% T.Properties.VariableNames = {'freq', 'db', 'phaseDeg'};
% 
% % Path to save CSV (Adjust this path for your system)
% % exportPath = 'C:\Users\aylin\Desktop\Masters in Systems Engineering\Master Courses\Semester 4\MECH 513 - Simulation Modeling and Experimentation\Final Project\Scripts';
% fullFile = fullfile(exportPath, 'CTLE_Gen6_3Stage_Response.csv');
% 
% % Write file
% writetable(T, fullFile); 
% 
% disp(['Exported CTLE response (', num2str(DCgain(idx)), ' dB setting) to: ', fullFile])


%% 5. Plots
figure(1)
ax1(1) = subplot(211);
semilogx(f, 20*log10(abs(H_3stage)))
grid on
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('3-Stage CTLE Model (LFEQ+CTLE) for PCIe 6.0 (Gain Range: -5 dB to -15 dB)')

ax1(2) = subplot(212);
semilogx(f, rad2deg(unwrap(angle(H_3stage))))
grid on
xlabel('Frequency (Hz)')
ylabel('Phase (Degrees)')

linkaxes(ax1, 'x')
xlim([1e8, f(end)]) % Set frequency limits to start above 0 Hz