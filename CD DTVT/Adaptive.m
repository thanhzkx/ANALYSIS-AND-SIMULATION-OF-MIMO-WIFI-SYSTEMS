clc; clear; close all;

%% =========================
%% NHAP THONG SO (CO MAC DINH)
%% =========================

Nt = input('Nhap so anten phat Nt (default = 2): ');
if isempty(Nt), Nt = 2; end

Nr = input('Nhap so anten thu Nr (default = 2): ');
if isempty(Nr), Nr = 2; end

Nbits = input('Nhap so bit mo phong (default = 1e5): ');
if isempty(Nbits), Nbits = 1e5; end

SNR_dB = input('Nhap day SNR (vd: 0:2:20) (default = 0:2:20): ');
if isempty(SNR_dB), SNR_dB = 0:2:20; end

threshold = input('Nhap nguong chuyen mode (dB) (default = 10): ');
if isempty(threshold), threshold = 10; end

fprintf('\n=== THONG SO HE THONG ===\n');
fprintf('Nt = %d, Nr = %d\n', Nt, Nr);
fprintf('Nbits = %d\n', Nbits);
fprintf('Threshold = %d dB\n', threshold);
fprintf('========================\n\n');

%% =========================
%% KHOI TAO
%% =========================

BER = zeros(size(SNR_dB));

%% =========================
%% VONG LAP SNR
%% =========================

for i = 1:length(SNR_dB)
    
    snr = SNR_dB(i);
    snr_linear = 10^(snr/10);
    noise_var = 1/(2*snr_linear);
    
    % sinh bit
    bits = randi([0 1], Nbits, 1);
    
    % QPSK
    symbols = (2*bits(1:2:end)-1) + 1j*(2*bits(2:2:end)-1);
    symbols = symbols / sqrt(2);
    
    Nsym = length(symbols);
    error = 0;
    
    %% =========================
    %% CHON CHE DO ADAPTIVE
    %% =========================
    
    if snr < threshold
        %% ===== ALAMOUTI (DIVERSITY) =====
        
        for k = 1:2:Nsym-1
            
            s1 = symbols(k);
            s2 = symbols(k+1);
            
            H = (randn(Nr,Nt)+1j*randn(Nr,Nt))/sqrt(2);
            
            n1 = sqrt(noise_var)*(randn(Nr,1)+1j*randn(Nr,1));
            n2 = sqrt(noise_var)*(randn(Nr,1)+1j*randn(Nr,1));
            
            x1 = [s1; s2];
            x2 = [-conj(s2); conj(s1)];
            
            y1 = H*x1 + n1;
            y2 = H*x2 + n2;
            
            s1_hat = sum(conj(H(:,1)).*y1 + H(:,2).*conj(y2));
            s2_hat = sum(conj(H(:,2)).*y1 - H(:,1).*conj(y2));
            
            s1_detect = sign(real(s1_hat)) + 1j*sign(imag(s1_hat));
            s2_detect = sign(real(s2_hat)) + 1j*sign(imag(s2_hat));
            
            bits_hat = [real(s1_detect)>0; imag(s1_detect)>0; ...
                        real(s2_detect)>0; imag(s2_detect)>0];
                    
            bits_tx = bits(2*k-1:2*k+2);
            
            error = error + sum(bits_hat ~= bits_tx);
        end
        
    else
        %% ===== SPATIAL MULTIPLEXING (ZF) =====
        
        for k = 1:Nt:Nsym-Nt+1
            
            s = symbols(k:k+Nt-1);
            
            H = (randn(Nr,Nt)+1j*randn(Nr,Nt))/sqrt(2);
            
            n = sqrt(noise_var)*(randn(Nr,1)+1j*randn(Nr,1));
            
            y = H*s + n;
            
            % Zero-Forcing
            s_hat = pinv(H)*y;
            
            s_detect = sign(real(s_hat)) + 1j*sign(imag(s_hat));
            
            bits_hat = [];
            for m = 1:Nt
                bits_hat = [bits_hat;
                    real(s_detect(m))>0;
                    imag(s_detect(m))>0];
            end
            
            bits_tx = bits(2*k-1:2*k+2*Nt-2);
            
            error = error + sum(bits_hat ~= bits_tx);
        end
        
    end
    
    BER(i) = error/Nbits;
end

%% =========================
%% VE DO THI
%% =========================

figure;
semilogy(SNR_dB, BER, 'o-','LineWidth',2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Adaptive MIMO (Alamouti + Spatial Multiplexing)');
legend('Adaptive');
