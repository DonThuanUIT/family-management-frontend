# Đặc Tả Giao Diện & Trải Nghiệm US-27: Ghi Nhận Sinh / Tử, Tính Ngày Giỗ Âm Lịch & Thờ Cúng Trang Trọng

## 1. Giới thiệu & Mục tiêu
- **User Story ID:** US-27
- **Tên User Story:** Ghi nhận tình trạng thành viên (còn sống / đã mất), ngày mất và tính ngày giỗ âm lịch.
- **Đối tượng thao tác (Actor):** Trưởng tộc (`CLAN_HEAD`), Trưởng nhánh (`BRANCH_HEAD`), Quản trị viên (`ADMIN`).
- **Mục tiêu UX/UI:**
  - Cung cấp giao diện trang nghiêm, trực quan để cập nhật tình trạng sinh/tử của thành viên.
  - Tích hợp bộ chuyển đổi Âm lịch tức thì (Live Preview): khi chọn ngày mất Dương lịch, hệ thống hiển thị ngay ngày giỗ Âm lịch kèm năm Can Chi và tuổi hưởng thọ.
  - Thiết kế viền và nhãn thờ cúng trang trọng trên thẻ thành viên đã mất trên Cây Gia Phả và Danh Sách Thành Viên (Sidebar).

---

## 2. Quy Tắc Trực Quan (Visual Design Guidelines)

### 2.1. Thẻ thành viên đã mất (Deceased Member Card)
- **Tông màu:**
  - Nền ngà trầm ấm: `#FAF6F0` hoặc `#FFFDF8`.
  - Viền trang nghiêm: Màu tro trầm `#54433E` hoặc vàng đồng cổ `#B8860B` với độ dày 1.5px.
  - Phù hiệu thờ cúng: Biểu tượng hoa sen 🪷 hoặc ngọn nến thơm 🕯️ bên cạnh tên thành viên.
- **Huy hiệu trạng thái (Status Badge):**
  - Nhãn: `Đã mất` (nền xám tro nhạt `#F2ECE9`, chữ `#54433E`, font đậm).
- **Dòng thông tin tưởng niệm:**
  - `Hưởng thọ: X tuổi • Giỗ: dd/MM ÂL (Năm Can Chi)`.
  - Ví dụ: `Hưởng thọ: 84 tuổi • Giỗ: 15/02 ÂL (Giáp Thìn)`.
  - Nơi an táng: Hiển thị icon địa điểm `Icons.location_on_outlined` kèm địa chỉ phần mộ/nghĩa trang (nếu có).

### 2.2. Hộp thoại cập nhật tình trạng Sinh / Tử (`UpdateLifeStatusDialog`)
- **Kích thước:** Modal Dialog nổi giữa màn hình (Web/Tablet rộng $\approx$ 520px, Mobile co giãn theo chiều rộng màn hình).
- **Thành phần giao diện:**
  1. **Header:** Icon ngọn nến hoặc hoa sen trang trọng, tiêu đề *"Cập Nhật Tình Trạng Thành Viên - [Tên Thành Viên]"*, nút đóng $\times$.
  2. **Bộ chuyển đổi trạng thái (Segmented Button):**
     - Hai lựa chọn rõ ràng:
       - `[ 🌿 Còn sống ]` (Màu xanh lục `#006E2A`).
       - `[ 🕯️ Đã mất ]` (Màu đồng trầm `#8F482F` hoặc `#54433E`).
  3. **Vùng nhập liệu khi chọn "Đã mất":**
     - **Bộ chọn ngày mất Dương lịch:** `DatePicker` tiếng Việt, bắt buộc. Ràng buộc:
       - Chặn chọn ngày trong tương lai ($> \text{now}$).
       - Chặn chọn ngày trước ngày sinh của thành viên ($< \text{dateOfBirth}$).
     - **Thẻ xem trước ngày giỗ Âm lịch (Live Preview):**
       - Container màu vàng ngà `#FFFDF8`, viền `#D4A017`, bo góc 10px.
       - Tự động hiển thị ngay:
         - Ngày giỗ Âm lịch: `Ngày 15 tháng 02 năm Giáp Thìn (Âm lịch)`.
         - Tuổi hưởng thọ: `84 tuổi`.
     - **Địa chỉ phần mộ / Nơi an táng (Tùy chọn):**
       - TextField 2 dòng: Ví dụ `Khu lăng mộ họ Nguyễn, nghĩa trang quê nhà, Hưng Yên`.
     - **Banner bảo lưu dữ liệu & bảo mật tài khoản:**
       - Nền màu vàng nhạt `#FFF9E6`, viền `#FFE082`.
       - Nội dung: *"Tài khoản đăng nhập (nếu có) sẽ tự động bị khóa để bảo mật. Vị trí trên cây phả hệ và toàn bộ lịch sử đóng góp quỹ dòng họ của thành viên được bảo lưu trọn vẹn 100%."*
  4. **Nút hành động:**
     - Nút *"Hủy"* (Outlined/Text button).
     - Nút *"Lưu Thay Đổi"* (ElevatedButton màu đỏ son `#8B1E1E`, hiển thị loading spinner khi đang xử lý API).

---

## 3. Kiến Trúc Mã Nguồn Frontend

```
family-management-frontend/lib/
├── core/
│   └── utils/
│       └── vietnamese_lunar_calendar.dart   <-- Bộ chuyển đổi Dương lịch <-> Âm lịch chuẩn Hồ Ngọc Đức
└── features/
    └── genealogy/
        ├── data/
        │   ├── datasources/
        │   │   └── genealogy_remote_datasource.dart (bổ sung updateLifeStatus)
        │   └── models/
        │       ├── branch_models.dart (thêm deathDate, status, burialPlace, isDeceased)
        │       └── update_life_status_request_dto.dart
        ├── presentation/
        │   ├── providers/
        │   │   └── genealogy_providers.dart (hàm updateLifeStatus và reload cây phả hệ)
        │   └── widgets/
        │       ├── update_life_status_dialog.dart   <-- Dialog cập nhật sinh/tử kèm lunar live preview
        │       └── branch_detail_sidebar.dart       <-- Cập nhật thẻ thành viên hiển thị viền/nhãn thờ cúng trang trọng
```
