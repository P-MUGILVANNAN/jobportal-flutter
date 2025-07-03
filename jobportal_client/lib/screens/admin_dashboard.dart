import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'applications.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> jobs = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://job-portal-8rv9.onrender.com/api/jobs'),
      );

      if (response.statusCode == 200) {
        setState(() {
          jobs = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch jobs')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isDrawerOpen = false;
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("FIIT JOBS ADMIN PANEL", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: _toggleDrawer,
        ),
      ),
      drawer: _buildMobileDrawer(),
      body: _buildMainContent(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostJobPage()),
                ).then((_) => _fetchJobs());
              },
              child: Icon(Icons.add),
              backgroundColor: const Color.fromARGB(255, 171, 210, 255),
              tooltip: 'Post New Job',
            )
          : null,
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        color: Colors.blue[50],
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue[800]),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0), // Added padding to align with menu items
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(Icons.dashboard, "Dashboard", 0),
            _buildNavItem(Icons.work, "Job Listings", 1),
            _buildNavItem(Icons.people, "Applications", 2),
            Spacer(),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blue[800]),
              title: Text("Logout", style: TextStyle(color: Colors.blue[800])),
              onTap: () => _logout(context),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue[800] : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blue[800] : Colors.grey,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
    );
  }

  Widget _buildMainContent() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _getCurrentPage(),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildJobListings();
      case 2:
        return ApplicationsPage();
      default:
        return _buildJobListings();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          // Stats Card
          _buildStatCard('Total Jobs', jobs.length.toString(), Icons.work),
          SizedBox(height: 30),
          Text(
            'Recent Job Postings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ...jobs.take(3).map((job) => _buildJobCard(job)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey)),
                Icon(icon, color: Colors.blue[800]),
              ],
            ),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job Listings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('${jobs.length} Jobs', style: TextStyle(color: Colors.grey)),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(job);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                        job['image'] ?? 'https://via.placeholder.com/100',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        job['company'],
                        style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                      ),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Chip(
                              label: Text(job['location']),
                              backgroundColor: Colors.blue[50],
                            ),
                            SizedBox(width: 4),
                            Chip(
                              label: Text(job['experience']),
                              backgroundColor: Colors.blue[50],
                            ),
                            SizedBox(width: 4),
                            Chip(
                              label: Text(job['salary']),
                              backgroundColor: Colors.blue[50],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(child: Text("Edit"), value: "edit"),
                    PopupMenuItem(child: Text("Delete"), value: "delete"),
                  ],
                  onSelected: (value) {
                    if (value == "edit") {
                      _navigateToEditJob(context, job, jobs.indexOf(job));
                    } else if (value == "delete") {
                      _showDeleteConfirmation(
                        context,
                        job['_id'],
                        jobs.indexOf(job),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Job Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              job['description'],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Text(
              'Posted on: ${job['postingDate']}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (job['skills'] != null && job['skills'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 6),
                  Text(
                    'Skills Required:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (job['skills'] is String
                              ? (job['skills'] as String)
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList()
                              : List<String>.from(job['skills']))
                          .map(
                            (skill) => Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Chip(
                                label: Text(skill),
                                backgroundColor: Colors.blue[50],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String jobId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Job'),
        content: Text('Are you sure you want to delete this job posting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final response = await http.delete(
                  Uri.parse('https://job-portal-8rv9.onrender.com/api/jobs/$jobId'),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    jobs.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Job deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete job')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditJob(
    BuildContext context,
    Map<String, dynamic> job,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostJobPage(job: job, isEditing: true),
      ),
    ).then((_) => _fetchJobs());
  }
}

class PostJobPage extends StatefulWidget {
  final Map<String, dynamic>? job;
  final bool isEditing;

  PostJobPage({this.job, this.isEditing = false});

  @override
  _PostJobPageState createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _roleController;
  late TextEditingController _locationController;
  late TextEditingController _salaryController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _skillsController;

  String _experienceLevel = 'Fresher';
  String? _selectedYears;
  final List<String> _experienceYears = List.generate(15, (index) => '${index + 1}');

  List<String> _selectedSkills = [];
  final List<String> _commonSkills = [
    'Html', 'Css', 'Javascript', 'Bootstrap', 'Tailwind CSS', 
    'React', 'Angular', 'Java', 'Python', 'Node.js', 
    'Express.js', 'Spring Boot', 'UI/UX', 'Django', 'Flutter',
    'Git', 'Github', 'SQL', 'NoSQL', 'Networking', 
    'Cloud', 'Linux', 'Hardware',
  ];

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.job?['company'] ?? '');
    _titleController = TextEditingController(text: widget.job?['title'] ?? '');
    _roleController = TextEditingController(text: widget.job?['role'] ?? '');
    _locationController = TextEditingController(text: widget.job?['location'] ?? '');
    _salaryController = TextEditingController(text: widget.job?['salary'] ?? '');
    _descriptionController = TextEditingController(text: widget.job?['description'] ?? '');
    _imageUrlController = TextEditingController(text: widget.job?['image'] ?? '');
    _skillsController = TextEditingController();

    if (widget.job?['skills'] != null) {
      if (widget.job!['skills'] is String) {
        _selectedSkills = (widget.job!['skills'] as String).split(',').map((e) => e.trim()).toList();
      } else if (widget.job!['skills'] is List) {
        _selectedSkills = List<String>.from(widget.job!['skills']);
      }
    }

    final exp = widget.job?['experience'] ?? '';
    if (exp.contains('Fresher')) {
      _experienceLevel = 'Fresher';
    } else {
      _experienceLevel = 'Experienced';
      final years = exp.split('+')[0].trim();
      if (_experienceYears.contains(years)) {
        _selectedYears = years;
      }
    }
  }

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) {
      String experienceText = _experienceLevel == 'Fresher' ? 'Fresher' : '$_selectedYears+ years';

      final jobData = {
        'company': _companyController.text,
        'title': _titleController.text,
        'role': _roleController.text,
        'location': _locationController.text,
        'experience': experienceText,
        'salary': _salaryController.text,
        'description': _descriptionController.text,
        'skills': _selectedSkills.join(', '),
        'postingDate': widget.job?['postingDate'] ?? DateTime.now().toString().split(' ')[0],
        'image': _imageUrlController.text,
      };

      try {
        final response = widget.isEditing
            ? await http.put(
                Uri.parse('https://job-portal-8rv9.onrender.com/api/jobs/${widget.job!['_id']}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(jobData),
              )
            : await http.post(
                Uri.parse('https://job-portal-8rv9.onrender.com/api/jobs'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(jobData),
              );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditing ? 'Job updated successfully' : 'Job posted successfully'),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${widget.isEditing ? 'update' : 'post'} job: ${response.body}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Job' : 'Post New Job'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Company Logo URL',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter image URL' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter company name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter job title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter role' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter location' : null,
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Experience Level', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Fresher'),
                          value: 'Fresher',
                          groupValue: _experienceLevel,
                          onChanged: (value) {
                            setState(() {
                              _experienceLevel = value!;
                              _selectedYears = null;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Experienced'),
                          value: 'Experienced',
                          groupValue: _experienceLevel,
                          onChanged: (value) {
                            setState(() {
                              _experienceLevel = value!;
                              _selectedYears = _selectedYears ?? '1';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_experienceLevel == 'Experienced') ...[
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedYears,
                      decoration: InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                      ),
                      items: _experienceYears.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year years'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYears = value;
                        });
                      },
                      validator: (value) {
                        if (_experienceLevel == 'Experienced' && value == null) {
                          return 'Please select years of experience';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  labelText: 'Salary Range',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter salary range' : null,
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skills Needed', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  if (_selectedSkills.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSkills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          deleteIcon: Icon(Icons.close, size: 18),
                          onDeleted: () => _removeSkill(skill),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skillsController,
                          decoration: InputDecoration(
                            labelText: 'Add Skill',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (value) => _addSkill(),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSkill,
                        child: Text('Add'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(80, 60),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Common Skills:', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonSkills.where((skill) => !_selectedSkills.contains(skill))
                        .map((skill) {
                          return ActionChip(
                            label: Text(skill),
                            onPressed: () {
                              setState(() {
                                _selectedSkills.add(skill);
                              });
                            },
                            backgroundColor: Colors.blue.shade50,
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Please enter job description' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitJob,
                child: Text(widget.isEditing ? 'Update Job' : 'Post Job'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}