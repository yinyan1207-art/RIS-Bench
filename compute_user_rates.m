function user_rates = compute_user_rates(theta, Hd, Hr, G, P_tx, noise_var, epsilon, I_K)
    % Evaluates individual user rates (returns K x 1 vector)
    theta = theta(:); 
    H_eq = Hd + Hr * (exp(1j * theta) .* G); 
    W_unnorm = H_eq' / (H_eq * H_eq' + epsilon * I_K);
    W = sqrt(P_tx / norm(W_unnorm, 'fro')^2) * W_unnorm;
    HW = H_eq * W;                   
    HW_abs_sq = abs(HW).^2;          
    signal_power = diag(HW_abs_sq);  
    total_power = sum(HW_abs_sq, 2); 
    interference_power = max(total_power - signal_power, 0); 
    sinr = signal_power ./ (interference_power + noise_var);
    user_rates = log2(1 + sinr); % Do not sum here
end