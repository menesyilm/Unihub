import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _profileImageUrl;
  String? _coverImageUrl;
  File? _selectedProfilImage;
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
              print('AccountInfo: Error parsing birthDate: $e');
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
          _profileImageUrl = data['profileImageUrl'];
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
                    icon: const Icon(Icons.close),
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
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _hasUniSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
                              Icon(
                                Icons.search_off,
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
                              ? const Icon(
                                  Icons.check,
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
                    icon: const Icon(Icons.close),
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
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _hasDeptSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
                              Icon(
                                Icons.search_off,
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
                              ? const Icon(
                                  Icons.check,
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
                    icon: const Icon(Icons.close),
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
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _hasClassSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
                              Icon(
                                Icons.search_off,
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
                              ? const Icon(
                                  Icons.check,
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
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedProfilImage = File(image.path);
        });
      }
    } catch (e) {
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

  Future<String?> _uploadImage() async {
    if (_selectedProfilImage == null && _selectedCoverImage == null) return _profileImageUrl;

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
      return null;
    }

    try {
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

      if (_selectedProfilImage != null) {
        final resProfile = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedProfilImage!.path, resourceType: CloudinaryResourceType.Image),
        );
        _profileImageUrl = resProfile.secureUrl;
      }

      if (_selectedCoverImage != null) {
        final resCover = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_selectedCoverImage!.path, resourceType: CloudinaryResourceType.Image),
        );
        _coverImageUrl = resCover.secureUrl;
      }

      return _profileImageUrl;
    } on CloudinaryException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloudinary hatası: ${err.message} (${err.request})'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
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
        await _uploadImage();

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
          'profileImageUrl': _profileImageUrl,
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
                                                      child: Icon(
                                                        Icons.image_outlined,
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
                                                child: Icon(
                                                  Icons.image_outlined,
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
                                    child: const Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              // Profile Image
                              Positioned(
                                left: 20,
                                bottom: -50,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[200],
                                      child: _selectedProfilImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                _selectedProfilImage!,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : _profileImageUrl != null
                                              ? ClipOval(
                                                  child: Image.network(
                                                    _profileImageUrl!,
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => 
                                                      Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: Colors.grey[400],
                                                      ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey[400],
                                                ),
                                    ),
                                  ),
                                ),
                              ),
                              // Camera icon for profile
                              if (_selectedProfilImage == null && _profileImageUrl == null)
                                Positioned(
                                  left: 90,
                                  bottom: -40,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 60),
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
                                        icon: const Icon(Icons.photo_camera, size: 18),
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
                                          icon: const Icon(Icons.delete_outline, size: 18),
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
                                const SizedBox(height: 12),
                                // Profile photo buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.person, size: 18),
                                        label: const Text('Profil Değiştir'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                    if (_selectedProfilImage != null || _profileImageUrl != null) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            setState(() {
                                              _selectedProfilImage = null;
                                              _profileImageUrl = null;
                                            });
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null) {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .update({'profileImageUrl': null});
                                            }
                                          },
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          label: const Text('Profil Kaldır'),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Form fields
                    _buildFormField(
                      controller: _firstNameController,
                      label: 'Ad',
                      hint: 'Adınızı giriniz',
                      icon: Icons.person_outline,
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
                      icon: Icons.person_outline,
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
                              child: const Icon(
                                Icons.cake_outlined,
                                color: Color(0xFF2563EB),
                                size: 20,
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
                            Icon(
                              Icons.calendar_today_outlined,
                              color: const Color(0xFF2563EB),
                              size: 20,
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
                            Icon(
                              Icons.school_outlined,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
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
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
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
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
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
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[600]
                                  : const Color(0xFF9CA3AF),
                              size: 20,
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
              prefixIcon: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : const Color(0xFF9CA3AF),
                size: 20,
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
                Icon(
                  Icons.access_time,
                  color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                  size: 20,
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

