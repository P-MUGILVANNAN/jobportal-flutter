import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ApplicationsPage extends StatefulWidget {
  @override
  _ApplicationsPageState createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  List<Map<String, dynamic>> applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _downloadResume(String url) async {
    var status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      try {
        Directory? dir = Directory('/storage/emulated/0/Download');
        String fileName = url.split('/').last;
        String savePath = "${dir.path}/$fileName";

        Dio dio = Dio();
        await dio.download(url, savePath);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloaded to $savePath')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Storage permission denied')));
    }
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://job-portal-8rv9.onrender.com/api/applications'),
      );

      if (response.statusCode == 200) {
        setState(() {
          applications = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch applications')));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Applications'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchApplications),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildApplicationsList(),
    );
  }

  Widget _buildApplicationsList() {
    if (applications.isEmpty) {
      return Center(
        child: Text(
          'No applications found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Title and Applied Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      application['jobTitle'] ?? 'No Job Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      _formatDate(application['appliedAt']),
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Divider(height: 24, thickness: 1),

                // Applicant Info
                _buildInfoRow('Name', application['name']),
                _buildInfoRow('Email', application['email']),
                _buildInfoRow('Phone', application['phone']),
                _buildInfoRow('Qualification', application['qualification']),

                // Academic Marks
                SizedBox(height: 12),
                Text(
                  'Academic Performance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        '10th',
                        '${application['tenthMark']}%',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildScoreCard(
                        '12th',
                        '${application['twelfthMark']}%',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildScoreCard(
                        'Degree',
                        '${application['degreePercentage']}%',
                      ),
                    ),
                  ],
                ),

                // Skills
                SizedBox(height: 16),
                Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (application['skills'] as List<dynamic>)
                          .map(
                            (skill) => Chip(
                              label: Text(skill.toString()),
                              backgroundColor: Colors.blue[50],
                            ),
                          )
                          .toList(),
                ),

                // Relocation and Resume
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      application['willingToRelocate']
                          ? 'Willing to relocate'
                          : 'Not willing to relocate',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed:
                          () =>
                              _downloadResume(application['resume']['fileUrl']),
                      icon: Icon(Icons.file_download, size: 18),
                      label: Text('Download Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.blue[800])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchResume(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open resume')));
    }
  }
}
