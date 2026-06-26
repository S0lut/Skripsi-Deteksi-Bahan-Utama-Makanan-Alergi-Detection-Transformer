# Skripsi-Deteksi-Bahan-Utama-Makanan-Alergi-Detection-Transformer
Aplikasi deteksi bahan makanan alergen menggunakan Detection Transformer (DETR) dengan backbone ResNet-50.
# NootriScan

**NootriScan** adalah aplikasi mobile berbasis Flutter yang dikembangkan untuk mendeteksi bahan makanan alergen pada citra hidangan. Aplikasi mengirimkan gambar ke layanan FastAPI yang menjalankan model **Detection Transformer (DETR)** dengan backbone **ResNet-50**, kemudian menampilkan bahan yang terdeteksi, tingkat keyakinan, posisi bounding box, dan peringatan berdasarkan profil alergi pengguna.

Repositori ini merupakan bagian dari skripsi:

> **Sistem Deteksi Bahan Utama Makanan Menggunakan Metode Detection Transformer**

## Identitas Penulis

- **Nama:** Vincent Wijaya
- **NIM:** 535220064
- **Program Studi:** Teknik Informatika
- **Fakultas:** Fakultas Teknologi Informasi
- **Universitas:** Universitas Tarumanagara
- **Tahun:** 2026

## Fitur Aplikasi

- Autentikasi pengguna menggunakan Firebase Authentication dan Google Sign-In.
- Pengaturan nama dan profil alergi setiap pengguna.
- Pemilihan gambar dari galeri atau pengambilan gambar melalui kamera.
- Pengiriman citra ke REST API untuk proses inferensi model DETR.
- Visualisasi hasil deteksi dalam bentuk nama bahan, confidence score, dan bounding box.
- Peringatan apabila bahan yang terdeteksi sesuai dengan profil alergi pengguna.
- Penyimpanan riwayat analisis secara lokal berdasarkan akun pengguna.
- Pengelolaan dan penghapusan riwayat analisis.

## Kelas Bahan yang Dideteksi

Model mendeteksi sepuluh kategori bahan makanan berikut:

1. Udang
2. Kepiting
3. Kerang
4. Ikan
5. Telur
6. Tahu
7. Tempe
8. Mie
9. Kacang mete
10. Almond

## Arsitektur Sistem

Alur kerja sistem secara umum adalah:

Pengguna
   │
   ▼
Aplikasi Flutter NootriScan
   │  HTTP multipart/form-data
   ▼
FastAPI melalui URL publik ngrok
   │
   ▼
Model DETR ResNet-50
   │
   ▼
Hasil JSON: label, confidence, dan bounding box
   │
   ▼
Pencocokan dengan profil alergi pengguna
   │
   ▼
Peringatan dan riwayat analisis
```

## Teknologi yang Digunakan

### Aplikasi Mobile

- Flutter
- Dart
- Provider
- Firebase Core
- Firebase Authentication
- Google Sign-In
- Shared Preferences
- HTTP Multipart Request
- Image Picker
- Permission Handler
- Flutter SVG

### API dan Model

- Python
- FastAPI
- Uvicorn
- PyTorch
- Hugging Face Transformers
- DETR dengan backbone ResNet-50
- Pillow
- Google Colab
- Google Drive
- ngrok

## Struktur Proyek Flutter

```text
nootriscan/
├── android/                    # Konfigurasi aplikasi Android
├── assets/
│   ├── icons/                  # Ikon bahan alergen
│   └── images/                 # Gambar antarmuka aplikasi
├── ios/                        # Konfigurasi aplikasi iOS
├── lib/
│   ├── models/                 # Model data alergi dan hasil analisis
│   ├── providers/              # State management aplikasi
│   ├── screens/                # Halaman aplikasi
│   ├── services/               # Layanan autentikasi
│   ├── theme/                  # Tema aplikasi
│   ├── firebase_options.dart   # Konfigurasi FlutterFire
│   └── main.dart               # Entry point aplikasi
├── test/                       # Pengujian Flutter
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
├── .gitignore
└── README.md
```

Untuk pengumpulan skripsi, kode pendukung dapat ditambahkan dengan struktur berikut:

```text
backend/
└── fastAPI.ipynb               # Notebook FastAPI dan inferensi di Colab

