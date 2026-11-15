# UI Spec — US-32: Hồ sơ thành viên, chân dung và tư liệu gia sử

Ngày cập nhật: **12/11/2026**. Trạng thái: **Thiết kế đề xuất, chờ duyệt trước khi sửa `lib/` và thêm dependency**.

## 1. User story và nguồn thiết kế

Là thành viên hoặc người quản lý gia phả đúng phạm vi, tôi muốn xem/bổ sung chân dung, viết tiểu sử và quản lý tư liệu gia sử trên hồ sơ thành viên để gìn giữ ký ức gia đình và chia sẻ đúng người.

Nguồn chuẩn: [đặc tả backend US-32](../../../../family-management-backend/docs/user-stories/US-32-member-portrait-biography-and-family-documents.md). Backend đã triển khai và kiểm chứng Supabase thật. Frontend chỉ gọi backend qua Dio, không đọc key Supabase hay gọi cloud trực tiếp.

Chưa có thiết kế Stitch cho US-32. Hai mockup sau là **đề xuất của agent**, kế thừa cấu trúc điều hướng hiện có và token `AppTheme`:

- [Mockup Web rộng](./mockup-desktop.html), bố cục tham chiếu 1280 px.
- [Mockup Mobile](./mockup-mobile.html), khung tham chiếu 390 px; bản Web cũng co giãn ở 840 px.

Mockup dùng dữ liệu minh họa, không kết nối API và không lưu thay đổi. Thanh điều khiển phía trên chỉ phục vụ duyệt thiết kế, không đưa vào sản phẩm.

## 2. Hợp đồng API đã đối chiếu

Đã đọc mã nguồn thực tế:

- [MemberMediaController.java](../../../../family-management-backend/src/main/java/com/familyfund/genealogy/internal/media/MemberMediaController.java): endpoint, multipart, JSON và headers download.
- [MemberMediaService.java](../../../../family-management-backend/src/main/java/com/familyfund/genealogy/internal/media/MemberMediaService.java): capabilities, phiên bản, idempotency, phân trang đã lọc quyền.
- [MemberMediaPolicy.java](../../../../family-management-backend/src/main/java/com/familyfund/genealogy/internal/media/MemberMediaPolicy.java): chính chủ/người quản lý, tenant và visibility.
- [BiographyValidator.java](../../../../family-management-backend/src/main/java/com/familyfund/genealogy/internal/media/BiographyValidator.java), [MediaFileValidator.java](../../../../family-management-backend/src/main/java/com/familyfund/genealogy/internal/media/MediaFileValidator.java): định dạng và giới hạn.

Các URL dưới đây được ghép với `EnvConfig.apiBaseUrl` vốn đã chứa `/api/v1`; không ghép lặp `/api/v1` khi dùng `contentUrl`/`avatarUrl` trả từ server.

1. `GET /members/{memberId}`: hồ sơ đã lọc US-25, `avatarUrl`, `biography` dạng Delta hoặc null, `biographyVisibility`, `biographyAccess`, `mediaVersion`, `capabilities.canEditMedia`, `capabilities.canUploadAttachment`.
2. `PUT /members/{memberId}/avatar`: multipart `file`, `expectedMediaVersion`; trả avatarUrl và mediaVersion mới. `DELETE` cùng route có query expectedMediaVersion. `GET .../avatar/content` trả bytes JPEG.
3. `PUT /members/{memberId}/biography`: JSON `{expectedMediaVersion, biography: {ops: [...]}, visibility}`; trả Delta, visibility và mediaVersion mới. Xóa nội dung bằng document `{"ops":[{"insert":"\n"}]}`.
4. `GET /members/{memberId}/attachments?page=0&size=10`: `items`, `page`, `size`, `totalElements`, `totalPages`; tổng chỉ bao gồm tư liệu người gọi được xem. Size tối đa 20.
5. `POST /members/{memberId}/attachments`: multipart `file`, `title`, `description` tùy chọn, `visibility` mặc định RESTRICTED; header Idempotency-Key UUID bắt buộc. Response 201 chứa metadata.
6. `PATCH /members/{memberId}/attachments/{id}`: expectedVersion và ít nhất một trường title/description/visibility. Bỏ trường là giữ nguyên; description null là xóa mô tả. Response có version mới.
7. `DELETE .../attachments/{id}?expectedVersion=...`: 204; ẩn tư liệu ngay, không đợi cloud xóa vật lý.
8. `GET .../attachments/{id}/content`: bytes có xác thực, disposition mặc định attachment; chỉ ảnh được phép inline. Không mở PDF bằng URL trực tiếp vì trình duyệt không tự gửi JWT của ứng dụng.

