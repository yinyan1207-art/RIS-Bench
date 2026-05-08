% =========================================================================
% RIS Benchmark Suite - 3D Visuals & Full Experiments (CSI + 1-bit + CSV)
% =========================================================================
clear; clc; close all; rng(2024);

% Figure settings
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultFigureColor', 'w');

% 安全创建输出文件夹
out_dir = fullfile(pwd, 'figures');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% 1. System Parameters
M = 32; K = 16; N = 512;
P_tx_dBm = 30; P_tx = 10^((P_tx_dBm - 30)/10); 
noise_dBm = -100; noise_var = 10^((noise_dBm - 30)/10); 
epsilon = K * noise_var / P_tx; 

num_trials = 100;
max_iter_AO = 30; pop_size = 50; max_gen = 50;

labels = {'AO-MMSE', 'MO-PGD', 'PSO', 'GA'};
colors = [0.000 0.447 0.741; 0.850 0.325 0.098; 0.929 0.694 0.125; 0.466 0.674 0.188];

channel_type = 'rayleigh'; K_factor = 3;
PL_BR = (50)^(-2.2) * 10^(-3);
PL_RU = (10)^(-2.8) * 10^(-3);
PL_BU = (60)^(-3.5) * 10^(-3);

disp('=== Advanced Visualization Suite Started ===');

%% =======================================================================
% Fig.1: 3D Wall + Line Plot for Runtime
% =======================================================================
disp('Generating Fig.1 (3D Wall Plot)...');
N_vec = [32, 64, 128, 256, 512]; 
time_mean = zeros(length(N_vec), 4);

for n_idx = 1:length(N_vec)
    [~, t_tmp] = run_bench(M, K, N_vec(n_idx), P_tx, noise_var, epsilon, 10, max_iter_AO, pop_size, max_gen, PL_BU, PL_RU, PL_BR, channel_type, K_factor);
    time_mean(n_idx, :) = mean(t_tmp, 1);
end

fig1 = figure('Position', [100, 100, 600, 500]);
ax1 = axes('Parent', fig1); hold(ax1, 'on'); grid(ax1, 'on'); view(ax1, [-40, 25]);
min_z = 1e-3; 

