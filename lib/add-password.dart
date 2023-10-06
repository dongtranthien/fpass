import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './models/token.dart';
import 'login_page.dart';
import 'card.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class AddPasswordPage extends StatefulWidget {
  const AddPasswordPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  _AddPasswordPageState createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _canAdd = false;

  void _checkCanAdd() {
    setState(() {
      _canAdd = _applicationController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _applicationController.addListener(_checkCanAdd);
    _usernameController.addListener(_checkCanAdd);
    _passwordController.addListener(_checkCanAdd);
  }

  @override
  void dispose() {
    _applicationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addToFirestore() async {
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      // Lấy giá trị từ các trường nhập liệu
      String application = _applicationController.text;
      String username = _usernameController.text;
      String password = _passwordController.text;

      // Kiểm tra xem các trường có dữ liệu hay không
      if (application.isNotEmpty &&
          username.isNotEmpty &&
          password.isNotEmpty) {
        var documentRef = FirebaseFirestore.instance
            .collection('fpassToken')
            .doc(widget.token);

        final key = encrypt.Key.fromUtf8('my 32 length key................');
        final iv = encrypt.IV.fromUtf8('1234567890123456');
        final encrypter =
            encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

        final dataUpdateEncrypt = {
          'n': encrypter.encrypt(application, iv: iv).base64,
          'u': encrypter.encrypt(username, iv: iv).base64,
          'p': encrypter.encrypt(password, iv: iv).base64,
          'm': iv.base64
        };
        print('dataUpdateEncrypt');
        print(dataUpdateEncrypt);
        var resultUpdate = await documentRef.update({
          "pass": FieldValue.arrayUnion([dataUpdateEncrypt])
        });
        //await FirebaseFirestore.instance.collection('fpassToken').add({
        //  'application': application,
        //  'username': username,
        //  'password': password,
        //});

        // Sau khi thêm dữ liệu thành công, làm sạch các trường nhập liệu
        _applicationController.clear();
        _usernameController.clear();
        _passwordController.clear();

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dữ liệu đã được thêm vào Firestore.'),
          ),
        );

        final dataResponse = {
          'n': application,
          'u': username,
          'p': password,
        };
        Map<String, String> result = dataResponse;

        Navigator.pop<Map<String, String>>(context, result);
      } else {
        // Hiển thị thông báo nếu một trong các trường nhập liệu còn trống
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin.'),
          ),
        );
      }
    } catch (error) {
      // Xử lý lỗi nếu có
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adding Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextFormField(
                            controller: _applicationController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Username/Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: _canAdd ? _addToFirestore : null,
                            child: Text(
                              'Add...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.deepPurpleAccent,
                              onPrimary: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
