import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import '../home/homepage.dart';
import 'forget_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isStudentMail = RegExp(r'^[^@]+@[^@]+\.edu\.tr$').hasMatch(email);
    if (!isStudentMail) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir öğrenci e-posta adresi (.edu.tr) ile giriş yapınız.';
        _isLoading = false;
      });
      return;
    }
    // Check if email exists in users collection
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Böyle bir kullanıcı bulunmuyor.';
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After sign-in, ensure email is verified AND Firestore isVerified is true
      if (credential.user != null) {
        await credential.user!.reload();
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw FirebaseAuthException(code: 'user-not-found', message: 'Kullanıcı bulunamadı');
        }

        // get firestore doc
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final firestoreVerified = doc.exists && (doc.data()?['isVerified'] == true);

        if (!user.emailVerified || !firestoreVerified) {
          // if auth says verified but firestore false, sync it
          if (user.emailVerified && !firestoreVerified) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'isVerified': true}, SetOptions(merge: true));
          } else {
            // not verified yet - sign out and show message
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                _errorMessage = 'Hesabınızı aktif ediniz, şu anda pasif durumdadır.';
                _isLoading = false;
              });
            }
            return;
          }
        }

        if (mounted) {
          debugPrint('Login successful: ${credential.user!.email}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          errorMessage = 'Şifreniz yanlış. Lütfen tekrar deneyin.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi.';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email veya şifre yanlış.';
          break;
        default:
          errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.message}';
      }
      
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              bottom: MediaQuery.of(context).size.height * 0.25,
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
                height: MediaQuery.of(context).size.height * 0.75,
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
                        'Giriş Yap',
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
                      
                      // Remember me and Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                  border: Border.all(
                                    color: _rememberMe ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB)),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: _rememberMe
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Beni Hatırla',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgetPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Şifreni mi Unuttun?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Error message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),
                      
                      // Login button
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
                            onTap: _isLoading ? null : () {
                              if (_emailController.text.trim().isEmpty || 
                                  _passwordController.text.trim().isEmpty) {
                                setState(() {
                                  _errorMessage = 'Lütfen email ve şifre alanlarını doldurun.';
                                });
                                return;
                              }
                              _signInWithEmailAndPassword();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                      : const Text(
                                          'Giriş Yap',
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
                      
                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Hesabınız yok mu? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Kayıt Ol',
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
