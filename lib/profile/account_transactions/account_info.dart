import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _interestTagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedUniversity = '';
  String _selectedDepartment = '';
  String _selectedClass = '';
  List<String> _interestTags = [];
  Map<String, String> _activeHours = {'start': '19:00', 'end': '22:00'};
  DateTime? _birthDate;
  List<String?> _profileImageUrls = [null, null, null, null];
  String? _coverImageUrl;
  List<File?> _selectedProfileImages = [null, null, null, null];
  File? _selectedCoverImage;
  bool _isLoading = false;
  bool _isSaving = false;

  List<String> _universities = [];
  List<String> _departments = [];
  List<String> _classes = [];
  
  List<String> _filteredUniversities = [];
  List<String> _filteredDepartments = [];
  List<String> _filteredClasses = [];

  bool _isLoadingUniversities = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingClasses = false;
  final TextEditingController _searchController = TextEditingController();
  bool _hasUniSearchText = false;
  bool _hasDeptSearchText = false;
  bool _hasClassSearchText = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUniversities();
    _loadDepartments();
    _loadClasses();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _isLoadingUniversities = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('universities')
          .orderBy('index')
          .get();

      final universities = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      universities.sort((a, b) => a.compareTo(b));

      setState(() {
        _universities = universities;
        _filteredUniversities = universities;
        _isLoadingUniversities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUniversities = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Üniversiteler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('departments')
          .orderBy('index')
          .get();

      final departments = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

          departments.sort((a, b) => a.compareTo(b));

      setState(() {
        _departments = departments;
        _filteredDepartments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDepartments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bölümler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .orderBy('index')
          .get();

      final classes = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      classes.sort((a, b) => a.compareTo(b));

      setState(() {
        _classes = classes;
        _filteredClasses = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingClasses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sınıflar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          
          // Load birthDate from Firebase
          if (data['birthDate'] != null) {
            try {
              if (data['birthDate'] is Timestamp) {
                _birthDate = (data['birthDate'] as Timestamp).toDate();
              } else if (data['birthDate'] is String) {
                _birthDate = DateTime.parse(data['birthDate']);
              }
            } catch (e) {
              debugPrint('AccountInfo: Error parsing birthDate: $e');
            }
          }
          
          _selectedUniversity = data['university'] ?? '';
          _selectedDepartment = data['department'] ?? '';
          _selectedClass = data['class'] ?? '';
          _departmentController.text = _selectedDepartment;
          _classController.text = _selectedClass;
          _bioController.text = data['bio'] ?? '';
          _interestTags = List<String>.from(data['interestTags'] ?? []);
          _activeHours = Map<String, String>.from(data['activeHours'] ?? {'start': '19:00', 'end': '22:00'});
          
          // Load profile images (support old single image and new multiple images)
          if (data['profileImages'] != null && data['profileImages'] is List) {
            final images = List<String>.from(data['profileImages']);
            for (int i = 0; i < images.length && i < 4; i++) {
              _profileImageUrls[i] = images[i];
            }
          } else if (data['profileImageUrl'] != null) {
            // Backward compatibility: convert old single image to array
            _profileImageUrls[0] = data['profileImageUrl'];
          }
          
          _coverImageUrl = data['coverImageUrl'];
          
          _interestTagsController.text = _interestTags.join(', ');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterUniversities(String query) {
    setState(() {
      _hasUniSearchText = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredUniversities = _universities;
      } else {
        _filteredUniversities = _universities
            .where((university) =>
                university.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _filterDepartments(String query) {
    setState(() {
      _hasDeptSearchText = query.isNotEmpty;
      _filteredDepartments = query.isEmpty
          ? _departments
          : _departments
              .where((d) => d.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }
  
  void _filterClasses(String query) {
    setState(() {
      _hasClassSearchText = query.isNotEmpty;
      _filteredClasses = query.isEmpty
         ? _classes
          : _classes
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _showUniversityBottomSheet() {
    _searchController.clear();
    _filterUniversities('');
    
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Üniversite Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                onChanged: (query) {
                  setState(() {
                    _hasUniSearchText = query.isNotEmpty;
                    if (query.isEmpty) {
                      _filteredUniversities = _universities;
                    } else {
                      _filteredUniversities = _universities
                          .where((university) =>
                              university.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Üniversite ara...',
                  hintStyle: TextStyle(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.grey[600] 
                        : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                  suffixIcon: _hasUniSearchText
                      ? IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hasUniSearchText = false;
                              _filteredUniversities = _universities;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoadingUniversities
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredUniversities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                size: 64,
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.grey[600]
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Üniversite bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.brightness == Brightness.dark 
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUniversities.length,
                          itemBuilder: (context, index) {
                            final university = _filteredUniversities[index];
                            final isSelected = university == _selectedUniversity;
                        
                        return ListTile(
                          title: Text(
                            university,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2563EB) : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: isSelected
                              ? const                                   FaIcon(
                                  FontAwesomeIcons.check,
                                  color: Color(0xFF2563EB),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedUniversity = university;
                            });
                            _searchController.clear();
                            _filterUniversities('');
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentBottomSheet() {
    _searchController.clear();
    _filterDepartments('');
    
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Bölüm Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                onChanged: (query) {
                  setState(() {
                    _hasDeptSearchText = query.isNotEmpty;
                    if (query.isEmpty) {
                      _filteredDepartments = _departments;
                    } else {
                      _filteredDepartments = _departments
                          .where((department) =>
                              department.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Bölüm ara...',
                  hintStyle: TextStyle(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.grey[600] 
                        : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                  suffixIcon: _hasDeptSearchText
                      ? IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hasDeptSearchText = false;
                              _filteredDepartments = _departments;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoadingDepartments
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredDepartments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                size: 64,
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.grey[600]
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bölüm bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.brightness == Brightness.dark 
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredDepartments.length,
                          itemBuilder: (context, index) {
                            final department = _filteredDepartments[index];
                            final isSelected = department == _selectedDepartment;
                        
                        return ListTile(
                          title: Text(
                            department,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2563EB) : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: isSelected
                              ? const                                   FaIcon(
                                  FontAwesomeIcons.check,
                                  color: Color(0xFF2563EB),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedDepartment = department;
                            });
                            _searchController.clear();
                            _filterDepartments('');
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassBottomSheet() {
    _searchController.clear();
    _filterClasses('');
    
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Sınıf Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                onChanged: (query) {
                  setState(() {
                    _hasClassSearchText = query.isNotEmpty;
                    if (query.isEmpty) {
                      _filteredClasses = _classes;
                    } else {
                      _filteredClasses = _classes
                          .where((classes) =>
                              classes.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Sınıf ara...',
                  hintStyle: TextStyle(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.grey[600] 
                        : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                  suffixIcon: _hasClassSearchText
                      ? IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hasClassSearchText = false;
                              _filteredClasses = _classes;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoadingClasses
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredClasses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                size: 64,
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.grey[600]
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sınıf bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.brightness == Brightness.dark 
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredClasses.length,
                          itemBuilder: (context, index) {
                            final classes = _filteredClasses[index];
                            final isSelected = classes == _selectedClass;
                        
                        return ListTile(
                          title: Text(
                            classes,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2563EB) : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: isSelected
                              ? const                                   FaIcon(
                                  FontAwesomeIcons.check,
                                  color: Color(0xFF2563EB),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedClass = classes;
                            });
                            _searchController.clear();
                            _filterClasses('');
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileImageSlot(int index, bool isDark) {
    final hasImage = _selectedProfileImages[index] != null || _profileImageUrls[index] != null;
    
    return GestureDetector(
      onTap: () => _pickProfileImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage 
              ? const Color(0xFF2563EB) 
              : (isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
            width: hasImage ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _selectedProfileImages[index] != null
                  ? Image.file(
                      _selectedProfileImages[index]!,
                      fit: BoxFit.cover,
                    )
                  : _profileImageUrls[index] != null
                      ? Image.network(
                          _profileImageUrls[index]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(index, isDark);
                          },
                        )
                      : _buildPlaceholder(index, isDark),
            ),
            
            // Delete button overlay
            if (hasImage)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedProfileImages[index] = null;
                      _profileImageUrls[index] = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(int index, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.image,
            size: 32,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf ${index + 1}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(int index) async {
    try {
      debugPrint('AccountInfo: Picking profile image for index $index');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedProfileImages[index] = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('AccountInfo: Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedCoverImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapak fotoğrafı seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    debugPrint('AccountInfo: Starting image upload');
    
    // .env dosyasından Cloudinary bilgilerini al
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']; 

    if (cloudName == null || uploadPreset == null || cloudName.isEmpty || uploadPreset.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloudinary yapılandırılmadı. .env dosyasını kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

      // Upload profile images
      for (int i = 0; i < _selectedProfileImages.length; i++) {
        if (_selectedProfileImages[i] != null) {
          debugPrint('AccountInfo: Uploading profile image $i');
          final res = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(_selectedProfileImages[i]!.path, resourceType: CloudinaryResourceType.Image),
          );
          _profileImageUrls[i] = res.secureUrl;
          debugPrint('AccountInfo: Profile image $i uploaded: ${res.secureUrl}');
        }
      }

      // Upload cover image
      if (_selectedCoverImage != null) {
        debugPrint('AccountInfo: Uploading cover image');
        final resCover = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedCoverImage!.path, resourceType: CloudinaryResourceType.Image),
        );
        _coverImageUrl = resCover.secureUrl;
        debugPrint('AccountInfo: Cover image uploaded');
      }
    } on CloudinaryException catch (err) {
      debugPrint('AccountInfo: Cloudinary error: ${err.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloudinary hatası: ${err.message} (${err.request})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUniversity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen üniversitenizi seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _uploadImages();

        // Filter out null values from profile images
        final profileImagesList = _profileImageUrls.where((url) => url != null).toList();
        
        debugPrint('AccountInfo: Saving profile with ${profileImagesList.length} images');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
          'university': _selectedUniversity,
          'department': _selectedDepartment,
          'class': _selectedClass,
          'bio': _bioController.text.trim(),
          'interestTags': _interestTags,
          'activeHours': _activeHours,
          'email': user.email,
          'profileImages': profileImagesList,
          'coverImageUrl': _coverImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil bilgileri başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _classController.dispose();
    _interestTagsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hesap Bilgileri'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Cover Image and Profile Photo
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          // Cover image area
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Cover Image
                              GestureDetector(
                                onTap: _pickCoverImage,
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: _selectedCoverImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.file(
                                            _selectedCoverImage!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : (_coverImageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(15),
                                              child: Image.network(
                                                _coverImageUrl!,
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                  Container(
                                                    color: const Color(0xFF2563EB),
                                                    child: const Center(
                                                      child: FaIcon(
                                                        FontAwesomeIcons.image,
                                                        size: 50,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(0xFF2563EB),
                                                    const Color(0xFF1D4ED8),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.image,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )),
                                ),
                              ),
                              // Camera icon for cover
                              if (_selectedCoverImage == null && _coverImageUrl == null)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.camera,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Image action buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover photo buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickCoverImage,
                                        icon: const FaIcon(FontAwesomeIcons.camera, size: 16),
                                        label: const Text('Kapak Değiştir'),
                                        style: OutlinedButton.styleFrom(
                                         backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Color(0xFF2563EB)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    if (_selectedCoverImage != null || _coverImageUrl != null) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            setState(() {
                                              _selectedCoverImage = null;
                                              _coverImageUrl = null;
                                            });
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null) {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .update({'coverImageUrl': null});
                                            }
                                          },
                                          icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                                          label: const Text('Kapak Kaldır'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Profile Photos Grid
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const FaIcon(FontAwesomeIcons.images, color: Color(0xFF2563EB), size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Profil Fotoğrafları',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Maksimum 4 fotoğraf ekleyebilirsiniz',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1,
                                        ),
                                        itemCount: 4,
                                        itemBuilder: (context, index) {
                                          return _buildProfileImageSlot(index, isDark);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Form fields
                    _buildFormField(
                      controller: _firstNameController,
                      label: 'Ad',
                      hint: 'Adınızı giriniz',
                      icon: FontAwesomeIcons.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad alanı zorunludur';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFormField(
                      controller: _lastNameController,
                      label: 'Soyad',
                      hint: 'Soyadınızı giriniz',
                      icon: FontAwesomeIcons.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Soyad alanı zorunludur';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Birth Date Picker
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _birthDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                          locale: const Locale('tr', 'TR'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: const Color(0xFF2563EB),
                                  onPrimary: Colors.white,
                                  surface: theme.cardColor,
                                  onSurface: theme.textTheme.bodyLarge?.color ?? Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _birthDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: theme.cardColor,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.cakeCandles,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Doğum Tarihi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _birthDate != null
                                        ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                                        : 'Doğum tarihinizi seçin',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _birthDate != null
                                          ? (isDark ? Colors.white : Colors.black87)
                                          : Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.calendar,
                              color: const Color(0xFF2563EB),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // University selection
                    Text(
                      'Üniversite',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showUniversityBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.graduationCap,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedUniversity.isEmpty 
                                    ? 'Üniversitenizi seçiniz'
                                    : _selectedUniversity,
                                style: TextStyle(
                                  color: _selectedUniversity.isEmpty 
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[600]
                                          : const Color(0xFF9CA3AF))
                                      : theme.textTheme.bodyLarge?.color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.chevronDown,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Department selection
                    Text(
                      'Bölüm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showDepartmentBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDepartment.isEmpty 
                                    ? 'Bölümünüzü seçiniz'
                                    : _selectedDepartment,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDepartment.isEmpty 
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[600]
                                          : const Color(0xFF9CA3AF))
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.chevronDown,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Class selection
                    Text(
                      'Sınıf',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showClassBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grade_outlined,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedClass.isEmpty 
                                    ? 'Sınıfınızı seçiniz'
                                    : _selectedClass,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedClass.isEmpty 
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[600]
                                          : const Color(0xFF9CA3AF))
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.chevronDown,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bio field
                    Text(
                      'Kısa Bio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _bioController,
                      label: '',
                      hint: 'Kendinizi kısaca tanıtın (140-200 karakter)',
                      icon: Icons.edit_note_outlined,
                      maxLines: 3,
                      maxLength: 200,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'Bio 200 karakterden uzun olamaz';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Interest Tags
                    Text(
                      'İlgi Alanları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _interestTagsController,
                      label: '',
                      hint: 'İlgi alanlarınızı virgülle ayırın (örn: koşu, sinema, müzik)',
                      icon: Icons.tag_outlined,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _interestTags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                        } else {
                          _interestTags = [];
                        }
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Active Hours
                    Text(
                      'Aktif Zamanlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeSelector(
                            'Başlangıç',
                            _activeHours['start']!,
                            (time) {
                              setState(() {
                                _activeHours['start'] = time;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTimeSelector(
                            'Bitiş',
                            _activeHours['end']!,
                            (time) {
                              setState(() {
                                _activeHours['end'] = time;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Hesap Bilgilerini Kaydet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
              prefixIcon: FaIcon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : const Color(0xFF9CA3AF),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, String time, Function(String) onTimeChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 $time:00')),
        );
        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.cardColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.clock,
                  color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

