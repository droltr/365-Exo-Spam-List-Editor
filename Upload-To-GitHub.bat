@echo off
echo GitHub'a yukleme islemi baslatiliyor...
echo.

REM Remote ekle (Eger yoksa)
git remote add origin https://github.com/droltr/365-Exo-Spam-List-Editor.git 2>NUL

REM Ana dali ayarla
git branch -M main

REM Yukle
echo Kodlar GitHub'a gonderiliyor...
git push -u origin main

echo.
if %errorlevel% neq 0 (
    echo [HATA] Yukleme basarisiz oldu. Lutfen sunlari kontrol edin:
    echo 1. GitHub'da '365-Exo-Spam-List-Editor' adinda bos bir depo olusturdunuz mu?
    echo 2. Internet baglantiniz var mi?
    echo 3. GitHub giris bilgileriniz dogru mu?
) else (
    echo [BASARILI] Proje basariyla yuklendi!
)
pause
