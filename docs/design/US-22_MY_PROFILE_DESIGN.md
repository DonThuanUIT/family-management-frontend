# Đặc Tả Giao Diện US-22: Hồ Sơ Cá Nhân & Đổi Mật Khẩu (My Profile)

## 1. Giới thiệu & Mục tiêu
- **User Story ID:** US-22
- **Tên User Story:** Thành viên tự xem và cập nhật hồ sơ cá nhân (SĐT, email, địa chỉ) và đổi mật khẩu.
- **Đối tượng:** Tất cả thành viên trong dòng họ có tài khoản đã kích hoạt.
- **Đường dẫn Route:** `/profile`
- **Mục tiêu:** Cung cấp cho thành viên không gian tự phục vụ quản lý thông tin liên hệ và bảo mật tài khoản, đồng thời bảo vệ tính bất biến của dữ liệu phả hệ nhân khẩu (Họ tên, ngày sinh, giới tính, đời thứ, chi nhánh).

---

## 2. Cấu trúc Giao diện & Luồng Tương tác

### 2.1. Header Thẻ Thành Viên (Profile Summary Card)
- **Avatar tròn:** Chữ cái đầu tên thành viên với viền Hoàng Kim (`#D4A017`), nền dốc Đỏ Son (`#8B1E1E` -> `#5A1212`).
- **Họ tên & Phân vị:** Hiển thị họ tên đầy đủ, tên chi tộc, số thế hệ (đời thứ).
- **Badges:**
  - Badge vai trò: Trưởng tộc, Trưởng nhánh, Thủ quỹ, Thành viên.
  - Badge trạng thái tài khoản: Kích hoạt / Hợp lệ (xanh lá cây `#006E2A`).

### 2.2. Khối 1: Thông Tin Phả Hệ Nhân Khẩu (Read-Only)
- **Mục đích:** Bảo vệ tính toàn vẹn lịch sử dòng họ.
- **Dấu hiệu nhận biết:** Huy hiệu `Read-only` kèm icon `Icons.lock_outline`, viền nét nhạt `#ECE6DF`, nền `#FBF9F6`.
- **Banner lưu ý:** Hộp thông báo màu vàng đồng giải thích rõ nguyên nhân không cho phép tự sửa (chỉ Trưởng tộc hoặc Trưởng nhánh mới có thẩm quyền hiệu đính gia phả).
- **Các trường cố định:**
  - Họ và tên (`fullName`)
  - Ngày sinh (`dateOfBirth` - định dạng `dd/MM/yyyy`)
  - Giới tính (`gender` - Nam / Nữ / Khác)
  - Đời thứ / Thế hệ (`generation`)
  - Chi nhánh / Phân chi (`branchName`)

### 2.3. Khối 2: Cập Nhật Thông Tin Liên Lạc (Editable Form)
- **Mục đích:** Cho phép thành viên tự do cập nhật kênh liên lạc cá nhân.
- **Các trường nhập liệu:**
  - **Số điện thoại:** Bắt buộc, 10 chữ số, bắt đầu bằng số `0`.
  - **Địa chỉ Email:** Tùy chọn, kiểm tra regex định dạng email tiêu chuẩn.
  - **Địa chỉ thường trú:** Tùy chọn, hiển thị đa dòng (tối đa 255 ký tự).
- **Nút hành động:** "Lưu Thông Tin Liên Lạc" (Màu Đỏ Son `AppTheme.primaryCrimson`), có trạng thái loading spinner khi đang gọi API.

### 2.4. Khối 3: Đổi Mật Khẩu Đăng Nhập (Self-Service Security)
- **Mục đích:** Đổi mật khẩu tài khoản bảo mật.
- **Các trường nhập liệu:**
  - **Mật khẩu hiện tại:** Bắt buộc, có nút ẩn/hiện mắt (`obscureText`).
  - **Mật khẩu mới:** Bắt buộc, tối thiểu 6 ký tự, không được trùng mật khẩu cũ.
  - **Xác nhận mật khẩu mới:** Bắt buộc, phải khớp chính xác với mật khẩu mới.
- **Nút hành động:** "Cập Nhật Mật Khẩu" (Màu Nâu Đất Đậm `#2B1810`), xóa sạch form khi thành công.

---

## 3. Quản lý Trạng thái & Tích hợp API
- **Provider:** `profileProvider` (sử dụng Riverpod `NotifierProvider<ProfileNotifier, ProfileState>`).
- **DataSource:** `ProfileRemoteDataSourceImpl` gọi các endpoints:
  - `GET /api/v1/profile/me`: Lấy dữ liệu hồ sơ cá nhân.
  - `PUT /api/v1/profile/me`: Cập nhật SĐT, email, địa chỉ.
  - `POST /api/v1/profile/change-password`: Đổi mật khẩu tài khoản.
