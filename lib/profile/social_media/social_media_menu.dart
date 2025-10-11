import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialMediaMenuPage extends StatefulWidget {
  const SocialMediaMenuPage({super.key});

  @override
  State<SocialMediaMenuPage> createState() => _SocialMediaMenuPageState();
}

class _SocialMediaMenuPageState extends State<SocialMediaMenuPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> socialMedias = {};
  bool isLoading = true;

  final List<Map<String, dynamic>> platforms = [
    {
      'name': 'Instagram',
      'key': 'instagram',
      'icon': FontAwesomeIcons.instagram,
      'color': const Color(0xFFE4405F),
    },
    {
      'name': 'Facebook',
      'key': 'facebook',
      'icon': FontAwesomeIcons.facebook,
      'color': const Color(0xFF1877F2),
    },
    {
      'name': 'Twitter',
      'key': 'twitter',
      'icon': FontAwesomeIcons.x,
      'color': const Color(0xFF1DA1F2),
    },
    {
      'name': 'Telegram',
      'key': 'telegram',
      'icon': FontAwesomeIcons.telegram,
      'color': const Color(0xFF0088CC),
    },
    {
      'name': 'LinkedIn',
      'key': 'linkedin',
      'icon': FontAwesomeIcons.linkedin,
      'color': const Color(0xFF0A66C2),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSocialMedias();
  }

  Future<void> _loadSocialMedias() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (mounted) {
          setState(() {
            socialMedias = doc.data()?['socialMedias'] ?? {};
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('SocialMedia: Error loading social medias: $e');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addOrEditSocialMedia(String platform, String key) async {
    final controller = TextEditingController(text: socialMedias[key] ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            '$platform Kullanıcı Adı',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adınızı girin',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              prefixIcon: FaIcon(
                FontAwesomeIcons.user,
                color: const Color(0xFF2563EB),
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            if (socialMedias[key] != null && socialMedias[key].toString().isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, 'DELETE'),
                child: const Text(
                  'Kaldır',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result != null && user != null) {
      try {
        if (result == 'DELETE') {
          // Kaldır
          socialMedias.remove(key);
        } else if (result.isNotEmpty) {
          // Ekle veya güncelle
          socialMedias[key] = result;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'socialMedias': socialMedias,
        });

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'DELETE' 
                    ? '$platform kaldırıldı' 
                    : '$platform kaydedildi',
              ),
              backgroundColor: const Color(0xFF2563EB),
            ),
          );
        }
      } catch (e) {
        debugPrint('SocialMedia: Error updating social media: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sosyal Medya Hesapları'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.circleInfo,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sosyal medya hesaplarınız profilinizde görüntülenecektir.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Social Media List
                      ...platforms.map((platform) {
                        final key = platform['key'] as String;
                        final name = platform['name'] as String;
                        final icon = platform['icon'] as IconData;
                        final color = platform['color'] as Color;
                        final username = socialMedias[key]?.toString() ?? '';
                        final hasUsername = username.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.grey[800]! 
                                  : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              hasUsername ? username : 'Ekle',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUsername
                                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                    : Colors.grey[500],
                                fontStyle: hasUsername 
                                    ? FontStyle.normal 
                                    : FontStyle.italic,
                              ),
                            ),
                            trailing: IconButton(
                              icon: FaIcon(
                                hasUsername ? FontAwesomeIcons.pen : FontAwesomeIcons.circlePlus,
                                color: const Color(0xFF2563EB),
                                size: 22,
                              ),
                              onPressed: () => _addOrEditSocialMedia(name, key),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

