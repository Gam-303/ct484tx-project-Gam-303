# PocketBase Schema cho Pomodoro (offline-first)

Tạo 3 collection sau trong PocketBase Admin UI.

## 1) `tasks`

- **Type**: Base collection
- **Fields**
  - `client_id` (text, required, unique trong phạm vi mỗi user qua index)
  - `user` (relation -> `_pb_users`, maxSelect: 1, required)
  - `title` (text, required)
  - `description` (editor/text, optional)
  - `deadline` (date, required)
  - `priority` (select: `high`, `medium`, `low`, required)
  - `estimated_pomodoros` (number, required, min: 1)
  - `completed_pomodoros` (number, required, min: 0)
  - `status` (select: `todo`, `completed`, required)
  - `updated_at_ms` (number, required)
  - `deleted` (bool, required, default: false)
- **Indexes**
  - unique: `(user, client_id)`
  - normal: `(user, updated_at_ms)`
- **Rules**
  - List/View: `@request.auth.id != "" && user = @request.auth.id`
  - Create: `@request.auth.id != "" && user = @request.auth.id`
  - Update: `@request.auth.id != "" && user = @request.auth.id`
  - Delete: `@request.auth.id != "" && user = @request.auth.id`

## 2) `pomodoro_sessions`

- **Type**: Base collection
- **Fields**
  - `client_id` (text, required)
  - `user` (relation -> `_pb_users`, maxSelect: 1, required)
  - `task` (relation -> `tasks`, maxSelect: 1, optional)
  - `phase` (select: `focus`, `short_break`, `long_break`, required)
  - `duration_seconds` (number, required, min: 1)
  - `started_at_ms` (number, required)
  - `ended_at_ms` (number, required)
  - `updated_at_ms` (number, required)
  - `deleted` (bool, required, default: false)
- **Indexes**
  - unique: `(user, client_id)`
  - normal: `(user, ended_at_ms)`
- **Rules**
  - List/View/Create/Update/Delete: `@request.auth.id != "" && user = @request.auth.id`

## 3) `user_settings`

- **Type**: Base collection
- **Fields**
  - `user` (relation -> `_pb_users`, maxSelect: 1, required)
  - `pomodoro_minutes` (number, required, min: 1)
  - `short_break_minutes` (number, required, min: 1)
  - `long_break_minutes` (number, required, min: 1)
  - `notifications_enabled` (bool, required)
  - `haptic_feedback` (bool, required)
  - `focus_sound` (bool, required)
  - `display_name` (text, optional)
  - `updated_at_ms` (number, required)
- **Indexes**
  - unique: `(user)`
- **Rules**
  - List/View/Create/Update/Delete: `@request.auth.id != "" && user = @request.auth.id`

## Gợi ý sync chiến lược

- App luôn ghi vào SQLite trước, đánh dấu `sync_state = pending_*`.
- Khi có mạng + user đã đăng nhập PocketBase, app push dữ liệu pending lên server.
- Sau khi push xong, app pull lại từ PocketBase để hợp nhất dữ liệu mới nhất.
- Xóa mềm ở server bằng cờ `deleted = true`, còn local có thể xóa cứng sau khi đồng bộ thành công.

## Hook custom đặt lại mật khẩu bằng OTP 6 số

- Đã thêm hook tại `pocketbase/pb_hooks/reset_password_by_otp.pb.js`.
- Endpoint mới: `POST /api/auth/reset-password-by-otp`.
- Body request:
  - `otpId` (string, từ API `users/request-otp`)
  - `otpCode` (string, 6 chữ số người dùng nhập)
  - `newPassword` (string, >= 8 ký tự)
- Hook sẽ:
  - Xác thực OTP bằng `otpId + otpCode`.
  - Đổi mật khẩu trực tiếp ở record user (không yêu cầu `oldPassword`).
  - Xóa OTP đã dùng để tránh tái sử dụng.
