%--------------------------------------------------------------------------
% 5G localization link level simulator 
% 2-D RTT+AOA positioning case
% RTT：First from target UE to reference UE, then from reference UE to target UE
% Developer: ZhengyuJin@Great
%--------------------------------------------------------------------------
close all;
clear;
clc;
%rng('default');
data.LocErrall = [];
p=1;
Batchsize = 1000;

for BW = [20 100]  % MHz
    eTemp = [];
    Batchnum=1;
    for i = 1:Batchsize
        %% target UE-->reference UE
        t_begin = 0; % RTT trigger time

        % generate system configuration, wireless channel information
        [sysPar, carrier, BeamSweep, Layout, RFI, PE, Chan] = lk.gen_sysconfig_pos(BW,30,50,1/6*pi);

        [data.CIR_cell, data.hcoef, data.Hinfo] = lk.gen_channelcoeff(sysPar, carrier, Layout, Chan, RFI); % Hinfo contains the lsp and ssp

        % generate RS symbols
        [data.rsSymbols, data.rsIndices, data.txGrid] = lk.gen_rssymbol(sysPar, carrier,BeamSweep.IndBmSweep);

        % OFDM modulation
        [data.txWaveform] = lk.gen_transmitsignal(sysPar, carrier,data, RFI, BeamSweep);

        % Channel filtering
        [data.rxWaveform] = lk.gen_receivesignal(sysPar, carrier, data, RFI, BeamSweep);

        % OFDM demodulation
        [data.rxGrid] = lk.gen_demodulatedgrid(sysPar, carrier, data.rxWaveform);

        % Channel estimation
        [data.hcfr_esti] = lk.gen_estimated_cfr(sysPar, carrier, data);

        % Angle estimation
        [data.Angle_esti] = lk.gen_estimated_angle(sysPar, data.hcfr_esti,PE);

        % 1st ToA estimation
        [data.Range_esti] = lk.gen_estimatedTOA(sysPar,data.hcfr_esti,PE);
        t_fly1 = data.Range_esti/PE.c;

        %pf.plotSysLayout(sysPar,Layout, data);  % display Layout
        %% target UE-->reference UE
        % Add reply time(time gap)at target UE
        t_reply = 2 * 5 * 1e-3 * randn(); % sigma = 5ms
        while t_reply > 10 * 1e-3 || t_reply <= 0  % truncated Ganssian distribution with (0, 10ms]
            t_reply =  2 * 5 * 1e-3 * randn();
        end

        % BackwardTrans configuration
        [sysPar2, BeamSweep2, Layout2, Chan2, RFI2] = gen_backwardconfig(sysPar,carrier);

        % Same as the procedure of 1st transmission
        [data2.CIR_cell, data2.hcoef, data2.Hinfo] = lk.gen_channelcoeff(sysPar2, carrier, Layout2, Chan2, RFI2);
        [data2.rsSymbols, data2.rsIndices, data2.txGrid] = lk.gen_rssymbol(sysPar2, carrier,BeamSweep2.IndBmSweep);
        [data2.txWaveform] = lk.gen_transmitsignal(sysPar2, carrier, data2, RFI2, BeamSweep2);
        [data2.rxWaveform] = lk.gen_receivesignal(sysPar2, carrier, data2, RFI2, BeamSweep2);
        [data2.rxGrid] = lk.gen_demodulatedgrid(sysPar2, carrier, data2.rxWaveform);
        [data2.hcfr_esti] = lk.gen_estimated_cfr(sysPar2, carrier, data2);

        % 2nd TOA estimation
        [data2.Range_esti] = lk.gen_estimatedTOA(sysPar,data2.hcfr_esti,PE);
        t_fly2 = data2.Range_esti/PE.c;

        %% RTT error calculation
        t_drift_max = 0.1e-6*t_reply + 0.1e-6*(t_reply+t_fly1+t_fly2); %maximum clock drift of 0.1ppm according to RAN4 specification, where t_reply is dorminated
        
        t_drift = 2 * 1/2*t_drift_max *randn();  %sigma = 1/2*t_drift_max
        while t_drift > t_drift_max || t_drift<-t_drift_max   % truncated Ganssian distribution with [-t_drift_max t_drift_max]
            t_drift = 2 * 1/2*t_drift_max *randn();
        end
        
        t_end = t_begin + t_fly1 + t_reply + t_fly2 +t_drift;
        RTT = t_end - t_begin - t_reply;
        ToF = RTT/2;
        estiD = ToF*PE.c;

        %% RTT+AOA for absolute (relative) position
        estPosi = [sysPar.BSPos(1,1)+estiD*cos(data.Angle_esti+sysPar.UEorientation-pi);sysPar.BSPos(2,1)+estiD*sin(data.Angle_esti+sysPar.UEorientation-pi)];
        ARerror = sqrt((estPosi(1,1)- sysPar.UEPos(1,1))^2+(estPosi(2,1)- sysPar.UEPos(2,1))^2);
        eTemp = [eTemp ARerror];
        Batchnum= Batchnum+1;

    end
    sortE(:,p) = sort(eTemp);

    %find the abnormal value beyond "mean value + 3 standard deviation"
    sortE_mean(:,p) = mean(sortE(:,p));
    sortE_std(:,p) = std(sortE(:,p));
    outlier_idx(:,p) = abs(sortE(:,p)- sortE_mean(:,p)) > 3 * sortE_std(:,p);
  
    %ninetyPercentE = prctile(eTemp,90);
    p = p+1;
end
sortE(outlier_idx) = NaN;
%% plot

% Calculate the cumulative distribution values
E1 = sortE(~isnan(sortE(:, 1)), 1);
E2 = sortE(~isnan(sortE(:, 2)), 2);
cdfValues1 = (1:length(E1))' / length(E1);
cdfValues2 = (1:length(E2))' / length(E2);

% Plot the CDF
plot(E1, cdfValues1,'b', 'LineWidth', 2);
hold on;
plot(E2, cdfValues2, 'r','LineWidth', 2);
hold off;
grid on;
legend('Bandwidth=20MHz','Bandwidth=100MHz');
xlabel('RTT+AOA positioning error @50m /m');
ylabel('CDF');
title('Cumulative Distribution Function');