Metadata tư liệu: id, memberId, title, description, originalFilename, mimeType, sizeBytes, visibility, version, createdAt, updatedAt, contentUrl, canEdit, canDelete.

Validation:

- Avatar: JPEG/PNG ≤5 MiB, ảnh tối thiểu 128 px, tối đa 20 megapixel; crop 1:1, xuất PNG vuông 512 px để giảm dung lượng trước upload. Backend chuẩn hóa JPEG 512 px và bỏ EXIF.
- Tư liệu: PDF/JPEG/PNG ≤10 MiB, tối đa 20 tư liệu/hồ sơ; title 1–150 ký tự sau trim, description ≤1.000 ký tự.
- Tiểu sử: ≤20.000 ký tự Unicode và ≤100 KiB JSON UTF-8; chỉ insert text, bold/italic/underline, header 1–3, list ordered/bullet, blockquote và link HTTPS. Không ảnh/embed/font/color/align/indent/HTML thô. Chuẩn hóa block attributes vào newline riêng, không gửi hai kiểu block trên cùng newline.
- Ngày giờ ISO-8601 UTC từ server, hiển thị qua AppFormatters. Dung lượng hiển thị theo KiB/MiB và giữ số bytes gốc.

Lỗi: 400 nội dung không hợp lệ; 401 hết phiên; 403 mất quyền sửa; 404 không tồn tại/không được biết; 409 phiên bản, idempotency, giới hạn tư liệu hoặc upload đang chạy; 413 quá dung lượng; 415 loại file; 429 vượt lượt; 503 storage/quota. UI ánh xạ theo `code`, không phân tích chuỗi message.

## 3. Màn hình, route và luồng

- Route mới `/members/:memberId`: trang chi tiết thành viên. Vào từ thao tác “Xem hồ sơ” trên thẻ thành viên của BranchDetailSidebar, và liên kết từ hồ sơ của tôi nếu có memberId.
- Dialog crop ảnh: chọn ảnh → crop vuông/zoom/di chuyển → xem trước → Lưu ảnh. Hủy không gửi request. Thay/xóa ảnh là hai hành động riêng.
- Dialog tiểu sử: toolbar giới hạn, nội dung, phạm vi chia sẻ, xem trước, Lưu/Hủy. Cảnh báo khi đóng mà có thay đổi; xóa trắng bài hiện có cần xác nhận.
- Dialog tư liệu: chọn nhiều file, metadata riêng từng file, upload tuần tự với tiến trình và kết quả từng file; một key cố định cho mỗi lần upload/retry, không thay key khi response chưa chắc chắn.
- Dialog sửa tư liệu: title, description, visibility và version. Xóa có xác nhận nêu tên tư liệu.
- Preview ảnh bằng bytes đã xác thực; PDF tải bytes qua Dio rồi lưu bằng adapter đa nền tảng. Không nhúng trình đọc PDF vào MVP.

## 4. Quyền × trạng thái

| Người xem/trạng thái | Xem avatar | Tiểu sử/tư liệu | Thay ảnh/viết bài/thêm file | Sửa/xóa tư liệu |
|---|---|---|---|---|
| Chính chủ Active, còn sống, hồ sơ thật | Có | Theo response, gồm RESTRICTED của mình | Theo capabilities | Theo canEdit/canDelete của item |
| Trưởng tộc/Admin trong tenant | Có | Theo response | Theo capabilities | Theo item |
| Trưởng nhánh quản lý hồ sơ/nhánh con | Có | Theo response | Theo capabilities | Theo item |
| Người cùng dòng họ không quản lý | Có | Chỉ nội dung backend cho phép | Ẩn | Ẩn nếu item không cho phép |
| Hồ sơ ảo/đã mất | Có khi được xem hồ sơ | Theo response | Chỉ người quản lý, dựa capabilities | Theo item |
| Chưa xác thực/ngoài tenant/404 | Không tải tiếp | Không tiết lộ metadata cũ | Không | Không |

