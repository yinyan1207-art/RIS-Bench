function theta_q = quantize_phase(theta, bits)
    % Quantizes continuous phases to discrete hardware levels
    if isinf(bits)
        theta_q = theta;
    else
        L = 2^bits;
        step = 2*pi / L;
        % Map to nearest discrete level in [0, 2pi)
        theta_q = mod(round(theta / step) * step, 2*pi);
    end
end