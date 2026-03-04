# Hướng dẫn Tạo Bài Học với OCR

## Tính năng mới: Tạo bài học riêng của bạn 📚

Bây giờ bạn có thể tạo bài học riêng bằng cách chụp ảnh từ vựng và ứng dụng sẽ tự động tạo flashcard cho bạn!

## Cách sử dụng

### Bước 1: Vào màn hình Tạo bài học
1. Mở app và vào tab **Lưu trữ** (Archive)
2. Nhấn vào nút **"Tạo bài học"** (Create Lesson)

### Bước 2: Đặt tên bài học
1. Nhập tên cho bài học của bạn (bắt buộc)
   - Ví dụ: "Từ vựng IELTS của tôi", "Từ sách giáo khoa"
2. Nhập mô tả (tùy chọn)
   - Ví dụ: "Các từ vựng quan trọng cho kỳ thi"
3. Nhấn nút **"Tiếp theo"**

### Bước 3: Chụp ảnh từ vựng
1. Chọn một trong hai cách:
   - 📷 **Máy ảnh**: Chụp ảnh trực tiếp
   - 🖼️ **Thư viện**: Chọn ảnh có sẵn

2. **Mẹo để có kết quả tốt nhất:**
   - ✅ Đảm bảo ánh sáng tốt
   - ✅ Chữ rõ ràng, không bị mờ
   - ✅ Chụp thẳng, tránh nghiêng
   - ✅ Tập trung vào từ vựng cần học

3. Sau khi chọn ảnh, nhấn **"Xử lý với OCR"**

### Bước 4: Xem và chỉnh sửa Flashcard
1. Hệ thống sẽ tự động:
   - Quét và nhận diện từ vựng trong ảnh
   - Tra cứu nghĩa từ trong từ điển
   - Tạo flashcard với phiên âm và ví dụ

2. **Chỉnh sửa flashcard:**
   - Nhấn nút **✏️** để sửa nội dung
   - Nhấn nút **🗑️** để xóa flashcard không cần thiết
   - Bạn có thể chỉnh sửa:
     - Từ vựng
     - Phiên âm
     - Nghĩa
     - Câu ví dụ

3. **Kiểm tra độ chính xác:**
   - Thanh màu bên trái mỗi flashcard cho biết độ tin cậy:
     - 🟢 Xanh: Rất chính xác (>80%)
     - 🟠 Cam: Trung bình (50-80%)
     - 🔴 Đỏ: Cần kiểm tra (<50%)

### Bước 5: Lưu bài học
1. Kiểm tra lại tất cả flashcard
2. Nhấn nút **"Lưu bài học"**
3. Bài học của bạn sẽ được lưu và hiển thị trong danh sách bài học

## Yêu cầu kỹ thuật

### Để sử dụng đầy đủ tính năng OCR:

1. **Backend Server**: Cần cài đặt backend Python với DeepSeek OCR
   - Xem hướng dẫn chi tiết tại: `OCR_INTEGRATION_GUIDE.md`
   - Hoặc sử dụng chế độ demo với dữ liệu mẫu

2. **Quyền truy cập**:
   - Camera: Để chụp ảnh trực tiếp
   - Thư viện ảnh: Để chọn ảnh có sẵn

## Chế độ hoạt động

### 1. Chế độ Demo (Mặc định)
- Sử dụng dữ liệu mẫu
- Không cần backend server
- Phù hợp để test giao diện

### 2. Chế độ Production
- Kết nối với backend DeepSeek OCR
- OCR thực tế từ ảnh
- Cần cài đặt backend server

## Các loại ảnh phù hợp

### ✅ Nên sử dụng:
- Trang sách giáo khoa
- Flashcard in sẵn
- Danh sách từ vựng viết tay rõ ràng
- Screenshot từ tài liệu PDF
- Bảng từ vựng trong bài kiểm tra

### ❌ Không nên sử dụng:
- Ảnh quá tối hoặc quá sáng
- Chữ viết tay không rõ ràng
- Ảnh bị mờ hoặc nghiêng nhiều
- Ảnh có quá nhiều text không liên quan

## Giải quyết vấn đề

### Không quét được từ vựng?
- Kiểm tra ánh sáng khi chụp
- Chụp lại ảnh rõ ràng hơn
- Thử sử dụng ảnh từ thư viện
- Đảm bảo backend đang chạy (nếu dùng chế độ production)

### Flashcard sai nghĩa?
- Sử dụng nút ✏️ để chỉnh sửa
- Kiểm tra lại từ vựng có đúng không
- Một số từ có nhiều nghĩa, chọn nghĩa phù hợp

### App bị lỗi khi xử lý?
- Kiểm tra kết nối internet
- Thử lại với ảnh nhỏ hơn
- Khởi động lại app

## Lợi ích

✨ **Tiết kiệm thời gian**: Không cần nhập từng từ thủ công

📚 **Học từ nhiều nguồn**: Sách, tài liệu, bài giảng...

🎯 **Cá nhân hóa**: Tạo bài học phù hợp với nhu cầu của bạn

🔄 **Tích hợp hoàn toàn**: Bài học tự tạo hoạt động như bài học có sẵn

## Ví dụ thực tế

### Tình huống 1: Học từ sách giáo khoa
1. Chụp ảnh trang từ vựng cuối sách
2. OCR tự động trích xuất tất cả từ
3. Xem và lưu làm bài học riêng

### Tình huống 2: Chuẩn bị cho kỳ thi
1. Chụp ảnh đề thi cũ
2. OCR tìm các từ khó
3. Tạo flashcard ôn tập

### Tình huống 3: Học từ bài báo
1. Screenshot đoạn text quan trọng
2. OCR trích xuất từ vựng mới
3. Lưu để học sau

## Lưu ý quan trọng

⚠️ **Bản quyền**: Chỉ chụp và sử dụng tài liệu mà bạn có quyền

🔒 **Quyền riêng tư**: Ảnh của bạn chỉ được xử lý và lưu cục bộ

💾 **Lưu trữ**: Bài học được lưu trong tài khoản của bạn

---

## Cần trợ giúp?

Nếu bạn gặp vấn đề hoặc có câu hỏi:
1. Xem lại hướng dẫn này
2. Kiểm tra file `OCR_INTEGRATION_GUIDE.md` cho hướng dẫn kỹ thuật
3. Liên hệ support

**Chúc bạn học tốt! 🎓**
