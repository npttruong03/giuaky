import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreennState();
}

class _HomeScreennState extends State<HomeScreen> {
  final TextEditingController _tensp = TextEditingController();
  final TextEditingController _loaisp = TextEditingController();
  final TextEditingController _giasp = TextEditingController();
  File? _selectedImage; // Thêm biến để lưu trữ ảnh đã chọn
  String? downloadUrl;

  CollectionReference _sanpham = FirebaseFirestore.instance.collection("sanpham");

  void _deletesanpham(String sanphamId, String imageUrl) async {
  // Xóa sản phẩm từ Firestore
  await _sanpham.doc(sanphamId).delete();

  // Nếu sản phẩm có ảnh, xóa ảnh khỏi Firebase Storage
  if (imageUrl.isNotEmpty) {
    Reference photoRef = FirebaseStorage.instance.refFromURL(imageUrl);
    await photoRef.delete();
  }
}


  void _editsanpham(DocumentSnapshot sanpham) {
    _tensp.text = sanpham['tensp'];
    _loaisp.text = sanpham['loaisp'];
    _giasp.text = sanpham['gia'];
    downloadUrl = sanpham['image_url'];

    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: Text('Edit sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tensp,
              decoration: InputDecoration(labelText: "Tên Sản phẩm"),
            ),
            SizedBox(height: 8,),
            TextFormField(
              controller: _loaisp,
              decoration: InputDecoration(labelText: "loại Sản phẩm"),
            ),
            SizedBox(height: 8,),
            TextFormField(
              controller: _giasp,
              decoration: InputDecoration(labelText: "giá Sản phẩm"),
            ),
            SizedBox(height: 8,),
            IconButton(
              onPressed: _pickAndUploadImage, // Cho phép người dùng chọn ảnh mới
              icon: const Icon(Icons.camera_alt),
            ),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 150, width: 150)
                : Image.network(downloadUrl!, height: 150, width: 150), // Hiển thị ảnh cũ nếu không có ảnh mới
          ],
        ),
        actions: [
          TextButton(onPressed: (){
            Navigator.pop(context);
        }, child: Text("hủy")),
        ElevatedButton(
          onPressed: (){
          _updatesanpham(sanpham.id);
          Navigator.pop(context);
        }, child: Text("Cập nhật")),
        ],
      );
    });

  }

  void _updatesanpham(String sanphamId) async {
  // Nếu không chọn ảnh mới, giữ URL cũ
  if (_selectedImage == null) {
    await _sanpham.doc(sanphamId).update({
      'tensp': _tensp.text,
      'loaisp': _loaisp.text,
      'gia': _giasp.text,
      'image_url': downloadUrl, // Giữ lại URL ảnh cũ nếu không chọn ảnh mới
    });
  } else {
    // Nếu chọn ảnh mới, upload ảnh mới và cập nhật URL
    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('images/$fileName');
    UploadTask uploadTask = ref.putFile(_selectedImage!);

    TaskSnapshot snapshot = await uploadTask;
    String newImageUrl = await snapshot.ref.getDownloadURL();

    // Cập nhật sản phẩm với URL ảnh mới
    await _sanpham.doc(sanphamId).update({
      'tensp': _tensp.text,
      'loaisp': _loaisp.text,
      'gia': _giasp.text,
      'image_url': newImageUrl, // Cập nhật URL ảnh mới
    });

    // Sau khi cập nhật, xoá ảnh cũ nếu cần (tuỳ chọn)
  }

  _tensp.clear();
  _loaisp.clear();
  _giasp.clear();
  setState(() {
    _selectedImage = null;
    downloadUrl = null;
  });
}

  // Hàm thêm sản phẩm
  void _addsanpham() async {
    if (downloadUrl == null) {
      // Kiểm tra nếu ảnh chưa được tải lên
      print("Vui lòng chọn và tải ảnh trước khi thêm sản phẩm.");
      return;
    }

    await _sanpham.add({
      'tensp': _tensp.text,
      'loaisp': _loaisp.text,
      'gia': _giasp.text,
      'image_url': downloadUrl, // Lưu đường dẫn ảnh vào Firestore
    });

    // Xóa dữ liệu sau khi thêm thành công
    _tensp.clear();
    _loaisp.clear();
    _giasp.clear();
    setState(() {
      _selectedImage = null;
      downloadUrl = null;
    });
  }

  // Hàm chọn và tải ảnh lên Firebase Storage
  Future<void> _pickAndUploadImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _selectedImage = File(file.path); // Lưu ảnh đã chọn vào biến
    });

    // Tải ảnh lên Firebase Storage
    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('images/$fileName');
    UploadTask uploadTask = ref.putFile(_selectedImage!);

    // Đợi quá trình upload hoàn tất và lấy URL
    TaskSnapshot snapshot = await uploadTask;
    downloadUrl = await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crud app"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _tensp,
              decoration: InputDecoration(labelText: "Nhập tên sản phẩm"),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _loaisp,
              decoration: InputDecoration(labelText: "Nhập loại sản phẩm"),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _giasp,
              decoration: InputDecoration(labelText: "Nhập giá sản phẩm"),
            ),
            SizedBox(height: 16),
            Center(
              child: IconButton(
                onPressed: _pickAndUploadImage, // Chọn và tải ảnh lên
                icon: const Icon(Icons.camera_alt),
              ),
            ),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 150, width: 150) // Hiển thị ảnh đã chọn
                : Container(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addsanpham, // Gọi hàm thêm sản phẩm
              child: Text("Add Sản Phẩm"),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: _sanpham.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length ?? 0,
                    itemBuilder: (context, index) {
                      var sanpham = snapshot.data!.docs[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                        leading: sanpham['image_url'] != null
                            ? Image.network(
                                sanpham['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.image_not_supported),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sanpham['tensp'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              sanpham['loaisp'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${sanpham['gia']} VND',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Đảm bảo không chiếm hết chiều ngang
                        children: [
                          IconButton(
                            iconSize: 20, // Kích thước icon nhỏ hơn
                            onPressed: () {
                              // Thêm logic chỉnh sửa tại đây
                              _editsanpham(sanpham);
                            },
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(
                            iconSize: 20,
                            onPressed: () {
                              // Xác nhận trước khi xóa
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Xóa sản phẩm"),
                                    content: Text("Bạn có chắc muốn xóa sản phẩm này không?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Đóng hộp thoại mà không làm gì
                                        },
                                        child: Text("Hủy"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deletesanpham(sanpham.id, sanpham['image_url']); // Gọi hàm xóa sản phẩm
                                          Navigator.pop(context); // Đóng hộp thoại sau khi xóa
                                        },
                                        child: Text("Xóa"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.delete),
                          ),

                        ],
                      ),
                      ),

                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
