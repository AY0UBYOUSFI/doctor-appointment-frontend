import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_patient_screen.dart';
import 'register_doctor_screen.dart';

class ChooseRoleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade600],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Section
                Column(
                  children: [
                    Icon(Icons.account_circle, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'اختيار نوع الحساب',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر نوع الحساب الذي تريد إنشاءه',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Role Selection Cards
                Column(
                  children: [
                    // Patient Card
                    _buildRoleCard(
                      icon: Icons.person,
                      title: 'مريض',
                      subtitle: 'إنشاء حساب كمريض لحجز المواعيد',
                      color: Colors.green.shade600,
                      onTap: () => Get.to(() => RegisterPatientScreen()),
                    ),
                    const SizedBox(height: 20),

                    // Doctor Card
                    _buildRoleCard(
                      icon: Icons.medical_services,
                      title: 'طبيب',
                      subtitle: 'إنشاء حساب كطبيب لإدارة العيادة',
                      color: Colors.orange.shade600,
                      onTap: () => Get.to(() => RegisterDoctorScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
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