UI không suy quyền media từ cờ quyền xem ngày sinh/SĐT/email, vai trò BTC hoặc portal đang chọn. Capabilities từ backend quyết định thao tác; không thay đổi mô hình role toàn cục để cấp quyền mới. Visibility dùng enum CLAN (“Trong dòng họ”), BRANCH (“Trong nhánh”), RESTRICTED (“Giới hạn”). Quyền đọc của chính chủ/người quản lý vẫn áp dụng với RESTRICTED.

## 5. Bố cục và trạng thái

Web 1280: HeritageNavBar, breadcrumb, tiêu đề trang; nội dung tối đa khoảng 960 px, hai cột: thẻ chân dung/thông tin cơ bản bên trái, tiểu sử và danh sách tư liệu bên phải. Danh sách tư liệu dạng hàng, tên file được wrap; không có dashboard/KPI khác story.

840 px: thu gọn nhãn điều hướng, nội dung co giãn; chuyển một cột khi vùng nội dung không còn đủ chiều rộng. Mobile 390 px: thẻ chân dung nằm trên, hai phần tiểu sử/tư liệu bên dưới; danh sách file thành thẻ. Dialog gần toàn màn hình, vùng hành động Lưu/Hủy rõ và không bị bàn phím che. Vùng chạm ≥48 dp, chữ nội dung ≥14sp, hỗ trợ scale 1,3× và focus bàn phím.

Các trạng thái có thể chọn trong mockup:

- Đầy đủ: nội dung minh họa, nút chỉnh sửa của chính chủ.
- Đang tải: skeleton; không hiện nội dung từ hồ sơ trước đó.
- Rỗng: avatar chữ viết tắt, hướng dẫn viết tiểu sử/thêm tư liệu nếu có quyền.
- Lỗi: giải thích và nút Thử lại; không thay bằng dữ liệu giả.
- Không đủ quyền/404: không hiển thị chi tiết hoặc tổng file cũ; có quay lại gia phả.
- Chỉ đọc: hiển thị nội dung được xem, ẩn mutation; không giả “được quyền sửa” vì là quản lý portal.
- Tiểu sử hạn chế: nhãn khóa và lời giải thích, không phân biệt có bài hay chưa. Tư liệu ẩn không có tên hoặc số lượng ẩn.
- Conflict 409: giữ draft, thông báo hồ sơ đã đổi, tải lại version trước khi lưu; không tự ghi đè hoặc tự retry mutation bằng version mới.

Trong sản phẩm, mặc định bài/tư liệu mới RESTRICTED. Thay sang CLAN/BRANCH có giải thích đối tượng; avatar được xem trong dòng họ. Khi 403/404 trong phiên xem file, bỏ bytes đang giữ trong state; không cố tải lại bằng URL public.

## 6. Thành phần tái sử dụng và dependency cần duyệt

Tái sử dụng: HeritageNavBar/HeritageBottomNavBar, Dio AuthInterceptor (JWT + X-Clan-Id), SecureTokenStorage, AppTheme/ColorScheme, AppFormatters, failures, cấu trúc repository/provider của genealogy và event. Chỉ giữ bytes private trong memory; hủy khi logout/đổi tenant, không lưu shared_preferences hay cache ảnh trên disk.

Theme: màu primary #8B1E1E → colorScheme.primary; gold #B8860B → secondary; teal #0F766E → tertiary; nền #F9F8F6 → scaffoldBackgroundColor. HTML dùng CSS variables mô phỏng token; Flutter mới dùng ColorScheme, không thêm palette hardcode, font hoặc sửa AppTheme. Mockup không dùng màu nền #FAF6F0 cũ của US-25 vì khác AppTheme hiện hành. Không có khác biệt Stitch vì chưa có nguồn Stitch.

