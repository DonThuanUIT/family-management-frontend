# Kiến Trúc Frontend Flutter (`familyfund_app`)

Tài liệu này mô tả chi tiết cấu trúc thư mục, kiến trúc **Feature-first + Clean Architecture**, công nghệ sử dụng và cách thức vận hành đa nền tảng (**Web App & Mobile App**) cho cả 2 phân hệ:
1. **Phân hệ Thành viên / Con cháu (`memberPortal`)**
2. **Phân hệ Quản trị / Trưởng tộc & Ban Tổ Chức (`managementPortal`)**

---

## 1. Công Nghệ Cốt Lõi (Tech Stack)

| Thành phần | Công nghệ / Package | Vai trò trong kiến trúc |
| :--- | :--- | :--- |
| **Framework & SDK** | Flutter 3.47+ / Dart 3.13+ | Đa nền tảng (Android, iOS, Web) từ một codebase duy nhất. |
| **Kiến trúc** | Feature-first + Clean Architecture | Tách biệt rõ 3 tầng `data`, `domain`, `presentation` trong mỗi phân hệ nghiệp vụ. |
| **State Management & DI** | `flutter_riverpod` + `riverpod_annotation` | Quản lý trạng thái phản ứng (reactive), phân tách logic khỏi UI và hỗ trợ Dependency Injection. |
| **Điều hướng (Routing)** | `go_router` (`StatefulShellRoute.indexedStack`) | Hỗ trợ Deep Linking trên Mobile, URL Routing trên Web và giữ trạng thái từng tab phân hệ. |
| **Giao tiếp API** | `dio` + `AuthInterceptor` | Tự động đính kèm Bearer JWT, `X-Clan-Id` (Multi-tenant) và chuẩn hóa `ApiResponse<T>`. |
| **Lưu trữ bảo mật** | `flutter_secure_storage` + `shared_preferences` | Lưu trữ an toàn JWT Token trên Android Keystore, iOS Keychain và WebCrypto. |
| **Data Modeling** | `freezed` + `json_serializable` | Sinh code bất biến (immutable models) và serialize/deserialize JSON an toàn kiểu. |

---

## 2. Thiết Kế Đa Nền Tảng Cho Cả 2 Phân Hệ (Adaptive Dual-Portal)

Hệ thống được thiết kế để **cả Mobile App (Android/iOS) và Web App** đều phục vụ đầy đủ 2 nhóm đối tượng thông qua [`AdaptiveWorkspaceShell`](../lib/core/widgets/adaptive_shell.dart) và [`DualRbacSessionNotifier`](../lib/core/security/rbac_models.dart):

- **Tự động thích ứng kích thước màn hình (Responsive Breakpoints)**:
  - **Web / Tablet ($\ge 840\text{px}$)**: Hiển thị thanh điều hướng dọc `NavigationRail` (mở rộng đầy đủ nhãn khi $\ge 1180\text{px}$) và bố cục thẻ 2 cột song song.
  - **Mobile ($< 840\text{px}$)**: Hiển thị `NavigationBar` dưới đáy màn hình và bố cục thẻ xếp chồng tối ưu thao tác một tay.
- **Chuyển đổi Không gian Phân hệ (`PortalWorkspaceMode`)**:
  - Người dùng có quyền Quản trị / Trưởng tộc / Trưởng chi hoặc nằm trong Ban Tổ Chức sự kiện (`EVENT_PERSONNEL`) có thể chuyển đổi tức thời giữa chế độ **Thành viên / Con cháu** và **Quản trị / BTC** ngay trên thanh công cụ ở cả Web lẫn Mobile.

---

## 3. Cấu Trúc Thư Mục Chi Tiết (`lib/`)