training/
├── training_scenario_1.ipynb  # Kode pelatihan skenario 1
├── training_scenario_2.ipynb  # Kode pelatihan skenario 2
└── evaluation.ipynb           # Kode evaluasi model
```

## Persyaratan

Sebelum menjalankan aplikasi, pastikan perangkat memiliki:

- Flutter SDK yang mendukung Dart `>=3.4.1 <4.0.0`
- Android Studio atau Visual Studio Code
- Android SDK dan perangkat Android/emulator
- Akun Firebase yang telah dikonfigurasi
- API FastAPI yang sedang aktif
- Koneksi internet

Periksa instalasi Flutter dengan perintah:

```bash
flutter doctor
```

## Instalasi Aplikasi Flutter

### 1. Clone repositori

```bash
git clone https://github.com/USERNAME/NAMA_REPOSITORI.git
cd NAMA_REPOSITORI
```

Ganti `USERNAME` dan `NAMA_REPOSITORI` sesuai repositori GitHub yang digunakan.

### 2. Instal dependensi

```bash
flutter pub get
```

### 3. Konfigurasi Firebase

Proyek menggunakan Firebase Authentication. Pastikan konfigurasi Firebase tersedia untuk platform yang digunakan.

Apabila membuat konfigurasi Firebase baru, jalankan:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Aktifkan metode autentikasi yang diperlukan pada Firebase Console, terutama:

- Email/Password
- Google Sign-In

Pastikan nama paket Android pada Firebase sesuai dengan konfigurasi aplikasi.

### 4. Konfigurasi URL FastAPI

Buka file:

```text
lib/providers/analysis_provider.dart
```

Ganti nilai `_apiUrl` dengan URL publik FastAPI yang sedang aktif:

```dart
static const String _apiUrl =
    'https://URL-NGROK-ANDA.ngrok-free.app/predict';
```

URL ngrok dapat berubah setiap kali runtime Google Colab dimulai ulang, kecuali menggunakan domain ngrok tetap.

### 5. Jalankan aplikasi

```bash
flutter run
```

Untuk membuat APK:

```bash
flutter build apk --release
```

Hasil APK akan tersedia di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

File APK tidak perlu dimasukkan ke source repository. APK dapat diunggah melalui GitHub Releases atau Google Drive.

## Menjalankan FastAPI di Google Colab

Notebook FastAPI menggunakan checkpoint model yang tersimpan di Google Drive.

### 1. Instal library

```python
!pip install fastapi "uvicorn[standard]" python-multipart pyngrok "transformers==4.38.2" -q
```

### 2. Hubungkan Google Drive

```python
from google.colab import drive
drive.mount('/content/drive')
```

### 3. Atur lokasi checkpoint

Sesuaikan `MODEL_PATH` dengan lokasi model di Google Drive:

```python
MODEL_PATH = "/content/drive/MyDrive/detr_output_new_data_latih_2_70_20_10/checkpoints/epoch_50"
```

Folder checkpoint harus memuat file yang diperlukan oleh `from_pretrained()`, misalnya:

```text
config.json
preprocessor_config.json
label_map.json
model.safetensors atau pytorch_model.bin
```

### 4. Simpan token ngrok dengan aman

Jangan menulis token ngrok langsung di notebook yang diunggah ke GitHub. Simpan token menggunakan **Colab Secrets** dengan nama:

```text
NGROK_AUTH_TOKEN
```

Contoh penggunaannya:

```python
from google.colab import userdata
from pyngrok import ngrok

