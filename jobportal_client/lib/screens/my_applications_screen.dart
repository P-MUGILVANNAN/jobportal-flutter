import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'job_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  @override
  _MyApplicationsScreenState createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<dynamic> applications = [];
  bool isLoading = false;
  String? error;
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserEmail();
    if (userEmail.isNotEmpty) {
      await _fetchApplications();
    } else {
      setState(() {
        error = "User email not found";
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? "";
    });
  }

  Future<void> _fetchApplications() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/applications/user/$userEmail'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          applications = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to load applications. Server responded ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error fetching applications: $e";
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Applications"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeData,
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : applications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No applications yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Apply for jobs to see them here",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final application = applications[index];
                          final resume = application['resume'] ?? {};
                          final skills = application['skills']?.join(', ') ?? 'No skills listed';

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
                                  // Job title and application status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          application['jobTitle'] ?? 'No Job Title',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          'Submitted',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.blue,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  
                                  // Applicant name and email
                                  _buildInfoRow(Icons.person, application['name'] ?? 'No Name'),
                                  _buildInfoRow(Icons.email, application['email'] ?? 'No Email'),
                                  _buildInfoRow(Icons.phone, application['phone'] ?? 'No Phone'),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Education details
                                  Text(
                                    'Education Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildEducationRow('10th Marks:', '${application['tenthMark']}%'),
                                  _buildEducationRow('12th Marks:', '${application['twelfthMark']}%'),
                                  _buildEducationRow('Degree:', application['qualification'] ?? 'Not specified'),
                                  _buildEducationRow('Degree %:', '${application['degreePercentage']}%'),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Skills and relocation
                                  Text(
                                    'Skills: $skills',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Willing to relocate: ${application['willingToRelocate'] == true ? 'Yes' : 'No'}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Resume and application date
                                  Row(
                                    children: [
                                      Icon(Icons.file_present, size: 16),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          resume['fileName'] ?? 'No resume uploaded',
                                          style: TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Applied on: ${_formatDate(application['appliedAt'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEducationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}