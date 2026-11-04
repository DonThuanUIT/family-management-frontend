# Family Management Frontend (`familyfund_app`)

Ứng dụng đa nền tảng (**Flutter Web & Mobile Android/iOS**) phục vụ **Hệ thống Quản lý Sự kiện và Quỹ Đại Gia Đình**, hỗ trợ đầy đủ cả **Phân hệ Thành viên / Con cháu** (`memberPortal`) và **Phân hệ Quản trị / Trưởng tộc & Ban Tổ Chức** (`managementPortal`) trên cùng một codebase theo kiến trúc **Feature-first + Clean Architecture**.

---

## 📋 Mục Lục

- [Yêu Cầu Hệ Thống & Tiên Quyết](#-yêu-cầu-hệ-thống--tiên-quyết)
- [Hướng Dẫn Cài Đặt Flutter SDK](#-hướng-dẫn-cài-đặt-flutter-sdk)
  - [1. Tải và Giải nén Flutter SDK](#1-tải-và-giải-nén-flutter-sdk)
  - [2. Cấu hình biến môi trường (PATH)](#2-cấu-hình-biến-môi-trường-path)
  - [3. Kiểm tra môi trường với `flutter doctor`](#3-kiểm-tra-môi-trường-với-flutter-doctor)
  - [4. Cài đặt IDE & Extension](#4-cài-đặt-ide--extension)
- [Cài Đặt Dự Án & Khởi Chạy](#-cài-đặt-dự-án--khởi-chạy)
- [Khắc Phục Sự Cố Thường Gặp](#-khắc-phục-sự-cố-thường-gặp)
- [Tài Liệu Tham Khảo](#-tài-liệu-tham-khảo)

---

## 💻 Yêu Cầu Hệ Thống & Tiên Quyết

- **Hệ điều hành**: Windows 10/11 (64-bit), macOS hoặc Linux.
- **Git**: Đã cài đặt [Git](https://git-scm.com/) trên máy.
- **Trình duyệt (cho Web)**: Google Chrome hoặc Microsoft Edge.
- **Thiết bị / Giả lập (cho Mobile)**:
  - **Android**: [Android Studio](https://developer.android.com/studio) với Android SDK & Android Emulator (hoặc điện thoại thật bật chế độ USB Debugging).
  - **iOS** *(chỉ trên macOS)*: Xcode bản mới nhất cùng CocoaPods.
- **Flutter SDK khuyến nghị**: Phiên bản **Flutter 3.24+** (kênh `stable`), tích hợp sẵn **Dart SDK 3.5+**.

---

## 🛠️ Hướng Dẫn Cài Đặt Flutter SDK

### 1. Tải và Giải nén Flutter SDK

#### Cách A: Tải từ trang chủ chính thức (Khuyên dùng)
1. Truy cập trang tải chính thức: **[docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)**.
2. Chọn hệ điều hành máy tính của bạn (Windows, macOS hoặc Linux).
3. Tải về file nén Flutter SDK (kênh **Stable**).
4. Giải nén vào một thư mục chuyên dụng, ví dụ:
   - **Windows**: `C:\src\flutter` (hoặc `D:\flutter`).
     > [!WARNING]
     > Không cài đặt hoặc giải nén Flutter vào thư mục yêu cầu quyền Quản trị viên (như `C:\Program Files\`) hoặc thư mục có dấu tiếng Việt, khoảng trắng.
   - **macOS / Linux**: `~/development/flutter`.

#### Cách B: Cài đặt qua dòng lệnh hoặc Trình quản lý gói

- **Windows (PowerShell)**:
  ```powershell
  # Cài qua Windows Package Manager:
  winget install Google.Flutter
  
  # Hoặc clone trực tiếp bằng Git:
  git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
  ```
- **macOS (Homebrew)**:
  ```bash
  brew install --cask flutter
  ```
- **Linux (Snap)**:
  ```bash
  sudo snap install flutter --classic
  ```

---

### 2. Cấu hình biến môi trường (PATH)

Sau khi giải nén, bạn cần thêm thư mục `bin` của Flutter vào biến môi trường `PATH` để có thể thực thi lệnh `flutter` ở bất kỳ đâu trên Terminal / Command Prompt.

#### Trên Windows:
1. Mở menu **Start**, tìm kiếm `env` và chọn **Edit the system environment variables** (hoặc *Chỉnh sửa biến môi trường hệ thống*).
2. Nhấn vào nút **Environment Variables...** (Biến môi trường).
3. Trong mục **User variables** (hoặc **System variables**), tìm biến `Path` và chọn **Edit...**.
4. Nhấn **New**, sau đó nhập đường dẫn đến thư mục `bin` của Flutter SDK (ví dụ: `C:\src\flutter\bin`).
5. Nhấn **OK** ở tất cả các cửa sổ để lưu lại thay đổi.
6. **Khởi động lại Terminal / PowerShell / VS Code** để nhận diện biến môi trường mới.

#### Trên macOS / Linux:
Mở terminal và thêm Flutter vào file cấu hình shell (`~/.zshrc` hoặc `~/.bashrc`):
```bash
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

---

### 3. Kiểm tra môi trường với `flutter doctor`

Mở một cửa sổ Terminal / PowerShell mới và chạy:

```bash
flutter doctor
```

Lệnh này sẽ quét toàn bộ hệ thống và hiển thị tình trạng các công cụ liên quan:
- `[✓] Flutter`: Flutter SDK đã được cài đặt thành công.
- `[✓] Windows Version / macOS`: Hệ điều hành tương thích.
- `[✓] Android toolchain`: Đã nhận diện Android SDK.
  > [!TIP]
  > Nếu gặp cảnh báo yêu cầu cấp phép bản quyền Android, hãy chạy lệnh sau và nhấn `y` để đồng ý tất cả điều khoản:
  > ```bash
  > flutter doctor --android-licenses
  > ```
- `[✓] Chrome`: Trình duyệt Chrome sẵn sàng để chạy và debug Web.
- `[✓] VS Code / Android Studio`: Các IDE đã được cấu hình.

---

### 4. Cài đặt IDE & Extension

Khuyến nghị sử dụng **Visual Studio Code**:
1. Tải và cài đặt [Visual Studio Code](https://code.visualstudio.com/).
2. Mở VS Code, nhấn tổ hợp phím `Ctrl + Shift + X` (hoặc `Cmd + Shift + X` trên Mac) để vào kho Extensions.
3. Tìm kiếm và cài đặt 2 extension:
   - **Flutter** (từ `Dart-Code`)
   - **Dart** (sẽ tự động cài kèm theo Flutter)

---

## 🚀 Cài Đặt Dự Án & Khởi Chạy

Sau khi đã có Flutter SDK, hãy mở thư mục dự án và thực hiện các bước sau:

```bash
# 1. Điều hướng vào thư mục frontend (nếu đang ở thư mục gốc)
cd family-management-frontend

# 2. Cài đặt các thư viện dependencies
flutter pub get

# 3. Sinh code tự động (BẮT BUỘC - dành cho Freezed, JsonSerializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 4. Kiểm tra phân tích tĩnh (Static Analysis)
flutter analyze

# 5. Chạy unit & widget tests
flutter test

# 6. Khởi chạy ứng dụng trên Web (Chrome)
flutter run -d chrome

# 7. Khởi chạy ứng dụng trên Mobile (Android Emulator / iOS Simulator / Thiết bị thật)
flutter run
```

### Chạy với cấu hình API Backend tùy chỉnh:
Mặc định ứng dụng tự động kết nối:
- Trên **Web**: `http://localhost:8080/api/v1/`
- Trên **Android Emulator**: `http://10.0.2.2:8080/api/v1/`

Nếu cần chỉ định địa chỉ Backend khác, dùng cờ `--dart-define`:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1/
```

---

## 🔧 Khắc Phục Sự Cố Thường Gặp

| Lỗi / Tình huống | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| `'flutter' is not recognized as an internal or external command` | Đường dẫn Flutter chưa được thêm vào `PATH`, hoặc terminal chưa được khởi động lại sau khi sửa `PATH`. | Kiểm tra lại mục [Cấu hình biến môi trường](#2-cấu-hình-biến-môi-trường-path), tắt và mở lại cửa sổ Terminal / IDE. |
| `Missing generated files (*.freezed.dart, *.g.dart)` hoặc lỗi đỏ ở các class model/provider | Chưa chạy generator sinh mã nguồn cho `freezed` và `riverpod_annotation`. | Chạy lệnh `dart run build_runner build --delete-conflicting-outputs`. |
| Cảnh báo Android Licenses khi chạy `flutter doctor` | Chưa chấp thuận điều khoản của Android SDK. | Chạy `flutter doctor --android-licenses` và gõ `y` cho tất cả câu hỏi. |
| Không nhận diện thiết bị / trình duyệt | Chưa bật USB debugging (đối với điện thoại thật) hoặc chưa cài Chrome. | Kiểm tra danh sách thiết bị bằng `flutter devices`. |

---

## 📚 Tài Liệu Tham Khảo

- **[docs/FRONTEND_ARCHITECTURE.md](./docs/FRONTEND_ARCHITECTURE.md)**: Chi tiết cấu trúc thư mục, kiến trúc phân lớp Clean Architecture và cơ chế bảo mật phân quyền kép (Dual-RBAC).
- **[Flutter Official Documentation](https://docs.flutter.dev/)**: Tài liệu chính thức từ đội ngũ Flutter.
