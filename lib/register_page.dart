import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
  _emailController.dispose();
  _nameController.dispose();
  _surnameController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background image - sadece üst kısımda
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height * 0.2,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Main content with curved bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        margin: const EdgeInsets.only(top: 8),
                      ),
                      const SizedBox(height: 40),
                      

                      // Name field
                      Text(
                        'Ad',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Adınızı giriniz',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.name,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Surname field
                      Text(
                        'Soyad',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _surnameController,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Soyadınızı giriniz',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.name,
                        ),
                      ),
                      const SizedBox(height: 24),
                                            // Email field
                      Text(
                        'E-posta',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'ogrenci@universite.edu.tr',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Password field
                      Text(
                        'Şifre',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Şifrenizi giriniz',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Confirm Password field
                      Text(
                        'Şifre Tekrarı',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Şifrenizi tekrar giriniz',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),
                      
                      // Create Account button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                // Email ile hesap oluşturma ve doğrulama linki gönderme
                                final email = _emailController.text.trim();
                                final name = _nameController.text.trim();
                                final surname = _surnameController.text.trim();
                                final isStudentMail = RegExp(r'^[^@]+@[^@]+\.edu\.tr$').hasMatch(email);
                                if (email.isEmpty || name.isEmpty || surname.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                                  );
                                  return;
                                }
                                if (!isStudentMail) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lütfen geçerli bir öğrenci e-posta adresi (.edu.tr) giriniz.')),
                                  );
                                  return;
                                }
                                final password = _passwordController.text.trim();
                                final confirm = _confirmPasswordController.text.trim();
                                if (password.isEmpty || confirm.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lütfen şifre alanlarını doldurun.')),
                                  );
                                  return;
                                }
                                if (password != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Şifreler eşleşmiyor.')),
                                  );
                                  return;
                                }
                                try {
                                  // Firebase Auth: kullanıcı oluşturma
                                  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                  // Firestore
                                  await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
                                    'email': email,
                                    'firstName': name,
                                    'lastName': surname,
                                    'profileImageUrl': null,
                                    'university': null,
                                    'department': null,
                                    'class': null,
                                    'bio': '',
                                    'joinedRooms': [],
                                    'isVerified': false,
                                  });
                                  // Email doğrulama linki gönder
                                  await credential.user!.sendEmailVerification();
                                  // Oturumu kapat, kullanıcı doğrulama yapmadan erişmemeli
                                  await FirebaseAuth.instance.signOut();
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Hesabınızı aktifleştirmek için e-posta adresinize gelen linke tıklayın.')),
                                  );
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  }
                                } catch (e) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Kayıt sırasında hata oluştu: $e')),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Hesap Oluştur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Login link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Zaten hesabınız var mı? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                debugPrint('login_page: Login link tapped');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),   
                      // Home indicator
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
