clear;clc;
close all
n=10000;n_us=0;n_s=0;shortt=0;n_usu=0;n_us2=0;er_num_unstable=[];er_num_stable=[];num_unstable=[];num_unstable3=[];num_unstable2=[];num_unstable1=[];num_sssaun=[];num_unstable0=[];true_unstable=[];
load('simulation_data_14_493_breaker_1003_2.mat');

parameters=Saveopt.Gen_P([2,3],:)';
% load('simulation_data_14_493_breaker_full2.mat');
% parameters=Saveopt.Gen_P([2,3],:)';
state=ones(n,2);
for step=1:n
% close all

t1=time_set1{step}; 
if max(t1)<20
    shortt=shortt+1;
    num_unstable0=[num_unstable0;step];
% figure(1001)
% hold on
% scatter(parameter(:,1), parameter(:,2), 50, 'r', 'x');

    continue
end
if isempty(t1)
     num_sssaun=[num_sssaun;step];
     state(step,1)=2;state(step,2)=2;
     num_unstable1=[num_unstable1;step];
    continue
end
parameter=parameters(step,:);
%真实稳定性
ft=find(t1<5);
delta_s=delta_set1{step};
% figure(step)
% plot(t1,delta_s)
true_max(:,1)=max(delta_s(:,ft),[],2)-min(delta_s(:,ft),[],2);
et=find(48<t1);
true_max(:,2)=max(delta_s(:,et),[],2)-min(delta_s(:,et),[],2);
et1=find(13<t1&t1<15);
true_max(:,3)=max(delta_s(:,et1),[],2)-min(delta_s(:,et1),[],2);
if sum(true_max(:,1)<true_max(:,2))
    state(step,1)=0;
%     true_unstable=[true_unstable;step];
num_unstable=[num_unstable;step];
% figure(1001)
% hold on
% scatter(parameter(:,1), parameter(:,2), 15, 'r', '*');
% else
% figure(1001)
% hold on
% scatter(parameter(:,1), parameter(:,2), 15, 'b', 'o');   
end
if sum(true_max(:,1)<true_max(:,3))
    state(step,1)=0;
%     true_unstable=[true_unstable;step];
num_unstable3=[num_unstable3;step];

end


tic;
tdmd2=15;rset=25;Ded=60;
[absb2,abse2,test_td2,delta_ori2,X02,X2,X_dmd_approx2,modal_energy2,damping_ratios2]=Hankel(t1,tdmd2,delta_set1,omega_set1,step,nsw,rset,Ded);
elapsedTime(step)= toc;
err = evaluateDMDerror(X2(:,1:size(X_dmd_approx2,2)),X_dmd_approx2);
err_save{step}=err;
damping_sort=sort(damping_ratios2);
% 查找重复的数值
[unique_vals, ~, ic] = unique(damping_sort); % 获取唯一值及其索引
counts = histcounts(ic, 1:length(unique_vals)+1); % 统计每个值的出现次数
repeated_vals = unique_vals(counts > 1); % 找出重复的值

% 提取第一个重复的数值
% if ~isempty(repeated_vals)
    first_repeated_value(step) = repeated_vals(1); % 第一个重复的数值
% else
%     first_repeated_value = []; % 如果没有重复值
%     warning('数据中没有重复的数值');
% end
[nn, T] = size(X_dmd_approx2);
% 
% figure(step);
% for i = 1:nn
%     subplot(nn,1,i);
%     plot(t1(test_td2(1:T)), X2(i,1:T), 'k-', 'LineWidth', 1.2); hold on;
%     plot(t1(test_td2(1:T)), X_dmd_approx2(i,:), 'r--', 'LineWidth', 1.2);
%     if i<=(nn/2)
%     ylabel(['A' num2str(i)]);
%     else
%     ylabel(['S' num2str(i)-nn/2]);
%     end
%     if i == 1
%         title('Original vs Hankel-DMD Reconstruction');
%         legend('Original', 'DMD');
%     end
% end
% xlabel('Time step');

