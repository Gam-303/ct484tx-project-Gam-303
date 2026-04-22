/// <reference path="../pb_data/types.d.ts" />

routerAdd("POST", "/api/auth/reset-password-by-otp", (e) => {
  const body = e.requestInfo().body || {};
  const otpId = String(body.otpId || "").trim();
  const otpCode = String(body.otpCode || "").trim();
  const newPassword = String(body.newPassword || "").trim();

  if (!otpId || !otpCode || !newPassword) {
    return e.json(400, {
      message: "Thiếu dữ liệu bắt buộc (otpId, otpCode, newPassword).",
    });
  }

  if (newPassword.length < 8) {
    return e.json(400, {
      message: "Mật khẩu mới phải có ít nhất 8 ký tự.",
    });
  }

  let otpRecord;
  try {
    otpRecord = e.app.findOTPById(otpId);
  } catch (_) {
    return e.json(400, { message: "OTP không hợp lệ hoặc đã hết hạn." });
  }

  if (!otpRecord || !otpRecord.validatePassword(otpCode)) {
    return e.json(400, { message: "OTP không chính xác." });
  }

  const userId = otpRecord.recordRef();
  if (!userId) {
    return e.json(400, { message: "OTP không liên kết với tài khoản hợp lệ." });
  }

  try {
    const usersCollection = e.app.findCollectionByNameOrId("users");
    const userRecord = e.app.findRecordById(usersCollection.id, userId);
    userRecord.setPassword(newPassword);
    userRecord.refreshTokenKey();
    e.app.save(userRecord);
    e.app.delete(otpRecord);
  } catch (_) {
    return e.json(500, { message: "Không thể đặt lại mật khẩu lúc này." });
  }

  return e.json(200, { message: "Đặt lại mật khẩu thành công." });
});
