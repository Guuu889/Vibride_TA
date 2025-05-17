import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileChangePasswordPage extends StatefulWidget {
  @override
  _ProfileChangePasswordPageState createState() => _ProfileChangePasswordPageState();
}

class _ProfileChangePasswordPageState extends State<ProfileChangePasswordPage> {
  final _auth = FirebaseAuth.instance;

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController(); // Untuk forgot password

  Future<void> _resetPassword() async {
    try {
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Masukkan email untuk reset password!')),
        );
        return;
      }

      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email reset password telah dikirim! Periksa inbox Anda.')),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah mengirim email
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim email reset: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0E1756), // Warna biru tua
      body: Column(
        children: [
          // Header dengan tombol back dan simpan
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            color: Color(0xFF0E1756),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),
                // Tombol Simpan (Untuk reset password)
                TextButton(
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "SIMPAN",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Container putih dengan sudut melengkung di atas
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView( // Ditambahkan untuk scrollable content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Ganti Password",
                        style: TextStyle(
                          fontFamily: 'Aileron',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Input Email untuk Forgot Password
                    _buildTextField(
                      label: "MASUKKAN EMAIL",
                      controller: _emailController,
                    ),
                    SizedBox(height: 16),

                    // Masukkan Password Sebelumnya (Opsional, bisa dihapus jika tidak diperlukan)
                    _buildPasswordField(
                      label: "MASUKKAN PASSWORD SEBELUMNYA",
                      controller: _oldPasswordController,
                      isPassword: true,
                    ),
                    SizedBox(height: 16),

                    // Masukkan Password Baru
                    _buildPasswordField(
                      label: "MASUKAN PASSWORD BARU",
                      controller: _newPasswordController,
                      isPassword: true,
                      isVisible: _isNewPasswordVisible,
                      onTap: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Konfirmasi Password Baru
                    _buildPasswordField(
                      label: "KONFIRMASI PASSWORD BARU",
                      controller: _confirmPasswordController,
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onTap: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar di Bawah (Komentar dilepas jika ingin digunakan)
          // Container(
          //   color: Color(0xFF0E1756),
          //   padding: EdgeInsets.symmetric(vertical: 10),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround,
          //     children: [
          //       IconButton(
          //         icon: Icon(Icons.headset_mic, color: Colors.white),
          //         onPressed: () {},
          //       ),
          //       IconButton(
          //         icon: Icon(Icons.place, color: Colors.white),
          //         onPressed: () {},
          //       ),
          //       Container(
          //         decoration: BoxDecoration(
          //           color: Colors.lightBlue.shade200,
          //           shape: BoxShape.circle,
          //         ),
          //         child: IconButton(
          //           icon: Icon(Icons.person, color: Colors.black),
          //           onPressed: () {},
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          decoration: InputDecoration(
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: onTap,
                  )
                : null,
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }
}