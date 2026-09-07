# 🍏 CyChronos Apple Design System & UX Philosophy

> **Tài liệu Định hướng Thiết kế & Trải nghiệm Người dùng Chuẩn mực của CyChronos**  
> *"Đơn giản là đỉnh cao của sự tinh tế." — Steve Jobs*

---

## 🎯 1. Tuyên ngôn Cốt lõi (Core Manifesto)

CyChronos là ứng dụng đồng hành cho người đạp xe. Người dùng thường quan sát màn hình trong tích tắc (0.2s - 0.5s) giữa các nhịp thở và khúc cua trên đường. Do đó, trải nghiệm của CyChronos phải tuân thủ nghiêm ngặt **3 Trụ cột Thiết kế của Apple**:

1. **Clarity (Minh bạch & Trực diện)**:
   - **Glanceable UI**: Mọi thông tin cốt lõi (hướng rẽ, khoảng cách, thời gian) phải đọc được ngay từ cái nhìn đầu tiên.
   - **Zero Noise**: Không bao giờ viết những câu văn dài dòng, giải thích thừa thãi (ví dụ: *"案内を停止しています。15分後に帰りのルートを表示します。"* ❌ $\rightarrow$ *`⏱️ 15分`* ✅). Hãy tin tưởng vào trí tuệ của người dùng và sức mạnh của UI biểu tượng.
2. **Deference (Tôn vinh Nội dung - Map is King)**:
   - Trong quá trình đạp xe, **Bản đồ lộ trình là VUA**.
   - UI chỉ là những **Hòn đảo Thủy tinh lơ lửng (Floating Glass Islands / Dynamic Capsules)** nhẹ nhàng nổi trên bản đồ, tuyệt đối không được dùng những khối hộp màu trắng đặc (Bottom Sheet) bám dính đáy che khuất 30% góc nhìn của người lái xe.
3. **Depth & Delight (Chiều sâu & Cảm xúc)**:
   - Chiều sâu được tạo ra bằng ánh sáng, độ mờ (Frosted Blur sigma 20), đường viền siêu mỏng (`Border.all(color: AppColors.border.withValues(alpha: 0.5))`) và bóng đổ tự nhiên (`BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: Offset(0, 4))`).
   - Cảm xúc được truyền tải qua phản hồi xúc giác (**Haptic Feedback**) và lò xo vật lý (**TapScale**).

---

## 🧭 2. Quy chuẩn Đồng nhất Giao diện Điều hướng (Navigation UI Standard)

### ❌ Sai lầm trong quá khứ (Anti-pattern):
- Đi 片道 (Một chiều) thì bản đồ toàn màn hình + chỉ có 1 nút đỏ `案内を終了`. Dù người dùng đến nơi hay mới bấm thấy xa quá ấn hủy thì app cũng đều tự động lưu chuyến đi 8.5km vào lịch sử và chúc mừng "お疲れさまでした!" rất vô lý.
- Đi 往復 (Khứ hồi) thì đột ngột biến thành một cái hộp chữ nhật màu trắng to đùng dính chặt đáy màn hình với thanh Home Indicator giả tạo và những đoạn văn bản dài loằng ngoằng.
$\rightarrow$ **Giao diện chắp vá, bất nhất và logic lưu lịch sử bị sai lệch.**

### ✅ Quy chuẩn Chuẩn hóa (Unified Apple Standard):
Tất cả các trạng thái trong chuyến đi (**Một chiều, Khứ hồi lượt đi, Tạm dừng/Nghỉ chân, Khứ hồi lượt về**) đều dùng chung cấu trúc **Hòn đảo Thủy tinh lơ lửng (Floating Apple Dock)** cách đáy 20px, bo góc 24px, phân định rõ ràng nút HỦY (bên trái) và nút TIẾN BƯỚC / HOÀN THÀNH (bên phải):