% figure(1001)
% hold on
% scatter(parameter(:,1), parameter(:,2), 15, 'b', 'o');
% xlim([0 1.4]);
% ylim([0 1]);
% figure(step+1);
% % subplot(3,1,1);
% % plot(t1,X02'); title('Original'); grid on;
% % subplot(3,1,2);
% plot(t1(test_td2),X2'); title('Original');grid on;
% subplot(3,1,3);
% plot(t1(1:size(X_dmd_approx2,2)),X_dmd_approx2'); title('Hankel-DMD Reconstruction'); grid on;
% figure(step)
% plot(t1(test_td2),X2'); 

[absb_sorted2, idx2] = sort(absb2, 'descend');
abse_sorted2 = abse2(idx2);

[abse_modal_energy2, idxg2] = sort(modal_energy2, 'descend');
abse_energy_sorted2 = abse2(idxg2);

if first_repeated_value(step)<0.005
% unstablemode2=find(abse2>1);
% if size(unstablemode2,1)>=2
% figure(step)
% plot(t1(test_td2),X2'); 
% figure(1001)
% hold on
% scatter(parameter(:,1), parameter(:,2),50, 'm', 'x');

% ue2=abse2(unstablemode2);
% num_unstable=[num_unstable;step];
state(step,2)=0;
num_unstable2=[num_unstable2;step];
n_us2=n_us2+1;
% figure(step+1);
% subplot(3,1,1);
% plot(t1,X02'); title('Original'); grid on;
% subplot(3,1,2);
% plot(t1(test_td2),X2'); title('Original');grid on;
% subplot(3,1,3);
% plot(t1(1:size(X_dmd_approx2,2)),X_dmd_approx2'); title('Hankel-DMD Reconstruction'); grid on;
% else
% figure(1002)
% hold on
% scatter(parameter(:,1), parameter(:,2), 15, 'r', '*');
% else
% figure(1002)
% hold on
% scatter(parameter(:,1), parameter(:,2), 15, 'b', 'o');  
end
% close(figure(step))
% if max(max(delta_ori(:,test_td)))>pi
%     n_usu=n_usu+1;
%     er_num_stable=[er_num_stable;step];
% end
end
% save('pfdatatestHankelparameter_1224_0.mat');
save('damping_0.mat', 'first_repeated_value')
first_repeated_value0=first_repeated_value;
first_repeated_value(:,num_unstable1)=100;
deta_damping=abs(first_repeated_value-0);
[min_val, position]=min(deta_damping);
save('position_0.mat', 'position')
exportPath = 'C:\Users\juelin\Documents\WPSDrive\1432879259\WPS云盘\日本留学期间的研究\PES-LETTER\画图-1';
% end
ct=mean(elapsedTime);
%% parameter
% 真实数据
index0=ones(n,1);
index0(num_unstable,:)=0;
index0(num_unstable1,:)=2;
us_parameters=parameters(num_unstable2,:);
num_stable_save=find(index0==1);
num_unstable_save=find(index0==0);
unstable_points = parameters(index0 == 0, :);
save('parameter_30_50.mat', 'parameters', 'index0');
% 绘图
figure;
% set(gcf, 'Position', [100, 100, 800, 600]);
set(gcf, 'PaperPositionMode', 'auto');
hold on;
scatter( parameters(index0==1,1), parameters(index0==1,2), ...
    15, 'b', 'o');
scatter(parameters(index0==0,1), parameters(index0==0,2), ...
    50, 'r', 'x');
xlabel('GenP 1', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('GenP 2', 'FontSize', 20, 'FontWeight', 'bold');
xlim([min(parameters(:,1)),max(parameters(:,1))])
ylim([min(parameters(:,2)),max(parameters(:,2))])
legend('stable','unstable')
ax = gca;
ax.FontSize = 12;  % 坐标轴数字大小
ax.FontWeight = 'bold';  % 坐标轴数字加粗% Y 轴：概率密度
% title('Convex Hull of Stable Region');
% view(3);
grid on;
camlight; lighting gouraud;
outputFile2 = fullfile(exportPath, 'Benchmark1.png');
% exportgraphics(gcf, outputFile2, 'Resolution', 300);

% index1=ones(n,1);
% index1(num_unstable3,:)=0;
% index1(num_unstable1,:)=2;
% us_parameters=parameters(num_unstable2,:);
% num_stable_save=find(index1==1);
% num_unstable_save=find(index1==0);
% unstable_points = parameters(index1 == 0, :);
% save('parameter_31.mat', 'parameters', 'index1');
% % 绘图
% figure;
% % set(gcf, 'Position', [100, 100, 800, 600]);
% set(gcf, 'PaperPositionMode', 'auto');
% hold on;
% scatter( parameters(index1==1,1), parameters(index1==1,2), ...
%     15, 'b', 'o');
% scatter(parameters(index1==0,1), parameters(index1==0,2), ...
%     50, 'r', 'x');
% xlabel('GenP 1', 'FontSize', 20, 'FontWeight', 'bold');
% ylabel('GenP 2', 'FontSize', 20, 'FontWeight', 'bold');
% xlim([min(parameters(:,1)),max(parameters(:,1))])
% ylim([min(parameters(:,2)),max(parameters(:,2))])
% legend('stable','unstable')
% ax = gca;
% ax.FontSize = 12;  % 坐标轴数字大小
% ax.FontWeight = 'bold';  % 坐标轴数字加粗% Y 轴：概率密度
% % title('Convex Hull of Stable Region');
% % view(3);
% grid on;
% camlight; lighting gouraud;


% 拟合数据
index=ones(n,1);
index(num_unstable2,:)=0;
index(num_unstable1,:)=2;
us_parameters=parameters(num_unstable2,:);
num_stable_save=find(index==1);
num_unstable_save=find(index==0);
unstable_points = parameters(index == 0, :);
save('parameter_3_noise_0.2_15_0.005.mat', 'parameters', 'index');
% 绘图
figure;
% set(gcf, 'Position', [100, 100, 800, 600]);
set(gcf, 'PaperPositionMode', 'auto');
hold on;
scatter(parameters(index==0,1), parameters(index==0,2), ...
    50, 'r', 'x');
scatter( parameters(index==1,1), parameters(index==1,2), ...
    15, 'b', 'o');

xlabel('GenP 1', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('GenP 2', 'FontSize', 20, 'FontWeight', 'bold');
xlim([min(parameters(:,1)),max(parameters(:,1))])
ylim([min(parameters(:,2)),max(parameters(:,2))])
legend('stable','unstable')
ax = gca;
ax.FontSize = 12;  % 坐标轴数字大小
ax.FontWeight = 'bold';  % 坐标轴数字加粗% Y 轴：概率密度
% title('Convex Hull of Stable Region');
% view(3);
grid on;
camlight; lighting gouraud;

outputFile2 = fullfile(exportPath, 'KOd15_noise_0.2_15_0.005.png');
% exportgraphics(gcf, outputFile2, 'Resolution', 300);
%误差计算
err_index0=index0;
err_index=index;
% err_index0(find(err_index0==2))=[];
% err_index(find(err_index==2))=[];
err_state=size(find(err_index0~=err_index))/size(err_index);
ac_state=(1-err_state)*100;
%% 3. 训练 MATLAB 内置的分类集成模型
% 使用 AdaBoostM1 方法，它非常适合二分类问题
% t = templateTree('MaxNumSplits', 10);
t = templateTree('MaxNumSplits', 30);
ens= fitcensemble(parameters, index, 'Method', 'Bag', 'NumLearningCycles', 50, 'Learners', t);

% t = templateTree('MaxNumSplits', 10);
% ens = fitcensemble(parameters, index, 'Method', 'AdaBoostM1', 'NumLearningCycles', 50, 'Learners', t);

%% 4. 绘制模型的决策边界
% 创建一个覆盖整个特征空间的密集网格
x1range = linspace(min(parameters(:,1))-1, max(parameters(:,1))+1, 100);
x2range = linspace(min(parameters(:,2))-1, max(parameters(:,2))+1, 100);
[xx1, xx2] = meshgrid(x1range, x2range);
XGrid = [xx1(:) xx2(:)];

% 使用训练好的模型对网格点进行预测
[predicted_labels, ~] = predict(ens, XGrid);

% 将预测结果重塑为与网格大小相同的矩阵
predicted_grid = reshape(predicted_labels, size(xx1));

% 使用 contour 函数绘制等高线图，'LineColor' 设置为黑色
contour(xx1, xx2, predicted_grid, [1 1], 'k-', 'LineWidth', 2);
xlim([min(parameters(:,1)),max(parameters(:,1))])
ylim([min(parameters(:,2)),max(parameters(:,2))])
% 关闭 hold on
hold off;
%% -----------------------------------------------------------------------
for step=1:n
err=err_save{step};
if ~isempty(err) 
MSE_all(step)= err.MSE;
RMSE_all(step)= err.RMSE;
MaxAbsError_all(step)= err.MaxAbsError;
RelativeError_all(step)= err.RelativeError;
end
end
un_err=find(MSE_all>1);
misjudge=MSE_all(un_err);
idx = true(size(MSE_all));
idx(un_err) = false; 
% idx(find(isnan(tmse)))=false;
% 计算平均值
avg_err.MSE = mean(MSE_all(idx));
avg_err.RMSE = mean(RMSE_all(idx));
avg_err.MaxAbsError = mean(MaxAbsError_all(idx));
avg_err.RelativeError = mean(RelativeError_all(idx));

[max_err.MSE,in] = max(MSE_all(idx));
max_err.RMSE = max(RMSE_all(idx));
max_err.MaxAbsError = max(MaxAbsError_all(idx));
max_err.RelativeError = max(RelativeError_all(idx));
% Count the number of values that are less than 1
count_less_than_1 = sum(MSE_all < 0.01);

% Get the total number of values
total_count = numel(MSE_all);

% Calculate the percentage
percentage = (count_less_than_1 / total_count) * 100;

figure;

% Plot the histogram with a specified number of bins.
% 'Normalization' can be set to 'count' (default), 'probability', or 'pdf'.
% Here we use 'count' to show the number of data points in each bin.
h = histogram(MSE_all(idx)*100, 'Normalization', 'count');

% --- Customizing the plot for high quality ---

% Set the bar color and edge color
h.FaceColor = [0 0.4470 0.7410]; % A nice blue color
h.EdgeColor = 'k'; % Black edges

% Add a title and labels
title('Distribution of MSE Values for Hankel-DMD', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Mean Squared Error (%)', 'FontSize', 12);
ylabel('Frequency', 'FontSize', 12);

% Add a grid for better readability
grid on;

% Make the plot look cleaner by adjusting the axes box
box on;

% Improve font and line quality
set(gca, 'FontSize', 11, 'FontName', 'Arial');


function [absb,abse,test_td,delta_ori,X0,X,X_dmd_approx,modal_energy,damping_ratios]=Hankel(t1,tdmd,delta_set1,omega_set1,step,nsw,rset,Ded)
test_td=find(0.02<t1&t1<=tdmd);
delta_ori0=delta_set1{step};
omega_ori0=omega_set1{step};
omega_ori0=omega_ori0-omega_ori0(nsw,:);
delta_ori=delta_ori0-delta_ori0(:,1);
omega_ori=omega_ori0-omega_ori0(:,1);
delta=delta_ori(:,test_td)./max(max(abs(delta_ori(:,test_td))));
omega=omega_ori(:,test_td)./max(max(abs(omega_ori(:,test_td))));

X0=[delta_ori0(2:end,:);omega_ori0(2:end,:)];
X1=[delta(2:end,:);omega(2:end,:)];

X_ori=X1;
% 引入噪声
noise_level = 0.2;  % 噪声强度，例如 0.01 表示 1% 的标准差
X = X_ori + noise_level * randn(size(X_ori));  % 加入高斯白噪声
n_ori=size(X,1);
% 参数设置
delays = Ded;  % 延迟步数，可调整
[X_h, Y_h] = construct_hankel(X, delays);

% DMD 主程序
r = rset; % 截断秩（不超过 size(X_h, 1)）
[U, S, V] = svd(X_h, 'econ');
U_r = U(:, 1:r); S_r = S(1:r, 1:r); V_r = V(:, 1:r);

A_tilde = U_r' * Y_h * V_r / S_r;
[W, D] = eig(A_tilde);
eigvals = diag(D);
eigvals_t=log(eigvals)/0.05;
%阻尼比
    sigma = real(eigvals_t);
    omega = imag(eigvals_t);

    % 自然频率 rad/s
    wn = sqrt(sigma.^2 + omega.^2);

    % 阻尼比
    damping_ratios = -sigma ./ wn;


abse=abs(eigvals);
Phi = Y_h * V_r / S_r * W;
absphi=abs(Phi(1:n_ori,:) )';
b = pinv(Phi) * X_h(:, 1); % 初始系数
absb=abs(b);
% b(3) = b(3) * 10;  % 放大10倍试试看
% b(4) = b(4) * 10;
omega = log(eigvals);
N = size(X_h, 2);
t = 0:N;
dt=1;
omega = log(D)/dt;
% Form Vandermonde matrix
Vand = zeros(r,N);
zdmd = diag(D);
for i = 1:N
    Vand(:,i) = zdmd.^(i-1);
end
X_dmd_hankel = Phi * diag(b)*Vand;
% 取 Hankel-DMD 重构结果的前 n 行，即代表原始变量第一个时刻
X_dmd_approx = real(X_dmd_hankel(1:size(X,1), :));
lambda =zdmd;  % 简化变量名（可选）

% 初始化能量数组
modal_energy = zeros(r, 1);

% 对每个模态计算其在重构信号中的能量贡献
for i = 1:r
    % 构造模态的时间响应（按列向量）
    time_response = b(i) * (lambda(i).^(0:N-1));  % 1×N
    % 重构该模态的整个时间行为（n × N）
    mode_i_full = Phi(:, i) * time_response;     % outer product
    
    % 计算 Frobenius 范数的平方（即总能量）
    modal_energy(i) =norm(mode_i_full, 'fro')^2;
end
end
function [X_hankel, Y_hankel] = construct_hankel(X, delays)
    % 将原始数据 X 构造成延时嵌入的 Hankel 矩阵
    [n, m] = size(X);
    N = m - delays;

    X_hankel = [];
    for i = 1:delays
        X_hankel = [X_hankel; X(:, i:N+i-1)];
    end
    Y_hankel = [];
    for i = 1:delays
        Y_hankel = [Y_hankel; X(:, i+1:N+i)];
    end
end

function err = evaluateDMDerror(X_original, X_dmd)
% 输入：
%   X_original : 原始数据 (n x T)
%   X_dmd      : DMD 重构数据 (n x T)
% 输出：
%   err        : 结构体，包含多种误差指标

    if size(X_original) ~= size(X_dmd)
        error('Size mismatch: X_original and X_dmd must have same dimensions');
    end

    diff = X_original - X_dmd;
    
    err.MSE = mean(diff(:).^2);
    err.RMSE = sqrt(err.MSE);
    err.MaxAbsError = max(abs(diff(:)));
    err.RelativeError = norm(diff, 'fro') / norm(X_original, 'fro');
end
