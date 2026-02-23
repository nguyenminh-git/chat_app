import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileEditPage({super.key, required this.userData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  DateTime? _selectedDate;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu cũ vào Controller
    _nameController = TextEditingController(text: widget.userData['displayName']);
    if (widget.userData['dob'] != null) {
      _selectedDate = (widget.userData['dob'] as Timestamp).toDate();
    }
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  // Hàm lưu thông tin
  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      // 1. Nếu có chọn ảnh mới, bạn cần code thêm phần upload lên Firebase Storage tại đây
      // Hiện tại chúng ta tạm để imageUrl = null nếu không đổi
      
      // 2. Gọi hàm update trong Service
      await AuthService().updateUserProfile(
        displayName: _nameController.text.trim(),
        dob: _selectedDate,
        photoUrl: imageUrl, 
      );

      if (mounted) {
        Navigator.pop(context); // Quay lại trang trước sau khi lưu
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chỉnh sửa hồ sơ")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Chọn ảnh đại diện
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (widget.userData['photoUrl'] != "" ? NetworkImage(widget.userData['photoUrl']) : null) as ImageProvider?,
                    child: (_imageFile == null && widget.userData['photoUrl'] == "") 
                        ? const Icon(Icons.camera_alt, size: 40) : null,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Tên hiển thị", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(_selectedDate == null ? "Chọn ngày sinh" : "Ngày sinh: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("LƯU THAY ĐỔI"),
                )
              ],
            ),
          ),
    );
  }
}