clear;clc;

close all
fclose('all');
kk=0;
sample_num=2000;
% Filedata_input='d_009_mdl_L1025';
% case_data='case9_L1';
% % 
% Filedata_input='d_009_mdl_1129';
% case_data='case9_L';
% % 
% Filedata_input='d_009_fault_mdl_L';
% case_data='case9_L';

% Filedata_input='d_009_tg_mdl_L';
% case_data='case9_L';
% 
Filedata_input='d_014_dyn_l10_mdl526';
case_data='case14_L';
% load('simulation_data_14_493_breaker1.mat');
% Filedata_input='d_014_dyn_l10_mdl_new';
% case_data='case14_L';

% Filedata_input='d_014_dyn_wind_mdl';
% case_data='case14_L';

eval(Filedata_input);
M = Syn.con(:,18);          % 发电机惯性常数 (M1, M2)
D = Syn.con(:,19);       % 阻尼系数
linedata_ori=Line.con(:,[1,2,8,9,10]);
linedata=Line.con(:,[1,2,8,9,10]);
loaddata=PQ.con(:,[1,4,5]);
gen_bus = [SW.con(:,1);PV.con(:,1)];       % 发电机连接母线
non_gen_bus = setdiff(1:9, gen_bus);  % 非发电机连接母线
ngen = size(gen_bus, 1);
bus_n=Bus.con(:,1);
nbus=size(Bus.con,1);
nline=size(Line.con,1);
mpc=eval(case_data);
% 潮流参数随机抽样
if mpc.branch(:,6)==0
    mpc.branch(:,6)=280;
end
Gen_num=[SW.con(:,1);PV.con(:,1)];
Load_num=PQ.con(:,1);
nPQ=size(PQ.con,1);
% for i=1:size(mpc.bus,1)
% s_PQ_P(i,:)=normrnd(mpc.bus(i,3)*1.6,0.2*mpc.bus(i,3),[1,sample_num]);
% s_PQ_Q(i,:)=normrnd(mpc.bus(i,4)*1.6,0.2*mpc.bus(i,4),[1,sample_num]);
% end
% for i=1:size(mpc.gen,1)
% s_PV_P(i,:)=mpc.gen(i,10)+lhsdesign(1,sample_num).*(mpc.gen(i,9)-mpc.gen(i,10));
% end
% bus_gen=mpc.bus(find(mpc.bus(:,2)~=1),1);
% bus_slack=mpc.bus(find(mpc.bus(:,2)==3),1);
% bus_PV=mpc.bus(find(mpc.bus(:,2)==2),1);
% for i=1:size(mpc.gen,1)
% s_PV_V(i,:)=mpc.bus(bus_gen(i),13)+lhsdesign(1,sample_num).*(mpc.bus(bus_gen(i),12)-mpc.bus(bus_gen(i),13));
% end
% s1=0;
% load('s14.mat');
% % mpc.bus(:,3)=mpc.bus(:,3)*1.2;
% % mpc.bus(:,4)=mpc.bus(:,4)*1.2;
% for step=1:sample_num
% mpc.bus(:,3)=s_PQ_P(:,439);
% mpc.bus(:,4)=s_PQ_Q(:,439);
% mpc.gen(:,2)=s_PV_P(:,439);
% mpc.gen(:,6)=s_PV_V(:,439);
% mpc.gen(2,2)=s_PV_P(2,step);
% mpc.gen(4,2)=rand*40;
% [baseMVA, bus, gen, branch, success]=runpf(mpc);
% % if success==1&&prod(gen(:,2)>=gen(:,10))&&prod(gen(:,2)<=gen(:,9))&&prod(abs(branch(:,14))<=branch(:,6))&&prod(abs(branch(:,16))<=branch(:,6))
% if success==1&&prod(gen(:,2)>=gen(:,10))&&prod(gen(:,2)<=gen(:,9))
% s1=s1+1;
% s.PL(:,s1)=bus(:,3);
% s.QL(:,s1)=bus(:,4);
% s.PG(:,s1)=gen(:,2);
% s.VG(:,s1)=gen(:,6);
% s.branchpf(:,s1)=branch(:,14);
% s.branchpt(:,s1)=branch(:,16);
% s.branchqf(:,s1)=branch(:,15);
% s.branchqt(:,s1)=branch(:,17);
% end
% end
% save('s14_2.mat','s'); 
load('s14.mat');
iuor=ones(size(s.PL,2),1);
n=10000;
% 获取各矩阵的尺寸
syn_size = size(Syn.con(:,8:19));
tg_size = size(Tg.con(:,4:8));
exc_size = size(Exc.con(:,5:8));
% % 初始化存储随机数的数组（第3维表示循环次数）
% rand_syn = zeros([syn_size, n]); % Syn.con 的随机数
% rand_tg = zeros([tg_size, n]);   % Tg.con 的随机数
% rand_exc = zeros([exc_size, n]); % Exc.con 的随机数
%     % 生成随机数并保存
%     for i=1:n
%     rand_syn(:,:,i) = rand(syn_size) * 0.5; % 0 到 0.5 的随机波动
%     rand_tg(:,:,i) = rand(tg_size) * 0.5;
%     rand_exc(:,:,i) = rand(exc_size) * 0.5;
%     end
% save('rand_syn14.mat','rand_syn'); 
% save('rand_tg14.mat','rand_tg'); 
% save('rand_exc14.mat','rand_exc'); 
% load('rand_syn14.mat'); 
% load('rand_tg14.mat'); 
% load('rand_exc14.mat'); 
% delta_set1 = cell(1, n);
% omega_set1 = cell(1, n);
% time_set1 = cell(1, n);
% delta_set2 = cell(1, n);
% omega_set2 = cell(1, n);
% time_set2 = cell(1, n);