Đề xuất **4 dependency trực tiếp mới**, chưa cài:

- [file_picker](https://pub.dev/packages/file_picker): chọn JPEG/PNG/PDF dạng bytes trên Web/Android/iOS.
- [crop_your_image](https://pub.dev/packages/crop_your_image): crop trong widget Flutter, giữ cùng trải nghiệm Web/Mobile.
- [flutter_quill](https://pub.dev/packages/flutter_quill): editor và viewer Quill Delta, toolbar theo allowlist backend; bổ sung localization delegate của package ở MaterialApp nếu phiên bản yêu cầu, không triển khai l10n toàn app.
- [file_saver](https://pub.dev/packages/file_saver): lưu bytes người dùng chủ động tải về; không tải qua URL bỏ qua JWT. Trên mobile cần thông báo đúng nơi lưu thực tế của package, không hứa luôn vào thư mục Downloads.

Sau khi được duyệt mới resolve phiên bản tương thích Dart/Flutter của repo, giữ nguyên ràng buộc package đang có và commit pubspec.lock. Nếu resolver báo xung đột buộc nâng dependency hiện hữu, báo lại thay vì tự đổi. Không thêm Supabase SDK hoặc key vào frontend.

## 7. Implementation plan — các file dự kiến

Theo `data → domain → presentation`, tận dụng feature genealogy hiện có:

1. `data/models/member_media_models.dart`: DTO hồ sơ/attachment, page, visibility, capabilities, version; parse JSON thủ công.
2. `data/datasources/member_media_remote_datasource.dart`: JSON/multipart/bytes, onSendProgress, CancelToken và Idempotency-Key; kiểm soát URL chỉ tới API ứng dụng, không gửi Authorization tới host lạ từ contentUrl.
3. `domain/repositories/member_media_repository.dart` và `data/repositories/member_media_repository_impl.dart`: contract nghiệp vụ, ánh xạ lỗi và tách Dio khỏi widget/notifier.
4. `presentation/providers/member_media_provider.dart`: state theo memberId và tenant/session, load detail/list, draft/mutation/version, phân trang, upload tuần tự, refresh sau thao tác; không ghép metadata private giữa hai phiên.
5. `presentation/screens/member_detail_screen.dart`: header, thông tin US-25, hai khu vực bài viết/tư liệu, responsive và 5 trạng thái bắt buộc.
6. Widgets mới trong `presentation/widgets/`: `member_avatar.dart`, `member_avatar_editor_dialog.dart`, `member_biography_editor_dialog.dart`, `member_attachments_section.dart`, `member_attachment_editor_dialog.dart`, `member_attachment_preview_dialog.dart`.
7. `core/files/member_file_actions.dart`: adapter chọn/lưu file bằng package đa nền tảng, dễ mock trong test; UUID v4 bằng Random.secure helper, không cần thêm package UUID.
8. Sửa nhỏ `core/router/app_router.dart` thêm route; `branch_detail_sidebar.dart` thêm mở hồ sơ; `branch_models.dart` đọc avatarUrl; cập nhật `my_profile_screen.dart` liên kết tới trang member nếu có memberId.
9. `pubspec.yaml`, `pubspec.lock`: bốn package đã duyệt. `app.dart`/file chứa MaterialApp chỉ sửa nếu package Quill cần localization delegate. Không sửa core RBAC hoặc AppTheme.
10. Test DTO/Delta allowlist/Unicode-byte limit, normalize URL, mapping lỗi, repository, provider session invalidation, retry idempotency, widget các trạng thái và điều hướng mở hồ sơ. Test có mock file actions/network, không gọi cloud thật mặc định.

File dùng chung có nguy cơ xung đột: router, pubspec/lock, MaterialApp và branch sidebar. Đọc lại diff trước khi sửa; không refactor các màn cũ. Nhánh hiện tại là `feat/fe-us27-life-status-and-deceased`, working tree sạch khi bắt đầu; chưa tự checkout theo workflow. Đề xuất nhánh triển khai khi được cho phép: `feat/fe-us32-member-media`.

## 8. Những điểm không khớp/rủi ro đã xác định

- `00-project-context.md` cũ: ghi genealogy rỗng và chưa có profile, trong khi code có US-22/25/27. Kế hoạch dựa trên mã thực tế đã đọc; đề nghị cập nhật context ở công việc riêng, không giả định thư mục rỗng.
- Frontend chưa có route chi tiết member, package chọn/crop/Rich Text/download. Thiết kế bổ sung các phần này, không nhầm hồ sơ tài khoản US-22 với hồ sơ gia phả của người khác.
- AuthInterceptor hiện không tự refresh JWT; cần dùng cách xử lý 401 sẵn có, giữ draft trong memory và yêu cầu đăng nhập lại. Không mở rộng auth refresh trong US-32.
- Dio base URL đã có `/api/v1`, trong khi URL bytes backend bắt đầu `/api/v1/...`; cần normalize và kiểm thử chống lặp path.
- Server có 20 attachment/hồ sơ nhưng totalElements của người xem đã lọc quyền; không dùng count của client để suy tổng file ẩn hoặc kết luận chắc còn slot. Xử lý ATTACHMENT_LIMIT_REACHED từ server.
- Hai kiểu giới hạn 20.000 ký tự Unicode / 100 KiB JSON khác nhau; dùng runes và utf8.encode(jsonEncode(...)), không chỉ String.length.
- Hủy request sau khi gửi có thể đã commit; tải lại hồ sơ trước retry. Key giữ nguyên trong trường hợp chưa rõ kết quả; không hứa rollback bằng nút Hủy.

## 9. Phần cần duyệt

- Bố cục hồ sơ và ba dialog xem trong hai mockup; route và liên kết từ cây gia phả/hồ sơ của tôi.
- Bốn dependency trong mục 6, phạm vi chỉnh sửa file dùng chung trong mục 7, và nhánh triển khai đề xuất.

Không có đề nghị sửa backend: hợp đồng hiện tại đủ cho MVP. Chưa đề xuất album, OCR, bình luận hoặc trình đọc PDF nhúng.

## 10. Nghiệm thu sau khi được duyệt

- Avatar: chọn/crop/hủy/lưu/thay/xóa; ảnh mới cập nhật ở detail và thẻ thành viên; không lộ token trong URL.
- Tiểu sử: round-trip Delta giữ đúng định dạng được hỗ trợ; hạn chế nội dung nguy hiểm và giới hạn; draft còn sau lỗi/409.
- Tư liệu: upload từng file có tiến trình, retry cùng key, sửa quyền/metadata, phân trang, preview ảnh và tải PDF có JWT.
- Quyền: backend capabilities quyết định thao tác; trạng thái giới hạn/không có quyền không lộ dữ liệu ẩn.
- Không cache private bytes trên disk; session/tenant đổi thì state và draft bị xóa.
- `flutter analyze`/`flutter test` đạt; kiểm tra Flutter Web với backend thật ở 390/840/1280, Android/iOS khi có thiết bị/SDK. Báo rõ phần chưa kiểm chứng, không khẳng định đã chạy iOS từ Windows.

## 11. Kiểm tra bản thiết kế trước duyệt

Giai đoạn thiết kế dưới đây đã kết thúc. Kết quả triển khai Flutter và kiểm chứng thực tế nằm trong [implementation.md](./implementation.md).

Đã render HTML bằng Chrome headless với viewport chính xác 390, 840 và 1280 px; kiểm tra trang hồ sơ, hộp thoại crop, editor và form tư liệu không tràn ngang, dialog nằm trong viewport. Đã mở đủ 8 trạng thái qua thanh chọn của mockup, kiểm tra cú pháp JavaScript và ID HTML không trùng. Màu/chữ được xem lại trên ảnh render; phần tên file và các nút thao tác mobile đã tách thành hai hàng để dễ đọc/chạm.

Đây là kiểm chứng **mockup HTML**, chưa phải kiểm thử Flutter, backend hoặc thiết bị Android/iOS. Chưa sửa `lib/`, `pubspec.yaml`, `pubspec.lock`; chưa tạo commit hoặc đổi nhánh. Ba file thiết kế là nội dung duy nhất thay đổi trong Git ở giai đoạn này.
