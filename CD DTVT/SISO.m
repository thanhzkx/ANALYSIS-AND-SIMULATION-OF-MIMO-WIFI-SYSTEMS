%% PHAN 1: MO PHONG HE THONG WIFI SISO (BASELINE)
clear all; close all; clc;

% --- 1. KHOI TAO THAM SO ---
N_bits = 1e6;                % So luong bit mo phong (Yeu cau 2)
SNR_dB = 0:2:20;             % Dai SNR khao sat tu 0 den 20 dB (Yeu cau 4)
SNR_linear = 10.^(SNR_dB/10);
BER_SISO = zeros(1, length(SNR_dB));

fprintf('BAT DAU MO PHONG HE THONG SISO (BASELINE)...\n');

for i = 1:length(SNR_dB)
    snr = SNR_linear(i);
    N0 = 1/snr;              % Cong suat nhieu ung voi muc SNR
    
    % --- 2. KHOI PHAT (Yeu cau 2) ---
    bits = randi([0 1], 1, N_bits); % Sinh chuoi bit ngau nhien
    
    % Dieu che QPSK
    bits_reshape = reshape(bits, 2, []).';
    sym = (2*bits_reshape(:,1)-1) + 1j*(2*bits_reshape(:,2)-1);
    sym = sym / sqrt(2);     % Chuan hoa cong suat phat Ps = 1
    
    % --- 3. KENH TRUYEN (Yeu cau 3) ---
    % Mo phong kenh Rayleigh Fading h ~ CN(0,1)
    h = (randn(size(sym)) + 1j*randn(size(sym))) / sqrt(2);
    
    % Nhieu AWGN n ~ CN(0, N0)
    n = sqrt(N0/2) * (randn(size(sym)) + 1j*randn(size(sym)));
    
    % Tin hieu nhan duoc: y = h*x + n
    y = h .* sym + n;
    
    % --- 4. KHOI THU & TINH BER (Yeu cau 4) ---
    % Can bang kenh Equalization (Zero Forcing cho SISO)
    sym_hat = y ./ h;
    
    % Giai dieu che QPSK (Quyet dinh cung)
    bits_out = zeros(1, N_bits);
    bits_out(1:2:end) = real(sym_hat) > 0;
    bits_out(2:2:end) = imag(sym_hat) > 0;
    
    % Tinh ty le loi bit BER
    BER_SISO(i) = sum(bits ~= bits_out) / N_bits;
    fprintf('   SNR = %2d dB | BER = %.6f\n', SNR_dB(i), BER_SISO(i));
end

% --- 5. VE DO THI BER VS SNR ---
figure('Color', 'w', 'Name', 'Ket qua mo phong SISO');
semilogy(SNR_dB, BER_SISO, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('Ti so tin hieu tren nhieu - SNR (dB)', 'FontWeight', 'bold');
ylabel('Ty le loi bit - BER', 'FontWeight', 'bold');
title('Hieu nang BER cua he thong SISO tren kenh Rayleigh', 'FontSize', 12);
legend('SISO Baseline', 'Location', 'southwest');