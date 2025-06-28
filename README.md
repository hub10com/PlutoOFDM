# PlutoOFDM

PlutoOFDM, ADALM-Pluto SDR donanımı kullanılarak OFDM haberleşme sistemleri ile adaptif ve adaptif olmayan frekans atlama yöntemlerinin, jammer etkisinden kaçınma amacıyla MATLAB ortamında geliştirilmesi ve test edilmesi için oluşturulmuş bir projedir. Bu çalışma, Hub10 proje ekibi tarafından Teknofest Kablosuz Haberleşme Yarışması kapsamında yürütülen bir akademik proje niteliğindedir.

## Özellikler
- OFDM çerçeve üretimi, modülasyon ve iletim
- Pluto SDR ile canlı kablosuz haberleşme
- Jammer (karıştırıcı) tespiti ve uyarlanabilir frekans atlama (FHSS)
- GMM tabanlı SNR ve jammer analiz mekanizmaları
- Yapılandırılmış sınıf, script ve yardımcı fonksiyon dizini

## Proje Yapısı
- **Classes/** → Ana sınıf dosyaları (ör. `OFDMPlutoRX`, `OFDMPlutoTX`, `ModulationMapper`)
- **Scripts/** → Test ve çalıştırma betikleri (ör. `ofdmPlutoTransmitter.m`, `ofdmPlutoReceiver.m`)
- **Config/** → Sistem parametre dosyaları
- **Sim/** → Simülasyonlar (ör. BPSK, QAM + konvülasyonel kodlama)
- **Utils/** → Yardımcı fonksiyonlar (ör. GMM modelleme)
- **Docs/** → Proje ile ilgili görseller, şemalar ve belgeler 

## Gereksinimler
- MATLAB R202x (Communications Toolbox ile)
- 2 adet ADALM-Pluto SDR cihazı

## Kullanım
1️) Pluto SDR cihazlarınızı kurun ve bağlantısını sağlayın.  
2️) Verici için `Scripts/ofdmPlutoTransmitter.m` dosyasını çalıştırın.  
3️) Alıcı için `Scripts/ofdmPlutoReceiver.m` ya da `Scripts/ofdmPlutoReceiverMinimal.m` dosyasını çalıştırın.  
4️) Jammer tespiti ve FHSS için ilgili scriptleri kullanabilirsiniz (`jammerDetection.m`, `ofdmFHSSTestTX.m` vb.)

## Not
Bu proje herhangi bir lisans içermemekte olup yalnızca akademik çalışma amacıyla geliştirilmiştir.

## İletişim
Proje ile ilgili tüm sorular için lütfen [GitHub üzerinden iletişime geçin](https://github.com/hub10com/PlutoOFDM/issues).
