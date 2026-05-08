function [results_rate, results_time] = run_single_benchmark(M, K, N, P_tx, ...
    noise_var, epsilon, num_trials, max_iter_AO, pop_size, max_gen, ...
    PL_BU, PL_RU, PL_BR)
    % Executes Monte Carlo trials across algorithms using parallel computing
    % 
    % Input:
    %   PL_BU, PL_RU, PL_BR - Path loss coefficients (pre-computed)
    
    results_rate = zeros(num_trials, 4); 
    results_time = zeros(num_trials, 4);
    I_K = eye(K); 
    
    parfor trial = 1:num_trials
        trial_rates = zeros(1, 4);
        trial_times = zeros(1, 4);
        
        % Channel Realizations: Rayleigh fading + Path Loss
        Hd = sqrt(PL_BU/2) * (randn(K, M) + 1j*randn(K, M)); 
        Hr = sqrt(PL_RU/2) * (randn(K, N) + 1j*randn(K, N)); 
        G  = sqrt(PL_BR/2) * (randn(N, M) + 1j*randn(N, M)); 
        
        theta_0 = 2 * pi * rand(N, 1); 
        
        % --- Algorithm 1: BCD-AO ---
        t0 = tic; 
        th_ao = theta_0;
        for it = 1:max_iter_AO
            H_eq = Hd + Hr * (exp(1j * th_ao) .* G); 
            W_u = H_eq' / (H_eq * H_eq' + epsilon * I_K);
            W = sqrt(P_tx / max(trace(W_u' * W_u), eps)) * W_u; 
            C = H_eq * (W * W');
            Cascaded_Gradient_diag = sum(Hr' .* (C * G').', 2); 
            th_new = angle(Cascaded_Gradient_diag);
            
            % Early stopping
            if norm(exp(1j*th_new) - exp(1j*th_ao), 'fro') < 1e-4
                th_ao = th_new;
                break;
            end
            th_ao = th_new;
        end
        trial_rates(1) = compute_sum_rate(th_ao, Hd, Hr, G, P_tx, noise_var, epsilon, I_K); 
        trial_times(1) = toc(t0);
        
        % --- Algorithm 2: Manifold Optimization (Gradient Descent) ---
        t1 = tic; 
        th_mo = theta_0; 
        step = 0.1;
        prev_rate = -inf;
        
        for it = 1:max_iter_AO
            base = compute_sum_rate(th_mo, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
            
            % Check convergence
            if abs(base - prev_rate) < 1e-4
                break;
            end
            prev_rate = base;
            
            % Compute gradient (sample for large N)
            N_grad = min(N, 200);  % Sample at most 200 elements
            gr = zeros(N, 1);
            for n = 1:N_grad
                tmp = th_mo; 
                tmp(n) = mod(tmp(n) + 1e-4, 2*pi);
                gr(n) = (compute_sum_rate(tmp, Hd, Hr, G, P_tx, noise_var, epsilon, I_K) - base) / 1e-4;
            end
            
            % Gradient ascent (positive gradient increases rate)
            th_mo = mod(th_mo + step * gr, 2*pi);
        end
        trial_rates(2) = compute_sum_rate(th_mo, Hd, Hr, G, P_tx, noise_var, epsilon, I_K); 
        trial_times(2) = toc(t1);
        
        % --- Algorithm 3: Particle Swarm Optimization (PSO) ---
        t2 = tic; 
        p_pso = mod(repmat(theta_0, 1, pop_size) + 0.1*randn(N, pop_size), 2*pi);
        v = zeros(N, pop_size); 
        pb = p_pso; 
        pb_v = zeros(1, pop_size);
        
        for p = 1:pop_size
            pb_v(p) = compute_sum_rate(p_pso(:,p), Hd, Hr, G, P_tx, noise_var, epsilon, I_K); 
        end
        [gb_v, idx] = max(pb_v); 
        gb = pb(:, idx);
        
        for g = 1:max_gen
            v = 0.7*v + 1.5*rand(N, pop_size).*(pb - p_pso) + 1.5*rand(N, pop_size).*(gb - p_pso);
            p_pso = mod(p_pso + v, 2*pi);
            
            for p = 1:pop_size
                val = compute_sum_rate(p_pso(:,p), Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
                if val > pb_v(p)
                    pb(:,p) = p_pso(:,p); 
                    pb_v(p) = val;
                    if val > gb_v
                        gb_v = val; 
                        gb = p_pso(:,p);
                    end
                end
            end
        end
        trial_rates(3) = gb_v; 
        trial_times(3) = toc(t2);
        
        % --- Algorithm 4: Genetic Algorithm (GA) ---
        t3 = tic; 
        p_ga = mod(repmat(theta_0, 1, pop_size) + 0.1*randn(N, pop_size), 2*pi);
        g_best_r = -inf; 
        g_best_theta = theta_0;
        
        for g = 1:max_gen
            fit = zeros(1, pop_size);
            for p = 1:pop_size
                fit(p) = compute_sum_rate(p_ga(:,p), Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
                if fit(p) > g_best_r
                    g_best_r = fit(p);
                    g_best_theta = p_ga(:,p);
                end
            end
            
            % Elitism: keep top 10%
            [~, s_i] = sort(fit, 'descend'); 
            elite_cnt = max(2, round(pop_size * 0.1));
            n_p = zeros(N, pop_size); 
            n_p(:, 1:elite_cnt) = p_ga(:, s_i(1:elite_cnt)); 
            
            % Crossover
            for p = (elite_cnt+1):pop_size
                p1 = p_ga(:, s_i(randi(pop_size/2))); 
                p2 = p_ga(:, s_i(randi(pop_size/2)));
                cp = randi(N-1); 
                n_p(:, p) = [p1(1:cp); p2(cp+1:end)];
            end
            
            % Mutation
            m_mask = rand(N, pop_size) < 0.05; 
            n_p(m_mask) = 2*pi*rand(sum(m_mask(:)), 1);
            p_ga = n_p;
        end
        trial_rates(4) = g_best_r; 
        trial_times(4) = toc(t3);
        
        results_rate(trial, :) = trial_rates;
        results_time(trial, :) = trial_times;
    end
end

function rate = compute_sum_rate(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    % Compute sum rate with MMSE beamforming
    theta = theta(:);
    H_eq = Hd + Hr * (exp(1j * theta) .* G);
    W_mmse = H_eq' / (H_eq * H_eq' + epsilon * I_K);
    power_norm = trace(W_mmse' * W_mmse);
    W = sqrt(P_tx / max(power_norm, eps)) * W_mmse;
    HW = H_eq * W;
    signal_power = abs(diag(HW)).^2;
    interference_power = max(sum(abs(HW).^2, 2) - signal_power, 1e-10);
    SINR = signal_power ./ (interference_power + noise_var);
    rate = sum(log2(1 + SINR));
end