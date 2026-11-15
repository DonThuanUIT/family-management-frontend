# US-32 — Triển khai frontend và kiểm chứng

## Phạm vi đã triển khai

- Nhánh triển khai: `feat/fe-us32-member-media`.
- Route `/members/:memberId`; mở từ biểu tượng **Xem hồ sơ thành viên** trong danh sách chi/nhánh hoặc nút **Ảnh chân dung, tiểu sử và tư liệu gia sử** tại Hồ sơ cá nhân.
- Ảnh chân dung: chọn JPEG/PNG, kiểm tra dung lượng/kích thước, cắt vuông, chuẩn hóa PNG 512 px trước khi gửi API, thay/gỡ ảnh và cập nhật avatar trong danh sách thành viên.
- Tiểu sử: Quill Rich Text với định dạng backend hỗ trợ, giới hạn 20.000 Unicode scalar/100 KiB JSON, phân quyền xem. Liên kết HTTPS được sao chép khi nhấn, không tự mở trang ngoài.
- Tư liệu: chọn nhiều PDF/JPEG/PNG, thông tin riêng cho từng file, upload tuần tự, tiến trình, thử lại cùng bytes và Idempotency-Key; sửa mô tả/quyền, xóa theo phiên bản, phân trang, xem ảnh riêng tư và tải file qua phiên đăng nhập. PDF được tải để mở bằng ứng dụng đọc PDF của thiết bị.
- File tải về dùng bytes đã xác thực; Web gửi tới trình tải của trình duyệt, mobile mở hộp thoại lưu của hệ thống. Hủy lưu trên mobile không báo thành công.
- Xung đột 409 giữ bản nháp và yêu cầu tải phiên bản mới trước khi lưu lại; lỗi idempotency có thao tác tạo lượt tải mới và giữ thông tin nhập.
- Loading, rỗng, lỗi mạng, hết phiên, không có quyền, giới hạn quyền xem và chế độ chỉ đọc. Khả năng chỉnh sửa lấy từ backend.
- Đổi JWT/clan hoặc danh tính sẽ hủy request, xóa state riêng tư và đóng dialog/bản nháp, kể cả dialog liên kết lồng nhau. Private image không dùng global ImageCache. Lỗi 401/403/404 không bị FutureProvider tự retry vô hạn.
- Không thêm Supabase SDK/key vào frontend. Backend giữ nguyên mã nguồn/cấu hình. Android release có quyền INTERNET; cấu hình API production cần HTTPS.

## Vị trí mã nguồn

- `lib/features/member_media/data/`: DTO, API JSON/multipart/bytes và ánh xạ Failure.
- `lib/features/member_media/domain/`: repository contract, cancellation boundary và chuẩn hóa Delta.
- `lib/features/member_media/presentation/`: provider, màn hình responsive và các dialog.
- `lib/core/files/member_file_actions.dart`: chọn/lưu file, kiểm tra kích thước ảnh, resize, UUID v4.
- `core/storage/secure_token_storage.dart`: tín hiệu xóa nội dung riêng tư khi thay đổi phiên.
- Bốn dependency đã duyệt được ghi trong `pubspec.yaml`, phiên bản resolve trong `pubspec.lock`.

## Kết quả kiểm chứng

Ngày kiểm chứng: 12/11/2026.

- **22 kiểm thử mới US-32 đạt**, gồm DTO/quyền, Delta, Unicode và byte limit, file limit, parser kích thước JPEG/PNG tương thích Web, URL API không lặp `/api/v1`, lỗi API, hủy request, ngăn dữ liệu phiên cũ, xung đột giữ nháp, retry upload bằng cùng key/bytes, đóng dialog lồng nhau và từ chối đọc tư liệu.
- Widget test ở **390 / 840 / 1280 px**, có tăng cỡ chữ **125%**: đạt.
- `flutter build web --no-pub --no-wasm-dry-run --no-web-resources-cdn`: đạt.
- Chrome headless cô lập: đăng nhập bằng tài khoản demo có sẵn, mở hồ sơ từ backend thật, kiểm tra ba viewport; chọn ảnh và hiển thị crop rồi hủy, mở editor tiểu sử; chọn PNG mẫu qua file chooser thật, upload từ Flutter tới backend/Supabase, xác nhận MIME `image/png`, quyền mặc định `RESTRICTED`, mở preview ảnh qua API có xác thực và tải thành công file PNG về trình duyệt. Tư liệu mẫu của từng lượt chạy đã được xóa qua API; worker backend phụ trách dọn object theo cơ chế hiện có.
- Không sửa ảnh chân dung hoặc tiểu sử sẵn có của tài khoản demo trong kiểm chứng trình duyệt. Luồng ghi tiểu sử/xung đột và retry được kiểm thử bằng repository fixture.
- `flutter analyze --no-pub`: **không có lỗi/cảnh báo mới**; còn 9 chẩn đoán cũ trong feature contribution/role (4 warning, 5 info).
- Regression toàn bộ: **97 đạt, 2 lỗi cũ**. US-22 kỳ vọng chữ “Hồ Sơ Cá Nhân” mà thanh điều hướng hiện không render `customTitle`; US-25 tràn hàng tiêu đề live preview trong `privacy_settings_screen.dart`. Không sửa lan hai màn hình này trong US-32. Bổ sung phương thức còn thiếu vào fake repository US-27 để bộ test có thể biên dịch.
- Chưa chạy trên thiết bị/emulator Android hoặc iOS; chưa xác minh hộp thoại lưu file native. iOS target hiện tại 15.0 đáp ứng yêu cầu tối thiểu iOS 14 của file picker.

Log và ảnh kiểm chứng cục bộ nằm trong `build/` (Git ignore): `us32-full-tests.log`, `us32-app-qa.json`, `us32-app-390.png`, `us32-app-840.png`, `us32-app-1280.png`, `us32-app-crop-mobile.png`, `us32-app-biography-mobile.png`, `us32-app-upload-mobile.png`, `us32-app-private-preview-mobile.png`.

## Chạy và kiểm tra tiếp

```sh
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
flutter test test/features/member_media
```

Với hồ sơ có quyền chỉnh sửa, kiểm tra chọn/cắt/lưu/gỡ avatar; viết và lưu các định dạng tiểu sử; upload nhiều file, sửa thông tin/quyền, tải PDF và xóa. Dùng hai phiên để tạo xung đột, kiểm tra bản nháp không mất và yêu cầu xác nhận tải bản mới. Với tài khoản chỉ đọc, kiểm tra không hiện nút ghi và không thấy tư liệu bị ẩn. Trên mobile cần kiểm tra thêm chọn file từ thiết bị, bàn phím, hủy/lưu file và đổi phiên khi đang tải.
