# Hướng Dẫn Phát Triển Ứng Dụng Chat App (Flutter + Firebase)

Tài liệu này hướng dẫn các bước để xây dựng tính năng cho ứng dụng Chat App của bạn.

## 1. Cấu Trúc Dữ Liệu Firebase (Firestore)

Để hỗ trợ các tính năng được yêu cầu, chúng ta cần thiết kế cơ sở dữ liệu Firestore như sau:

### Users Collection (`users`)
Lưu thông tin người dùng.
- `uid` (String): ID của user (từ Authentication)
- `email` (String)
- `displayName` (String): Tên hiển thị
- `photoUrl` (String): Link ảnh đại diện
- `dob` (Date/Timestamp): Ngày sinh
- `friends` (Array<String>): Danh sách UID của bạn bè

### Chats Collection (`chats`)
Lưu trữ các cuộc hội thoại.
- `id` (String): ID cuộc trò chuyện (có thể tạo từ 2 UID: `min(uid1, uid2)_max(uid1, uid2)` để đảm bảo duy nhất giữa 2 người)
- `participants` (Array<String>): Danh sách UID người tham gia
- `lastMessage` (String): Nội dung tin nhắn cuối cùng để hiển thị ở danh sách chat
- `lastMessageTime` (Timestamp): Thời gian tin nhắn cuối
- `lastSenderId` (String): Người gửi tin nhắn cuối (để in đậm nếu chưa đọc)

### Messages Sub-collection (`chats/{chatId}/messages`) (hoặc top-level `messages`)
Lưu trữ nội dung tin nhắn.
- `senderId` (String): Người gửi
- `text` (String): Nội dung
- `timestamp` (Timestamp): Thời gian gửi
- `type` (String): Loại tin nhắn (text, image, vv)

## 2. Các Bước Thực Hiện

### Bước 1: Authentication (Đăng nhập/Đăng ký)
- **Công nghệ**: `firebase_auth`
- **Màn hình**: Login, Register.
- **Logic**: 
    - Đăng ký bằng Email/Password.
    - Sau khi đăng ký thành công, tạo một document mới trong collection `users` với thông tin cơ bản.

### Bước 2: Profile Cá Nhân
- **Công nghệ**: `cloud_firestore`, `firebase_storage` (cho avatar), `image_picker`.
- **Chức năng**:
    - Hiển thị thông tin user hiện tại.
    - Cho phép edit `displayName`, `dob`.
    - Upload avatar lên Firebase Storage -> lấy URL -> update vào Firestore `photoUrl`.

### Bước 3: Tìm Kiếm & Kết Bạn
- **Công nghệ**: `cloud_firestore`.
- **Chức năng**:
    - Tìm kiếm user theo `email` hoặc `displayName` (lưu ý Firestore search text cần giải pháp như Algolia hoặc search đơn giản `IsEqualTo`/`array-contains`).
    - Nút "Kết bạn": Thêm UID của đối phương vào mảng `friends` của mình và ngược lại (hoặc dùng sub-collection `friend_requests` nếu muốn có bước xác nhận).
    - Ở đây để đơn giản: Tìm thấy -> Chat ngay (như Messenger người lạ) hoặc Add friend để lưu vào danh bạ.

### Bước 4: Danh Sách Bạn Bè & Chat
- **Màn hình Home**: Hiển thị danh sách các cuộc hội thoại (`chats` collection) có chứa `uid` của mình.
- **Màn hình Danh bạ**: Hiển thị list user từ mảng `friends`.

### Bước 5: Màn Hình Chat (Nhắn tin)
- **Công nghệ**: `cloud_firestore` (realtime updates với `snapshots`).
- **Chức năng**:
    - Gửi tin nhắn: Add document vào `chats/{chatId}/messages`. Đồng thời update `lastMessage` & `lastMessageTime` ở `chats/{chatId}`.
    - Nhận tin nhắn: Lắng nghe `snapshots` từ collection messages, hiển thị lên `ListView` (đảo ngược chiều).

## 3. Các Package Cần Thiết (pubspec.yaml)
Bổ sung các thư viện sau nếu chưa có:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest_version
  firebase_auth: latest_version
  cloud_firestore: latest_version
  firebase_storage: latest_version
  image_picker: latest_version # Để chọn ảnh avatar
  intl: latest_version # Để format ngày tháng
  cached_network_image: latest_version # Hiển thị ảnh avatar mượt mà hơn
```

## 4. Gợi Ý File Structure
```
lib/
  ├── models/          # User, Message models
  ├── services/        # AuthService, FirestoreService, StorageService
  ├── pages/
  │   ├── login_page.dart
  │   ├── register_page.dart
  │   ├── home_page.dart (Tab bar: Chats, Friends, Profile)
  │   ├── chat_page.dart
  │   ├── profile_page.dart
  │   └── search_page.dart
  ├── widgets/         # MessageBubble, UserTile, etc.
  └── main.dart
