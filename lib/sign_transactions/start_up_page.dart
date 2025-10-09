import 'package:flutter/material.dart';
import 'login_page.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              bottom: MediaQuery.of(context).size.height * 0.45,
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
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Hoş Geldiniz',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'UniHub\'a hoş geldiniz. Üniversite hayatınızı kolaylaştıracağız.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    // Continue button with arrow image
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => const LoginPage(),
                                 ),
                               );
                             },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Devam Et',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    'assets/images/arrow.png',
                                    width: 18,
                                    height: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