for step=1:n
    close all
    clear Bus Line Breaker Fault SW PV PQ Syn Tg Exc
eval(Filedata_input);
baseMVA=mpc.baseMVA;
nd=([1:size(Syn.con,1)]'-1).*Syn.con(:,5)+1;
nsw=(SW.con(:,1)-1).*Syn.con(find(Syn.con(:,1)==SW.con(:,1)),5)+1;
nw=([1:size(Syn.con,1)]'-1).*Syn.con(:,5)+2;
% nd=gen_bus;
% nsw=SW.con(:,1);
% Fault.con=[Fault.con;Fault.con];

Fault.con(1,1)=4;
% Fault.con(2,1)=5;
Fault.con(1,6)=0.02;
clear_time=Fault.con(1,6);
Fault.con(1,5)=0;
Breaker.con(:,7)=1.2;
% Fault.con(2,6)=0.2;
% Fault.con(2,5)=0.1;
%稳定参数抽样
    
    % 应用随机波动到原始数据
    % Syn.con(:,8:19) = Syn.con(:,8:19) .* (1 + rand_syn(:,:,8));
    % Tg.con(:,4:8) = Tg.con(:,4:8) .* (1 + rand_tg(:,:,8));
    % Exc.con(:,5:8) = Exc.con(:,5:8) .* (1 + rand_exc(:,:,8));

% fault_duration = Fault.con(:,6)-Fault.con(:,5); % 故障持续时间 (s)
% tspan_fault = [Fault.con(:,5), Fault.con(:,6)];    % 故障时段
% SW.con(:,4)=s.VG(find(mpc.gen(:,1)==SW.con(:,1)),step);
SW.con(:,4)=s.VG(find(mpc.gen(:,1)==SW.con(:,1)),493);
    for i=1:size(mpc.gen,1)
        j=find(PV.con(:,1)==mpc.gen(i,1));
        % PV.con(j,4)=s.PG(i,step)/baseMVA;
        % PV.con(j,5)=s.VG(i,step);
        if i==2
        PV.con(j,4)=rand(1)*1.4;
        elseif i==4
        PV.con(j,4)=rand(1);
        else
        PV.con(j,4)=s.PG(i,493)/baseMVA;
        end
        PV.con(j,5)=s.VG(i,493);
    end
    for i=1:size(mpc.bus,1)  
        j=find(PQ.con(:,1)==mpc.bus(i,1));
        % PQ.con(j,4)=s.PL(i,step)/baseMVA;
        % PQ.con(j,5)=s.QL(i,step)/baseMVA;
        PQ.con(j,4)=s.PL(i,493)/baseMVA;
        PQ.con(j,5)=s.QL(i,493)/baseMVA;
    end
kk=step;
    try
    matlab.io.saveVariablesToScript('d_new1.m',{'Bus','Line','SW','PV','Fault','Breaker','PQ','Syn','Tg','Exc'});
        % matlab.io.saveVariablesToScript('d_009_new.m',{'Bus','Line','Breaker','Fault','SW','PV','PQ','Syn','Tg','Exc'});
    filename='d_new1.m';filename_new='d_new1.m';

    modifyfile(filename,filename_new);
    catch
        fprintf('跳过文件: %s（无法打开或修改）\n', filename);
        ineffective(kk,:)=1;
        continue;  % 跳过当前文件
    end
    initpsat;
    runpsat('d_new1','data');
    Settings.tf=50;
    all_time1=Settings.tf;
    Settings.fixt=1;
    Settings.tstep=0.05;

%     Settings.plot=1;
    runpsat('pf');

Bus.Pg(Gen_num,:)
% %    
%     %闃诲凹姣旇绠?
   % if Settings.idAVR==1&&Settings.idTG==1
    % if Settings.idTG==1
   time_pf(kk,:)=Settings.lftime;
   [buss,ordbus] = sort(Bus.names(1:end));
   Saveopt.theta(:,kk) = DAE.y(ordbus);
   Saveopt.Vs(:,kk) = DAE.y(ordbus+Bus.n);
   Saveopt.Gen_V(:,kk)=Saveopt.Vs(Gen_num,kk);
   Saveopt.Gen_P(:,kk)=Bus.Pg(Gen_num,:);
   Saveopt.Load_P(:,kk)=Bus.Pl(Load_num,:);
   Saveopt.Load_Q(:,kk)=Bus.Ql(Load_num,:);
   
   Saveopt.n(:,kk)=step;
   V =DAE.y(ordbus+Bus.n);
   Pm(:,kk) =Bus.Pg(gen_bus,:);
   E(:,kk)=DAE.y(2*nbus+1+4*(0:ngen-1));
   % runpsat('sssa')
   % rei=real(SSSA.eigs);
   % sun=find( rei>0);
   % sssa_save{kk}=SSSA.eigs;
   % unpf=SSSA.pf(:,sun);
   % [mpf idx_max]=max(unpf);
   %    if ~isempty(sun)
   %        if any(idx_max<10)
   %        continue
   %        end
   %    end
% % 假设 SSSA.eigs 是特征值向量
% % 替换为您的实际特征值数据，例如：eigs = [-1+2i; -1-2i; -0.5; ...];
% % eigs = SSSA.eigs(sun,:); % 请替换为实际数据
% eigs = SSSA.eigs;
% % 初始化结果数组
% n = length(eigs);
% damping_ratio = zeros(n, 1); % 阻尼比
% frequency = zeros(n, 1);     % 频率（Hz）
% 
% for i = 1:n
%     % 提取实部和虚部
%     sigma = real(eigs(i)); % 实部
%     omega = imag(eigs(i)); % 虚部
% 
%     % 计算模（magnitude）
%     mag = sqrt(sigma^2 + omega^2);
% 
%     % 计算阻尼比
%     if mag ~= 0 % 避免除以零
%         damping_ratio(i) = -sigma / mag;
%     else
%         damping_ratio(i) = 1; % 纯实数特征值，阻尼比设为1
%     end
% 
%     % 计算振荡频率（Hz）
%     frequency(i) = abs(omega) / (2 * pi); % 绝对值确保频率为正
% end



runpsat('td');

delta1=DAE.trajectory(nd,:)-DAE.trajectory(nsw,:);
% delta=DAE.state(nd,:)-DAE.state(nsw,:);
% delta_s=delta(:,1);
omega1= DAE.trajectory(nw, :)-DAE.trajectory(nw, 1);
delta_set1{kk} = delta1;
omega_set1{kk} = omega1;
time_set1{kk} = DAE.tend;
time_td1(kk,:)=DAE.toc;
time_simulation1(kk,:)=time_pf(kk,:)+time_td1(kk,:);



% 
% figure
% plot(DAE.tend,delta1-delta1(:,1))
% figure
% plot(DAE.tend,omega1-omega1(:,1))
% ylim([-0.6 0.2])
% clear Bus Line Breaker Fault SW PV PQ Syn Tg Exc 
% DAE.trajectory=[];DAE.tend=[];DAE.toc=[];
% eval('d_new1')
% Fault.con(1,6)=0.6;
%  try
%     matlab.io.saveVariablesToScript('d_new2.m',{'Bus','Line','Fault','SW','PV','PQ','Syn'});
%         % matlab.io.saveVariablesToScript('d_009_new.m',{'Bus','Line','Breaker','Fault','SW','PV','PQ','Syn','Tg','Exc'});
%     filename='d_new2.m';filename_new='d_new2.m';
% 
%     modifyfile(filename,filename_new);
%     catch
%         fprintf('跳过文件: %s（无法打开或修改）\n', filename);
%         ineffective(kk,:)=1;
%         continue;  % 跳过当前文件
%  end
%     Settings.tf=2;
%% 
%     all_time2=Settings.tf;
%     Settings.fixt=1;
%     Settings.tstep=0.05;
%     runpsat('d_new2','td');
% 
% delta2=DAE.trajectory(nd,:)-DAE.trajectory(nsw,:);
% % delta=DAE.state(nd,:)-DAE.state(nsw,:);
% % delta_s=delta(:,1);
% omega2 = DAE.trajectory(nw, :)-DAE.trajectory(nw, 1);
% delta_set2{kk} = delta2;
% omega_set2{kk} = omega2;
% time_set2{kk} = DAE.tend;
% time_td2(kk,:)=DAE.toc;
% time_simulation2(kk,:)=time_pf(kk,:)+time_td2(kk,:);
end
save('simulation_data_14_493_breaker_1003_2.mat');
