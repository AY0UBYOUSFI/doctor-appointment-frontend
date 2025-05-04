import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final Map doctor;
  const CreateAppointmentScreen({required this.doctor});

  @override
  _CreateAppointmentScreenState createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  late Future<List<dynamic>> _availabilityFuture;
  final GetStorage storage = GetStorage();
  Map? selectedAvailability; // 👉 متغير لتخزين التوفر المختار

  @override
  void initState() {
    super.initState();
    _availabilityFuture = fetchAvailability();
  }

  Future<List<dynamic>> fetchAvailability() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/doctors/${widget.doctor['id']}/availabilities'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('فشل في جلب التوفر');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  void confirmAppointment() {
    if (selectedAvailability == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رجاءً اختر موعداً أولاً')),
      );
      return;
    }

    // 🔥 هنا ترسل معلومات الحجز الى السيرفر عبر API
    // ولكن مبدئياً نعرض فقط رسالة نجاح:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'تم إرسال طلب الحجز ليوم ${selectedAvailability!['day']} من ${selectedAvailability!['start_time']} إلى ${selectedAvailability!['end_time']}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حجز موعد مع ${widget.doctor['name']}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _availabilityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('لا يوجد أوقات متاحة لهذا الطبيب.'));
                } else {
                  final availabilities = snapshot.data!;
                  return ListView.builder(
                    itemCount: availabilities.length,
                    itemBuilder: (context, index) {
                      final item = availabilities[index];
                      final isSelected = selectedAvailability == item;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvailability = item;
                          });
                        },
                        child: Card(
                          color: isSelected ? Colors.blue[100] : null,
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text('يوم: ${item['day']}'),
                            subtitle: Text(
                                'من ${item['start_time']} إلى ${item['end_time']}'),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blue)
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: confirmAppointment,
              child: Text('تأكيد حجز الموعد'),
            ),
          ),
        ],
      ),
    );
  }
}
