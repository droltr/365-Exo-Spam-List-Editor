# Proje Geliştirme ve Gereksinim Dokümanı (Spam Manager)

Bu doküman, **Exchange Online Spam Manager** projesinin geliştirilmesi, test edilmesi ve tamamlanması süreçlerinde yapay zeka asistanından beklenen standartları, teknik gereksinimleri ve tasarım tercihlerini içerir. Gelecekteki geliştirmelerde referans olarak kullanılmalıdır.

## 1. Proje Özeti ve Amacı
Exchange Online (Office 365) spam filtrelerini yönetmek için PowerShell tabanlı, grafik arayüzlü (GUI) bir araçtır. Kullanıcıların metin dosyalarından toplu olarak engellenen gönderici, alan adı ve anahtar kelime yüklemesini sağlar.

## 2. Teknik Gereksinimler ve Kod Yapısı

### 2.1. Dil ve Ortam
*   **Dil:** PowerShell 5.1+
*   **Arayüz:** Windows Forms (System.Windows.Forms)
*   **Modüller:** `ExchangeOnlineManagement` modülü zorunludur. Eksikse otomatik kurulmalıdır.
*   **Bağımlılıklar:** Harici DLL kullanılmamalı, mümkün olduğunca native PowerShell komutları tercih edilmelidir.

### 2.2. Kod Organizasyonu (Modüler Yapı)
Proje tek bir devasa dosya yerine modüllere ayrılmalıdır:
*   `Start-SpamManager.ps1`: Başlatıcı script (EXE derlemesi için giriş noktası).
*   `Main-Controller.ps1`: İş mantığını yöneten ana kontrolcü.
*   `GUI-Interface.ps1`: Tüm görsel arayüz kodları.
*   `Connect-ExchangeOnline.ps1`: Bağlantı yönetimi.
*   `Parse-BlockedFile.ps1`: Dosya okuma ve sınıflandırma (Regex).
*   `Update-EOPPolicy.ps1`: EOP politikalarını güncelleme.
*   `Update-TransportRule.ps1`: Transport kurallarını güncelleme.
*   `Common-Utils.ps1`: Ortak yardımcı fonksiyonlar (Loglama vb.).

## 3. Arayüz (UI/UX) Tasarım Kuralları

### 3.1. Genel Görünüm
*   **Tema:** "Professional Dark Theme" (Koyu gri arka plan, beyaz metinler).
*   **Stil:** `[System.Windows.Forms.Application]::EnableVisualStyles()` aktif edilmelidir.
*   **Font:** Okunaklı modern fontlar (Segoe UI) kullanılmalıdır.

### 3.2. Yerleşim (Layout)
Arayüz yukarıdan aşağıya şu bloklardan oluşmalıdır:
1.  **Connection (Bağlantı) Bölümü:**
    *   En üstte yer almalı.
    *   Login/Logout butonları, Bağlantı Durumu (Renkli Kutu) ve Hesap Adı (UserPrincipalName) burada bulunmalı.
    *   Giriş yapılınca Login gizlenmeli, Logout görünmeli.
2.  **File Selection (Dosya Seçimi):**
    *   Dosya yolu kutusu, "Browse" butonu ve **"Create Example"** (Örnek Dosya Oluştur) butonu yan yana olmalı.
3.  **Rule Selection (Kural Seçimi):**
    *   EOP Senders, EOP Domains ve Transport Rules için Checkbox'lar.
    *   "Download Rules" ve "Upload File" işlem butonları.
    *   EOP ve Transport Rules yönetim sayfalarına giden **tıklanabilir linkler**.
4.  **Options (Seçenekler):**
    *   "Sync Mode" (Dosyada olmayanları sil) seçeneği.
5.  **Progress (İlerleme):**
    *   İlerleme çubuğu (ProgressBar).
    *   Detaylı log penceresi (TextBox).
6.  **Action (Alt Aksiyon):**
    *   En altta "Start" ve "Close" butonları.

### 3.3. Davranışsal Özellikler
*   **Responsive:** Pencere genişletildiğinde butonlar kaybolmamalı, sağa yaslı kalmalı (`Anchor` veya `Resize` eventleri ile).
*   **Loglama:** Log penceresi otomatik olarak en aşağı kaymalı (Auto-scroll). Loglar `[HH:mm:ss] Mesaj` formatında ve alt alta olmalı.

## 4. Fonksiyonel Gereksinimler

### 4.1. Bağlantı Yönetimi
*   **Yöntem:** Modern Auth (OAuth) kullanılmalı.
*   **Fallback:** Önce `-Device` parametresi denenmeli, hata verirse interaktif moda düşülmelidir.
*   **Durum Kontrolü:** Bağlantı kopsa bile arayüzde durum doğru yansıtılmalı.

### 4.2. Dosya İşleme
*   **Format:** `.txt` dosyaları okunmalı.
*   **Yorumlar:** `#` ile başlayan satırlar ve boş satırlar yoksayılmalı.
*   **Sınıflandırma:** E-postalar, Domainler ve `---keywords---` altındaki kelimeler otomatik ayrıştırılmalı.

### 4.3. İlerleme Bildirimi
*   Kullanıcıya sadece "%50 tamamlandı" denmemeli.
*   "5 adet e-posta ekleniyor...", "Transport kuralı güncelleniyor..." gibi **granular (parçalı)** detaylar loglanmalı.

## 5. Test ve Kalite Kontrol
Her değişiklikten sonra şu testler yapılmalıdır:
1.  **Birim Testleri:** `tests/` klasöründeki Pester testleri (`Invoke-Pester`) çalıştırılmalı.
2.  **Entegrasyon Testi:** `Test-Integration.ps1` ile GUI mantığı ve modül yüklemeleri test edilmeli.
3.  **Manuel Kontrol:** `Run-SpamManager.bat` çalıştırılarak butonların yerleşimi ve pencere boyutlandırma davranışı kontrol edilmeli.

## 6. Paketleme ve Dağıtım
*   **Executable:** `PS2EXE` modülü kullanılarak `.ps1` dosyası `.exe`'ye çevrilmelidir.
    *   *Önemli:* EXE derlenirken script path (`$PSScriptRoot`) sorunu için `[System.IO.Path]::GetDirectoryName` kullanılmalıdır.
*   **Launcher:** Kullanıcı kolaylığı için `Run-SpamManager.bat` dosyası bulunmalıdır.
*   **Dokümantasyon:** `README.md`, `USAGE.md`, `CONTRIBUTING.md`, `CHANGELOG.md` ve `LICENSE` dosyaları eksiksiz olmalıdır.
*   **Git:** Gereksiz dosyalar `.gitignore` ile engellenmelidir.

## 7. Versiyonlama
*   Sürüm numaraları `CHANGELOG.md` dosyasında tutulmalı.
*   Beta sürümler `0.x.x`, kararlı sürümler `1.x.x` olarak adlandırılmalı.