for i = 1:4
    x = N_vec; y = i * ones(size(x)); z = time_mean(:, i)';
    fill3([x, fliplr(x)], [y, y], [min_z*ones(size(z)), fliplr(z)], colors(i,:), 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot3(x, y, z, '-o', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), 'DisplayName', labels{i});
    for j = 1:length(x)
        plot3([x(j) x(j)], [y(j) y(j)], [min_z z(j)], '--', 'Color', [colors(i,:) 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
    end
end

set(ax1, 'YTick', 1:4, 'YTickLabel', labels, 'XScale', 'log', 'ZScale', 'log', 'FontSize', 11);
xlabel(ax1, 'Number of Elements $N$'); zlabel(ax1, 'Execution Time (s)');
export_fig(fig1, 'Fig1_3D_Runtime', out_dir);
writematrix([N_vec', time_mean], fullfile(out_dir, 'Data_Runtime.csv'));

%% =======================================================================
% Fig.2: Gradient Polar Rose Chart
% =======================================================================
disp('Generating Fig.2 (Polar Rose Chart)...');
K_vec = [4, 8, 16, 24, 32]; 
rate_mean = zeros(length(K_vec), 4);

for k_idx = 1:length(K_vec)
    [r_tmp, ~] = run_bench(M, K_vec(k_idx), N, P_tx, noise_var, epsilon, 10, max_iter_AO, pop_size, max_gen, PL_BU, PL_RU, PL_BR, channel_type, K_factor);
    rate_mean(k_idx, :) = mean(r_tmp, 1);
end

fig2 = figure('Position', [720, 100, 600, 550], 'Color', 'w');
ax2 = axes('Parent', fig2); axis(ax2, 'equal'); hold(ax2, 'on'); axis(ax2, 'off');
num_groups = length(K_vec); num_bars = 4; gap_group = 0.15; gap_bar = 0.02;
angle_per_group = 2*pi / num_groups; bar_angle = (angle_per_group - gap_group - (num_bars-1)*gap_bar) / num_bars;
max_rate = max(rate_mean, [], 'all');

for r_grid = linspace(0, max_rate, 5)
    t_grid = linspace(0, 2*pi, 100);
    plot(ax2, r_grid*cos(t_grid), r_grid*sin(t_grid), '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
end

current_angle = 0;
for k = 1:num_groups
    for a = 1:num_bars
        r = rate_mean(k, a); t_start = current_angle; t_end = current_angle + bar_angle;
        t_patch = [linspace(t_start, t_end, 20), t_end, t_start]; r_patch = [r*ones(1,20), 0, 0];
        patch(ax2, r_patch.*cos(t_patch), r_patch.*sin(t_patch), colors(a,:), 'FaceAlpha', 0.6 + 0.4*(k/num_groups), 'EdgeColor', 'w', 'LineWidth', 1);
        current_angle = current_angle + bar_angle + gap_bar;
    end
    label_angle = current_angle - (num_bars*(bar_angle+gap_bar))/2; text_r = max_rate * 1.15;
    text(text_r*cos(label_angle), text_r*sin(label_angle), sprintf('K=%d', K_vec(k)), 'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    current_angle = current_angle + gap_group;
end

for a = 1:4, plot(ax2, NaN, NaN, 's', 'MarkerFaceColor', colors(a,:), 'MarkerEdgeColor', 'none', 'DisplayName', labels{a}); end
legend(ax2, 'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 11);
export_fig(fig2, 'Fig2_Polar_Scalability', out_dir);
writematrix([K_vec', rate_mean], fullfile(out_dir, 'Data_Scalability.csv'));

%% =======================================================================
% Fig.3: CSI Robustness (3D Floating Style)
% =======================================================================
disp('Generating Fig.3 (3D CSI Robustness)...');
sigma_e2_vec = [0, 0.05, 0.1, 0.15]; 
csi_rates = zeros(length(sigma_e2_vec), 4);

for err_idx = 1:length(sigma_e2_vec)
    r_tmp = run_csi(M, K, N, P_tx, noise_var, epsilon, 10, max_iter_AO, pop_size, max_gen, PL_BU, PL_RU, PL_BR, sigma_e2_vec(err_idx), channel_type, K_factor);
    csi_rates(err_idx, :) = mean(r_tmp, 1);
end

fig3 = figure('Position', [100, 680, 550, 450]);
ax3 = axes('Parent', fig3); hold(ax3, 'on'); grid(ax3, 'on'); view(ax3, [-30, 25]);
x_steps = 1:length(sigma_e2_vec);
min_csi_rate = min(csi_rates, [], 'all') - 5;

for i = 1:4
    y = i * ones(1, length(x_steps)); z = csi_rates(:, i)';
    plot3(ax3, x_steps, y, z, '-', 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', labels{i});
    scatter3(ax3, x_steps, y, z, 40, colors(i,:), 'filled', 'HandleVisibility', 'off');
    for j = 1:length(x_steps)
        plot3(ax3, [x_steps(j) x_steps(j)], [y(j) y(j)], [min_csi_rate z(j)], '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end

set(ax3, 'XTick', x_steps, 'XTickLabel', sigma_e2_vec, 'YTick', 1:4, 'YTickLabel', labels, 'FontSize', 11);
xlabel(ax3, 'CSI Error Variance $\sigma_e^2$'); zlabel(ax3, 'Sum Rate (bps/Hz)');
export_fig(fig3, 'Fig3_3D_CSI_Robustness', out_dir);
writematrix([sigma_e2_vec', csi_rates], fullfile(out_dir, 'Data_CSI.csv'));

%% =======================================================================
% Fig.4: 3D Convergence Trajectory
% =======================================================================
disp('Generating Fig.4 (3D Convergence)...');
[h_ao, h_mo, h_pso, h_ga] = track_convergence(M, K, N, P_tx, noise_var, epsilon, max_iter_AO, pop_size, max_gen, PL_BU, PL_RU, PL_BR, channel_type, K_factor);

fig4 = figure('Position', [680, 680, 550, 450]);
ax4 = axes('Parent', fig4); hold(ax4, 'on'); grid(ax4, 'on'); view(ax4, [-30, 25]);
max_steps = 50; x_steps = 1:max_steps;
h_ao_pad = [h_ao, h_ao(end)*ones(1, max_steps - length(h_ao))];
h_mo_pad = [h_mo, h_mo(end)*ones(1, max_steps - length(h_mo))];
all_hists = {h_ao_pad, h_mo_pad, h_pso, h_ga};

for i = 1:4
    y = i * ones(1, max_steps); z = all_hists{i};
    plot3(ax4, x_steps, y, z, '-', 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', labels{i});
    idx_markers = 1:5:max_steps;
    scatter3(ax4, x_steps(idx_markers), y(idx_markers), z(idx_markers), 30, colors(i,:), 'filled', 'HandleVisibility', 'off');
    plot3(ax4, [max_steps max_steps], [i i], [min(h_pso) z(end)], '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
end

set(ax4, 'YTick', 1:4, 'YTickLabel', labels, 'FontSize', 11);
xlabel(ax4, 'Iteration / Generation'); zlabel(ax4, 'Sum Rate (bps/Hz)');
export_fig(fig4, 'Fig4_3D_Convergence', out_dir);
writematrix([h_ao_pad', h_mo_pad', h_pso', h_ga'], fullfile(out_dir, 'Data_Convergence.csv'));

%% =======================================================================
% TABLE II: 1-Bit Quantization Test
% =======================================================================
disp('Running 1-Bit Quantization Test (Output to CSV)...');
q_rates_cont = zeros(20, 2); % 20 trials, AO & GA
q_rates_1bit = zeros(20, 2); 

for t = 1:20
    Hd = gen_ch(K, M, PL_BU, channel_type, K_factor); 
    Hr = gen_ch(K, N, PL_RU, channel_type, K_factor); 
    G  = gen_ch(N, M, PL_BR, channel_type, K_factor); 
    I_K = eye(K); th0 = 2 * pi * rand(N, 1);
    
    % Continuous AO
    th = th0;
    for it = 1:max_iter_AO
        H_eq = Hd + Hr * (exp(1j * th) .* G); W_u = H_eq' / (H_eq * H_eq' + epsilon * I_K);
        C = H_eq * ((sqrt(P_tx / max(norm(W_u, 'fro')^2, eps)) * W_u) * (sqrt(P_tx / max(norm(W_u, 'fro')^2, eps)) * W_u)');
        th_new = angle(sum(Hr' .* (C * G').', 2));
        if norm(exp(1j*th_new) - exp(1j*th), 'fro') < 1e-3, th = th_new; break; end
        th = th_new;
    end
    r_ao_cont = get_rate(th, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
    
    % 1-Bit AO (Quantized mapping to 0 or pi)
    th_1bit = sign(cos(th)) * pi/2 + pi/2 * (1 - sign(cos(th)));
    r_ao_1b = get_rate(th_1bit, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
    
    % Continuous GA
    p_ga = mod(repmat(th0, 1, pop_size) + 0.1*randn(N, pop_size), 2*pi); g_best = -inf;
    for g = 1:max_gen
        fit = zeros(1, pop_size);
        for p = 1:pop_size, fit(p) = get_rate(p_ga(:,p), Hd, Hr, G, P_tx, noise_var, epsilon, I_K); if fit(p) > g_best, g_best = fit(p); end; end
        [~, s_i] = sort(fit, 'descend'); n_p = zeros(N, pop_size); n_p(:, 1:5) = p_ga(:, s_i(1:5));
        for p = 6:pop_size, cp = randi(N-1); n_p(:, p) = [p_ga(1:cp, s_i(randi(25))); p_ga(cp+1:end, s_i(randi(25)))]; end
        mut = rand(N, pop_size) < 0.05; n_p(mut) = 2*pi*rand(sum(mut(:)), 1); p_ga = n_p;
    end
    r_ga_cont = g_best;
    
    % 1-bit GA
    p_ga_1b = sign(cos(p_ga(:,1))) * pi/2 + pi/2 * (1 - sign(cos(p_ga(:,1))));
    r_ga_1b = get_rate(p_ga_1b, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
    
    q_rates_cont(t, :) = [r_ao_cont, r_ga_cont];
    q_rates_1bit(t, :) = [r_ao_1b, r_ga_1b];
end

avg_cont = mean(q_rates_cont, 1);
avg_1bit = mean(q_rates_1bit, 1);
fprintf('--- Table II Results ---\n');
fprintf('Continuous - AO: %.2f | GA: %.2f\n', avg_cont(1), avg_cont(2));
fprintf('1-Bit Quantized - AO: %.2f | GA: %.2f\n', avg_1bit(1), avg_1bit(2));
writematrix([avg_cont; avg_1bit], fullfile(out_dir, 'Data_1Bit_Table.csv'));
disp('=== All Experiments, CSVs, and PDF figures generated successfully! ===');

%% =========================================================================
% CORE FUNCTIONS
% =========================================================================
function H = gen_ch(dim1, dim2, PL, type, K_factor)
    if strcmp(type, 'rayleigh')
        H = sqrt(PL/2) * (randn(dim1, dim2) + 1j*randn(dim1, dim2));
    else
        K_lin = 10^(K_factor/10); s = sqrt(K_lin / (K_lin + 1)); sig = sqrt(1 / (2*(K_lin + 1)));
        H = sqrt(PL) * (s * ones(dim1, dim2) + sig * (randn(dim1, dim2) + 1j*randn(dim1, dim2)));
    end
end

function rate = get_rate(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    H_eq = Hd + Hr * (exp(1j * theta(:)) .* G);
    W_u = H_eq' / (H_eq * H_eq' + epsilon * I_K);
    W = sqrt(P_tx / max(norm(W_u, 'fro')^2, eps)) * W_u;
    HW = H_eq * W;
    sig_pwr = abs(diag(HW)).^2;
    int_pwr = max(sum(abs(HW).^2, 2) - sig_pwr, 0);
    rate = sum(log2(1 + sig_pwr ./ (int_pwr + noise_var + eps)));
end

function [r_out, t_out] = run_bench(M, K, N, P_tx, noise_var, epsilon, num_trials, max_iter, pop_size, max_gen, PL_BU, PL_RU, PL_BR, type, K_fac)
    r_out = zeros(num_trials, 4); t_out = zeros(num_trials, 4); I_K = eye(K); 
    parfor t = 1:num_trials
        Hd = gen_ch(K, M, PL_BU, type, K_fac); Hr = gen_ch(K, N, PL_RU, type, K_fac); G = gen_ch(N, M, PL_BR, type, K_fac); th0 = 2*pi*rand(N,1); 
        
        t0=tic; th=th0;
        for it=1:max_iter
            H_eq=Hd+Hr*(exp(1j*th).*G); W_u=H_eq'/(H_eq*H_eq'+epsilon*I_K);
            C=H_eq*((sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)*(sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)');
            th_new=angle(sum(Hr'.*(C*G').',2)); if norm(exp(1j*th_new)-exp(1j*th),'fro')<1e-3, th=th_new; break; end; th=th_new;
        end
        r1=get_rate(th,Hd,Hr,G,P_tx,noise_var,epsilon,I_K); t1=toc(t0);
        
        t02=tic; th_m=th0; % MO: Simplified Manifold Gradient Descent Proxy
        for it=1:max_iter
            base=get_rate(th_m,Hd,Hr,G,P_tx,noise_var,epsilon,I_K); grad=zeros(N,1);
            for n=1:min(N,100), tmp=th_m; tmp(n)=mod(tmp(n)+1e-3,2*pi); grad(n)=(get_rate(tmp,Hd,Hr,G,P_tx,noise_var,epsilon,I_K)-base)/1e-3; end
            th_new=mod(th_m+0.5*grad,2*pi); if norm(exp(1j*th_new)-exp(1j*th_m),'fro')<1e-3, th_m=th_new; break; end; th_m=th_new;
        end
        r2=get_rate(th_m,Hd,Hr,G,P_tx,noise_var,epsilon,I_K); t2=toc(t02);
        
        t03=tic; p_pso=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); v=zeros(N,pop_size); pb=p_pso; pb_v=zeros(1,pop_size);
        for p=1:pop_size, pb_v(p)=get_rate(p_pso(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); end
        [gb_v,idx]=max(pb_v); gb=pb(:,idx);
        for g=1:max_gen
            v=0.5*v+1.5*rand(N,pop_size).*(pb-p_pso)+1.5*rand(N,pop_size).*(gb-p_pso); p_pso=mod(p_pso+v,2*pi);
            for p=1:pop_size, val=get_rate(p_pso(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); if val>pb_v(p), pb(:,p)=p_pso(:,p); pb_v(p)=val; if val>gb_v, gb_v=val; gb=p_pso(:,p); end; end; end
        end
        r3=gb_v; t3=toc(t03);
        
        t04=tic; p_ga=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); g_best=-inf;
        for g=1:max_gen
            fit=zeros(1,pop_size); for p=1:pop_size, fit(p)=get_rate(p_ga(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); if fit(p)>g_best, g_best=fit(p); end; end
            [~,s_i]=sort(fit,'descend'); n_p=zeros(N,pop_size); n_p(:,1:5)=p_ga(:,s_i(1:5));
            for p=6:pop_size, cp=randi(N-1); n_p(:,p)=[p_ga(1:cp,s_i(randi(25))); p_ga(cp+1:end,s_i(randi(25)))]; end
            mut=rand(N,pop_size)<0.05; n_p(mut)=2*pi*rand(sum(mut(:)),1); p_ga=n_p;
        end
        r4=g_best; t4=toc(t04);
        r_out(t,:)=[r1,r2,r3,r4]; t_out(t,:)=[t1,t2,t3,t4];
    end
end

function r_out = run_csi(M, K, N, P_tx, noise_var, epsilon, num_trials, max_iter, pop_size, max_gen, PL_BU, PL_RU, PL_BR, sigma_e2, type, K_fac)
    r_out=zeros(num_trials,4); I_K=eye(K); c1=sqrt(1-sigma_e2); c2=sqrt(sigma_e2);
    for t=1:num_trials
        Hd_t=gen_ch(K,M,PL_BU,type,K_fac); Hr_t=gen_ch(K,N,PL_RU,type,K_fac); G_t=gen_ch(N,M,PL_BR,type,K_fac);
        Hd_e=c1*Hd_t+c2*gen_ch(K,M,PL_BU,type,K_fac); Hr_e=c1*Hr_t+c2*gen_ch(K,N,PL_RU,type,K_fac); G_e=c1*G_t+c2*gen_ch(N,M,PL_BR,type,K_fac); th0=2*pi*rand(N,1);
        
        th=th0;
        for it=1:max_iter
            H_eq_e=Hd_e+Hr_e*(exp(1j*th).*G_e); W_u=H_eq_e'/(H_eq_e*H_eq_e'+epsilon*I_K);
            C=H_eq_e*((sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)*(sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)');
            th_new=angle(sum(Hr_e'.*(C*G_e').',2)); if norm(exp(1j*th_new)-exp(1j*th),'fro')<1e-3, th=th_new; break; end; th=th_new;
        end
        r_ao=get_rate(th,Hd_t,Hr_t,G_t,P_tx,noise_var,epsilon,I_K);
        
        th_m=th0;
        for it=1:max_iter
            base=get_rate(th_m,Hd_e,Hr_e,G_e,P_tx,noise_var,epsilon,I_K); grad=zeros(N,1);
            for n=1:min(N,50), tmp=th_m; tmp(n)=mod(tmp(n)+1e-3,2*pi); grad(n)=(get_rate(tmp,Hd_e,Hr_e,G_e,P_tx,noise_var,epsilon,I_K)-base)/1e-3; end
            th_new=mod(th_m+0.5*grad,2*pi); if norm(exp(1j*th_new)-exp(1j*th_m),'fro')<1e-3, th_m=th_new; break; end; th_m=th_new;
        end
        r_mo=get_rate(th_m,Hd_t,Hr_t,G_t,P_tx,noise_var,epsilon,I_K);
        
        p_pso=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); v=zeros(N,pop_size); pb=p_pso; pb_v=zeros(1,pop_size);
        for p=1:pop_size, pb_v(p)=get_rate(p_pso(:,p),Hd_e,Hr_e,G_e,P_tx,noise_var,epsilon,I_K); end
        [gb_v,idx]=max(pb_v); gb=pb(:,idx);
        for g=1:max_gen
            v=0.5*v+1.5*rand(N,pop_size).*(pb-p_pso)+1.5*rand(N,pop_size).*(gb-p_pso); p_pso=mod(p_pso+v,2*pi);
            for p=1:pop_size, val=get_rate(p_pso(:,p),Hd_e,Hr_e,G_e,P_tx,noise_var,epsilon,I_K); if val>pb_v(p), pb(:,p)=p_pso(:,p); pb_v(p)=val; if val>gb_v, gb_v=val; gb=p_pso(:,p); end; end; end
        end
        r_pso=get_rate(gb,Hd_t,Hr_t,G_t,P_tx,noise_var,epsilon,I_K);
        
        p_ga=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); g_best=-inf;
        for g=1:max_gen
            fit=zeros(1,pop_size); for p=1:pop_size, fit(p)=get_rate(p_ga(:,p),Hd_e,Hr_e,G_e,P_tx,noise_var,epsilon,I_K); if fit(p)>g_best, g_best=fit(p); end; end
            [~,s_i]=sort(fit,'descend'); n_p=zeros(N,pop_size); n_p(:,1:5)=p_ga(:,s_i(1:5));
            for p=6:pop_size, cp=randi(N-1); n_p(:,p)=[p_ga(1:cp,s_i(randi(25))); p_ga(cp+1:end,s_i(randi(25)))]; end
            mut=rand(N,pop_size)<0.05; n_p(mut)=2*pi*rand(sum(mut(:)),1); p_ga=n_p;
        end
        r_out(t,:)=[r_ao,r_mo,r_pso,g_best];
    end
end

function [h_ao, h_mo, h_pso, h_ga] = track_convergence(M, K, N, P_tx, noise_var, epsilon, max_iter, pop_size, max_gen, PL_BU, PL_RU, PL_BR, type, K_fac)
    Hd=gen_ch(K,M,PL_BU,type,K_fac); Hr=gen_ch(K,N,PL_RU,type,K_fac); G=gen_ch(N,M,PL_BR,type,K_fac); I_K=eye(K); th0=2*pi*rand(N,1);
    
    h_ao=zeros(1,max_iter); th=th0;
    for it=1:max_iter
        H_eq=Hd+Hr*(exp(1j*th).*G); W_u=H_eq'/(H_eq*H_eq'+epsilon*I_K);
        C=H_eq*((sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)*(sqrt(P_tx/max(norm(W_u,'fro')^2,eps))*W_u)');
        th_new=angle(sum(Hr'.*(C*G').',2)); h_ao(it)=get_rate(th_new,Hd,Hr,G,P_tx,noise_var,epsilon,I_K);
        if norm(exp(1j*th_new)-exp(1j*th),'fro')<1e-3, h_ao(it:end)=h_ao(it); break; end; th=th_new;
    end
    
    h_mo=zeros(1,max_iter); th_m=th0;
    for it=1:max_iter
        base=get_rate(th_m,Hd,Hr,G,P_tx,noise_var,epsilon,I_K); grad=zeros(N,1);
        for n=1:min(N,100), tmp=th_m; tmp(n)=mod(tmp(n)+1e-3,2*pi); grad(n)=(get_rate(tmp,Hd,Hr,G,P_tx,noise_var,epsilon,I_K)-base)/1e-3; end
        th_new=mod(th_m+0.5*grad,2*pi); h_mo(it)=get_rate(th_new,Hd,Hr,G,P_tx,noise_var,epsilon,I_K);
        if norm(exp(1j*th_new)-exp(1j*th_m),'fro')<1e-3, h_mo(it:end)=h_mo(it); break; end; th_m=th_new;
    end
    
    h_pso=zeros(1,max_gen); p_pso=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); v=zeros(N,pop_size); pb=p_pso; pb_v=zeros(1,pop_size);
    for p=1:pop_size, pb_v(p)=get_rate(p_pso(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); end
    [gb_v,idx]=max(pb_v); gb=pb(:,idx);
    for g=1:max_gen
        v=0.5*v+1.5*rand(N,pop_size).*(pb-p_pso)+1.5*rand(N,pop_size).*(gb-p_pso); p_pso=mod(p_pso+v,2*pi);
        for p=1:pop_size, val=get_rate(p_pso(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); if val>pb_v(p), pb(:,p)=p_pso(:,p); pb_v(p)=val; if val>gb_v, gb_v=val; gb=p_pso(:,p); end; end; end
        h_pso(g)=gb_v;
    end
    
    h_ga=zeros(1,max_gen); p_ga=mod(repmat(th0,1,pop_size)+0.1*randn(N,pop_size),2*pi); g_best=-inf;
    for g=1:max_gen
        fit=zeros(1,pop_size); for p=1:pop_size, fit(p)=get_rate(p_ga(:,p),Hd,Hr,G,P_tx,noise_var,epsilon,I_K); if fit(p)>g_best, g_best=fit(p); end; end; h_ga(g)=g_best;
        [~,s_i]=sort(fit,'descend'); n_p=zeros(N,pop_size); n_p(:,1:5)=p_ga(:,s_i(1:5));
        for p=6:pop_size, cp=randi(N-1); n_p(:,p)=[p_ga(1:cp,s_i(randi(25))); p_ga(cp+1:end,s_i(randi(25)))]; end
        mut=rand(N,pop_size)<0.05; n_p(mut)=2*pi*rand(sum(mut(:)),1); p_ga=n_p;
    end
end

function export_fig(fig_handle, filename, out_dir)
    exportgraphics(fig_handle, fullfile(out_dir, [filename, '.pdf']), 'ContentType', 'vector');
end