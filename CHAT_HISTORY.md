# Chat History - 365-Exo-Spam-List-Editor

This document records the development session history and interactions for the 365-Exo-Spam-List-Editor project. It serves as a log of changes, decisions, and automated actions performed by the AI assistant.

## Session: 2025-12-24

### User
projeyi githuba yükle

### Assistant
Proje başarıyla GitHub'a yüklendi.

Yapılan işlemler:
1.  `Upload-To-GitHub.bat` dosyası git'e eklendi ve commit edildi.
2.  Remote origin `https://github.com/droltr/365-Exo-Spam-List-Editor.git` olarak ayarlandı.
3.  Kodlar `main` branch'ine push edildi.

### User
açıklama ekle, gereksiz dosyaları .deleted içine taşı, bu klasör ignore liste eklenecek. projeye gerekli omayan dosyaları githuba yuükleme

### Assistant
(Dosya düzenlemeleri ve taşımalar yapıldı)

### User
nedir durum

### Assistant
İstenilen değişiklikler yapıldı ve GitHub'a yüklendi:

1.  **Gereksiz dosyalar `.deleted` klasörüne taşındı:**
    *   `365ExoSpamListEditor.exe` (Zaten gitignore'daydı ama klasöre taşındı)
    *   `Run-365ExoSpamListEditor.bat`
    *   `Upload-To-GitHub.bat`
    *   `blocked.txt`
    *   `blocked_lists.txt`
    *   `new_blocked_lists.txt`

2.  **`.gitignore` güncellendi:**
    *   `.deleted/` klasörü eklendi.
    *   `!blocked.txt` istisnası kaldırıldı.

3.  **`README.md` güncellendi:**
    *   Proje açıklaması PowerShell script odaklı olacak şekilde düzenlendi.
    *   İndirme (Download) bölümü kaldırıldı.
    *   Kullanım talimatları sadece PowerShell scriptini çalıştıracak şekilde güncellendi.

4.  **Değişiklikler GitHub'a push edildi.**

### User
tüm chati bir md dosyasına kayıt et