| Trạng thái | Hình thái Giao diện | Thành phần bên trong |
| :--- | :--- | :--- |
| **片道 (Một chiều)** | **Floating Apple Dock** | Bên trái: `[ ✕ 案内を終了 ]` (Hủy/dừng). Bên phải: `[ 🏁 到着・完了 ]` (Hoàn thành & Lưu lịch sử). |
| **往復 Lượt đi (Outbound)** | **Floating Apple Dock** | Bên trái: `[ ✕ 案内を終了 ]` (Hủy/dừng). Bên phải: `[ 到着・滞在を開始 ]` (Đến điểm dừng, bắt đầu nghỉ chân). |
| **往復 Nghỉ chân (Staying)** | **Floating Apple Dock** | Hàng trên: Icon cà phê `Icons.coffee_rounded` + Chữ `滞在中` + Badge thời gian `⏱️ 15分` (JetBrainsMono). Hàng dưới: `[ ✕ 案内を終了 ]` + `[ 今すぐ折り返す ]`. |
| **往復 Lượt về (Return)** | **Floating Apple Dock** | Bên trái: `[ ✕ 案内を終了 ]` (Hủy/dừng). Bên phải: `[ 🏁 到着・完了 ]` (Hoàn thành chuyến đi khứ hồi & Lưu lịch sử). |

---

## 🚦 3. Logic Hoàn Thành vs Hủy Chuyến Đi (Completion vs Cancel Logic)

> **"Mới bấm thấy xa quá ấn hủy mà cũng lưu vào lịch sử là dở hơi!"** — Đây là nguyên tắc cốt tử về tính toàn vẹn dữ liệu (Data Integrity).

### 1. Khi người dùng bấm `[ 🏁 到着・完了 ]` (hoặc GPS tự động đến đích):
- Người dùng đã thực sự hoàn thành chuyến đi.
- Gọi `endTrip` lên server, lưu lịch sử, cập nhật tab HISTORY.
- Mở màn hình tổng kết chúc mừng `TripSummaryScreen` với hiệu ứng vòng hào quang và số liệu.

### 2. Khi người dùng bấm `[ ✕ 案内を終了 ]`:
- **Trường hợp A: Hủy tức thì / Bấm nhầm / Thấy xa quá hủy (Quick Cancel)**
  - Điều kiện: Thời gian từ lúc bắt đầu `< 2 phút` và chưa có tọa độ GPS di chuyển đáng kể.
  - **Hành động: KHÔNG LƯU VÀO LỊCH SỬ!**
  - Gọi `cancelTrip` (DELETE `/api/trips/:tripId`) để xóa bản ghi tạm trên server. Địa điểm đó không bị đánh dấu là "đã đến" và vẫn được gợi ý trong tương lai.
  - KHÔNG mở màn hình tổng kết chúc mừng.
  - Quay về màn hình xem trước tức thì, không hiện toast dư thừa làm che khuất bản đồ (Zero Noise).
- **Trường hợp B: Đã đạp xe một quãng đường nhưng muốn dừng giữa chừng (Mid-Ride Termination)**
  - Điều kiện: Đã đạp xe `>= 2 phút` và có GPS log thực tế.
  - Hiển thị hộp thoại xác nhận tối giản chuẩn Apple (Tối giản tuyệt đối với **đúng 2 nút đối xứng**, tránh gây rối mắt khi lái xe):
    - **`続ける`**: Đóng hộp thoại, tiếp tục lộ trình.
    - **`終了する`** (Màu đỏ Apple): Hủy chuyến đi dở dang và quay về, không lưu lịch sử rác.
    - *(Lưu ý: Nếu người dùng muốn hoàn thành chuyến đi và lưu lịch sử, họ chỉ cần nhấn nút `[ 🏁 到着・完了 ]` ngay trên Dock).*

---

## 🎨 4. Bảng Màu & Tokens (Color Tokens)

```dart
// 🌲 Gam màu chủ đạo (Deep Nature Cycling)
static const Color primary = Color(0xFF1B4332);      // Xanh rừng thẳm sang trọng
static const Color primaryLight = Color(0xFF2D6A4F); // Xanh thứ cấp
static const Color accentMint = Color(0xFF52B788);   // Xanh bạc hà thể thao
static const Color accentBg = Color(0xFFD8F3DC);     // Nền badge/chip sinh động

// 🚨 Gam màu trạng thái Apple
static const Color danger = Color(0xFFE63946);       // Đỏ Apple (dừng/hủy/nguy hiểm)
static const Color warning = Color(0xFFFF9500);      // Cam Apple (nghỉ chân/cảnh báo)

// 🌫️ Nền & Kính thủy tinh (Frosted Surfaces)
static const Color bgCool = Color(0xFFF7F9FC);       // Xám lạnh sạch sẽ
static const Color cardBg = Colors.white;            // Trắng tinh khiết
static const Color border = Color(0xFFE2E8F0);       // Viền siêu mảnh tinh tế
```

