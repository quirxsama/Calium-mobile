# İndirme güvenilirliği ve UI/UX — ilk aşama

## Kapsam ve kullanıcı senaryosu

Android 16'da uygulamadan çıkınca indirme kesiliyor. Öncelik sırası:
arka plan yaşam döngüsü, dosya bütünlüğü, duraklat/devam et, durum ve hata UX'i.
İnceleme mevcut çalışma ağacındaki değişiklikler üzerinden yapıldı.

## Bulgular ve uygulanan değişiklikler

| Öncelik | Bulgu | Uygulama |
|---|---|---|
| P1 | Dart yalnızca `updateProgress` çağırıyor; native taraf bu yolda `startForeground` çağırmıyordu. | Başlatma ve güncelleme aynı foreground başlangıç yoluna bağlandı. Servisi durdurmak için yeni servis başlatılmıyor. |
| P1 | İndirme Activity'ye ait Flutter engine üzerinde çalışıyordu. Activity yok edildiğinde Dart işlemleri de sonlanabiliyordu. | Engine ve indirme kanalı `CaliumApplication` tarafından tutuluyor; Activity yeniden açılırken aynı engine kullanılıyor. |
| P1 | Başarısız HLS parçaları sessizce atlanıp eksik video tamamlandı sayılıyordu. | Parça hatası artık aktarımı başarısız yapıyor. Yerel HTTP testi eski davranışı yeniden üretti. |
| P1 | HLS iptali döngüden çıkıp dosyayı tamamlayabiliyordu. | Tamamlamadan önce iptal denetleniyor; dosya tanıtıcısı her çıkış yolunda kapatılıyor. |
| P1 | Devam et işlemi geçici dosyayı siliyordu. | HLS için tamamlanan parça grupları ve bayt sınırı diske kaydediliyor. MP4 için doğrulayıcıyla `Range`/`If-Range` kullanılıyor; sunucu tam yanıt verirse dosya güvenle baştan yazılıyor. |
| P1 | Kaynak çözülürken liste indeksi eskiyebiliyordu. | Görevler kimlikle güncelleniyor; iptal belirteci hazırlık başlamadan oluşturuluyor; eşzamanlı çalışan işler bitene kadar kuyruk yuvasını tutuyor. |
| P2 | Kuyruk yeniden başlatmada beklemede kalabiliyordu. | Yarım ve bekleyen görevler açılışta kullanıcı tarafından devam ettirilebilen duraklatılmış duruma getiriliyor. |
| P2 | HLS ilerleme çubuğu alınan/toplam bayt oranıyla erken doluyordu. | Gerçek parça ilerlemesi kullanılıyor; bilinmeyen toplam boyut gerçekmiş gibi sunulmuyor. |
| P2 | Depolama kapasitesi sabit 100 GB varsayılıyordu. | Sahte kapasite çubuğu kaldırıldı; hazır/aktif/başarısız sayıları ve alınan video verisi gösteriliyor. |
| P2 | Hata nedeni ve kurtarma adımı görünmüyordu. | Sunucu, bağlantı, depolama ve desteklenmeyen yayın hataları ayrıştırıldı; hata metni saklanıyor. 401/403 sonrasında yeniden deneme kaynak bağlantısını yeniden çözüyor. |
| P2 | Büyük yazıda yatay ekran taşıyordu; indirme seçenekleri kaydırılamıyordu. | Özet ve liste ortak kaydırmaya alındı; seçenekler kaydırılabilir yapıldı. |
| P2 | Yinelenen ekleme girişimleri başarı mesajı veriyordu. | Ekleme sonucu ve gerçekten eklenen bölüm sayısı kullanıcıya bildiriliyor. |

## Davranış sınırları

- Android'in kullanıcı tarafından **zorla durdurduğu** bir uygulama indirmeye devam edemez.
  Süreç öldürüldükten sonra uygulama açıldığında kullanıcı devam ettirir.
