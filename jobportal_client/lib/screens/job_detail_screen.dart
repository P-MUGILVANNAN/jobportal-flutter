import 'package:flutter/material.dart';
import './apply_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle skills whether they come as List or comma-separated string
    List<String> skills = [];
    if (job['skills'] is List) {
      skills = List<String>.from(job['skills'] ?? []);
    } else if (job['skills'] is String) {
      skills =
          (job['skills'] as String).split(',').map((s) => s.trim()).toList();
    }

    // Filter out any empty skills
    skills = skills.where((skill) => skill.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(job['title'] ?? 'Job Details'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title and Company
            Text(
              job['title'] ?? 'No Title Provided',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job['company'] ?? 'No Company Provided',
              style: TextStyle(fontSize: 18, color: Colors.blue.shade600),
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(thickness: 1),
            ),

            // Job Meta Information
            _buildInfoRow(
              Icons.location_on,
              job['location'] ?? 'Location not specified',
            ),
            _buildInfoRow(
              Icons.attach_money,
              job['salary'] ?? 'Salary not disclosed',
            ),
            _buildInfoRow(
              Icons.access_time,
              job['postingDate'] ?? 'Posted date not available',
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(thickness: 1),
            ),

            // Job Description Section
            Text(
              'JOB DESCRIPTION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              job['description'] ?? 'No job description provided.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(thickness: 1),
            ),

            // Skills Section
            Text(
              'REQUIRED SKILLS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Text(
                'No specific skills required',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    skills.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.blue.shade100),
                        ),
                      );
                    }).toList(),
              ),

            // Apply Button
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ApplyScreen(
                            jobId: job['_id'],
                            jobTitle: job['title'],
                          ),
                    ),
                  );
                },
                child: const Text(
                  'APPLY NOW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
