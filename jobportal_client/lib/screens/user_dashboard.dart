import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // For logout navigation
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String name = "Loading...";
  String email = "Loading...";
  String location = "Loading...";
  String userId = "";
  String about = "";
  String education = "";
  List<String> skills = [];

  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  bool isLoading = false;
  bool isProfileLoading = false;
  String? error;

  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchJobs();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isProfileLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token is null - User not authenticated');
      }

      final response = await http.get(
        Uri.parse('https://job-portal-8rv9.onrender.com/api/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('name', data['name']);
        await prefs.setString('email', data['email']);
        await prefs.setString('location', data['location'] ?? 'Not specified');
        await prefs.setString('userId', data['_id']);
        await prefs.setString('about', data['about'] ?? '');
        await prefs.setString('education', data['education'] ?? '');
        await prefs.setStringList(
          'skills',
          List<String>.from(data['skills'] ?? []),
        );

        setState(() {
          name = data['name'];
          email = data['email'];
          location = data['location'] ?? 'Not specified';
          userId = data['_id'];
          about = data['about'] ?? '';
          education = data['education'] ?? '';
          skills = List<String>.from(data['skills'] ?? []);
          _locationController.text = location;
          isProfileLoading = false;
        });
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print("Error loading profile: $e");
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        name = prefs.getString('name') ?? 'John Doe';
        email = prefs.getString('email') ?? 'john@example.com';
        location = prefs.getString('location') ?? 'Not specified';
        userId = prefs.getString('userId') ?? '';
        about = prefs.getString('about') ?? '';
        education = prefs.getString('education') ?? '';
        skills = prefs.getStringList('skills') ?? [];
        isProfileLoading = false;
        _locationController.text = location;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile(Map<String, dynamic> profileData) async {
    setState(() {
      isProfileLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token is null - User not authenticated');
      }

      // Ensure all fields have non-null values
      final cleanedData = {
        'name': profileData['name']?.toString() ?? '',
        'email': profileData['email']?.toString() ?? '',
        'location': profileData['location']?.toString() ?? '',
        'about': profileData['about']?.toString() ?? '',
        'education': profileData['education']?.toString() ?? '',
        'skills':
            profileData['skills'] is List
                ? (profileData['skills'] as List)
                    .map((e) => e?.toString() ?? '')
                    .toList()
                : [],
      };

      final response = await http.put(
        Uri.parse('https://job-portal-8rv9.onrender.com/api/users/update-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cleanedData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('name', data['name'] ?? '');
        await prefs.setString('email', data['email'] ?? '');
        await prefs.setString('location', data['location'] ?? '');
        await prefs.setString('about', data['about'] ?? '');
        await prefs.setString('education', data['education'] ?? '');
        await prefs.setStringList(
          'skills',
          (data['skills'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );

        setState(() {
          name = data['name'] ?? '';
          email = data['email'] ?? '';
          location = data['location'] ?? '';
          about = data['about'] ?? '';
          education = data['education'] ?? '';
          skills =
              (data['skills'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          isProfileLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isProfileLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  Future<void> _fetchJobs() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://job-portal-8rv9.onrender.com/api/jobs'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          jobs = data.cast<Map<String, dynamic>>();
          filteredJobs = List.from(jobs);
          isLoading = false;
        });
      } else {
        setState(() {
          error =
              "Failed to load jobs. Server responded ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error fetching jobs: $e";
        isLoading = false;
      });
    }
  }

  void _filterJobs() {
    final searchTerm = _searchController.text.toLowerCase();
    final locationTerm = _locationController.text.toLowerCase();

    setState(() {
      filteredJobs =
          jobs.where((job) {
            final titleMatch =
                job['title']?.toString().toLowerCase().contains(searchTerm) ??
                false;
            final companyMatch =
                job['company']?.toString().toLowerCase().contains(searchTerm) ??
                false;
            final locationMatch =
                job['location']?.toString().toLowerCase().contains(
                  locationTerm,
                ) ??
                false;

            return (titleMatch || companyMatch) && locationMatch;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Job Portal"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with user info
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_outline,
                      title: "My Profile",
                      onTap: () {
                        Navigator.pop(context);
                        _showProfilePage(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.work_outline,
                      title: "My Applications",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyApplicationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Footer with logout
              Padding(
                padding: EdgeInsets.all(16),
                child: _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red.shade600,
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Search Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search for jobs...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) => _filterJobs(),
                  ),
                  SizedBox(height: 10),

                  // Location Field
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) => _filterJobs(),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),

            // Job Listings Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Available Jobs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  TextButton(
                    child: Text(
                      "Refresh",
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: _fetchJobs,
                  ),
                ],
              ),
            ),

            // Job Listings
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : error != null
                      ? Center(child: Text(error!))
                      : filteredJobs.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No jobs found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Try adjusting your search filters",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = filteredJobs[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row with title and save icon
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          job['title'] ?? 'No Title',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.bookmark_border,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    job['company'] ?? 'No Company',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        job['location'] ?? 'No Location',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.money,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        job['salary'] ?? 'Salary not specified',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(Icons.access_time, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        job['postingDate'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton(
                                        child: Text("View Details"),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.blue),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      JobDetailScreen(job: job),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfilePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProfilePage(
              name: name,
              email: email,
              location: location,
              about: about,
              education: education,
              skills: skills,
              onSave: _saveProfile,
              isProfileLoading: isProfileLoading,
            ),
      ),
    );
  }
}

// Helper method for drawer items
Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? color,
}) {
  return ListTile(
    leading: Icon(icon, color: color ?? Colors.blue.shade700),
    title: Text(
      title,
      style: TextStyle(
        color: color ?? Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: onTap,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
    minLeadingWidth: 24,
    dense: true,
    visualDensity: VisualDensity.compact,
  );
}

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String location;
  final String about;
  final String education;
  final List<String> skills;
  final Function(Map<String, dynamic>) onSave;
  final bool isProfileLoading;

  const ProfilePage({
    required this.name,
    required this.email,
    required this.location,
    required this.about,
    required this.education,
    required this.skills,
    required this.onSave,
    required this.isProfileLoading,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool _isEditMode;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;
  late TextEditingController _educationController;
  late TextEditingController _skillsController;
  late List<String> _editableSkills;

  @override
  void initState() {
    super.initState();
    _isEditMode = false;
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _locationController = TextEditingController(text: widget.location);
    _aboutController = TextEditingController(text: widget.about);
    _educationController = TextEditingController(text: widget.education);
    _skillsController = TextEditingController();
    _editableSkills = List.from(widget.skills);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Reset to original values when exiting edit mode without saving
        _nameController.text = widget.name;
        _emailController.text = widget.email;
        _locationController.text = widget.location;
        _aboutController.text = widget.about;
        _educationController.text = widget.education;
        _editableSkills = List.from(widget.skills);
      }
    });
  }

  void _saveProfile() {
    final profileData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'location': _locationController.text,
      'about': _aboutController.text,
      'education': _educationController.text,
      'skills': _editableSkills,
    };
    widget.onSave(profileData);
    setState(() {
      _isEditMode = false;
    });
  }

  void _addSkill() {
    if (_skillsController.text.trim().isNotEmpty) {
      setState(() {
        _editableSkills.add(_skillsController.text.trim());
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _editableSkills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Profile" : "My Profile"),
        actions: [
          if (!_isEditMode)
            IconButton(icon: Icon(Icons.edit), onPressed: _toggleEditMode),
          if (_isEditMode)
            IconButton(icon: Icon(Icons.close), onPressed: _toggleEditMode),
          if (_isEditMode)
            IconButton(
              icon:
                  widget.isProfileLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Icon(Icons.save),
              onPressed: widget.isProfileLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              SizedBox(height: 24),

              // Profile Sections
              _buildProfileSection(
                title: "Basic Information",
                icon: Icons.person_outline,
                child: _buildBasicInfoSection(),
              ),
              SizedBox(height: 16),

              _buildProfileSection(
                title: "About",
                icon: Icons.info_outline,
                child: _buildAboutSection(),
              ),
              SizedBox(height: 16),

              _buildProfileSection(
                title: "Education",
                icon: Icons.school_outlined,
                child: _buildEducationSection(),
              ),
              SizedBox(height: 16),

              _buildProfileSection(
                title: "Skills",
                icon: Icons.star_outline,
                child: _buildSkillsSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blue.shade700),
            ),
            SizedBox(height: 16),
            Text(
              _nameController.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _emailController.text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    if (_isEditMode) {
      return Column(
        children: [
          _buildEditableField(
            controller: _nameController,
            label: "Full Name",
            icon: Icons.person,
          ),
          SizedBox(height: 12),
          _buildEditableField(
            controller: _emailController,
            label: "Email",
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12),
          _buildEditableField(
            controller: _locationController,
            label: "Location",
            icon: Icons.location_on,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildInfoRow(Icons.person, "Name", _nameController.text),
          SizedBox(height: 12),
          _buildInfoRow(Icons.email, "Email", _emailController.text),
          SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            "Location",
            _locationController.text,
          ),
        ],
      );
    }
  }

  Widget _buildAboutSection() {
    if (_isEditMode) {
      return TextFormField(
        controller: _aboutController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "About",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.info),
        ),
      );
    } else {
      return Text(
        _aboutController.text.isNotEmpty
            ? _aboutController.text
            : "No information provided",
        style: TextStyle(fontSize: 16),
      );
    }
  }

  Widget _buildEducationSection() {
    if (_isEditMode) {
      return TextFormField(
        controller: _educationController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: "Education",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.school),
        ),
      );
    } else {
      return Text(
        _educationController.text.isNotEmpty
            ? _educationController.text
            : "No education information provided",
        style: TextStyle(fontSize: 16),
      );
    }
  }

  Widget _buildSkillsSection() {
    if (_isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Skills
          if (_editableSkills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _editableSkills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          deleteIcon: Icon(Icons.close, size: 18),
                          onDeleted: () => _removeSkill(skill),
                        ),
                      )
                      .toList(),
            ),
          SizedBox(height: 12),

          // Add New Skill
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: "Add new skill",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addSkill,
                child: Text("Add"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return _editableSkills.isNotEmpty
          ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _editableSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    )
                    .toList(),
          )
          : Text("No skills added yet", style: TextStyle(fontSize: 16));
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade700),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
    );
  }
}
