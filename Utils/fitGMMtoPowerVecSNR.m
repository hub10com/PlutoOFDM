function mu_sorted = fitGMMtoPowerVecSNR(powerVec)

    % --- Soft outlier temizleme
    pLow  = prctile(powerVec, 1);   
    pHigh = prctile(powerVec, 99);  
    cleanPowerVec = powerVec(powerVec >= pLow & powerVec <= pHigh);

    % --- GMM fit
    try
        gm = fitgmdist(cleanPowerVec(:), 2, 'RegularizationValue', 0.01);
        mu = sort(gm.mu);  % küçük - büyük sırala

        fprintf("🎯 GMM fit başarılı — Küme Ortalamaları: [%.2f dBm, %.2f dBm]\n", mu(1), mu(2));

    catch
        % GMM fallback → KMeans
        warning("⚠️ GMM başarısız — KMeans fallback kullanılıyor.");

        [~, C] = kmeans(cleanPowerVec(:), 2);
        C = sort(C);

        mu = C;

        fprintf("🎯 KMeans fallback — Küme Ortalamaları: [%.2f dBm, %.2f dBm]\n", mu(1), mu(2));
    end

    mu_sorted = mu;

    % --- Opsiyonel: Histogram ve KDE göster
    figure('Name', 'GMM Tabanlı SNR Ölçümü');
    histogram(cleanPowerVec, 50, 'Normalization', 'pdf', 'FaceAlpha', 0.6);
    hold on;
    try
        [f, xi] = ksdensity(cleanPowerVec);
        plot(xi, f, 'r-', 'LineWidth', 2);
    catch
    end
    snr_dB = mu(1)-mu(2);
    grid on;
    xlabel('Güç (dBm)');
    ylabel('Yoğunluk');
    title(sprintf('GMM Tabanlı SNR Ölçümü | SNR = %.2f dB',- snr_dB));
    hold off;

end
