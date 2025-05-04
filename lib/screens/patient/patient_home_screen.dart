import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'CreateAppointmentScreen.dart';

class AvailableDoctorsScreen extends StatefulWidget {
  @override
  _AvailableDoctorsScreenState createState() => _AvailableDoctorsScreenState();
}

class _AvailableDoctorsScreenState extends State<AvailableDoctorsScreen> {
  late Future<List<dynamic>> _doctorsFuture;
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _doctorsFuture = fetchDoctors();
  }

  Future<List<dynamic>> fetchDoctors() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/doctors'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('doctors')) return data['doctors'];
        throw Exception('Unexpected data format');
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'الأطباء المتاحون',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _doctorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'حدث خطأ في التحميل',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا يوجد أطباء متاحون حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ListView.separated(
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doctor = snapshot.data![index];
                        return _buildDoctorCard(doctor, context);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAppointmentScreen(doctor: doctor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.medical_services,
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
                      doctor['name'] ?? 'دكتور غير معروف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      doctor['specialization'] ?? 'تخصص غير متوفر',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (doctor['bio'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        doctor['bio'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyAppointmentsScreen extends StatefulWidget {
  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late Future<List<dynamic>> _appointmentsFuture;
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
  }

  Future<List<dynamic>> _fetchAppointments() async {
    try {
      final token = _storage.read('token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/appointments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('appointments'))
          return data['appointments'];
        throw Exception('Unexpected data format');
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      final token = _storage.read('token');
      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:8000/api/appointments/$appointmentId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء الموعد بنجاح')),
        );
        setState(() {
          _appointmentsFuture = _fetchAppointments();
        });
      } else {
        throw Exception('Failed to cancel appointment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إلغاء الموعد: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مواعيدي'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoAppointments();
          } else {
            return _buildAppointmentsList(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('حدث خطأ في تحميل المواعيد'),
          SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAppointments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا يوجد مواعيد حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<dynamic> appointments) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    Color statusColor;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'canceled':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    final doctor = appointment['doctor'] ?? {};
    final doctorName = doctor['name'] ?? 'طبيب غير معروف';
    final doctorSpecialization = doctor['specialization'] ?? 'تخصص غير معروف';
    final appointmentDate =
        appointment['appointment_date'] ?? 'تاريخ غير متوفر';
    final notes = appointment['notes'] ?? 'لا توجد ملاحظات';

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    _translateStatus(status),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              doctorSpecialization,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(appointmentDate),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.note, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  notes,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (status == 'pending' || status == 'approved')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (status == 'pending')
                    ElevatedButton.icon(
                      icon: Icon(Icons.close, size: 18),
                      label: Text('إلغاء'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                      ),
                      onPressed: () {
                        _cancelAppointment(appointment['id'].toString());
                      },
                    ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.message, size: 18),
                    label: Text('تواصل'),
                    onPressed: () {
                      // Implement communication functionality
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentHeader(
      Map<String, dynamic> appointment, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          appointment['doctor']['name'] ?? 'طبيب غير معروف',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Chip(
          label: Text(
            _translateStatus(status),
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
      ],
    );
  }

  Widget _buildDoctorSpecialization(Map<String, dynamic> appointment) {
    return Text(
      appointment['doctor']['specialization'] ?? 'تخصص غير معروف',
      style: TextStyle(color: Colors.grey.shade600),
    );
  }

  Widget _buildAppointmentDate(Map<String, dynamic> appointment) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.blue),
        SizedBox(width: 8),
        Text(appointment['appointment_date']),
      ],
    );
  }

  Widget _buildAppointmentNotes(Map<String, dynamic> appointment) {
    return Row(
      children: [
        Icon(Icons.note, size: 16, color: Colors.blue),
        SizedBox(width: 8),
        Text(
          appointment['notes'] ?? 'لا توجد ملاحظات',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> appointment, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (status == 'pending')
          ElevatedButton.icon(
            icon: Icon(Icons.close, size: 18),
            label: Text('إلغاء'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            onPressed: () {
              _cancelAppointment(appointment['id'].toString());
            },
          ),
        ElevatedButton.icon(
          icon: Icon(Icons.message, size: 18),
          label: Text('تواصل'),
          onPressed: () {
            // TODO: Implement communication functionality
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'مؤكد';
      case 'rejected':
        return 'مرفوض';
      case 'canceled':
        return 'ملغى';
      default:
        return status;
    }
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _doctorsFuture;
  final GetStorage storage = GetStorage();
  List<dynamic> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _doctorsFuture = fetchDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchDoctors() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/doctors'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('doctors')) return data['doctors'];
        throw Exception('Unexpected data format');
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  void _onSearchChanged() {
    _doctorsFuture.then((doctors) {
      setState(() {
        _filteredDoctors = doctors.where((doctor) {
          final name = doctor['name']?.toString().toLowerCase() ?? '';
          final specialization =
              doctor['specialization']?.toString().toLowerCase() ?? '';
          final searchTerm = _searchController.text.toLowerCase();
          return name.contains(searchTerm) ||
              specialization.contains(searchTerm);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب أو تخصص...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _doctorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text('حدث خطأ في التحميل'),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا يوجد أطباء متاحون'),
                        ],
                      ),
                    );
                  } else {
                    final doctorsToDisplay = _searchController.text.isEmpty
                        ? snapshot.data!
                        : _filteredDoctors;

                    if (doctorsToDisplay.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('لا توجد نتائج بحث'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: doctorsToDisplay.length,
                      itemBuilder: (context, index) {
                        final doctor = doctorsToDisplay[index];
                        return _buildDoctorCard(doctor, context);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAppointmentScreen(doctor: doctor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.medical_services,
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
                      doctor['name'] ?? 'دكتور غير معروف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      doctor['specialization'] ?? 'تخصص غير متوفر',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ... [Keep the rest of your existing ProfileScreen and PatientHomeScreen code] ...

class ProfileScreen extends StatelessWidget {
  final Map user;
  ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              user['name'] ?? 'المستخدم',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              user['email'] ?? '',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            _buildProfileItem(Icons.person_outline, 'معلومات الحساب'),
            _buildProfileItem(Icons.settings, 'الإعدادات'),
            _buildProfileItem(Icons.help_outline, 'المساعدة'),
            _buildProfileItem(Icons.logout, 'تسجيل الخروج'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Icon(Icons.chevron_left, color: Colors.grey),
      onTap: () {},
    );
  }
}

class PatientHomeScreen extends StatefulWidget {
  final Map user;
  const PatientHomeScreen({required this.user});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AvailableDoctorsScreen(),
      MyAppointmentsScreen(),
      SearchScreen(),
      ProfileScreen(user: widget.user),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مرحباً ${widget.user['name']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blue.shade800,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            backgroundColor: Colors.white,
            elevation: 10,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services),
                label: 'الأطباء',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'مواعيدي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'بحث',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