```text
lib/
├── main.dart                                 # Điểm khởi chạy ứng dụng + ProviderScope
├── core/                                     # Tầng hạ tầng & tiện ích dùng chung toàn cục
│   ├── config/
│   │   └── env_config.dart                   # Tự động phân giải API URL (Web/iOS vs Android Emulator)
│   ├── constants/                            # Hằng số toàn cục
│   ├── error/
│   │   └── failures.dart                     # Các lớp Failure (BusinessInvariantFailure, ForbiddenFailure...)
│   ├── network/
│   │   ├── api_response.dart                 # Wrapper chuẩn ApiResponse<T> (code, message, data, timestamp)
│   │   └── dio_client.dart                   # Dio instance + AuthInterceptor (JWT & X-Clan-Id)
│   ├── router/
│   │   └── app_router.dart                   # Cấu hình GoRouter + StatefulShellRoute cho 6 phân hệ chính
│   ├── security/
│   │   └── rbac_models.dart                  # Mô hình Dual-RBAC (SystemRole + EventContextualRole + Read-Only)
│   ├── storage/
│   │   └── secure_token_storage.dart         # Lưu trữ JWT Token đa nền tảng
│   ├── theme/
│   │   └── app_theme.dart                    # Thiết kế Material 3 (Tông Đỏ son gia phả & Vàng đồng)
│   ├── utils/
│   │   └── formatters.dart                   # Định dạng tiền tệ VNĐ & Ngày giờ
│   └── widgets/
│       ├── adaptive_shell.dart               # Khung giao diện thích ứng Web (NavigationRail) & Mobile (NavigationBar)
│       └── module_overview_card.dart         # Khung hiển thị tính năng theo từng phân hệ
└── features/                                 # 7 Phân hệ nghiệp vụ theo Clean Architecture
    ├── auth/                                 # Xác thực, Kích hoạt PositionLinkCode & Phiên Dual-RBAC
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    ├── genealogy/                            # Phân hệ 1: Cây gia phả (FAMILY_BRANCH), Thành viên (MEMBER), Lời mời
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    ├── event/                                # Phân hệ 2: Sự kiện (EVENT), Nhân sự BTC (EVENT_PERSONNEL), Đăng ký hộ
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    ├── task/                                 # Phân hệ 3: Công việc (EVENT_TASK) & Cảnh báo 24h/12h (TASK_PROGRESS_ALERT)
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    ├── contribution/                         # Phân hệ 4: Đóng góp Tiền mặt/Hiện vật & Tài sản dòng họ (CLAN_ASSET)
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    ├── finance/                              # Phân hệ 5: Tạm ứng, Quyết toán & Sổ cái bất biến (IMMUTABLE_LEDGER)
    │   ├── data/ (datasources, models, repositories)
    │   ├── domain/ (entities, repositories, usecases)
    │   └── presentation/ (providers, screens, widgets)
    └── report/                               # Phân hệ 6: Báo cáo thu chi & Cộng dồn công đức đệ quy (TinhTongDongGopDeQuy)
        ├── data/ (datasources, models, repositories)
        ├── domain/ (entities, repositories, usecases)
        └── presentation/ (providers, screens, widgets)
```

---

## 4. Ràng Buộc Nghiệp Vụ Cốt Lõi Được Ánh Xạ Vào Frontend

1. **Quy tắc A (Toàn vẹn Cây Phả hệ)**: Tách biệt `MEMBER` (hồ sơ sinh học, gồm cả hồ sơ ảo `is_placeholder = true`) và `USER_ACCOUNT`. Hỗ trợ kích hoạt trực tiếp qua `PositionLinkCode`.
2. **Quy tắc B (Phân quyền Kép Dual-RBAC)**: Kết hợp quyền tĩnh (`ROLE_CLAN_HEAD`, `ROLE_BRANCH_HEAD`, `ROLE_MEMBER`, `ROLE_ADMIN`) và quyền động theo sự kiện (`HeadOfOrganizer`, `EventTreasurer`, `OrganizerMember`). Khi sự kiện `Closed`, cờ `isEffectiveReadOnly` tự động bật `true` để khóa mọi thao tác thêm/sửa/xóa trên UI.
3. **Quy tắc C (Chặn Khóa Sổ Khi Còn Giải Trình)**: Xử lý ngoại lệ `BusinessInvariantFailure` khi đóng sự kiện còn phiếu quyết toán ở trạng thái `NeedsExplanation`.
4. **Quy tắc D (Sổ Cái Bất Biến - Append-Only)**: Giao diện Sổ cái chỉ cho phép tra cứu và đề xuất bù trừ (`LEDGER_ADJUSTMENT_REQUEST`), tuyệt đối không có chức năng sửa/xóa dòng lịch sử.
