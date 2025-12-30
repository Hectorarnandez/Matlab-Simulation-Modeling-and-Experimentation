%% Monte Carlo Simulation Setup for SerDes Channel Loss 

% --- 1. Define Monte Carlo Parameters ---
numSims = 50; % Number of Monte Carlo runs/scenarios
modelName = 'PCIe6_SerDes_Model'; % 

% Channel Loss Variation Parameters
mu_Loss = 26; % Mean channel loss in dB
std_Loss = 1; % Standard Deviation in dB
min_Loss = 24;
max_Loss = 28;

% --- 2. Generate Random Input Values (Normal Distribution) ---
random_Loss_values = normrnd(mu_Loss, std_Loss, numSims, 1);
% Truncate/Clamp the values to stay within the desired range [24 dB, 28 dB]
random_Loss_values = max(min_Loss, min(max_Loss, random_Loss_values));

fprintf('Generated %d random channel loss values (Range: %.2f dB to %.2f dB).\n', ...
    numSims, min(random_Loss_values), max(random_Loss_values));

% --- 3. Create Simulation Input Objects and Set Parameters ---
in(1:numSims) = Simulink.SimulationInput(modelName);


block_path = 'PCIe6_SerDes_Model/Analog Channel'; 

for i = 1:numSims
    current_loss = random_Loss_values(i);
    
    % This is the correct way to set the block parameter for parsim
    in(i) = in(i).setBlockParameter(block_path, 'Loss', num2str(current_loss));
end 


% --- 4. Run Parallel Simulations using parsim ---
if isempty(gcp('nocreate'))
    parpool;
end

disp('Starting parallel simulation runs...');

% Use SetupFcn to load gpz_full ONLY on the parallel workers.
out = parsim(in, ...
    'ShowProgress', 'on', ...
    'SetupFcn', @()evalin('base', 'load_gpz')); % Assumes you created load_gpz.m

disp('All simulations complete.');

% --- 5. Process and Analyze Results ---

eyeHeights = zeros(numSims, 1);
failureCount = 0;

for i = 1:numSims
    if ~isempty(out(i).ErrorMessage)
        eyeHeights(i) = NaN;
        failureCount = failureCount + 1;
    else
        % *** Step 1: Find the signal (returns a Dataset) ***
        logData = out(i).logsout.find('Name', 'FinalEyeHeight');
        
        if logData.numElements > 0 % Check if the signal was found
             
             % *** Step 2: Extract the actual signal element (CORRECTED LINE) ***
             signal_element = logData.getElement(1);
             
             % *** Step 3: Access the data within the signal element ***
             % The .Values property exists on the Signal Element, not the Dataset.
             eyeHeights(i) = signal_element.Values.Data(end);
             
        else
             fprintf('Run %d completed, but Eye Height data was not found.\n', i);
             eyeHeights(i) = NaN;
             failureCount = failureCount + 1;
        end
    end
end

% Statistical Analysis
valid_runs = ~isnan(eyeHeights);
eyeHeights_valid = eyeHeights(valid_runs);

fprintf('\n--- Monte Carlo Results ---\n');
fprintf('Total Simulations: %d\n', numSims);
fprintf('Failed Simulations: %d\n', failureCount);
fprintf('Valid Runs: %d\n', length(eyeHeights_valid));

if length(eyeHeights_valid) > 0
    fprintf('Mean Eye Height: %.3f\n', mean(eyeHeights_valid));
    fprintf('Min Eye Height (Worst Case): %.3f\n', min(eyeHeights_valid));
    fprintf('Std. Dev. of Eye Height: %.3f\n', std(eyeHeights_valid));

    % Plot the distribution
    figure;
    histogram(eyeHeights_valid);
    title('Monte Carlo Distribution of Eye Height (Channel Loss Variation)');
    xlabel('Eye Height (V)');
    ylabel('Frequency');
    grid on;
end