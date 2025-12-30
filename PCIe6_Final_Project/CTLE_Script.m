% Based on the PCIe Gen6 Base Specification, Equation 8-15:
DCgain = 5:15; %Adc defined as a range from -5 to -15dB in steps of 1dB for 64.0 GT/s Rx Equalization.
ADC = 10.^(-DCgain/20);

z1 = 250e6; %Hz
wz1 = 2*pi*z1;
p1 = 1.30 * z1; %Hz
wp1 = 2*pi*p1;
p2 = 7.7e9; %Hz
wp2 = 2*pi*p2;
p3 = 22.0e9; %Hz
wp3 = 2*pi*p3;
p4 = 28.0e9; %Hz
wp4 = 2*pi*p4;
p5 = 32.0e9; %Hz
wp5 = 2*pi*p5;
p6 = 32.0e9; %Hz
wp6 = 2*pi*p6;

z3 = 7.7e9; %Hz
wz3 = 2*pi*z3;

f = linspace(0,100e9,1001);
w = 2*pi*f;
s = 1j*w;

H = zeros(length(ADC),length(f));

for ii = 1:length(ADC)
    z2(ii) = abs(ADC(ii))*p2;
    wz2(ii) = 2*pi*z2(ii);
    H(ii,:) = ((wp1*wp3*wp4*wp5*wp6)/(wz1*wz3)).*(((s+wz1).*(s+wp2*ADC(ii)).*(s+wz3))./((s+wp1).*(s+wp2).*(s+wp3).*(s+wp4).*(s+wp5).*(s+wp6)));
end

%Define gpz matrix [G,P1,Z1,P2,Z2,P3,0,P4]:
gpz = zeros(length(ADC),8);
gpz(:,1) = -DCgain;
gpz(:,2) = -p1;
gpz(:,3) = -z1; %z1
gpz(:,4) = -p2;
gpz(:,5) = -z2;
gpz(:,6) = -p3;
%Note: Zero, pad column 7 with zeros since there are 2 more poles than
%zeros.
gpz(:,8) = -p4;

save('gpz_data.mat', 'gpz'); 
fprintf('The gpz matrix has been saved to gpz_data.mat.\n');


figure(1)
ax1(1) = subplot(211);
semilogx(f,db(H))
grid on
xlabel('Hz')
ylabel('dB')
title('Reference CTLE from PCIe 6.0 BASE Spec, Equation 8-15')
ax1(2) = subplot(212);
semilogx(f,unwrap(angle(H)))
grid on
xlabel('Hz')
ylabel('Radians')
linkaxes(ax1,'x')