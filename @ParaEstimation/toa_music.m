function result = toa_music(PE,data);
%toa_music calculate toa via dbf
%
% DESCRIPITION
%   The dimension of data is nSC * nRx * nTx. One of nRx and nTx should be
%   1. 
%
% Developer: Jia. Institution: PML. Date: 2022/05/20
data1 = data;
% % %% Time offset
% [~, L] = size(data1);
% del_f = RFI.SCS * 1000;
% nfft = RFI.nFFT;
% %TOsigma = RFI.TOsigma;
% TOsigma = 20;
% %[~, L] = size(data1);
% temp = zeros(L, 1);
% for i = 1 : L
%     temp(i) = randn(RFI.randstream4);
%     while temp(i) >=2 || temp(i) <= -2
%         temp(i) = randn( RFI.randstream4 );
%     end
% end
% offset = temp.' * TOsigma;
% rxfreq = fft(data1, [], 1) .* exp(1i *( 0 : length(data1) -1).'...
%     * offset* 1e-9 * del_f * nfft * 2 * pi / length(data1) );
% data1 = ifft(rxfreq);
[nSC,~] = size(data1);
freq_index=(1:8:nSC).';
data1 = data1(freq_index,1);
Rx=data1*data1';%  covariance matrix
[M,~]=size(Rx);
[EgV,D] = eig(Rx);
Egv=diag(D);
[~,b]=sort(Egv);% ordering from minimum
target_Num=1;%PE.nTarget;% signal number
i=b(1:M-target_Num);%noise subspace index
UN=EgV(:,i);   % noise subspace
%take nRx dimension as nsnapshot
Interval1 = 1;
%range= (0:Interval1:88);
range= (0:Interval1:130);
Tmp_co = ranging_music(PE,range,freq_index,UN);

Interval2 = 0.05;
range= (Tmp_co-Interval1:Interval2:Tmp_co+Interval1);
result = ranging_music(PE,range,freq_index,UN);

end

function out = ranging_music(PE,range,freq_index,UN)
RangeEst = zeros(length(range),1);
for irng = 1 : length(range)
    a = exp(-1i * 2 * pi * (freq_index ) * PE.deltaf * range(irng)/PE.c);
    RangeEst(irng) = 1/abs(a'*(UN*UN')*a);
end
% plot(RangeEst)
[~,Sub]=max(RangeEst);
out=range(Sub);
end