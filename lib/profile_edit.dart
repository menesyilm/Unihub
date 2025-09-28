import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
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
  String? _profileImageUrl;
  File? _selectedImage;
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

      // Alfabetik sıralama
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
          _ageController.text = data['age']?.toString() ?? '';
          _selectedUniversity = data['university'] ?? '';
          _selectedDepartment = data['department'] ?? '';
          _selectedClass = data['class'] ?? '';
          _departmentController.text = _selectedDepartment;
          _classController.text = _selectedClass;
          _bioController.text = data['bio'] ?? '';
          _interestTags = List<String>.from(data['interestTags'] ?? []);
          _activeHours = Map<String, String>.from(data['activeHours'] ?? {'start': '19:00', 'end': '22:00'});
          _profileImageUrl = data['profileImageUrl'];
          
          // Update interest tags controller
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

    // Arama kutusunu temizle
    _searchController.clear();
    _filterUniversities('');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'Üniversite Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
            // Universities list
            Expanded(
              child: _isLoadingUniversities
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredUniversities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Üniversite bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Farklı bir arama terimi deneyin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2D3748),
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'Bölüm Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
            // Universities list
            Expanded(
              child: _isLoadingDepartments
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredDepartments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Bölüm bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Farklı bir arama terimi deneyin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2D3748),
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
    // Arama kutusunu temizle
    _searchController.clear();
    _filterClasses('');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'Sınıf Seçin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
            // Universities list
            Expanded(
              child: _isLoadingClasses
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredClasses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sınıf bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Farklı bir arama terimi deneyin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2D3748),
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
          _selectedImage = File(image.path);
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

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _profileImageUrl;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      
      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
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
        // Fotoğrafı yükle
        final imageUrl = await _uploadImage();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'university': _selectedUniversity,
          'department': _selectedDepartment,
          'class': _selectedClass,
          'bio': _bioController.text.trim(),
          'interestTags': _interestTags,
          'activeHours': _activeHours,
          'email': user.email,
          'profileImageUrl': imageUrl,
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
    _ageController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _classController.dispose();
    _interestTagsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profil Düzenle'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    // Header with Profile Photo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF1D4ED8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          // Profile Photo Section
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _selectedImage!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _profileImageUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _profileImageUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person_outline,
                                                size: 50,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_outline,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Profil Fotoğrafınızı Değiştirin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Fotoğrafa dokunarak seçin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                    
                    _buildFormField(
                      controller: _ageController,
                      label: 'Yaş',
                      hint: 'Yaşınızı giriniz',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Yaş alanı zorunludur';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age < 16 || age > 100) {
                          return 'Geçerli bir yaş giriniz (16-100)';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // University selection
                    const Text(
                      'Üniversite',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showUniversityBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF9CA3AF),
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
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF2D3748),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedUniversity.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          'Üniversite seçimi zorunludur',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Department selection
                    const Text(
                      'Bölüm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showDepartmentBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              color: Color(0xFF9CA3AF),
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
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Class selection
                    const Text(
                      'Sınıf',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showClassBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.grade_outlined,
                              color: Color(0xFF9CA3AF),
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
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bio field
                    const Text(
                      'Kısa Bio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
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
                    const Text(
                      'İlgi Alanları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
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
                    const Text(
                      'Aktif Zamanlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
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
                                'Profil Bilgilerini Kaydet',
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF9CA3AF),
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
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          // ignore: unnecessary_brace_in_string_interps
          initialTime: TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 ${time}:00')),
        );
        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
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
