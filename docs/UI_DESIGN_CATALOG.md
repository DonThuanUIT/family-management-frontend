# Danh Mục Thiết Kế Giao Diện Hệ Thống (UI Design Catalog)
**Dự án**: FamilyFund - Quản Lý Sự Kiện & Quỹ Đại Gia Đình (Gia Tộc Việt Nam)  
**Kiến trúc**: Adaptive Dual-Portal (Mobile App con cháu + Web/Desktop Admin Portal)  
**Cập nhật lần cuối**: 01/11/2026

---

## 1. Nguồn Lưu Trữ Thiết Kế Đã Đọc & Lưu Vào Dự Án

Toàn bộ tài nguyên thiết kế từ **Figma** (Mobile) và **Stitch** (Web) đã được tải về và lưu trữ cố định trong thư mục `docs/` của dự án:

| Nền tảng | Nguồn gốc | Thư mục lưu trữ nội bộ | Nội dung lưu trữ |
| :--- | :--- | :--- | :--- |
| **Mobile App** | Figma (`ergCC6DpOHIdUef0lJ9Drk`) | [`docs/figma_previews/`](file:///d:/family-management-frontend/docs/figma_previews) | Đầy đủ 9 ảnh chụp màn hình độ phân giải cao (`01_*.png` $\rightarrow$ `09_*.png`). |
| **Web Portal** | Stitch Project `1546466708008991451` | [`docs/stitch/stitch_familyfund_clan_management_platform/`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform) | Đầy đủ 7 màn hình Web (`code.html` + `screen.png`) + Đặc tả hệ thống [`DESIGN.md`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/warm_editorial_heritage/DESIGN.md). |

---

## 2. Hệ Thống Design Tokens Dùng Chung (Warm Editorial Heritage)

- **Phong cách**: *Warm Editorial* — Tôn nghiêm truyền thống, kết hợp chất liệu giấy ngà/giấy dó (`#FAF9F5`), đường kẻ chỉ tinh xảo (`1px solid #E6DFD8`), không dùng xám lạnh vô cảm.
- **Bảng màu chuẩn**:
  - **Primary (Đỏ son / Terracotta)**: `#8F482F` / `#8B1E1E` — Màu chủ đạo, đại diện gia phong và huyết thống.
  - **Secondary (Xanh ngọc lục bảo / Emerald Ledger)**: `#2E8B43` — Biểu thị số dư dương, khoản thu đã đối soát tất toán.
  - **Tertiary (Vàng hoàng kim / Warm Amber)**: `#D4A017` / `#B36E1B` — Huy hiệu, hương hỏa, vật phẩm thờ tự, chứng từ.
  - **Critical / Outflow (Đỏ gạch)**: `#C64545` — Chi phí, cảnh báo trễ hạn công việc (12h/24h).
  - **Canvas Background**: `#FAF9F5` (nền sáng ngà cổ kính); **Cards**: `#F5F0E8` / `#FFFFFF`.
- **Typography**:
  - **Headlines / Đại tự**: `Merriweather` (hoặc `Be Vietnam Pro` in hoa đậm).
  - **Body / Interface**: `Plus Jakarta Sans` / `Be Vietnam Pro`.
  - **Mã định danh / Sổ cái**: `JetBrains Mono` (dùng cho mã thế hệ `GEN-04-B02`, số tiền tệ VNĐ, mã băm SHA-256).

---

## 3. Danh Mục 9 Màn Hình Mobile App (Figma)

Toàn bộ ảnh chụp màn hình được lưu trong [`docs/figma_previews/`](file:///d:/family-management-frontend/docs/figma_previews):

| STT | Màn hình | Node ID | Tệp ảnh đã lưu | Chức năng & Thành phần UI chính |
| :---: | :--- | :---: | :--- | :--- |
| **01** | **Chào Mừng** | `1:2` | [`01_welcome_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/01_welcome_screen.png) | • Huy hiệu Gia Tộc Việt Nam (Trống đồng & Hoa sen).<br>• Nút Tạo cây gia phả mới (Trưởng tộc).<br>• Nút Nhập mã gia phả dòng họ (Thành viên).<br>• Dải họa tiết sơn mài phân cách & liên kết Đăng nhập ngay. |
| **02** | **Đăng Ký Thành Viên** | `1:61` | [`02_register_member_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/02_register_member_screen.png) | • Banner *"Ghi Tên Vào Gia Phả"*, hoa văn góc truyền thống.<br>• Ô nhập & quét QR mã thư mời nhánh chi (`DK-CHI2-NHA-A-05`).<br>• Form nhập: Họ tên, Số điện thoại, Giới tính, Ngày sinh.<br>• Cam kết gia phong & nút Hoàn tất đăng ký. |
| **03** | **Trang Chủ Gia Tộc** | `1:188` | [`03_home_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/03_home_screen.png) | • Thẻ định danh: *"Chào cháu - Đời thứ 12, Chi 2"* + Ngày âm lịch.<br>• Thẻ sự kiện nổi bật màu đỏ rượu: *"Đại Lễ Giỗ Tổ Đầu Xuân 2026"* + Nút Đăng ký tham gia ngay.<br>• Thẻ việc họ cá nhân & Đóng góp thường niên.<br>• Thông báo từ Trưởng tộc (dự thảo tu bổ nhà bia) + 2 nút phản hồi.<br>• Album ảnh Khoảnh khắc sum họp + Bottom Navigation Bar 5 tab. |
| **04** | **Đăng Ký Dự Lễ** | `1:388` | [`04_event_registration_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/04_event_registration_screen.png) | • Thông tri đại lễ: Ngày 10/03 ÂL, hạn chót báo cỗ.<br>• Chọn số lượng người tham dự (Stepper tăng giảm, quy đổi số mâm cỗ 6 người).<br>• Chọn loại cỗ: Cỗ mặn truyền thống / Cỗ chay / Cỗ trẻ nhỏ + Ghi chú dị ứng.<br>• Phương tiện di chuyển: Tự túc / Xe chung dòng họ.<br>• Sticky footer bar xác nhận gửi Ban Tổ Chức. |
| **05** | **Tiến Độ Công Việc** | `1:568` | [`05_task_progress_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/05_task_progress_screen.png) | • Hạng mục: Mua sắm mâm cỗ & Lễ vật dâng hương (KPI 60% vòng tròn).<br>• Bộ đếm ngược thời hạn (Ngày : Giờ : Phút) + Cảnh báo trễ hạn 24h/12h.<br>• Kinh phí tộc biểu: Tạm ứng (5tr), Đã chi (3.45tr), Còn dư (1.55tr).<br>• Checklist công việc 5 việc (mua hoa quả, trầu cau, heo quay...).<br>• Tải ảnh hóa đơn chứng từ & Nút Báo cáo hoàn thành công việc. |
| **06** | **Báo Cáo Thu Chi** | `1:833` | [`06_finance_report_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/06_finance_report_screen.png) | • Quyết toán thu chi sự kiện toàn diện.<br>• Tổng thu cúng tiến (45tr), Thực tế chi lễ (38.5tr), Hiện vật quy đổi.<br>• Danh sách hạng mục cỗ bàn, vàng hương kèm ảnh hóa đơn.<br>• Hộp con dấu & chữ ký số kép Trưởng tộc / Thủ quỹ.<br>• Tính năng sao kê & ghi nhận phản hồi giám sát cộng đồng. |
| **07** | **Phả Hệ Hữu Cơ** | `1:1084` | [`07_genealogy_tree_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/07_genealogy_tree_screen.png) | • Cây phả hệ số trên nền giấy dó truyền thống.<br>• Bộ công cụ: Thu phóng, tìm kiếm người thân.<br>• Thẻ hồ sơ thành viên: Họ tên, Thế hệ, Trưởng/Thứ, Chi phái, Quản tự từ đường, SĐT, năm sinh - mất.<br>• Nút hành động tương tác gia tộc (Liên hệ, kết nối cội nguồn). |
| **08** | **Lịch Sự Kiện Dòng Họ** | `1:1268` | [`08_event_calendar_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/08_event_calendar_screen.png) | • Lịch âm dương toàn diện theo tháng/Can chi.<br>• Đánh dấu huy hiệu vàng ngày sóc vọng, giỗ chạp và đại lễ.<br>• Danh sách chi tiết sự kiện trong ngày đã chọn.<br>• Nút nổi (FAB) viền vàng hoàng kim tạo sự kiện mới. |
| **09** | **Quỹ Họ & Tài Chính** | `1:1660` | [`09_clan_fund_screen.png`](file:///d:/family-management-frontend/docs/figma_previews/09_clan_fund_screen.png) | • Ngân khố dòng họ: Tổng quỹ thặng dư, kiểm kê gần nhất.<br>• Tabs phân loại: Quỹ tế tự, Quỹ khuyến học, Quỹ tu bổ từ đường.<br>• Thẻ kiểm toán từng sự kiện (Thu - Chi - Số hộ cúng tiến).<br>• Sổ cái cúng tiến, lịch sử giải ngân & Nút xuất chứng từ biên nhận. |

---

## 4. Danh Mục 7 Màn Hình Web / Desktop Admin Portal (Stitch)

Toàn bộ mã HTML/CSS và ảnh render được lưu trong [`docs/stitch/stitch_familyfund_clan_management_platform/`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform):

| STT | Màn hình | Thư mục lưu trữ nội bộ | Tệp mã nguồn & Ảnh | Tính năng cốt lõi |
| :---: | :--- | :--- | :--- | :--- |
| **W1** | **Đăng Nhập & Kích Hoạt Mã Mời** | `ng_nh_p_k_ch_ho_t_m_m_i_gia_ph` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/ng_nh_p_k_ch_ho_t_m_m_i_gia_ph/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/ng_nh_p_k_ch_ho_t_m_m_i_gia_ph/screen.png) | • Layout chia đôi: Giới thiệu triết lý gia tộc và form đăng nhập.<br>• Nhập mã mời `LE-CHI2-DOI5-9821` tự động gắn vào Đời 5, Chi 2.<br>• Hỗ trợ đăng nhập mật khẩu hoặc kích hoạt mã mời trực tiếp. |
| **W2** | **Sơ Đồ Phả Hệ Đa Chi Phái** | `c_y_ph_h_tr_c_quan_a_chi_ph_i` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_y_ph_h_tr_c_quan_a_chi_ph_i/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_y_ph_h_tr_c_quan_a_chi_ph_i/screen.png) | • Canvas Cây phả hệ số 5 thế hệ (128 nhân khẩu).<br>• Node Thủy Tổ Đời 1 niêm phong + 4 chi nhánh lớn.<br>• Chi 1 & Chi 2 hiển thị quỹ tích lũy từng chi và chuỗi kế thừa.<br>• Breadcrumb đáy màn hình định vị chính xác vị trí con cháu. |
| **W3** | **Cấp Mã Mời & Khởi Tạo Hồ Sơ** | `c_p_m_m_i_kh_i_t_o_h_s_gia_ph` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_p_m_m_i_kh_i_t_o_h_s_gia_ph/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_p_m_m_i_kh_i_t_o_h_s_gia_ph/screen.png) | • Cơ chế phân cấp hồ sơ có tọa độ phả hệ niên khóa 2026.<br>• Tạo mã liên kết thành viên mới gắn chi phái và đời thứ.<br>• Mô thức ghép nhánh trực quan (Khớp mã 100%, băm SHA-256).<br>• Bảng quản lý 12 mã liên kết đã phát hành kèm trạng thái kích hoạt. |
| **W4** | **Quản Lý Sự Kiện & Phân Việc** | `qu_n_l_s_ki_n_ph_n_c_ng_nhi_m_v` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/qu_n_l_s_ki_n_ph_n_c_ng_nhi_m_v/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/qu_n_l_s_ki_n_ph_n_c_ng_nhi_m_v/screen.png) | • Quản lý Lễ Giỗ Tổ (85 người, 18 mâm cỗ đăng ký).<br>• 4 thẻ KPI ngân sách (Hạn mức, Tạm ứng, Quyết toán, Đối soát).<br>• Bảng Kanban 3 cột: Cần làm (To Do), Đang thực hiện, Đã quyết toán.<br>• Báo động đỏ trễ hạn 14h gửi SMS khẩn tới Trưởng tộc. |
| **W5** | **Sổ Cái Tài Chính & Đối Soát** | `s_c_i_t_i_ch_nh_i_so_t_ng_g_p` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/s_c_i_t_i_ch_nh_i_so_t_ng_g_p/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/s_c_i_t_i_ch_nh_i_so_t_ng_g_p/screen.png) | • Sổ cái Append-Only bất biến, đối soát 1:1 sao kê ngân hàng.<br>• 4 KPI: Tổng quỹ tích lũy (148tr), Đóng góp đệ quy (100% khớp 32 chi), Tạm ứng, Hiện vật.<br>• Bảng nhật ký giao dịch chi tiết (VietQR Auto, Chuyển khoản, Hiện vật).<br>• Chứng thư niêm phong chữ ký số Trưởng tộc. |
| **W6** | **Cổng Đóng Góp Quỹ Qua VietQR** | `c_ng_ng_g_p_th_nh_vi_n_vietqr` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_ng_ng_g_p_th_nh_vi_n_vietqr/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/c_ng_ng_g_p_th_nh_vi_n_vietqr/screen.png) | • Quét mã VietQR động Napas 247 có logo họ Lê ở tâm.<br>• Chọn mục đích quỹ (Khuyến học, Tu bổ, Tế tự) & số tiền (500k, 1tr, 2tr, 5tr).<br>• Cú pháp chuẩn hóa: `LE HUU TUAN DONG GOP CHI2`.<br>• Sinh phiếu thu điện tử và tự động ghi sổ cái sau 3 giây. |
| **W7** | **Trung Tâm Báo Cáo & Kiểm Toán** | `trung_t_m_b_o_c_o_ki_m_to_n_minh_b_ch` | [`code.html`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/trung_t_m_b_o_c_o_ki_m_to_n_minh_b_ch/code.html)<br>[`screen.png`](file:///d:/family-management-frontend/docs/stitch/stitch_familyfund_clan_management_platform/trung_t_m_b_o_c_o_ki_m_to_n_minh_b_ch/screen.png) | • Xuất bản 9 loại báo cáo chuyên sâu (Báo cáo Thu Chi, Hiện Vật Công Đức, Phát Triển Nhân Khẩu).<br>• Nhật ký niêm phong tự động bằng chuỗi băm SHA-256 Clan Hash.<br>• Tư liệu lưu trữ đối chiếu có ảnh từ đường và gia phả cổ năm 1928.<br>• Nút Xuất toàn bộ báo cáo dạng PDF dành cho Trưởng tộc. |

---

## 5. Tình Trạng Mã Nguồn Codebase Đối Ứng Hiện Tại

| Phân hệ mã nguồn Flutter | Màn hình cần triển khai theo Thiết Kế | Trạng thái codebase hiện tại |
| :--- | :--- | :--- |
| `features/auth` | Chào mừng, Đăng ký thành viên, Kích hoạt mã mời | **Đã hoàn thành cơ bản** ([`WelcomeScreen`](file:///d:/family-management-frontend/lib/features/auth/presentation/screens/welcome_screen.dart), [`RegisterMemberScreen`](file:///d:/family-management-frontend/lib/features/auth/presentation/screens/register_member_screen.dart), [`InviteCodeScreen`](file:///d:/family-management-frontend/lib/features/auth/presentation/screens/invite_code_screen.dart)). |
| `features/home` | Trang chủ Gia tộc (Thẻ sự kiện đỏ rượu, Việc họ, Khoảnh khắc sum họp) | **Cần nâng cấp** ([`HomeScreen`](file:///d:/family-management-frontend/lib/features/home/presentation/screens/home_screen.dart) hiện mới là placeholder). |
| `features/genealogy` | Cây phả hệ hữu cơ (Mobile) & Sơ đồ phả hệ 5 đời (Web) | **Chưa triển khai** (Mới có thư mục khung). |
| `features/event` | Đăng ký dự lễ (Mobile) & Quản lý sự kiện, Lịch âm dương | **Đã có 1 phần** ([`EventListScreen`](file:///d:/family-management-frontend/lib/features/event/presentation/screens/event_list_screen.dart), cần bổ sung Lịch Âm Dương & Đăng ký cỗ bàn). |
| `features/task` | Tiến độ hạng mục (Checklist, đếm ngược, cảnh báo 24h/12h) & Kanban (Web) | **Chưa triển khai** (Mới có thư mục khung). |
| `features/finance` | Cổng VietQR, Quỹ họ, Sổ cái Append-Only | **Chưa triển khai** (Mới có thư mục khung). |
| `features/report` | Báo cáo thu chi (Mobile) & Trung tâm kiểm toán minh bạch (Web) | **Chưa triển khai** (Mới có thư mục khung). |
