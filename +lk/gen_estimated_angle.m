function [Angle_esti] = gen_estimated_angle(sysPar,hcfr_esti,PE);
%gen_estimatedAOA Estimate azimuth angle.
% 
% Description:
%   This function aims to estimate angle(s) of arrival or departure using
%   selected angle estimation methods.
% 
% Input： hcfr_esti : nSC * nRx * nTx * nRSslot * nRr * nTr
% Output:  Angle_esti : nRSslot * nRr * nTr * 2dimAngle
% Note:  Counterclockwise is corresponding to the positive angles, and
% angle 0 is corresponding to the x-axis.
%
% Developer: Jia. Institution: PML. Date: 2021/08/06

nRr = sysPar.nRr;
nTr = sysPar.nTr;
nRSslot = sysPar.nRSslot;
Angle_esti = zeros( nRSslot, nRr, nTr,2);

i = 1;
AngleEst_Array = [];
theta_Array = [];
for iTr = 1 : nTr
    for iRr = 1 : nRr
        for islot = 1 : nRSslot
            if sysPar.IndUplink
                a = hcfr_esti(:, 1, :, islot, iRr, iTr);
                [AngleEst,result,theta] = music1(PE, hcfr_esti(:, :, 1, islot, iRr, iTr));
                Angle_esti(islot, iRr, iTr,:) = result;
                AngleEst_Array(i,:) = AngleEst;
                theta_Array(i,:) = theta;
                i = i+1;
%                 eval(['Angle_esti(islot, iRr, iTr,:) = ', PE.AngEstiMethodSel,...
%                     '(PE,hcfr_esti(:, :, 1, islot, iRr, iTr) );']);
            else
                a = permute( hcfr_esti(:, : , 1, islot, iRr, iTr), [1 3 2]);
                b = permute( a, [1 3 2]);
                [AngleEst,result,theta] = music1(PE, b);
                Angle_esti(islot, iRr, iTr,:) = result;
                AngleEst_Array(i,:) = AngleEst;
                theta_Array(i,:) = theta;

%                 eval(['Angle_esti(islot, iRr, iTr,:) = ', PE.AngEstiMethodSel,...
%                     '(PE,permute( hcfr_esti(:, 1, :, islot, iRr, iTr), [1 3 2]) );'] );
            end    
        end
    end
end
% 绘制空间谱图

% theta_deg = rad2deg(theta_Array);
% figure;
% [ax, h1, h2] = plotyy(theta_deg(1,:), AngleEst_Array(1,:), theta_deg(2,:), AngleEst_Array(2,:));
% % 设置 x 轴范围为 -90 到 90 度
% xlim(ax(1), [-90, 90]);
% xlim(ax(2), [-90, 90]);
% % 设置第一个 y 轴的标签和标题
% ylabel(ax(1), '空间谱 1(dB)');
% xlabel('Theta (degrees)');
% title('music算法空间谱');
% 
% % 设置第二个 y 轴的标签
% ylabel(ax(2), '空间谱 2(dB)');
% 
% % 绘制网格线
% grid on;
% 
% % 找到两条曲线的最高点
% [~, idx1] = max(AngleEst_Array(1,:));
% [~, idx2] = max(AngleEst_Array(2,:));
% 
% % 在最高点处显示坐标值
% text(theta_deg(2,idx2), AngleEst_Array(2,idx2), ['(', num2str(theta_deg(2,idx2)), ', ', num2str(AngleEst_Array(2,idx2)), ')'], 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
% text(theta_deg(1,idx1), AngleEst_Array(1,idx1), ['(', num2str(theta_deg(1,idx1)), ', ', num2str(AngleEst_Array(1,idx1)), ')'], 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
% 




end
