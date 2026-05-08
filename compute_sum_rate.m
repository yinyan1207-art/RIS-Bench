function rate = compute_sum_rate(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    % Evaluates the MU-MISO sum rate under R-ZF precoding.
    sinr = compute_sinr_core(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
    rate = sum(log2(1 + sinr));
end

function user_rates = compute_user_rates(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    % Evaluates individual user rates (returns K x 1 vector)
    sinr = compute_sinr_core(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K);
    user_rates = log2(1 + sinr);
end

function sinr = compute_sinr_core(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    % Core engine to compute SINR efficiently
    theta = theta(:); 
    
    % Equivalent Channel
    H_eq = Hd + Hr * (exp(1j * theta) .* G); 
    
    % R-ZF Precoding
    W_unnorm = H_eq' / (H_eq * H_eq' + epsilon * I_K);
    
    % Robust & Efficient Power Normalization
    power_unnorm = sum(abs(W_unnorm(:)).^2); % Faster than trace(W'*W)
    W = sqrt(P_tx / max(power_unnorm, eps)) * W_unnorm;
    
    % Effective Received Signal
    HW = H_eq * W;                   
    HW_abs_sq = abs(HW).^2;          
    
    signal_power = diag(HW_abs_sq);  
    total_power = sum(HW_abs_sq, 2); 
    
    % Interference
    interference_power = max(total_power - signal_power, 0); 
    
    % SINR
    sinr = signal_power ./ (interference_power + noise_var);
end

function theta_q = quantize_phase(theta, bits)
    % Quantizes continuous phases to discrete hardware levels
    if isinf(bits)
        theta_q = theta;
    else
        L = 2^bits;
        step = 2*pi / L;
        theta_cont = mod(real(theta), 2*pi);
        theta_q = round(theta_cont / step) * step;
        theta_q(theta_q >= 2*pi - 1e-6) = 0;
    end
end