# UI Spec – US-17: Đăng Ký Gia Nhập Gia Tộc Qua Mã Mời Chung

Tài liệu đặc tả giao diện và hợp đồng tích hợp phía Frontend cho tính năng **[US-17] Đăng ký tự do qua Mã mời chung (Luồng Onboarding từ bên ngoài)**.

---

## 1. User Story & Tiêu Chí Nghiệm Thu
* **Với vai trò:** Người dùng mới (Khách / Con cháu họ hàng chưa có tài khoản trong hệ thống).
* **Tôi muốn:** Nhập mã mời chung (từ US-16), xem thông tin dòng họ, xem cây phả hệ thu gọn để chọn vị trí chi nhánh muốn gia nhập (hoặc đề xuất tạo nhánh con mới), điền thông tin cá nhân và thiết lập mật khẩu đăng nhập.
* **Để:** Gửi hồ sơ đề xuất gia nhập dòng họ lên Ban quản trị (Trưởng tộc / Trưởng chi) phê duyệt.
* **Tiêu chí nghiệm thu (Acceptance Criteria):**
  - **Cho trước:** Có mã mời chung hợp lệ (`isActive = true`, còn thời hạn `expiresAt > NOW()`, chưa vượt quá số lượt dùng `usedCount < maxUses`).
  - **Khi:** Khách nộp thông tin cá nhân hợp lệ và chọn nhánh gia nhập (hoặc đề xuất nhánh con mới).
  - **Thì:**
    1. Hệ thống tạo yêu cầu gia nhập (`branch_join_requests`) với trạng thái `Pending`.
    2. Khởi tạo tài khoản người dùng (`user_accounts`) ở trạng thái tạm khóa chờ duyệt (`PendingApproval`).
    3. Không cấp token phiên đăng nhập; chuyển hướng người dùng đến màn hình "Chờ Phê Duyệt" hiển thị mã đơn, thông tin dòng họ và hướng dẫn.
    4. Khi Trưởng tộc / Trưởng chi phê duyệt, tài khoản mới được kích hoạt (`Active`), sinh hồ sơ `MEMBER`, cấp vai trò `ROLE_MEMBER` để người dùng có thể đăng nhập.

---

## 2. Hợp Đồng API (Đối Chiếu Thực Tế Từ Repo Backend)

