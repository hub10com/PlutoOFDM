function threshold_dBm = fitGMMtoPowerVecJammer(powerVec)

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

    threshold_dBm = (mu(1) + mu(2)) / 2;

    % --- Histogram + KDE + Threshold Çizgisi çizimi
    figure('Name', 'GMM Tabanlı Eşik Değeri Tahmini');
    h = histogram(cleanPowerVec, 50, 'Normalization', 'pdf', 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    hold on;

    try
        [f, xi] = ksdensity(cleanPowerVec);
        plot(xi, f, 'r-', 'LineWidth', 2);
    catch
    end

    % --- Eşik çizgisi
    yLimits = ylim;
    plot([threshold_dBm threshold_dBm], yLimits, 'k--', 'LineWidth', 2);

    grid on;
    xlabel('Güç (dBm)');
    ylabel('Yoğunluk');
    title(sprintf('GMM Tabanlı Eşik Değeri Tahmini — Eşik Değeri %.2f dBm', threshold_dBm));
    hold off;

end
