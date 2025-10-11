import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings/settings.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<String> profileImages = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
      try {
      debugPrint('ProfileInformation: Loading user data for userId: ${widget.userId}');
        final doc = await FirebaseFirestore.instance
            .collection('users')
          .doc(widget.userId)
            .get();

        if (mounted) {
        final data = doc.data();
        
        // Load profile images
        if (data?['profileImages'] != null && data!['profileImages'] is List) {
          profileImages = List<String>.from(data['profileImages']);
        } else if (data?['profileImageUrl'] != null) {
          // Backward compatibility
          profileImages = [data!['profileImageUrl']];
        }
        
        debugPrint('ProfileInformation: Loaded ${profileImages.length} profile images');
        
          setState(() {
          userData = data;
            isLoading = false;
          });
        }
      } catch (e) {
      debugPrint('ProfileInformation: Error loading user data: $e');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
    }
  }

  bool _isEmailVerified(String? email) {
    if (email == null) return false;
    return email.endsWith('.edu.tr') || email.endsWith('.edu');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isViewingOwnProfile = currentUserId == widget.userId;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
        ),
        body: const Center(
          child: Text('Kullanıcı bilgileri yüklenemedi'),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with cover image and profile photo only
              Stack(
                children: [
                  // Cover Image
              Container(
                width: double.infinity,
                    height: 200,
                    decoration: userData!['coverImageUrl'] != null
                    ? BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(userData!['coverImageUrl']),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                      ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                  // Profile Photo PageView positioned at the bottom center
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (profileImages.isNotEmpty) {
                            _showFullScreenImages(context);
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                              width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                          child: Stack(
                            children: [
                              ClipOval(
                                child: profileImages.isNotEmpty
                                    ? Image.network(
                                        profileImages[0],
                                        width: 100,
                                        height: 100,
                                          fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const FaIcon(
                                            FontAwesomeIcons.user,
                                            size: 50,
                                                  color: Color(0xFF2563EB),
                                                );
                                              },
                                      )
                                    : const FaIcon(
                                        FontAwesomeIcons.user,
                                        size: 50,
                                        color: Color(0xFF2563EB),
                                      ),
                              ),
                              // Image count indicator
                              if (profileImages.length > 1)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                        const FaIcon(FontAwesomeIcons.images, size: 10, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${profileImages.length}',
                                          style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ),
                  // Back button (only for other users' profiles)
                  if (!isViewingOwnProfile)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.arrowLeft,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  // Settings menu button (only for own profile)
                  if (isViewingOwnProfile)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.bars,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;

                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  var offsetAnimation = animation.drive(tween);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                                            ),
                                          ),
                                        ],
              ),

              const SizedBox(height: 60),

              // User Information Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    // Name and verification badge
                            Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                          '${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}'
                              .trim(),
                                  style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                        
                              ],
                            ),
                            const SizedBox(height: 15),
                    
                    // Email
                    if (userData!['email'] != null)
                      _buildInfoRow(
                        FontAwesomeIcons.envelope,
                        userData!['email'],
                        isDark,
                      ),
                    // Birth Date, Age and Zodiac
                    if (userData!['birthDate'] != null)
                      _buildInfoRow(
                        FontAwesomeIcons.cakeCandles,
                        _getBirthDateInfo(),
                        isDark,
                      ),
                    // University
                    if (userData!['university'] != null)
                      _buildInfoRow(
                        FontAwesomeIcons.graduationCap,
                        userData!['university'],
                        isDark,
                      ),
                    // Department and Class
                    if (userData!['department'] != null || userData!['class'] != null)
                      _buildInfoRow(
                        FontAwesomeIcons.book,
                                              '${userData!['department'] ?? ''} ${userData!['class'] != null ? '- ${userData!['class']}' : ''}'
                                                  .trim(),
                        isDark,
                      ),
                    // Bio
                    if (userData!['bio'] != null &&
                        userData!['bio'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 10),
                                  Text(
                        userData!['bio'],
                                    style: TextStyle(
                                      fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 10),
                      if (_isEmailVerified(userData!['email'])) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                          children: [
                                FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Doğrulanmış',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                                      ),
                                    ],
                        ],
                    
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tabs Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    // TabBar
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
                        indicatorColor: const Color(0xFF2563EB),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(
                            icon: FaIcon(FontAwesomeIcons.shareNodes, size: 18),
                          ),
                          Tab(
                            icon: FaIcon(FontAwesomeIcons.chartLine, size: 18),
                          ),
                          Tab(
                            icon: FaIcon(FontAwesomeIcons.tag, size: 18),
                    ),
                  ],
                ),
              ),
                    // TabBarView
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: _tabController,
                    children: [
                          // Social Media Tab
                          _buildSocialMediaTab(isDark),
                          // Statistics Tab
                          _buildStatisticsTab(isDark),
                          // Interest Tags Tab
                          _buildInterestTagsTab(isDark),
                        ],
                        ),
                      ),
                    ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasSocialMedias() {
    if (userData!['socialMedias'] == null) return false;
    final socialMedias = userData!['socialMedias'] as Map;
    return socialMedias.values
        .any((value) => value != null && value.toString().isNotEmpty);
  }

  Widget _buildSocialMediaTab(bool isDark) {
    final firstName = userData!['firstName'] ?? 'Kullanıcı';
    
    if (!_hasSocialMedias()) {
      return Center(
          child: Padding(
          padding: const EdgeInsets.all(40),
                  child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              FaIcon(
                FontAwesomeIcons.shareNodes,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
                      Text(
                '$firstName herhangi bir sosyal medya hesabı eklemedi.',
                textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14, 
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
              ],
            ),
          ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _buildSocialMediaGridItems(isDark),
      ),
    );
  }

  Widget _buildStatisticsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
            children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Katıldığı Oda',
                  _getJoinedRoomsCount(),
                  FontAwesomeIcons.doorOpen,
                  isDark,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  'Aktif Zaman',
                  _getActiveHours(),
                  FontAwesomeIcons.clock,
                  isDark,
                ),
              ),
            ],
              ),
            ],
          ),
    );
  }

  Widget _buildInterestTagsTab(bool isDark) {
    final firstName = userData!['firstName'] ?? 'Kullanıcı';
    
    if (userData!['interestTags'] == null || 
        (userData!['interestTags'] as List).isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
              FaIcon(
                FontAwesomeIcons.tag,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
                  Text(
                '$firstName herhangi bir ilgi alanı eklemedi.',
                textAlign: TextAlign.center,
                    style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: (userData!['interestTags'] as List)
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildSocialMediaGridItems(bool isDark) {
    final socialMedias = userData!['socialMedias'] as Map;
    final platforms = {
      'instagram': {
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'name': 'Instagram',
      },
      'facebook': {
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'name': 'Facebook',
      },
      'twitter': {
        'icon': FontAwesomeIcons.x,
        'color': const Color(0xFF1DA1F2),
        'name': 'Twitter',
      },
      'telegram': {
        'icon': FontAwesomeIcons.telegram,
        'color': const Color(0xFF0088CC),
        'name': 'Telegram',
      },
      'linkedin': {
        'icon': FontAwesomeIcons.linkedin,
        'color': const Color(0xFF0A66C2),
        'name': 'LinkedIn',
      },
    };

    List<Widget> items = [];

    platforms.forEach((key, value) {
      if (socialMedias[key] != null && socialMedias[key].toString().isNotEmpty) {
        items.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: (value['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (value['color'] as Color).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FaIcon(
                  value['icon'] as IconData,
                  color: value['color'] as Color,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  socialMedias[key],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    });

    return items;
  }

  String _getJoinedRoomsCount() {
    try {
      if (userData!['joinedRooms'] != null) {
        if (userData!['joinedRooms'] is List) {
          return (userData!['joinedRooms'] as List).length.toString();
        }
      }
      return '0';
    } catch (e) {
      debugPrint('ProfileInformation: Error getting joined rooms count: $e');
      return '0';
    }
  }

  String _getActiveHours() {
    try {
      if (userData!['activeHours'] != null) {
        final activeHours = userData!['activeHours'];
        if (activeHours is Map && 
            activeHours['start'] != null && 
            activeHours['end'] != null) {
          return '${activeHours['start']}-${activeHours['end']}';
        }
      }
      return 'Belirsiz';
    } catch (e) {
      debugPrint('ProfileInformation: Error getting active hours: $e');
      return 'Belirsiz';
    }
  }

  String _getBirthDateInfo() {
    try {
      if (userData!['birthDate'] != null) {
        DateTime birthDate;
        if (userData!['birthDate'] is Timestamp) {
          birthDate = (userData!['birthDate'] as Timestamp).toDate();
        } else if (userData!['birthDate'] is String) {
          birthDate = DateTime.parse(userData!['birthDate']);
        } else {
          return 'Doğum tarihi yok';
        }
        
        final age = _calculateAge(birthDate);
        final zodiac = _getZodiacSign(birthDate);
        
        return '$age yaşında • $zodiac';
      }
      return 'Doğum tarihi yok';
    } catch (e) {
      debugPrint('ProfileInformation: Error getting birth date info: $e');
      return 'Doğum tarihi yok';
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return '♈ Koç';
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return '♉ Boğa';
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return '♊ İkizler';
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return '♋ Yengeç';
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return '♌ Aslan';
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return '♍ Başak';
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return '♎ Terazi';
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return '♏ Akrep';
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return '♐ Yay';
    } else if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return '♑ Oğlak';
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return '♒ Kova';
    } else {
      return '♓ Balık';
    }
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
        return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
          FaIcon(
            icon,
            size: 16,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
                Expanded(
            child: Text(
              text,
                        style: TextStyle(
                          fontSize: 14, 
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isDark) {
        return Container(
          padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              width: 1,
                ),
              ),
                child: Column(
                  children: [
              Center(
                child: FaIcon(icon, color: const Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(height: 8),
                    Text(
                value,
                style: const TextStyle(
                        fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                      ),
                    ),
              const SizedBox(height: 4),
                    Text(
                title,
                      style: TextStyle(
                  fontSize: 12, 
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }

  void _showFullScreenImages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
          children: [
              PageView.builder(
                controller: _pageController,
                itemCount: profileImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        profileImages[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: FaIcon(
                              FontAwesomeIcons.circleExclamation,
                              color: Colors.white,
                              size: 64,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
          ),
        );
      },
        ),
      ),
    );
                },
              ),
              // Close button
              SafeArea(
                child: Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              // Page indicator
              if (profileImages.length > 1)
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
          child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      profileImages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
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

