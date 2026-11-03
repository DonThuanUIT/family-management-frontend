# Đề Nghị Cải Tiến Backend – US-07: Phân Hệ Công Việc & Phân Công Nhiệm Vụ Sự Kiện

Tài liệu này tổng hợp các yêu cầu, đề xuất bổ sung tính năng và tinh chỉnh API từ phía Frontend gửi đến nhóm Backend cho phân hệ **US-07 (Khởi tạo hạng mục công việc chuẩn bị sự kiện & phân công nhiệm vụ)**.

---

## 1. Bổ Sung API Cập Nhật & Sửa Chi Tiết Công Việc

* **Hiện trạng Backend:** Hiện tại Backend chỉ hỗ trợ tạo mới (`POST /tasks`) và phân công/gán lại (`POST /tasks/{taskId}/assign`). Nếu Ban tổ chức muốn điều chỉnh tên việc, nội dung chi tiết, cập nhật hạn chót hoặc điều chỉnh ngân sách tạm ứng dự kiến thì chưa có endpoint để thực hiện.
* **Đề xuất Endpoint:** `PUT /api/v1/events/{eventId}/tasks/{taskId}`
* **Quyền:** `hasAnyRole('CLAN_HEAD', 'ADMIN') or @eventSecurity.hasContextualRole(#eventId, 'HeadOfOrganizer', 'OrganizerMember')`
* **Request Body (`UpdateTaskRequest`):**
  ```json
  {
    "taskName": "Mua sắm hoa quả, trầu cau và hương đèn (Cập nhật)",
    "details": "Bổ sung thêm 2 mâm ngũ quả lớn",
    "advanceBudget": 4000000.0,
    "deadline": "2026-04-22T17:00:00Z"
  }
  ```
* **Quy tắc nghiệp vụ đề xuất:**
  - `deadline` phải ở tương lai và trước thời điểm sự kiện (`deadline < event.eventDatetime`).
  - Nếu sự kiện đã `Closed`, chặn không cho cập nhật với mã lỗi `400 Bad Request`.
  - Nếu công việc đã `Completed`, chỉ cho phép chỉnh sửa nội dung/ghi chú, không cho phép đổi hạn chót về quá khứ.

---

## 2. Bổ Sung API Xóa Hạng Mục Công Việc

* **Hiện trạng Backend:** Chưa có endpoint xóa công việc (`DELETE /tasks/{taskId}`). Khi Ban tổ chức tạo nhầm hoặc hủy bỏ một hạng mục hậu cần, công việc đó vẫn tồn tại trong danh sách.
* **Đề xuất Endpoint:** `DELETE /api/v1/events/{eventId}/tasks/{taskId}`
* **Quyền:** `hasAnyRole('CLAN_HEAD', 'ADMIN') or @eventSecurity.hasContextualRole(#eventId, 'HeadOfOrganizer')` (Chỉ Trưởng BTC, Trưởng tộc, hoặc Admin mới có quyền xóa).
* **Quy tắc nghiệp vụ đề xuất:**
  - Nếu công việc đã giải ngân tạm ứng (ở story tài chính tiếp theo), từ chối xóa và yêu cầu quyết toán/hoàn ứng trước.
  - Sự kiện đã `Closed`: Chặn không cho xóa.
  - Có thể thực hiện xóa mềm (`is_deleted = true`) để lưu vết kiểm toán.

---

## 3. Tiện Ích Kiểm Tra Quyền Ngữ Cảnh Theo Sự Kiện (`Contextual RBAC`)

* **Hiện trạng Backend:**
  - Token JWT sau khi đăng nhập chỉ chứa các vai trò toàn cục (`ROLE_CLAN_HEAD`, `ROLE_ADMIN`, `ROLE_MEMBER`...).
  - Khi xem chi tiết sự kiện `GET /api/v1/events/{eventId}`, backend trả về danh sách `personnel: List<EventPersonnelResponse>`.
  - Frontend hiện đang phải lấy `currentSession.memberId` duyệt thủ công từng phần tử trong `personnel` để xác định vai trò của người dùng trong sự kiện này.
* **Đề xuất:**
  - **Phương án 1 (Khuyến nghị):** Bổ sung trực tiếp vào `EventDetailResponse`:
    ```json
    {
      "eventId": "EVT20260426001",
      "eventName": "Lễ Giỗ Tổ 2026",
      "myRoleInEvent": "HeadOfOrganizer",
      "canManageTasks": true,
      "canMutateFinance": false,
      "isEffectiveReadOnly": false,
      "personnel": [...]
    }
    ```
  - **Phương án 2:** Cung cấp endpoint riêng `GET /api/v1/events/{eventId}/my-permissions` trả về quyền ngữ cảnh của người dùng hiện tại đối với sự kiện đó.

---

## 4. Endpoint Tra Cứu Danh Sách Thành Viên Dòng Họ Phục Vụ Phân Công (Tuân Thủ US-25)

* **Hiện trạng Backend:**
  - Backend đã có `GET /api/v1/branches/tree` để duyệt cây chi nhánh gia phả.
  - Tuy nhiên, chưa có REST endpoint phân trang để tìm kiếm danh sách thành viên trong dòng họ (`members`) phục vụ Tab "Cá nhân" trong bộ chọn người nhận việc.
  - Backend hiện chỉ có internal service `GenealogyQueryService.findMemberSummary(memberId)`.
* **Đề xuất Endpoint:** `GET /api/v1/clans/members`
* **Query Parameters:**
  - `keyword`: Tìm kiếm gần đúng theo họ tên (không phân biệt hoa thường).
  - `branchId`: Lọc theo chi nhánh cụ thể (tùy chọn).
  - `page`: Số trang (mặc định 0).
  - `size`: Kích thước trang (mặc định 20).
* **Response DTO (`MemberSummaryResponse`):**
  ```json
  {
    "memberId": "MEM10000002",
    "fullName": "Lê Hữu Tuấn",
    "branchId": "BR10000002",
    "branchName": "Chi 2 - Phái Ất",
    "generation": 5,
    "isPlaceholder": false
  }
  ```
* **Ràng buộc an ninh dữ liệu cá nhân (US-25):**
  - **Tuyệt đối KHÔNG trả về:** `phoneNumber`, `email`, `dateOfBirth`, `identityCardNumber` trong response của endpoint tìm kiếm này.

