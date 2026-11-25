clear all; close all; clc;

%% KHOI TAO THONG SO HE THONG
N = 10^6; % So luong bit mo phong (1 trieu bit)
SNR_dB = 0:2:20; % Dai SNR khao sat tu 0 den 20 dB
SNR_linear = 10.^(SNR_dB/10); 

% Khoi tao mang luu ket qua BER
BER_Alamouti = zeros(1, length(SNR_dB));

fprintf('BAT DAU CHAY MO PHONG ALAMOUTI 2x1 VOI: %d BITS\n', N);

%% loop
for i = 1:length(SNR_dB)
    snr = SNR_linear(i);
    
    % 1. TAO DU LIEU VA DIEU CHE QPSK
    data = randi([0 1], 1, N); % Tao chuoi bit ngau nhien
    
    % Dieu che QPSK (Gom 2 bit thanh 1 symbol phuc)
    data_matrix = reshape(data, 2, N/2);
    sym = (2*data_matrix(1,:) - 1) + 1i*(2*data_matrix(2,:) - 1);
    sym = sym / sqrt(2); % Chuan hoa nang luong symbol = 1
    
    % MO PHONG HE THONG ALAMOUTI STBC 2x1
    % Tach luong symbol thanh cac cap x1 (le) va x2 (chan)
    x1 = sym(1:2:end);
    x2 = sym(2:2:end);
    
    % Khoi tao kenh Rayleigh doc lap cho 2 anten phat
    h1 = (randn(1, length(x1)) + 1i*randn(1, length(x1))) / sqrt(2);
    h2 = (randn(1, length(x2)) + 1i*randn(1, length(x2))) / sqrt(2);
    
    % Tao nhieu AWGN cho t1 va t2
    n1 = (randn(1, length(x1)) + 1i*randn(1, length(x1))) / sqrt(2);
    n2 = (randn(1, length(x2)) + 1i*randn(1, length(x2))) / sqrt(2);
    
    % Qua trinh truyen qua kenh
    % (t1): Tx1 phat x1, Tx2 phat x2
    r1 = h1.*x1 + h2.*x2 + n1 * sqrt(1/snr);
    
    % (t2): Tx1 phat -x2*, Tx2 phat x1*
    r2 = -h1.*conj(x2) + h2.*conj(x1) + n2 * sqrt(1/snr);
    
    % Giai ma MRC tai may thu
    x1_est = conj(h1).*r1 + h2.*conj(r2);
    x2_est = conj(h2).*r1 - h1.*conj(r2); 
    
    % Ghep lai symbol
    sym_eq_alamouti = zeros(1, N/2);
    sym_eq_alamouti(1:2:end) = x1_est;
    sym_eq_alamouti(2:2:end) = x2_est;
    
    % Giai dieu che QPSK (quyet dinh cung)
    demod_ala = zeros(2, N/2);
    demod_ala(1,:) = real(sym_eq_alamouti) > 0;
    demod_ala(2,:) = imag(sym_eq_alamouti) > 0;
    
    % Dem loi
    so_bit_loi_Alamouti = sum(sum(data_matrix ~= demod_ala));
    BER_Alamouti(i) = so_bit_loi_Alamouti / N;
    
    fprintf('Muc SNR = %2d dB\n', SNR_dB(i));
    fprintf('   -> So bit loi Alamouti (2x1): %7d bits\n', so_bit_loi_Alamouti);
    fprintf('   -> Ty le loi bit (BER)      : %9.6f\n', BER_Alamouti(i));
end

fprintf('\nMO PHONG HOAN TAT\n');

%% ve do thi
figure('Color', 'w', 'Name', 'Ket qua mo phong Alamouti 2x1');
semilogy(SNR_dB, BER_Alamouti, 'r-*', 'LineWidth', 2, 'MarkerSize', 8);
grid on;

axis([0 20 10^-5 1]);
xlabel('Ti so tin hieu tren nhieu - SNR (dB)', 'FontWeight', 'bold');
ylabel('Ty le loi bit (BER)', 'FontWeight', 'bold');
title('Hieu nang BER cua thuat toan Alamouti 2x1', 'FontWeight', 'bold');
legend('He thong Alamouti STBC (2x1)', 'Location', 'southwest');