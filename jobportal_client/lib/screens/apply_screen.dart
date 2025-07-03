import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApplyScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplyScreen({
    Key? key,
    required this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitializing = true;
  Uint8List? _resumeBytes;
  String? _resumeFileName;
  String? _resumeFileExtension;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _tenthMarkController = TextEditingController();
  final TextEditingController _twelfthMarkController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _degreePercentageController = TextEditingController();
  bool _willingToRelocate = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final email = prefs.getString('email');
      final name = prefs.getString('name');
      final phone = prefs.getString('phone');
      final skills = prefs.getStringList('skills')?.join(', ');

      if (token == null || email == null) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You need to be logged in to apply")),
        );
        return;
      }

      setState(() {
        if (name != null) _nameController.text = name;
        if (email != null) _emailController.text = email;
        if (phone != null) _phoneController.text = phone;
        if (skills != null && skills.isNotEmpty) _skillsController.text = skills;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading user data: $e")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          setState(() {
            _resumeBytes = file.bytes;
            _resumeFileName = file.name;
            _resumeFileExtension = file.extension;
          });
        } else {
          if (file.bytes != null) {
            setState(() {
              _resumeBytes = file.bytes;
              _resumeFileName = file.name;
              _resumeFileExtension = file.extension;
            });
          } else if (file.path != null) {
            final fileData = await File(file.path!).readAsBytes();
            setState(() {
              _resumeBytes = fileData;
              _resumeFileName = file.name;
              _resumeFileExtension = file.extension;
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitApplication() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_resumeBytes == null || _resumeFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        throw Exception('User not authenticated');
      }

      final applicationData = {
        'jobId': widget.jobId,
        'jobTitle': widget.jobTitle, 
        'userId': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'skills': _skillsController.text.trim().isNotEmpty
            ? _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : <String>[],
        'tenthMark': _tenthMarkController.text.trim(),
        'twelfthMark': _twelfthMarkController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'degreePercentage': _degreePercentageController.text.trim(),
        'willingToRelocate': _willingToRelocate,
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://job-portal-8rv9.onrender.com/api/apply'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['applicationData'] = jsonEncode(applicationData);

      request.files.add(http.MultipartFile.fromBytes(
        'resume',
        _resumeBytes!,
        filename: _resumeFileName ?? 'resume',
      ));

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    _tenthMarkController.dispose();
    _twelfthMarkController.dispose();
    _qualificationController.dispose();
    _degreePercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Apply for ${widget.jobTitle}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for ${widget.jobTitle}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Form',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Personal Information
              _buildSectionHeader('Personal Information'),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // Make email read-only since it's from profile
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your phone number';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value!)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              // Education
              _buildSectionHeader('Education Details'),
              _buildTextField(
                controller: _tenthMarkController,
                label: '10th Percentage/CGPA',
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your 10th marks' : null,
              ),
              _buildTextField(
                controller: _twelfthMarkController,
                label: '12th Percentage/CGPA',
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your 12th marks' : null,
              ),
              _buildTextField(
                controller: _qualificationController,
                label: 'Highest Qualification',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your qualification' : null,
              ),
              _buildTextField(
                controller: _degreePercentageController,
                label: 'Degree Percentage/CGPA',
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your degree marks' : null,
              ),

              // Skills
              _buildSectionHeader('Skills'),
              _buildTextField(
                controller: _skillsController,
                label: 'Skills (comma separated)',
                hintText: 'e.g. Flutter, Dart, Firebase',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your skills' : null,
              ),

              // Relocation
              _buildSectionHeader('Other Information'),
              CheckboxListTile(
                title: const Text('Willing to relocate'),
                value: _willingToRelocate,
                onChanged: (value) => setState(() => _willingToRelocate = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Resume Upload
              _buildSectionHeader('Upload Resume'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickResume,
                    child: const Text('Select Resume (PDF/DOC)'),
                  ),
                  const SizedBox(width: 16),
                  if (_resumeFileName != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resumeFileName!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_resumeFileExtension != null)
                            Text(
                              '${_resumeFileExtension!.toUpperCase()} file',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),

              // Submit Button
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT APPLICATION',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
        ),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
      ),
    );
  }
}