---

## 🔤 5. Kiểu Chữ & Phân Cấp (Typography Hierarchy)

| Loại hiển thị | Phông chữ | Trọng lượng (Weight) | Ứng dụng |
| :--- | :--- | :--- | :--- |
| **Tiêu đề lớn / Hero** | `HankenGrotesk` | `w800` (ExtraBold) | Tên địa điểm, số liệu tổng kết, tiêu đề màn hình. |
| **Số đo / Thời gian / Vận tốc** | `JetBrainsMono` | `w700` (Bold) | `8.5km`, `約40分`, `18.4km/h`, `⏱️ 15分`. Tạo cảm giác thể thao, chính xác của đồng hồ bấm giờ. |
| **Nút bấm / Nhãn** | `HankenGrotesk` | `w700` (Bold) | Nhãn nút hành động (`案内開始`, `案内を終了`, `到着・完了`). |
| **Nội dung / Địa chỉ** | `Inter` / `NotoSansJP` | `w500` - `w600` | Địa chỉ, tên đường rẽ, mô tả ngắn gọn. |

---

## 📳 6. Tương tác Xúc giác & Vật lý (Haptics & Physics)

1. **TapScale**:
   - Mọi nút bấm và thẻ có thể chạm (Card, Button, Tile) đều phải có hiệu ứng co nhún nhẹ (`Transform.scale: 0.96`) khi ấn xuống và bung ra khi nhấc tay.
2. **Haptic Feedback**:
   - `HapticFeedback.selectionClick()`: Khi chuyển tab hoặc đổi lựa chọn (Picker, Segmented Control).
   - `HapticFeedback.mediumImpact()`: Khi kích hoạt hành động quan trọng (Bắt đầu dẫn đường, Đổi hướng rẽ, Kết thúc chuyến đi).

---

## 🛡️ 7. An toàn Chuyến đi (Trip Safety Guard)

Khi người dùng đang trong chuyến đi đạp xe (`isTripNavigatingProvider == true`):
- **Khóa thao tác Reset tab Home**: Nhấn lại vào nút Home ở bottom nav sẽ **bị vô hiệu hóa** (không gọi `popUntil`).
- **Khóa cử chỉ Back của HĐH**: Toàn bộ màn hình được bọc trong `PopScope(canPop: !_isNavigating)`.
- **Triệt tiêu Toast dư thừa**: Trước khi mở `TripSummaryScreen`, luôn gọi `AppToast.clear()` để không làm hỏng không khí chúc mừng hoàn thành chặng đường.

---

## 📋 8. Checklist Kiểm duyệt (Apple Design Checklist)

Trước khi submit bất kỳ tính năng hoặc màn hình mới nào trong CyChronos, hãy tự hỏi:
- [ ] Màn hình có tối giản không? Có câu chữ nào dài hơn 1 dòng có thể cắt bỏ hoặc thay bằng icon không?
- [ ] Logic lưu lịch sử có phân định rành mạch giữa **HỦY** (không lưu) và **HOÀN THÀNH** (lưu) không?
- [ ] Số liệu khoảng cách, thời gian, tốc độ đã dùng phông `JetBrainsMono` chưa?
- [ ] Nút bấm đã dùng bo góc chuẩn Apple (`14px` - `18px` hoặc `Pill 9999`) và có hiệu ứng co nhún không?
- [ ] Các thành phần trên bản đồ có lơ lửng (`Floating Dock`) hay đang bị đóng hộp vuông vức thô kệch?
- [ ] Giao diện giữa các chế độ (Một chiều vs Khứ hồi) có đồng nhất 100% về vị trí, hình dáng và linh hồn không?