```

## 5. Các Tính Năng Đã Thực Hiện (Tiến độ dự án hiện tại)
2. **Cải thiện UI/UX Tìm kiếm và Kết bạn**:
   - Tách tính năng "Tìm kiếm người dùng" và danh sách "Yêu cầu kết bạn" từ cùng một màn hình (`search_page.dart`) ra thành hai trang độc lập.
   - Tạo trang `friend_request_page.dart` chuyên quản lý việc chấp nhận/từ chối lời mời.
   - Thêm biểu tượng thông báo (Quả chuông có đếm số lượng lời mời) ngay trên thanh AppBar của `home_page.dart` để trải nghiệm người dùng tự nhiên hơn giống các mạng xã hội.

3. **Chuyển đổi State Management sang Provider (Tái cấu trúc)**:
   - Thay thế việc gọi trực tiếp `AuthService` và dùng `setState` bằng kiến trúc `ChangeNotifierProvider`.
   - Đã tạo `AuthProvider` để quản lý toàn bộ luồng xử lý Firebase Authentication (Đăng nhập, Đăng ký, Đăng xuất) và lưu trữ trạng thái `User?`.
   - Gọi `MultiProvider` ở cấp cao nhất trong `main.dart` để truyền State xuyên suốt ứng dụng.
4. **Tính năng Gửi Hình Ảnh (Image Picker + Storage)**:
   - Tích hợp `image_picker` cho phép người dùng chọn ảnh từ thư viện (`Gallery`).
   - Sử dụng `firebase_storage` tạo hàm `sendImage` trong `ChatService` để upload ảnh lên Cloud.
   - Thay đổi cấu trúc Model `Message` để hỗ trợ định dạng `type` (text/image).
   - Tối ưu hóa UI `ChatBubble` bằng nút gửi ảnh và dùng `Image.network` để tự thiết kế biểu đồ bong bóng hình ảnh. Cập nhật giao diện Chat mượt mà với hiệu ứng xoay (Loading Indicator) khi ảnh đang được tải lên.

## 6. Lên ý tưởng Gửi Thông Báo Push Notification (FCM)

Để thông báo cho người dùng khi có tin nhắn mới (ngay cả khi ứng dụng bị tắt), dự án cần tích hợp **Firebase Cloud Messaging (FCM)** và **Firebase Cloud Functions**.

### Quy trình 4 bước triển khai Push Notification:

#### Bước 1: Thu thập & Lưu trữ Device Token
- **Hành động:** Sử dụng package `firebase_messaging` để xin quyền thông báo từ người dùng.
- **Lưu trữ:** Lấy FCM Token (mã định danh thiết bị duy nhất) và lưu vào document của người dùng tương ứng trên collection `users` trong Firestore (Ví dụ: thêm field `fcmToken: "dxx_abc123..."`).

#### Bước 2: Yêu cầu quyền gửi thông báo (Quan trọng cho iOS & Android 13+)
- Phải hiển thị pop-up xin phép `ChatApp muốn gửi thông báo cho bạn`. Nếu người dùng từ chối, token sẽ không có tác dụng.

#### Bước 3: Đẩy thông báo từ Backend (Cloud Functions)
- **Vấn đề bảo mật:** Việc gửi Push Notification trực tiếp từ phía thiết bị người gửi (Client) là không an toàn.
- **Giải pháp:** Viết một đoạn mã Node.js tải lên Firebase Cloud Functions. Hàm này sẽ liên tục theo dõi sub-collection `messages`. Đoạn code hoạt động như sau:
  1. Khi có document tin nhắn mới, hàm sẽ đọc thông tin người nhận (`receiverID`).
  2. Truy vấn vào collection `users` lấy `fcmToken` của người nhận.
  3. Gửi payload (Token + Nội dung tin nhắn) tới máy chủ FCM để đẩy thông báo xuống thiết bị nhận.

#### Bước 4: Xử lý thông báo phía Ứng Dụng (Flutter)
- **App chạy nền/Bị tắt (Background/Terminated):** OS tự động hiển thị pop-up. Cần viết code lắng nghe sự kiện khi người dùng "chạm" vào thông báo để mở trực tiếp trang `chat_page.dart` của người gửi.
- **App đang mở (Foreground):** FCM sẽ không tự hiện thông báo. Cần kết hợp sử dụng plugin `flutter_local_notifications` để tự tay render giao diện pop-up thông báo hiển thị từ cạnh trên màn hình.

---
## 7. Lịch Sử Thay Đổi (Changelog)

Theo dõi các bản cập nhật và cải tiến của dự án:

*   **[22/02/2026] Khởi tạo & Việt hóa:**
    *   Setup cấu trúc ứng dụng cơ bản.
    *   Dịch toàn bộ comments mã nguồn từ tiếng Anh sang tiếng Việt để dễ bảo trì (`chat_page`, `search_page`, `friend_service`...).
*   **[23/02/2026] Tái cấu trúc UI/UX & Tính năng mới:**
    *   **Tách trang:** Tách riêng tính năng "Bạn bè & Lời mời" ra khỏi `search_page` thành `friend_request_page.dart`.
    *   **Thông báo:** Thêm biểu tượng chuông thông báo (kèm số lượng lời mời) trên AppBar của trang chủ.
    *   **State Management:** Chuyển đổi kiến trúc sang dùng thư viện `Provider`. Đã refactor thành công Auth feature (Tạo `AuthProvider` thay thế `AuthService`) cho các trang Login/Register.
    *   **Gửi hình ảnh:** Tích hợp thành công chức năng gửi ảnh trong phòng chat sử dụng `image_picker`, upload lên `firebase_storage` và hiển thị bằng `cached_network_image`.

Chúc bạn phát triển ứng dụng thành công! Nếu cần code mẫu cho phần nào, hãy yêu cầu tôi nhé.
