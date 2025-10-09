import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/bottom_navigation.dart';
import 'services/chat_service.dart';
import 'pages/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationWrapper();
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  Future<void> _navigateToChat(BuildContext context, String activity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;
    final university = doc.data()?[ 'university' ] as String?;
    if (university == null || university.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce profilinizden üniversitenizi seçin.')),
        );
      }
      return;
    }

    final roomId = await ChatService.instance.getOrCreateRoom(
      university: university,
      activity: activity,
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            roomId: roomId,
            activity: activity,
            titleSuffix: university,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          title: const Text('UniHub'),
          centerTitle: true,
          automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoş Geldiniz!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Merhaba ${user?.email ?? 'Kullanıcı'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Firebase Authentication başarılı!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sosyalleşme Aktiviteleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Quick access cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.menu_book,
                          title: 'Kitap Okuma',
                          subtitle: 'Kitap okuma arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Kitap Okuma'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.school,
                          title: 'Ders Çalışma',
                          subtitle: 'Ders çalışma arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Ders Çalışma'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.movie,
                          title: 'Sinema',
                          subtitle: 'Film izleme arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Sinema'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.local_cafe,
                          title: 'Kahve',
                          subtitle: 'Kahve içme arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Kahve'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.restaurant,
                          title: 'Yemek',
                          subtitle: 'Yemek yeme arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Yemek'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.fitness_center,
                          title: 'Spor',
                          subtitle: 'Spor yapma arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Spor'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          
                          context: context,
                          icon: Icons.sports_esports,
                          title: 'Oyun',
                          subtitle: 'Oyun oynama arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Oyun'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildQuickAccessCard(
                          context: context,
                          icon: Icons.directions_walk,
                          title: 'Yürüyüş',
                          subtitle: 'Yürüyüş arkadaşı bul',
                          onTap: () => _navigateToChat(context, 'Yürüyüş'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Recent activity
                  Text(
                    'Son Aktiviteler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          context: context,
                          icon: Icons.login,
                          title: 'Giriş yapıldı',
                          subtitle: 'Hesabınıza başarıyla giriş yaptınız',
                          time: 'Az önce',
                        ),
                        const SizedBox(height: 15),
                        _buildActivityItem(
                          context: context,
                          icon: Icons.person_add,
                          title: 'Hesap oluşturuldu',
                          subtitle: 'UniHub hesabınız oluşturuldu',
                          time: 'Bugün',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}