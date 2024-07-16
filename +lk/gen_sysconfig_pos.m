function [sysPar,carrier,BeamSweep,Layout,RFI,PE,Chan] = gen_sysconfig_pos(BW,SCS,dis,angle);
%gen_sysconfig_pos System paramenters Config. for RTT+AOA positioning
%% ====Basic Parameters Config.====%
sysPar.nFrames = 0.05;    % 5 ranging estimations got when nFrames equals to 1
sysPar.center_frequency = 4.9e9;
sysPar.UEstate = 'static';  % static or dynamic
sysPar.SignalType = 'PRS';       
sysPar.VelocityUE = 10;  % m/s
SRS = 'SRS';
if sysPar.SignalType == SRS
    sysPar.BSArraySize = [1 4];
    sysPar.UEArraySize = [1 1];
    sysPar.nBS = 1;
    sysPar.nUE = 1;
else 
    sysPar.BSArraySize = [1 1];
    sysPar.UEArraySize = [1 4];
    sysPar.nBS = 1;
    sysPar.nUE = 1;
end

sysPar.RSPeriod = 4;  % n slot
sysPar.BeamSweep = 0;
sysPar.SNR = 20; % in dB 
%% ====System layout Config.========%
sysPar.h_BS = 3;
sysPar.h_UE = 1.5;
sysPar.BSorientation = 1*pi;
sysPar.UEorientation = 2*pi;
sysPar.BSPos = [ 0 ;  dis ; sysPar.h_BS ];
sysPar.UEPos = [ -dis*0.5/tan(angle); 0.5*dis; sysPar.h_UE];
sysPar.realD = sqrt((sysPar.BSPos(1,1)-sysPar.UEPos(1,1))^2+(sysPar.BSPos(2,1)-sysPar.UEPos(2,1))^2);
%%
% sysPar.Scenario = '3GPP_38.901_Indoor_LOS';
sysPar.Scenario = {'umi'};
% '3GPP_38.901_InF_DH''LOSonly','3GPP_38.901_Indoor_LOS'
sysPar.powerUE = 23; % dBm 200 mW   
sysPar.powerBS = 24; % dBm 250 mW
sysPar = cf.ParaTransConfig(sysPar);
%% ====Carrier Config.==============%
carrier = nr.CarrierConfig;

%   RB table for scs = 15 30 60:
%{
%   BW=5,10,15,20,25,30,40,50,60,70,80,90,100:
%   25	52	79	106	133	160	216	270	0	0	0	0	0
%   11	24	38	51	65	78	106	133	162	189	217	245	273 √
%   0	11	18	24	31	38	51	65	79	93	107	121	135
%}
if BW==100&&SCS==30
    sysPar.bandwidth = 1e8;
    carrier.NSizeGrid = 272;   % RB number, remember to modify the corresponding signal config
    carrier.SubcarrierSpacing = SCS;
elseif BW==20&&SCS==30
    sysPar.bandwidth = 2e7;
    carrier.NSizeGrid = 51;
    carrier.SubcarrierSpacing = SCS;
%
elseif BW==40&&SCS==30
    sysPar.bandwidth = 4e7;
    carrier.NSizeGrid = 106;
    carrier.SubcarrierSpacing = SCS;
elseif BW==40&&SCS==15
    sysPar.bandwidth = 4e7;
    carrier.NSizeGrid = 216;
    carrier.SubcarrierSpacing = SCS;
elseif BW==40&&SCS==60
    sysPar.bandwidth = 4e7;
    carrier.NSizeGrid = 51;
    carrier.SubcarrierSpacing = SCS;
end  
%% ====RS Config.===================%
sysPar = cf.SigResConfig(sysPar, carrier);
if strcmp(sysPar.SignalType,'SRS')
    switch sysPar.bandwidth
        case 2e7
            sysPar.SigRes.C_SRS = 13;
        case 1e8
            sysPar.SigRes.C_SRS = 61;
    end
end
%% ====Beam Sweeping Config.========%
BeamSweep = BeamSweepConfig(sysPar,carrier);
%% ====Channel Simulator Config.====%
[Layout, Chan] = cf.ChanSimuConfig(sysPar, carrier);
%% ======Hardware Imparement========%
RFI = RFImpairConfig(sysPar, carrier);
% FRI.Ind_AntPhaseOffset =1;
% FRI.Ind_IQImbalance = 1; 
RFI.Ind_TimingOffset = 0;
% FRI.Ind_ApproxiCIR = true;
RFI.Ind_SNR = 0; % 0 for base noise; 1 sig power by path loss; 2 measured; 3 no noise
%% === Estimation Config.===========%
PE = ParaEstimation;
PE.SCS = carrier.SubcarrierSpacing;
% SRS = nr.SRSConfig;
% SRS.m_srs_b = carrier.NSizeGrid;
PE.AngEstiMethodSel = 'music1';
PE.RngEstiMethodSel = 'toa_music';
end