### 2.1. Bảng Tổng Hợp Endpoint
| Endpoint | Phương thức | Request DTO / Params | Response DTO | Quyền | File Backend Đã Đọc & Đối Chiếu |
|---|---|---|---|---|---|
| `/api/v1/invitations/{inviteCode}` | `GET` | Path variable `inviteCode` | `ApiResponse<InviteCodeResponse>` | Public | [`InvitationController.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/controller/InvitationController.java#L70-L75)<br>[`InvitationServiceImpl.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/service/InvitationServiceImpl.java#L125-L128) |
| `/api/v1/invitations/{inviteCode}/tree` | `GET` | Path variable `inviteCode` | `ApiResponse<OnboardingBranchTreeNode>` | Public | [`InvitationController.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/controller/InvitationController.java#L80-L85)<br>[`GenealogyQueryServiceImpl.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/genealogy/internal/service/GenealogyQueryServiceImpl.java#L76-L135) |
| `/api/v1/invitations/{inviteCode}/join` | `POST` | Path variable `inviteCode`<br>Body: `SubmitJoinRequest` | `ApiResponse<JoinRequestResponse>` (HTTP 201) | Public | [`InvitationController.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/controller/InvitationController.java#L90-L99)<br>[`BranchJoinRequestServiceImpl.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/service/BranchJoinRequestServiceImpl.java#L60-L155) |
| `/api/v1/auth/login` | `POST` | Body: `LoginRequest` (`loginIdentifier`, `password`) | `ApiResponse<AuthTokenResponse>` | Public | [`AuthController.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/controller/AuthController.java)<br>[`AuthServiceImpl.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/internal/service/AuthServiceImpl.java#L36-L56) |

---

### 2.2. Chi Tiết Request / Response DTOs

#### DTO: `SubmitJoinRequest` (Payload gửi lên khi đăng ký)
*Đọc từ [`SubmitJoinRequest.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/api/dto/SubmitJoinRequest.java):*
* `phoneNumber` (String, Bắt buộc): Định dạng regex `^(0|\+84)[0-9]{9,10}$`.
* `password` (String, Bắt buộc): Độ dài từ 6 đến 50 ký tự.
* `email` (String, Tùy chọn): Nếu có phải đúng định dạng `^[A-Za-z0-9+_.-]+@(.+)$`.
* `fullName` (String, Bắt buộc): Tối đa 100 ký tự.
* `dateOfBirth` (LocalDate, Tùy chọn): Định dạng `YYYY-MM-DD`, phải là ngày trong quá khứ (`@Past`).
* `gender` (String, Bắt buộc): Phải là một trong ba giá trị `'Male' | 'Female' | 'Other'`.
* `proposalType` (Enum, Bắt buộc): `'ExistingBranchLeaf'` (xin vào nhánh hiện hữu) hoặc `'NewChildBranch'` (đề xuất nhánh con mới).
* `targetBranchId` (String, Bắt buộc): ID của nhánh muốn xin vào (hoặc nhánh cha nếu đề xuất nhánh mới).
* `proposedNewBranchName` (String, Bắt buộc nếu là `NewChildBranch`): Tối đa 100 ký tự.
* `proposedGeneration` (Integer, Bắt buộc): Phải là số nguyên `>= 1`.
* `relationshipNote` (String, Tùy chọn): Tối đa 255 ký tự.

#### DTO: `OnboardingBranchTreeNode` (Cây phả hệ thu gọn)
*Đọc từ [`OnboardingBranchTreeNode.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/genealogy/api/OnboardingBranchTreeNode.java):*
* `branchId` (String): ID định danh chi nhánh.
* `clanId` (String) & `clanName` (String): ID và tên dòng họ.
* `branchName` (String): Tên chi nhánh.
* `generationLevel` (Integer): Đời thứ / cấp độ thế hệ của chi nhánh.
* `parentBranchId` (String?): ID chi nhánh cha (null nếu là nhánh gốc).
* `representativeName` (String?): Tên đại diện chi nhánh.
* `memberCount` (int): Số lượng thành viên của chi nhánh.
* `children` (List<OnboardingBranchTreeNode>): Danh sách nhánh con cháu trực thuộc.

> [!IMPORTANT]
> **Bảo mật dữ liệu cá nhân (Tuân thủ US-25):** DTO cây thu gọn này **hoàn toàn loại bỏ** số điện thoại, email, ngày sinh, địa chỉ và thông tin chi tiết của các thành viên. Khách vãng lai chỉ thấy danh mục phân cấp chi nhánh và danh xưng đại diện.

#### DTO: `JoinRequestResponse` (Phản hồi sau khi nộp đơn)
*Đọc từ [`JoinRequestResponse.java`](file:///d:/WorkSpace/Family-Management/family-management-backend/src/main/java/com/familyfund/identity/api/dto/JoinRequestResponse.java):*
* `requestId` (String): Mã định danh yêu cầu (ví dụ: `REQ_ABC123DEF456`).
* `accountId` (String): Mã tài khoản tạm khóa (`ACC_...`).
* `clanId` (String): Mã dòng họ.
* `inviteCode` (String): Mã mời đã dùng.
* `fullName` (String): Họ và tên đăng ký.
* `proposalType` (String): `ExistingBranchLeaf` hoặc `NewChildBranch`.
* `targetBranchId` (String) & `targetBranchName` (String): Chi nhánh mục tiêu.
* `proposedNewBranchName` (String?): Tên nhánh mới (nếu có).
* `proposedGeneration` (Integer): Đời thứ đề xuất.
* `approvalStatus` (Enum): `Pending` | `Approved` | `Rejected`.
* `createdAt` (Instant): Thời gian gửi đơn (ISO-8601 UTC).

---

### 2.3. Quy Tắc Xác Thực (Validation) & Xử Lý Mã Lỗi Nghiệp Vụ

#### 1. Các trường hợp lỗi của Mã Mời (`inviteCode`):
* **Không tồn tại hoặc đã bị thu hồi (`isActive = false`):** Backend trả HTTP `404 Not Found`, message: `"Không tìm thấy Mã mời với inviteCode: {code}"`.
* **Hết hạn (`expiresAt < NOW()`):** Backend trả HTTP `400 Bad Request`, message: `"Mã mời đã hết hạn sử dụng"`.
* **Hết lượt (`usedCount >= maxUses`):** Backend trả HTTP `400 Bad Request`, message: `"Mã mời đã hết lượt sử dụng"`.
* **Mã mời có chỉ định nhánh cố định (`targetBranchId != null`):**
  - Backend giới hạn cây `/tree` chỉ hiển thị nhánh này và các nhánh con của nó.
  - Trên giao diện, **ô chọn nhánh mục tiêu phải bị khóa cứng (read-only) và tự động điền sẵn `targetBranchName`**.
  - Nếu gửi sai `targetBranchId`, backend ném HTTP `400 Bad Request`: `"Mã mời này chỉ áp dụng cho nhánh mục tiêu: {targetBranchId}"`.

#### 2. Khác biệt cốt lõi giữa Mã Chung (US-17) và Mã Liên Kết Vị Trí (US-19):
* **Mã chung (`GeneralClanInvite` - US-16, US-17):** Dành cho nhiều người (`maxUses` lớn), người dùng chưa có trên phả hệ, phải chọn nhánh/đề xuất nhánh con, tài khoản tạo ra ở trạng thái `PendingApproval`, bắt buộc qua Trưởng tộc/nhánh phê duyệt.
* **Mã liên kết vị trí (`PositionLinkCode` - US-18, US-19):** Gán 1-1 với một vị trí `targetMemberId` có sẵn trên phả hệ do Trưởng tộc tạo trước. Khi người dùng nhập mã này, tài khoản được kích hoạt ngay (`Active`) và liên kết vào thành viên mà không cần chờ duyệt.
* **Cơ chế dùng chung màn hình:** Cả 2 luồng dùng chung màn hình nhập mã ban đầu `/invite-code`. Sau khi gọi `previewInvite(code)`, hệ thống đọc trường `inviteType`:
  - Nếu `inviteType == 'GeneralClanInvite'` -> Điều hướng sang `/register-member?inviteCode=...` (US-17).
  - Nếu `inviteType == 'PositionLinkCode'` -> Điều hướng sang luồng liên kết tài khoản trực tiếp (US-19).

#### 3. Các lỗi khi nộp đơn (`/join`):
* Trùng số điện thoại: HTTP `400 Bad Request` `"Số điện thoại đã được đăng ký trong hệ thống"`.
* Trùng email (nếu có nhập): HTTP `400 Bad Request` `"Email đã được đăng ký trong hệ thống"`.
* Nhánh không tồn tại trong dòng họ: HTTP `404 Not Found` `"Không tìm thấy Nhánh gia phả với branchId: {targetBranchId}"`.
* Đề xuất nhánh mới nhưng để trống tên: HTTP `400 Bad Request` `"Tên chi nhánh mới không được để trống khi đề xuất tạo nhánh mới"`.

#### 4. Phản hồi khi đăng nhập lúc tài khoản chưa được duyệt (`PendingApproval`):
* Endpoint: `POST /api/v1/auth/login`
* Khi nhập SĐT + Mật khẩu lúc tài khoản đang chờ duyệt: Backend trả HTTP `400 Bad Request` với message:
  `"Tài khoản đang ở trạng thái: PendingApproval. Vui lòng liên hệ quản trị viên để được kích hoạt."`
* Nếu bị từ chối (`Deactivated`): Trả HTTP `400 Bad Request` với message:
  `"Tài khoản đang ở trạng thái: Deactivated. Vui lòng liên hệ quản trị viên để được kích hoạt."`
* Giao diện đăng nhập (`LoginScreen`) bắt chuỗi `PendingApproval` để hiển thị banner thông báo và nút chuyển sang màn hình xem trạng thái chờ duyệt.

#### 5. Bị từ chối có được gửi lại không?
* **Hiện trạng backend:** Khi bị từ chối, tài khoản chuyển sang `Deactivated`. Do số điện thoại vẫn lưu trong bảng `user_accounts` với ràng buộc `UNIQUE`, nếu gửi lại bằng chính số điện thoại đó, backend sẽ báo lỗi `"Số điện thoại đã được đăng ký trong hệ thống"`. Người dùng hiện tại **không thể gửi lại bằng cùng số điện thoại** trừ khi quản trị viên xóa tài khoản cũ (xem chi tiết mục *Đề nghị backend*).

---

## 3. Màn Hình Và Luồng Người Dùng

### 3.1. Danh Sách Màn Hình Thuộc Phạm Vi
| # | Màn hình | Vai trò sử dụng | Tạo mới / Sửa | Route |
|---|---|---|---|---|
| 1 | Nhập Thư Mời Gia Tộc (`InviteCodeScreen`) | Khách / Người dùng mới | Sửa | `/invite-code` |
| 2 | Đăng Ký Gia Nhập Gia Tộc (`RegisterMemberScreen`) | Khách / Người dùng mới | Sửa toàn diện | `/register-member?inviteCode=...` |
| 3 | Hồ Sơ Chờ Phê Duyệt (`PendingApprovalScreen`) | Khách / Người dùng mới | Sửa | `/pending-approval` |
| 4 | Đăng Nhập (`LoginScreen`) | Người dùng đã đăng ký | Sửa (bổ sung xử lý lỗi `PendingApproval`) | `/login` |

### 3.2. Sơ Đồ Luồng Nghiệp Vụ
```
[Khách mở ứng dụng / Web]
       │
       ▼
[Màn hình Nhập Mã Mời (/invite-code)]
       │  (Nhập mã -> Gọi GET /api/v1/invitations/{code})
       ├─────────────────────────────────────────┐
       ▼ (Nếu inviteType == GeneralClanInvite)    ▼ (Nếu inviteType == PositionLinkCode)
[Màn hình Đăng Ký Gia Nhập (/register-member)]    [Luồng US-19: Khớp vị trí tức thì]
       │
       ├─► 1. Tự động tải Cây phả hệ thu gọn: GET /api/v1/invitations/{code}/tree
       ├─► 2. Chọn vị trí:
       │      • Tab 1: Chọn nhánh hiện có (targetBranchId) [Bị khóa nếu mã có targetBranchId cố định]
       │      • Tab 2: Đề xuất nhánh con mới (targetBranchId là nhánh cha, nhập proposedNewBranchName)
       ├─► 3. Chọn đời thứ đề xuất (proposedGeneration) & Ghi chú quan hệ (relationshipNote)
       ├─► 4. Nhập thông tin cá nhân (Họ tên, SĐT, Ngày sinh, Giới tính, Mật khẩu)
       ├─► 5. Bấm "Gửi Đơn Gia Nhập Dòng Họ" (Chống double click, validate client)
       │      • Gọi POST /api/v1/invitations/{code}/join
       ▼ (Thành công: HTTP 201 Created nhận JoinRequestResponse)
[Màn hình Chờ Phê Duyệt (/pending-approval)]
       │ (Hiển thị requestId, tên dòng họ, nhánh đề xuất, lời nhắn)
       ▼
(Sau này, người dùng mở app bấm Đăng nhập tại /login)
       │
       ├──► Nếu vẫn PendingApproval: Login lỗi 400 -> Hiện banner hướng dẫn & nút xem trạng thái chờ duyệt.
       ├──► Nếu đã Approved (Active): Login thành công 200 OK -> Vào /home (Role: ROLE_MEMBER).
       └──► Nếu bị Rejected: Login báo tài khoản bị từ chối kèm hướng dẫn liên hệ Ban quản trị.
```

---

## 4. Báo Cáo Audit Code Hiện Trạng (Khắc Phục 4 Điểm Mâu Thuẫn)

| Điểm kiểm tra | Hiện trạng code frontend cũ | Đối chiếu thực tế Backend | Giải pháp khắc phục trong Plan |
|---|---|---|---|
| **1. RegisterMemberRequestDto thiếu trường** | Chỉ có 7 trường cơ bản (`inviteCode, fullName, phone, pass, gender, dob, email`). | Backend yêu cầu thêm: `proposalType`, `targetBranchId`, `proposedNewBranchName`, `proposedGeneration`, `relationshipNote`. | Cập nhật toàn diện `RegisterMemberRequestDto` và tạo enum `ProposalType` chuẩn xác. |
| **2. Chưa có API/giao diện lấy danh sách nhánh** | Thư mục `features/genealogy` rỗng; màn hình không có widget cây/danh sách nhánh. | Backend cung cấp public endpoint `GET /api/v1/invitations/{code}/tree` trả về `OnboardingBranchTreeNode`. | Bổ sung API `getOnboardingBranchTree` vào datasource và xây dựng widget chọn nhánh trực quan (Tree selector / Dropdown). |
| **3. Fallback mock và "thành công giả"** | `previewInvite` khi lỗi thì catch nuốt lỗi tạo fake data; `registerMember` gọi nhầm `auth/register-member` và khi bị 404 thì return coi như thành công. | Backend đã có endpoint chuẩn `POST /api/v1/invitations/{code}/join` và `GET /api/v1/invitations/{code}`. | Xóa bỏ 100% logic mock, nuốt lỗi; ném exception chuẩn để UI xử lý đúng lỗi. |
| **4. Tự đăng nhập sau khi nộp đơn** | Code cũ gọi `login` ngay sau khi đăng ký rồi catch lỗi để `push('/pending-approval')`. | Backend trả về `201 Created` kèm `JoinRequestResponse`, tài khoản `PendingApproval` không được phép login. | Bỏ hoàn toàn thao tác cố login sau đăng ký; nhận `JoinRequestResponse` rồi điều hướng trực tiếp sang `/pending-approval` truyền theo dữ liệu đơn. |

---

## 5. Chi Tiết Từng Màn Hình

### 5.1. Màn hình 1: Nhập Thư Mời Gia Tộc (`InviteCodeScreen` - `/invite-code`)
* **Mục đích:** Cho phép con cháu nhập hoặc dán mã mời chung để xác thực trước khi bước vào đăng ký.
* **Bố cục:**
  - **Mobile (~390px):** Form căn giữa, banner quốc huy / huy hiệu dòng họ, ô nhập mã dạng monospace chữ hoa (`LE-CHI2-DOI5-9821`), nút kiểm tra mã.
  - **Web (~1280px):** Khung card chia 2 cột kiểu Warm Editorial (cột trái hình ảnh truyền thống gia phong và lời răn dạy; cột phải là tương tác nhập mã).
* **Trạng thái:**
  - *Đang tải:* Nút kiểm tra hiển thị spinner, disable input.
  - *Lỗi (Hết hạn / Hết lượt / Không tồn tại):* Hiển thị Card cảnh báo đỏ viền gạch, thông báo chi tiết lỗi từ backend.
  - *Thành công:* Thẻ thông tin xem trước mã (Tên dòng họ, loại mã, thời hạn, ghi chú) và nút chuyển sang màn hình đăng ký.

### 5.2. Màn hình 2: Đăng Ký Gia Nhập Gia Tộc (`RegisterMemberScreen` - `/register-member`)
* **Mục đích:** Khách điền hồ sơ thành viên, chọn vị trí trên phả hệ và tạo tài khoản.
* **Bố cục Mobile (~390px):**
  - Thanh cuộn dọc chia 4 khối thẻ rõ ràng (Parchment card nền `#FFFDF9`, viền `#E5DDD0`):
    1. **Thẻ huy hiệu dòng họ & mã mời:** Huy hiệu tròn, tên dòng họ, chip xanh `Mã mời hợp lệ: {code}`.
    2. **Thẻ vị trí phả hệ (Genealogy Placement):**
       - Hai tab: `Gia nhập nhánh có sẵn` (mặc định) và `Đề xuất nhánh con mới`.
       - Danh sách cây chi nhánh thu gọn: Hiển thị các chi nhánh dạng cây có thụt lề, radio button chọn nhánh. Nếu mã mời có `targetBranchId`, nhánh này tự động được chọn và bị khóa không cho đổi.
       - Ô nhập/chọn Đời thứ đề xuất (`proposedGeneration`): Giá trị mặc định gợi ý theo nhánh đã chọn.
       - Nếu chọn tab *Đề xuất nhánh con mới*: Hiển thị thêm ô `Tên chi nhánh mới đề xuất` (bắt buộc).
       - Ô `Ghi chú mối quan hệ / nguồn gốc` (`relationshipNote`).
    3. **Thẻ thông tin cá nhân & tài khoản:**
       - Họ và tên con cháu (Textfield).
       - Số điện thoại (Textfield format VN, ghi chú: *Dùng làm tài khoản đăng nhập*).
       - Ngày sinh (Date Picker kết hợp chuyển đổi âm lịch tham khảo) & Giới tính (Segmented button Nam/Nữ/Khác).
       - Mật khẩu & Xác nhận mật khẩu (Toggle xem/ẩn mật khẩu).
    4. **Cam kết & Nút hành động:**
       - Checkbox cam kết gia phong và tôn trọng truyền thống gia tộc.
       - Nút chính: **"Gửi Đơn Gia Nhập Dòng Họ"** (Màu đất nung `#CC785C`).
* **Bố cục Web (~1280px):**
  - Hai cột song song (Two-column layout):
    - Cột trái (5/12): Khung cây phả hệ thu gọn trực quan (Interactive Tree View) để người dùng bấm trực tiếp vào từng nhánh xem tên đại diện và số đời để chọn vị trí.
    - Cột phải (7/12): Form thông tin cá nhân và đề xuất tài khoản.
* **Chống bấm đúp (Debounce / Double-click prevention):**
  - Biến `_isSubmitting`: Vô hiệu hóa nút gửi ngay khi nhấn, hiển thị `CircularProgressIndicator` kèm text *"Đang gửi hồ sơ..."*.
* **5 trạng thái màn hình:**
  1. *Đang tải:* Skeleton loading toàn bộ form và cây phả hệ khi đang fetch API `/tree`.
  2. *Rỗng:* Khi cây phả hệ trả về rỗng, hiển thị thông báo không tìm thấy chi nhánh và nút liên hệ Trưởng tộc.
  3. *Lỗi:* Banner đỏ viền gạch hiển thị lỗi API (trùng SĐT, mã mời hết hạn giữa chừng).
  4. *Không đủ quyền / Mã không hợp lệ:* Chặn không cho nhập form, hiển thị nút quay lại màn hình nhập mã mời.
  5. *Đang gửi:* Disable tất cả input, nút chuyển sang trạng thái loading.

### 5.3. Màn hình 3: Hồ Sơ Chờ Phê Duyệt (`PendingApprovalScreen` - `/pending-approval`)
* **Mục đích:** Báo cho người dùng biết đơn đã ghi nhận thành công và đang chờ Trưởng tộc/nhánh duyệt.
* **Bố cục (Mobile & Web):**
  - Huy hiệu đồng hồ cát / thư tín cổ truyền màu vàng đất.
  - Tiêu đề: **"Hồ Sơ Đã Ghi Vào Sổ Vàng Gia Tộc"**.
  - Bảng thông tin tóm tắt hồ sơ:
    - Mã đơn: `requestId` (copyable).
    - Dòng họ: `clanName`.
    - Vị trí đề xuất: Nhánh mục tiêu & Đời thứ.
    - Ngày gửi: Giờ định dạng Việt Nam.
    - Trạng thái: Badge màu hổ phách `Chờ Phê Chuẩn (Pending)`.
  - Hướng dẫn 3 bước:
    1. Hồ sơ đã được gửi tới Trưởng tộc / Trưởng chi quản lý.
    2. Ban quản trị sẽ đối soát phả hệ và duyệt đơn.
    3. Sau khi duyệt, bạn có thể đăng nhập bằng Số điện thoại và Mật khẩu đã tạo.
  - Nút hành động: "Về Màn Hình Đăng Nhập".

---

## 6. Thiết Kế Stitch & Mockup

* **Desktop Mockup (Dự án gốc `286117820646935235`):**
  - Màn hình tham chiếu: `Đăng Nhập & Kích Hoạt Mã Mời Gia Phả` (ID: `eddecbbc64404e9dae700b53e853832f`).
  - Đã lưu file HTML: [`mockup-desktop.html`](file:///d:/WorkSpace/Family-Management/family-management-frontend/docs/design/US-17/mockup-desktop.html).
* **Mobile Mockup (Dự án Stitch mới `17774159724462403647`):**
  - Tên dự án: `FamilyFund Mobile Onboarding (US-17)`.
  - Màn hình đã tạo: `Đăng Ký Gia Nhập Gia Tộc (US-17)` (ID: `8cf109b34ee948feaba967a6db510b59`).
  - Đã lưu file HTML: [`mockup-mobile.html`](file:///d:/WorkSpace/Family-Management/family-management-frontend/docs/design/US-17/mockup-mobile.html).
  - Phong cách: **Warm Editorial Heritage** (Màu `#CC785C`, nền giấy dó `#FAF9F5`, font `Merriweather` + `Be Vietnam Pro` / `Plus Jakarta Sans`).

---

## 7. Tái Sử Dụng Và Tạo Mới Code

### Tái sử dụng:
* `DioClient`: [`dio_client.dart`](file:///d:/WorkSpace/Family-Management/family-management-frontend/lib/core/network/dio_client.dart).
* `ApiResponse`: [`api_response.dart`](file:///d:/WorkSpace/Family-Management/family-management-frontend/lib/core/network/api_response.dart).
* `AppTheme`: [`app_theme.dart`](file:///d:/WorkSpace/Family-Management/family-management-frontend/lib/core/theme/app_theme.dart) và các màu tokens (`primary`, `surface`, `onSurface`, `secondary`).
* Formatters: [`formatters.dart`](file:///d:/WorkSpace/Family-Management/family-management-frontend/lib/core/utils/formatters.dart).

### Tạo mới / Nâng cấp:
* Model DTOs mới:
  - `SubmitJoinRequestDto` (chuẩn hóa đầy đủ các trường khớp backend).
  - `JoinRequestResponseDto` (chứa `requestId`, `approvalStatus`, `targetBranchName`...).
  - `OnboardingBranchTreeNodeDto` (mô hình hóa cây phân cấp chi nhánh đệ quy).
  - Enum `ProposalType` (`ExistingBranchLeaf`, `NewChildBranch`).
  - Enum `JoinRequestApprovalStatus` (`Pending`, `Approved`, `Rejected`).
* Widget trực quan:
  - `OnboardingBranchSelector`: Widget hiển thị danh sách nhánh dạng cây thu gọn cho phép chọn hoặc đề xuất nhánh mới, thích ứng cả Mobile và Web.

---

## 8. Danh Sách File Dự Kiến Tạo / Sửa (Sau Khi Được Duyệt Plan)

1. **`lib/features/auth/data/models/auth_models.dart` (Sửa):**
   - Thêm `ProposalType`, `JoinRequestApprovalStatus`.
   - Cập nhật `RegisterMemberRequestDto` (thay thế hoặc bổ sung thành `SubmitJoinRequestDto`).
   - Thêm `JoinRequestResponseDto`, `OnboardingBranchTreeNodeDto`.
   - Cập nhật `InviteCodePreviewDto` để nhận thêm `clanName`, `targetBranchName`.
2. **`lib/features/auth/data/datasources/auth_remote_datasource.dart` (Sửa):**
   - Sửa endpoint `registerMember` sang `POST invitations/{inviteCode}/join` và trả về `JoinRequestResponseDto`.
   - Xóa bỏ fallback mock trong `previewInvite` và `registerMember`.
   - Bổ sung hàm `Future<OnboardingBranchTreeNodeDto> getOnboardingBranchTree(String inviteCode)`.
3. **`lib/features/auth/presentation/screens/invite_code_screen.dart` (Sửa):**
   - Xóa fallback mock giả lập.
   - Kiểm tra `inviteType`: nếu `GeneralClanInvite` điều hướng sang `/register-member`, nếu `PositionLinkCode` báo rõ hoặc chuyển sang màn liên kết.
4. **`lib/features/auth/presentation/screens/register_member_screen.dart` (Sửa toàn diện):**
   - Tích hợp tải cây phả hệ `/tree`.
   - Bổ sung bộ chọn nhánh / đề xuất nhánh con mới và chọn đời thứ.
   - Khóa nhánh nếu mã mời có `targetBranchId`.
   - Chống bấm đúp (debounce submit button).
   - Bỏ đoạn code cố tình login sau khi gửi đơn; nhận kết quả `JoinRequestResponseDto` và chuyển thẳng sang `/pending-approval`.
5. **`lib/features/auth/presentation/screens/pending_approval_screen.dart` (Sửa):**
   - Nhận dữ liệu `JoinRequestResponseDto` từ route extra để hiển thị mã đơn thực tế (`requestId`), chi nhánh và dòng họ.
6. **`lib/features/auth/presentation/screens/login_screen.dart` (Sửa nhỏ):**
   - Xử lý thông điệp lỗi chứa `PendingApproval` khi đăng nhập để hiển thị nút liên kết sang màn hình chờ duyệt.

---

## 9. Rủi Ro & Nợ Kỹ Thuật Chạm Tới

1. **Nuốt lỗi và Mock ngầm trong code cũ:** Code cũ có nhiều đoạn `catch` tự tạo mock khi lỗi mạng hoặc lỗi 404. Cần dọn dẹp triệt để để lộ lỗi thật từ server.
2. **Khóa vĩnh viễn số điện thoại khi bị từ chối:** Nếu một yêu cầu bị Trưởng tộc từ chối (`Rejected`), tài khoản `user_accounts` bị đánh dấu `Deactivated`. Backend hiện tại kiểm tra `existsByPhoneNumber` nên số điện thoại đó không thể đăng ký lại được. Cần lưu ý người dùng về cơ chế này.
3. **Tài liệu spec kiến trúc chưa đồng bộ với code thật:** Theo rule 00, không được dùng các class giả định như `AdaptiveWorkspaceShell` hay thư viện `freezed` vì codebase hiện tại chưa cài đặt; toàn bộ DTO viết tay và dùng responsive thuần Flutter.

---

## 10. Đề Nghị Backend (Backend Enhancements)

1. **Cho phép gửi lại yêu cầu khi bị từ chối:** Đề xuất backend bổ sung cơ chế giải phóng số điện thoại hoặc cho phép cập nhật lại đơn yêu cầu (`branch_join_requests`) nếu tài khoản trước đó ở trạng thái `Deactivated` và chưa từng liên kết với `member_id` chính thức.
2. **Endpoint công khai tra cứu tiến độ đơn:** Hiện tại chỉ có các vai trò quản trị (`CLAN_HEAD`, `BRANCH_HEAD`, `ADMIN`) mới có API xem danh sách đơn. Đề xuất bổ sung một endpoint công khai tra cứu trạng thái đơn:
   `GET /api/v1/invitations/requests/{requestId}?phone={phoneNumber}`
   để người dùng có thể chủ động tra cứu xem hồ sơ của mình đã được duyệt hay bị từ chối mà không cần phải thử đăng nhập lại.

---

## 11. Checklist Tiêu Chí Nghiệm Thu (Acceptance Criteria Checklist)
- [ ] Nhập mã mời chung hợp lệ, tải và hiển thị chính xác thông tin dòng họ cùng cây phả hệ thu gọn (không lộ SĐT/email/ngày sinh của thành viên khác).
- [ ] Nếu mã mời có `targetBranchId`, ô chọn nhánh bị khóa cứng và điền sẵn tên nhánh đó.
- [ ] Người dùng có thể chọn một chi nhánh hiện có hoặc chuyển sang đề xuất chi nhánh con mới kèm tên nhánh mới.
- [ ] Chọn đời thứ đề xuất (số nguyên >= 1).
- [ ] Form kiểm tra hợp lệ đầy đủ (SĐT VN, mật khẩu 6-50 ký tự, họ tên, giới tính).
- [ ] Chống bấm đúp (Disable nút khi đang gửi, hiển thị trạng thái đang xử lý).
- [ ] Không có fallback mock hay nuốt lỗi; lỗi từ backend được hiển thị rõ ràng bằng tiếng Việt.
- [ ] Gửi đơn thành công nhận mã `requestId` và chuyển sang màn hình Chờ Phê Duyệt (`PendingApprovalScreen`), không cố tự động đăng nhập.
- [ ] Đăng nhập khi tài khoản đang ở trạng thái `PendingApproval` hiển thị đúng thông báo chờ duyệt và có lối dẫn sang màn hình thông tin hồ sơ.

