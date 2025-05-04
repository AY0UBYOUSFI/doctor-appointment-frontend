import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Map user;
  const DoctorHomeScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GetStorage storage = GetStorage();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        storage.remove('token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الخروج: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("مرحباً د. ${widget.user['name'] ?? 'طبيب'}"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'المواعيد'),
            Tab(text: 'أوقات العمل'),
            Tab(text: 'التقييمات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AppointmentsTab(),
          AvailabilitiesTab(),
          RatingsTab(),
        ],
      ),
    );
  }
}

// ----------------- Appointments Tab -----------------
class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({Key? key}) : super(key: key);

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  late Future<List<dynamic>> _appointmentsFuture;
  final GetStorage storage = GetStorage();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = fetchAppointments();
  }

  Future<List<dynamic>> fetchAppointments() async {
    try {
      final token = storage.read('token');
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

  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      final token = storage.read('token');
      final endpoint = status == 'approve' ? 'approve' : 'reject';
      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:8000/api/appointments/$appointmentId/$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث حالة الموعد بنجاح')),
        );
        setState(() {
          _appointmentsFuture = fetchAppointments();
        });
      } else {
        throw Exception('Failed to update appointment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث الموعد: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _appointmentsFuture = fetchAppointments();
        });
      },
      child: FutureBuilder<List<dynamic>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('حدث خطأ في تحميل المواعيد'),
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
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد مواعيد حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data![index];
                return _buildAppointmentCard(appointment);
              },
            );
          }
        },
      ),
    );
  }

Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
  // First, add null checks for the entire appointment object
  if (appointment == null) {
    return SizedBox.shrink(); // or return an empty container
  }

  // Get the patient data with null safety
  final patient = appointment['patient'] ?? {};
  final patientName = patient['name'] ?? 'مريض غير معروف';
  final patientId = patient['id']?.toString() ?? 'غير متوفر';

  // Get status with default value
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

  // Safely format the date
  String formattedDate = 'تاريخ غير محدد';
  try {
    if (appointment['appointment_date'] != null) {
      final date = DateTime.parse(appointment['appointment_date']);
      formattedDate = DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(date);
    }
  } catch (e) {
    formattedDate = appointment['appointment_date']?.toString() ?? 'تاريخ غير محدد';
  }

  return Card(
    elevation: 2,
    margin: EdgeInsets.all(8),
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
                patientName, // Use the safely extracted name
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
            'رقم الملف: $patientId',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(formattedDate),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.note, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                appointment['notes'] ?? 'لا توجد ملاحظات',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          if (status == 'pending') ...[
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.check, size: 18),
                  label: Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    _updateAppointmentStatus(appointment['id']?.toString() ?? '', 'approve');
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.close, size: 18),
                  label: Text('رفض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    _updateAppointmentStatus(appointment['id']?.toString() ?? '', 'reject');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'canceled':
        return 'ملغى';
      default:
        return status;
    }
  }
}

// ----------------- Availabilities Tab -----------------
class AvailabilitiesTab extends StatefulWidget {
  const AvailabilitiesTab({Key? key}) : super(key: key);

  @override
  State<AvailabilitiesTab> createState() => _AvailabilitiesTabState();
}

class _AvailabilitiesTabState extends State<AvailabilitiesTab> {
  late Future<List<dynamic>> _availabilitiesFuture;
  final GetStorage storage = GetStorage();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _availabilitiesFuture = fetchAvailabilities();
  }

  Future<List<dynamic>> fetchAvailabilities() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/doctor/availabilities'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('availabilities'))
          return data['availabilities'];
        throw Exception('Unexpected data format');
      } else {
        throw Exception(
            'Failed to load availabilities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  Future<void> _addAvailability() async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/doctor/availabilities'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'day': _dayController.text,
          'start_time': _startTimeController.text,
          'end_time': _endTimeController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة وقت التوفر بنجاح')),
        );
        setState(() {
          _availabilitiesFuture = fetchAvailabilities();
        });
        _dayController.clear();
        _startTimeController.clear();
        _endTimeController.clear();
        Navigator.pop(context);
      } else {
        throw Exception('Failed to add availability: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة وقت التوفر: $e')),
      );
    }
  }

  void _showAddAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('إضافة وقت توفر جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dayController,
                decoration: InputDecoration(
                  labelText: 'اليوم',
                  hintText: 'مثال: السبت',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'وقت البدء',
                  hintText: 'مثال: 09:00',
                ),
                keyboardType: TextInputType.datetime,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _endTimeController,
                decoration: InputDecoration(
                  labelText: 'وقت الانتهاء',
                  hintText: 'مثال: 17:00',
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _addAvailability,
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddAvailabilityDialog,
        tooltip: 'إضافة وقت توفر',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _availabilitiesFuture = fetchAvailabilities();
          });
        },
        child: FutureBuilder<List<dynamic>>(
          future: _availabilitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('حدث خطأ في تحميل أوقات التوفر'),
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
                    Icon(Icons.access_time, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد أوقات توفر محددة',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final availability = snapshot.data![index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: Colors.blue),
                      title: Text(
                        availability['day'] ?? 'يوم غير محدد',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${availability['start_time'] ?? '--:--'} - ${availability['end_time'] ?? '--:--'}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Implement delete functionality
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

// ----------------- Ratings Tab -----------------
class RatingsTab extends StatefulWidget {
  const RatingsTab({Key? key}) : super(key: key);

  @override
  State<RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends State<RatingsTab> {
  late Future<List<dynamic>> _ratingsFuture;
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _ratingsFuture = fetchRatings();
  }

  Future<List<dynamic>> fetchRatings() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/ratings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('ratings')) return data['ratings'];
        throw Exception('Unexpected data format');
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _ratingsFuture = fetchRatings();
        });
      },
      child: FutureBuilder<List<dynamic>>(
        future: _ratingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('حدث خطأ في تحميل التقييمات'),
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
                  Icon(Icons.star, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد تقييمات حتى الآن',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final rating = snapshot.data![index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              rating['patient']['name'] ?? 'مريض غير معروف',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  '${rating['rating'] ?? '0'}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (rating['comment'] != null &&
                            rating['comment'].isNotEmpty)
                          Text(
                            rating['comment'],
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        SizedBox(height: 8),
                        Text(
                          _formatDate(rating['created_at']),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
