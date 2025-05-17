import 'package:flutter/material.dart';

class ProfileUSMPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0E1756), // Warna latar belakang biru gelap
      body: Stack(
        children: [
          // Tombol back di pojok kiri atas
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Color(0xFF0E1756)),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.87,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Manual Pengguna',
                          style: TextStyle(
                            fontFamily: 'Aileron',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      sectionTitle(context, "PENDAHULUAN"),
                      sectionText(
                        context,
                        "Aplikasi ini dirancang untuk membantu pengemudi ojek online tunarungu "
                        "dalam navigasi menggunakan sistem getaran di telinga.",
                      ),
                      SizedBox(height: 20),
                      sectionTitle(context, "INSTALASI & OPERASIONAL"),
                      sectionBulletText(
                        context,
                        "• Hidupkan Wi-Fi dan hubungkan ponsel dengan headset vibrasi.",
                      ),
                      sectionBulletText(
                        context,
                        "• Pastikan GPS sudah menyala sebelum menjalankan aplikasi.",
                      ),
                      sectionSubBulletText(
                        context,
                        "Apabila aplikasi tidak berjalan, pastikan perizinan akses lokasi "
                        "pada navigasi di pengaturan ponsel sudah menyala.",
                      ),
                      SizedBox(height: 20),
                      sectionTitle(context, "NOTIFIKASI HEADSET VIBRASI"),
                      sectionText(
                        context,
                        "Navigasi dalam aplikasi ini bekerja dengan sistem geofencing.",
                      ),
                      SizedBox(height: 10),
                      sectionImage('assets/navigate.png'),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: MediaQuery.of(context).size.width * 0.04,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 171, 171, 171),
      ),
    );
  }

  Widget sectionText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: MediaQuery.of(context).size.width * 0.04,
        color: Colors.black87,
      ),
    );
  }

  Widget sectionBulletText(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ",
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: Colors.black87)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget sectionSubBulletText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("◦ ",
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: Colors.black87)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionImage(String assetPath) {
    return Center(
      child: Image.asset(
        assetPath,
        width: double.infinity, // Sesuaikan dengan lebar layar
        height: 450, // Sesuaikan tinggi agar proporsional
        fit: BoxFit.contain, // Jaga agar gambar tidak terpotong
      ),
    );
  }
}
