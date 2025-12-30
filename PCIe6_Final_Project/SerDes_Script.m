% ------------------------------------
% MATLAB script to build SerDes System
% ------------------------------------

% Build cell array of Tx blocks:
txBlocks{1} = serdes.FFE;
txBlocks{1}.BlockName = 'FFE';
txBlocks{1}.Mode = 1;
txBlocks{1}.TapSpacing = 'T-spaced';
txBlocks{1}.TapWeights = [0.083 -0.208 0.709 0];
txBlocks{1}.Normalize = true;

% Build cell array of Rx blocks:
rxBlocks{1} = serdes.CTLE;
rxBlocks{1}.BlockName = 'CTLE';
rxBlocks{1}.Mode = 2;
rxBlocks{1}.Specification = 'GPZ Matrix';
rxBlocks{1}.SliceSelect = 0;
rxBlocks{1}.ConfigSelect = 0;
rxBlocks{1}.GPZ = [0 -23771428571 -10492857142 -13092857142;-1 -17603571428 -7914982142 -13344642857;-2 -17935714285 -6845464285 -13596428571;-3 -15321428571 -5574642857 -13848214285;-4 -15600000000 -4960100000 -14100000000;-5 -15878571428 -4435821428 -14351785714;-6 -16157142857 -3981285714 -14603571428;-7 -16435714285 -3581089285 -14855357142;-8 -16714285714 -3227142857 -15107142857];
rxBlocks{1}.PerformanceCriteria = 'SNR';
rxBlocks{1}.FilterMethod = 'Cascaded';
rxBlocks{1}.OutputOptMetric = true;
rxBlocks{2} = serdes.DFECDR;
rxBlocks{2}.BlockName = 'DFECDR';
rxBlocks{2}.Mode = 2;
rxBlocks{2}.TapWeights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
rxBlocks{2}.MinimumTap = [-0.4 -0.2 -0.125 -0.125 -0.125 -0.125 -0.04 -0.04 -0.04 -0.04 -0.04 -0.04 -0.04 -0.04 -0.04 -0.04];
rxBlocks{2}.MaximumTap = [0.4 0.2 0.125 0.125 0.125 0.125 0.04 0.04 0.04 0.04 0.04 0.04 0.04 0.04 0.04 0.04];
rxBlocks{2}.Taps2x = false;
rxBlocks{2}.PhaseDetector = 'BangBang';

% Build txModel:
txAnalogModel = AnalogModel( ...
	'R',50, ...
	'C',1.000000e-13);
tx = Transmitter( ...
	'Blocks',txBlocks, ...
	'AnalogModel',txAnalogModel, ...
	'RiseTime',7.500000e-12, ...
	'VoltageSwingIdeal',1, ...
	'Name','TX');

% Build rxModel:
rxAnalogModel = AnalogModel( ...
	'R',50, ...
	'C',2.000000e-13);
rx = Receiver( ...
	'Blocks',rxBlocks, ...
	'AnalogModel',rxAnalogModel, ...
	'Name','RX');

% Build ChannelData:
channel = ChannelData( ...
	'ChannelLossdB',24, ...
	'ChannelLossFreq',16000000000, ...
	'ChannelDifferentialImpedance',85);

% Build jitter parameters defined as Type UI:
Tx_DCD = SimpleJitter('Value',0.000000000006250,'Include',true,'Type','UI');
Tx_Rj = SimpleJitter('Value',0.000000000000433,'Include',true,'Type','UI');
Tx_Dj = SimpleJitter('Value',0.000000000002500,'Include',true,'Type','UI');

% Build Jitter And Noise Object:
jitter = JitterAndNoise( ...
	'Tx_DCD',Tx_DCD,...
	'Tx_Rj',Tx_Rj,...
	'Tx_Dj',Tx_Dj,...
	'RxClockMode','clocked');

% Build SerDes System:
SymbolTime = 3.125e-11;
SamplesPerSymbol = 16;
ModulationLevels = 4;
BERtarget = 1e-06;
sys = SerdesSystem(...
	'TxModel',tx,...
	'RxModel',rx,...
	'ChannelData',channel,...
	'JitterAndNoise',jitter,...
	'SymbolTime',SymbolTime, ...
	'SamplesPerSymbol',SamplesPerSymbol, ...
	'Modulation',ModulationLevels, ...
	'Signaling','Differential', ...
	'BERtarget',BERtarget);

%Visualize Pulse Response
figure
plotPulse(sys)

%Visualize PRBS Waveform Response
figure
plotWavePattern(sys)

%Plot bathtubs, Statistical Eye and contours
figure
plotStatEye(sys)

%Display Report
analysisReport(sys)

% To export Serdes System to Simulink execute the following command:
% exportToSimulink(sys);
