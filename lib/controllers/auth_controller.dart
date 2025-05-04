import 'package:get/get.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/doctor/doctor_home_screen.dart';
import '../services/api_service.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  var isLoading = false.obs;

  Future<void> registerPatient(String name, String email, String password,
      String confirmPassword) async {
    isLoading.value = true;
    try {
      final response = await ApiService.registerPatient(
          name, email, password, confirmPassword);
      final user = response['user'];
      Get.offAll(() => PatientHomeScreen(user: user));
    } catch (e) {
      Get.snackbar("خطأ", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerDoctor(
      String name,
      String email,
      String password,
      String confirmPassword,
      String specialization,
      String phone,
      String bio) async {
    isLoading.value = true;
    try {
      final response = await ApiService.registerDoctor(
          name, email, password, confirmPassword, specialization, phone, bio);
      final user = response['user'];
      Get.offAll(() => DoctorHomeScreen(user: user));
    } catch (e) {
      Get.snackbar("خطأ", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  final GetStorage storage = GetStorage();

  Future<void> login(String email, String password) async {
    isLoading.value = true;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/login'),
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String token = data['token'];
      final Map user = data['user'];

      // حفظ التوكن وبيانات المستخدم
      storage.write('token', token);
      storage.write('user', user);

      // التحقق من نوع المستخدم بناءً على "role" أو "type"
      String role = user['role']; // أو user['type'] حسب استجابة API

      if (role == 'doctor') {
        Get.offAll(() => DoctorHomeScreen(user: user));
      } else if (role == 'patient') {
        Get.offAll(() => PatientHomeScreen(user: user));
      } else {
        Get.snackbar('خطأ', 'نوع مستخدم غير معروف');
      }
    } else {
      Get.snackbar('خطأ', 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    isLoading.value = false;
  }
}
