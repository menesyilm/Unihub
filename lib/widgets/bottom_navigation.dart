import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../friends/friends_page.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  String? _avatarUrl;                // cache’lenen URL
  ImageProvider? _avatarProvider;    // cache’lenen ImageProvider

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _startAvatarListener();
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // hiçbir şey; BottomNavigation yeniden build olsa bile _avatarProvider cache’te
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startAvatarListener() {
    if (_uid == null || _uid!.isEmpty) return;
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      String? url;
      if (data['profileImages'] is List && (data['profileImages'] as List).isNotEmpty) {
        url = (data['profileImages'] as List).first as String?;
      } else if (data['profileImageUrl'] is String) {
        url = data['profileImageUrl'] as String?;
      }

      if (url != null && url.isNotEmpty && url != _avatarUrl) {
        // Yeni görseli önbelleğe al, sonra state’i güncelle
        final provider = NetworkImage(url);
        // context hazır olduğunda önceden yükle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          precacheImage(provider, context);
        });
        setState(() {
          _avatarUrl = url;
          _avatarProvider = provider;
        });
      } else if ((url == null || url.isEmpty) && _avatarUrl != null) {
        // Görsel kaldırılmışsa fallback’e dön
        setState(() {
          _avatarUrl = null;
          _avatarProvider = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        // Yazıları tamamen gizle
        showSelectedLabels: false,
        showUnselectedLabels: false,
        // const kaldırıldı çünkü dinamik ikon kullanıyoruz
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Arkadaşlar',
          ),
          BottomNavigationBarItem(
            icon: _AvatarIcon(provider: _avatarProvider, isActive: false, size: 26),
            activeIcon: _AvatarIcon(provider: _avatarProvider, isActive: true, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  List<Widget> get _pages {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return [
      const HomeContent(),
      const FriendsPage(),
      ProfilePage(userId: userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// Sadece cache’lenmiş ImageProvider ile çalışan, Firestore’a bağlanmayan ikon
class _AvatarIcon extends StatelessWidget {
  final ImageProvider? provider;
  final bool isActive;
  final double size;

  const _AvatarIcon({
    required this.provider,
    required this.isActive,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? const Color(0xFF2563EB) : Colors.grey.shade300;
    final borderColor = isActive ? Colors.white : Colors.transparent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: isActive ? 2 : 0),
      ),
      child: ClipOval(
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: bgColor,
          backgroundImage: provider, // varsa direkt bu kullanılıyor (flicker yok)
          // provider yoksa fallback ikon
          child: provider == null
              ? Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: isActive ? Colors.white : const Color(0xFF2563EB),
                )
              : null,
        ),
      ),
    );
  }
}
