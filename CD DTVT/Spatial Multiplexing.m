clc; clear; close all;
 
%% ===========================
%% 1. NHAP THAM SO (co gia tri mac dinh)
%% ===========================
 
Nt = input('Nhap so anten phat Nt (default = 2): ');
if isempty(Nt), Nt = 2; end
 
Nr = input('Nhap so anten thu Nr (default = 2): ');
if isempty(Nr), Nr = 2; end
 
N = input('Nhap so symbol N (default = 1e5): ');
if isempty(N), N = 1e5; end
 
SNR_dB_range = input('Nhap dai SNR (vd: 0:2:20, default = 0:2:20): ');
if isempty(SNR_dB_range), SNR_dB_range = 0:2:20; end
 
BER_MMSE = zeros(size(SNR_dB_range));
 
fprintf('\n BAT DAU MO PHONG \n');
 
%% ===========================
%% 2. VONG LAP THEO SNR
%% ===========================
 
for snr_idx = 1:length(SNR_dB_range)
 
    SNR_dB = SNR_dB_range(snr_idx);
    SNR = 10^(SNR_dB/10);
    N0 = 1/SNR;
 
    fprintf('\n SNR = %d dB \n', SNR_dB);
 
    %% ===========================
    %% 2.1 Tao chuoi bit ngau nhien
    %% ===========================
    bits = randi([0 1], N*Nt, 1);
 
    %% ===========================
    %% 2.2 Dieu che QPSK
    %% ===========================
    bits_reshape = reshape(bits, 2, []).';
 
    symbols = (2*bits_reshape(:,1)-1) + 1j*(2*bits_reshape(:,2)-1);
    symbols = symbols / sqrt(2);   % chuan hoa cong suat symbol
 
    %% ===========================
    %% 2.3 Spatial Multiplexing
    %% ===========================
    x = reshape(symbols, Nt, []);
    x = x / sqrt(Nt);   % chia cong suat cho moi anten
 
    % hien thi cong suat de kiem tra
    power_total = mean(sum(abs(x).^2,1));
    fprintf('Total power = %.4f\n', power_total);
 
    %% ===========================
    %% 2.4 Kenh Rayleigh fading
    %% ===========================
    H = (randn(Nr,Nt,size(x,2)) + 1j*randn(Nr,Nt,size(x,2))) / sqrt(2);
 
    % kiem tra thong ke kenh
    h_sample = H(1,1,:);
    h_sample = h_sample(:);
    fprintf('Mean(H) = %.4f, Var(H) = %.4f\n', mean(h_sample), var(h_sample));
 
    %% ===========================
    %% 2.5 Nhieu AWGN
    %% ===========================
    n = sqrt(N0/2)*(randn(Nr,size(x,2)) + 1j*randn(Nr,size(x,2)));
 
    %% ===========================
    %% 2.6 Truyen tin hieu qua kenh
    %% ===========================
    y = zeros(Nr, size(x,2));
 
    for k = 1:size(x,2)
        y(:,k) = H(:,:,k)*x(:,k);
    end
 
    y = y + n;
 
    %% ===========================
    %% 2.7 MMSE Detection
    %% ===========================
    x_hat = zeros(Nt, size(y,2));
 
    for k = 1:size(y,2)
        Hk = H(:,:,k);
        W = inv(Hk'*Hk + N0*eye(Nt)) * Hk';
        x_hat(:,k) = W * y(:,k);
    end
 
    fprintf('MMSE detection done\n');
 
    %% ===========================
    %% 2.8 Giai dieu che (demodulation)
    %% ===========================
    x_hat = x_hat * sqrt(Nt);
 
    bits_hat = zeros(2*size(x_hat,2),1);
    idx = 1;
 
    for k = 1:size(x_hat,2)
        for i = 1:Nt
            bits_hat(idx) = real(x_hat(i,k)) > 0;
            bits_hat(idx+1) = imag(x_hat(i,k)) > 0;
            idx = idx + 2;
        end
    end
 
    %% ===========================
    %% 2.9 Tinh BER
    %% ===========================
    bits = bits(1:length(bits_hat));
    BER_MMSE(snr_idx) = sum(bits ~= bits_hat) / length(bits);
 
    fprintf('BER = %.6f\n', BER_MMSE(snr_idx));
 
end
 
%% ===========================
%% 3. Ve do thi BER vs SNR
%% ===========================
 
figure;
semilogy(SNR_dB_range, BER_MMSE, '-o','LineWidth',2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('BER vs SNR - MIMO 2x2 MMSE');