- Android'in dataSync zaman aşımı callback'i kuyruğu duraklatır ve devam etme mesajı gösterir.
- MP4 devamı güvenilir bir sunucu doğrulayıcısına bağlıdır. Doğrulayıcı yoksa veya sunucu
  Range isteğini yok sayarsa yeni tam yanıt kullanılır; eski ve yeni içerik birleştirilmez.
- HLS devamı aynı parça listesine bağlıdır. Liste değiştiyse güvenli şekilde baştan başlar.
  Canlı, şifreli, byte-range ve discontinuity içeren yayınlar eksik dosya üretmek yerine açık hata verir.
- Cihaz bağlı olmadığı için Home, kilit ekranı, son uygulamalardan kaldırma ve üretici pil
  yönetiminin Android 16 üzerindeki gerçek etkisi bu ortamda doğrulanamadı.

## Otomatik doğrulama

```sh
flutter test
flutter analyze --no-pub
flutter build apk --debug --no-pub
```

`test/download_service_test.dart` şu davranışları kapsar:

1. Eksik HLS parçasının tamamlanmış dosya oluşturmaması.
2. HLS duraklat/devam et sırasında tamamlanan parçaların tekrar alınmaması ve doğru sırada birleşmesi.
3. MP4 devamında Range/If-Range ve sonuç dosyasının bayt düzeyinde eşitliği.
4. Range yok sayıldığında eklemek yerine baştan yazılması.
5. Hatalı Content-Range yanıtının reddedilmesi.
6. Aktif görev silindiğinde son dosya ve checkpoint kalmaması.
7. Kaynak çözülürken daha önceki görev silindiğinde doğru görevin güncellenmesi.
8. %50 HLS ilerlemesi ve 320×568 / 568×320 boyutlarında 2× yazı ölçeği.
9. Kaydırılabilir seçenekler ve boş ses gruplarının seçime sunulmaması.
10. Toplu indirme kaynağı çözülürken ilk ses grubu boş olsa da geçerli grubun seçilmesi.

Depodaki mevcut smoke testiyle birlikte 11 test geçiyor. Analiz temiz.
Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`.
Derleme, mevcut `package_info_plus` / `wakelock_plus` eklentileri için Kotlin Gradle geçiş uyarısı veriyor.

## Sonraki aşamalar ve kabul ölçütleri

### Android 16 cihaz doğrulaması

Bir MP4 ve bir HLS indirmesiyle aşağıdaki işlemleri ayrı ayrı dene:

- Home'a dön; bildirim ve aktarım sürmeli.
- Ekranı kilitle; geri açıldığında ilerleme artmış olmalı.
- Son uygulamalardan kaldır; tekrar açıldığında aynı görev görünmeli, çift indirme oluşmamalı.
- Wi-Fi'yi kes/aç ve mobil veriye geç; eksik dosya tamamlandı sayılmamalı, yeniden deneme/Devam et çalışmalı.
- İndirme sırasında duraklat, devam et ve sil; tamamlandı bildirimi yalnızca tam aktarım için gelmeli.
- Süreci sonlandırıp uygulamayı aç; yarım görev duraklatılmış görünmeli, uygun kaynakta devam edebilmeli.
- Tamamlanan videoyu uçak modunda baştan, ortadan ve sona yakın oynat.

### Uygulama geneli UI/UX incelemesi

İkinci aşamada oynatıcı, ana sayfa ve kitaplık durumları ele alındı.
Güncel bulgular ve 25 testlik doğrulama sonucu: [ikinci aşama raporu](player-home-library-review.md).

İlk aşama indirme ekranı ve indirme seçenekleriyle sınırlıdır. Kalan inceleme:
bölüm detayları, tablet yerleşimleri ve gerçek TalkBack odak sırası;
oynatıcı yeniden bağlanmasının ve çevrimdışı altyazının cihaz üzerinde doğrulanması.
Tüm ekranlar için tamamlanmış bir görsel audit veya cihaz testi iddiası yoktur.
