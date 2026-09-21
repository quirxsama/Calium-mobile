# Solid UI — uygulama ve geri dönüş

## Çalışma yeri

- Dal: `ui/solid-responsive`
- İzole çalışma ağacı: `.worktrees/solid-responsive`
- Önceki durumun Git stash yedeği: `ddabb1f4be118eec22d50ac3050400a3c7ea296c`
- Ana proje klasörü hâlâ `main` dalında. İzlenen dosyaları UI öncesi yedekle
  karşılaştırıldı; fark yok. Önceki indirme/oynatıcı düzeltmeleri her iki çalışma
  klasöründe de mevcut.
- UI değişiklikleri bu çalışma ağacında, henüz commit/push yapılmadı.

## Tasarım

Impeccable'ın `bolder`, `adapt.native` ve Android rehberleri kullanıldı.
Koyu zemin, rose/crimson vurgusu, Jakarta/Inter font ailesi korundu.

- Daha güçlü başlıklar ve okunaklı iki satırlı afiş başlıkları.
- Daha büyük, belirgin eylem içeren ana sayfa vitrini. Sürekli otomatik hareket
  yerine erişilebilir önceki/sonraki kontrolleri; animasyon kapatma tercihine uyum.
- Ana sayfanın parlama/blur yoğunluğu azaltıldı. Birincil eylemler pembe,
  ikincil kontroller koyu yüzeylerde tutuldu.
- Aynı anime farklı raflarda göründüğünde çakışan Hero etiketleri kaldırıldı.
- Anime detayında sade izleme/favori/liste/indirme eylemleri, geniş banner ve
  okunaklı bölüm kartları. İndirme eylemi mevcut kalite/ses seçim sayfasını açar.
- Bölüm arama, sıralama, sezon değiştirme, doğrudan oynatma ve daha fazla bölüm
  yükleme işlevleri korunur. Sezon değişince arama alanı da temizlenir.

## Telefon ve tablet düzeni

- 600 dp altındaki pencerelerde alt gezinme; 600 dp ve üzeri yan gezinme.
  1200 dp ve üzeri yan gezinmede genişletilmiş etiketler.
- Ana içerik en fazla 1400 dp. Profil, sosyal, ayarlar ve indirmeler için daha
  dar okuma alanları; tablet ekranına yayılan gereksiz uzun satırlar engellenir.
- Anime detayında 900 dp'den itibaren özet/eylemler ile bölüm tarayıcısı yan yana.
- Keşfet, arama, favoriler, Türkçe dublaj ve özel liste ızgaraları gerçek alan
  genişliğine ve yazı ölçeğine göre sütun/kart yüksekliğini hesaplar.
- Sabit, kısa bölüm arama alanı ve sezon şeridi yerini doğal yüksekliğe sahip
  Material kontrollere bıraktı. Dokunma hedefleri en az 48 dp olacak şekilde temalandı.

## Doğrulama

Bu klasörde çalıştırıldı:

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
git diff --check
```

Sonuç: **37 test geçti**, analiz temiz, APK üretildi ve diff boşluk kontrolü temiz.
`test/responsive_ui_test.dart` 12 yeni kontrol içerir:

- 360×800 telefon, 800×1280 dikey tablet ve 1280×800 yatay geniş ekran.
- Telefonda ve geniş ekranda 2× yazı ölçeği.
- Alt/yan gezinme seçimi, etkileşimleri ve vitrin sayfalama.
- Afiş ızgarasının sütunları ve taşmasız başlıkları.
- Anime detayının iki sütunlu yapısı, büyük yazıda bölüm arama ve sezon değiştirme.

Opsiyonel widget-render görselleri kontrollü test verisi ve test font ortamına
bağlıdır; gerçek anime görselleriyle cihaz ekran görüntüsü olarak değerlendirilmez.
Fiziksel tablet, katlanabilir cihaz menteşesi ve gerçek TalkBack kontrolü yapılmadı.

## Deneme ve geri dönüş

Yeni arayüz APK'sı, ana proje klasörüne göre:

`.worktrees/solid-responsive/build/app/outputs/flutter-apk/app-debug.apk`

Kaynak üzerinden çalıştırmak için IDE'de `.worktrees/solid-responsive` klasörünü
açıp orada `flutter run` kullanın. Ana klasörde çalıştırmak UI öncesi sürümü açar.

Tasarım beğenilmezse ana proje klasörünü kullanmaya devam etmek yeterli; oradaki
`main` çalışma durumu UI refactor tarafından değiştirilmedi. Mevcut düzenlemeleri
kaybetmemek için `git reset --hard` veya worktree'yi zorla silmek gerekmez.

UI farkını önceki işlevsel düzeltmelerden ayrı incelemek için bu worktree içinde:

```sh
git diff ddabb1f4be118eec22d50ac3050400a3c7ea296c -- lib
git status --short
```

Yeni eklenen izlenmeyen UI dosyaları da `git status` listesinden incelenmelidir.