ngrok.set_auth_token(userdata.get("NGROK_AUTH_TOKEN"))
```

### 5. Jalankan server

FastAPI berjalan pada port `8000` dan menyediakan endpoint:

```text
POST /predict
GET  /health
```

Setelah tunnel ngrok dibuat, salin URL publiknya ke `_apiUrl` pada aplikasi Flutter.

## Format Permintaan API

Endpoint prediksi menerima gambar dengan nama field `image` menggunakan format `multipart/form-data`.

Contoh menggunakan cURL:

```bash
curl -X POST \
  -F "image=@contoh_makanan.jpg" \
  https://URL-NGROK-ANDA.ngrok-free.app/predict
```

## Contoh Respons API

```json
{
  "predictions": [
    {
      "label": "udang",
      "confidence": 0.92,
      "is_allergen": true,
      "box": [0.12, 0.18, 0.56, 0.71]
    }
  ],
  "has_allergen": true,
  "allergen_summary": "udang"
}
```

Koordinat `box` menggunakan format:

```text
[x1, y1, x2, y2]
```

dan telah dinormalisasi terhadap ukuran citra pada rentang 0 sampai 1.

## Model, Dataset, dan Kode Pelatihan


- **Dataset skenario 1:** `https://drive.google.com/drive/folders/17sG9iNiJh8NbpS1riumd4LM0xkJ0o53T?usp=sharing`
- **Dataset skenario 2:** `https://drive.google.com/drive/folders/1T6zznW712l3SyBoYrlleKO85mCt67-C6?usp=sharing`
- **Dataset pengujian skenario 1:** `https://drive.google.com/drive/folders/1-g1igZqxSwDWB3j0-LQ7I9P4Ai27Im1A?usp=sharing`
- **Dataset pengujian skenario 2:** `https://drive.google.com/drive/folders/1d31hqeNMEGBBj9USiUxluQ4adwyw_Ns8?usp=sharing`
- **Pemilihan Model Terbaik:** `https://drive.google.com/drive/folders/1UXp9GyrigbQxfYfjvk19hkhXp2xUhy4k?usp=drive_link`


## Cara Penggunaan Aplikasi

1. Masuk menggunakan akun yang tersedia.
2. Isi nama pengguna dan pilih bahan yang menjadi alergi.
3. Ambil foto hidangan atau pilih gambar dari galeri.
4. Tekan tombol untuk memulai analisis.
5. Aplikasi mengirimkan gambar ke FastAPI.
6. Model DETR melakukan deteksi bahan makanan.
7. Aplikasi menampilkan bahan, confidence score, bounding box, dan status alergi.
8. Hasil analisis dapat disimpan ke riwayat.

## Batasan Sistem

- Sistem hanya mengenali sepuluh kategori bahan yang digunakan saat pelatihan.
- Bahan yang tertutup sepenuhnya atau tidak tampak secara visual tidak dapat dideteksi.
- Performa dipengaruhi oleh pencahayaan, sudut pengambilan gambar, kualitas citra, dan tumpang tindih antarobjek.
- URL ngrok dapat berubah setelah runtime Google Colab berhenti.
- FastAPI hanya dapat digunakan selama runtime Google Colab dan tunnel ngrok masih aktif.
- Hasil deteksi merupakan alat bantu dan tidak menggantikan pemeriksaan medis atau informasi resmi dari penyedia makanan.



## Membersihkan Proyek Sebelum Diunggah

Jalankan perintah berikut untuk menghapus hasil build dan cache Flutter:

```bash
flutter clean
flutter pub get
```


## Lisensi dan Penggunaan

Repositori ini dibuat untuk keperluan akademik dan pengumpulan skripsi. Penggunaan, pengembangan, atau distribusi lebih lanjut harus mencantumkan sumber dan memperoleh izin dari penulis apabila diperlukan.

## Penulis

**Vincent Wijaya**  
NIM 535220064  
Program Studi Teknik Informatika  
Fakultas Teknologi Informasi  
Universitas Tarumanagara
