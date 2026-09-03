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
- Đi 片道 (Một chiều) thì bản đồ toàn màn hình + một nút đỏ tròn lơ lửng.
- Đi 往復 (Khứ hồi) thì đột ngột biến thành một cái hộp chữ nhật màu trắng to đùng dính chặt đáy màn hình với thanh Home Indicator giả tạo và những đoạn văn bản dài loằng ngoằng.
- Khi quay về (復路) thì lại nhảy sang nút đỏ tròn.
$\rightarrow$ **Giao diện chắp vá, bất nhất và phi Apple.**

### ✅ Quy chuẩn Chuẩn hóa (Unified Apple Standard):
Tất cả các trạng thái trong chuyến đi (**Một chiều, Khứ hồi lượt đi, Tạm dừng/Nghỉ chân, Khứ hồi lượt về**) đều phải dùng chung một ngôn ngữ thiết kế:

| Trạng thái | Hình thái Giao diện | Thành phần |
| :--- | :--- | :--- |
| **片道 (Một chiều)** | **Floating Apple Capsule** | Nút đỏ `[ ✕ 案内を終了 ]` bo tròn pill 9999, bóng đổ rực, nổi lơ lửng cách đáy 24px. |
| **往復 Lượt đi (Outbound)** | **Floating Apple Dock** | Hòn đảo bo góc 24px nổi lơ lửng. Bên trái: `[ ✕ 案内を終了 ]` viền mảnh đỏ nhạt. Bên phải: `[ 到着・滞在を開始 ]` nút xanh chủ đạo bo 14px. |
| **往復 Nghỉ chân (Staying)** | **Floating Apple Dock** | Hòn đảo bo góc 24px. Hàng trên: Icon cà phê `Icons.coffee_rounded` + Chữ `滞在中` + Badge thời gian `⏱️ 15分` (JetBrainsMono). Hàng dưới: `[ ✕ 案内を終了 ]` + `[ 今すぐ折り返す ]`. Tuyệt đối không có văn bản giải thích dài dòng. |
| **往復 Lượt về (Return)** | **Floating Apple Capsule** | Giống hệt trạng thái 片道: Nút đỏ `[ ✕ 案内を終了 ]` nổi lơ lửng trên bản đồ. |

---

## 🎨 3. Bảng Màu & Tokens (Color Tokens)

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

## 🔤 4. Kiểu Chữ & Phân Cấp (Typography Hierarchy)

| Loại hiển thị | Phông chữ | Trọng lượng (Weight) | Ứng dụng |
| :--- | :--- | :--- | :--- |
| **Tiêu đề lớn / Hero** | `HankenGrotesk` | `w800` (ExtraBold) | Tên địa điểm, số liệu tổng kết, tiêu đề màn hình. |
| **Số đo / Thời gian / Vận tốc** | `JetBrainsMono` | `w700` (Bold) | `8.5km`, `約40分`, `18.4km/h`, `⏱️ 15分`. Tạo cảm giác thể thao, chính xác của đồng hồ bấm giờ. |
| **Nút bấm / Nhãn** | `HankenGrotesk` | `w700` (Bold) | Nhãn nút hành động (`案内開始`, `案内を終了`). |
| **Nội dung / Địa chỉ** | `Inter` / `NotoSansJP` | `w500` - `w600` | Địa chỉ, tên đường rẽ, mô tả ngắn gọn. |

---

## 📳 5. Tương tác Xúc giác & Vật lý (Haptics & Physics)

1. **TapScale**:
   - Mọi nút bấm và thẻ có thể chạm (Card, Button, Tile) đều phải có hiệu ứng co nhún nhẹ (`Transform.scale: 0.96`) khi ấn xuống và bung ra khi nhấc tay.
2. **Haptic Feedback**:
   - `HapticFeedback.selectionClick()`: Khi chuyển tab hoặc đổi lựa chọn (Picker, Segmented Control).
   - `HapticFeedback.mediumImpact()`: Khi kích hoạt hành động quan trọng (Bắt đầu dẫn đường, Đổi hướng rẽ, Kết thúc chuyến đi).

---

## 🛡️ 6. An toàn Chuyến đi (Trip Safety Guard)

Khi người dùng đang trong chuyến đi đạp xe (`isTripNavigatingProvider == true`):
- **Khóa thao tác Reset tab Home**: Nhấn lại vào nút Home ở bottom nav sẽ **bị vô hiệu hóa** (không gọi `popUntil`).
- **Khóa cử chỉ Back của HĐH**: Toàn bộ màn hình được bọc trong `PopScope(canPop: !_isNavigating)`.
- **Triệt tiêu Toast dư thừa**: Trước khi mở `TripSummaryScreen`, luôn gọi `AppToast.clear()` để không làm hỏng không khí chúc mừng hoàn thành chặng đường.

---

## 📋 7. Checklist Kiểm duyệt (Apple Design Checklist)

Trước khi submit bất kỳ tính năng hoặc màn hình mới nào trong CyChronos, hãy tự hỏi:
- [ ] Màn hình có tối giản không? Có câu chữ nào dài hơn 1 dòng có thể cắt bỏ hoặc thay bằng icon không?
- [ ] Số liệu khoảng cách, thời gian, tốc độ đã dùng phông `JetBrainsMono` chưa?
- [ ] Nút bấm đã dùng bo góc chuẩn Apple (`14px` - `18px` hoặc `Pill 9999`) và có hiệu ứng co nhún không?
- [ ] Các thành phần trên bản đồ có lơ lửng (`Floating Dock`) hay đang bị đóng hộp vuông vức thô kệch?
- [ ] Giao diện giữa các chế độ (Một chiều vs Khứ hồi) có đồng nhất 100% về vị trí, hình dáng và linh hồn không?
