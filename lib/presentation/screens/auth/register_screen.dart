import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bus_time_track/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController driverKeyController = TextEditingController();

  String selectedRole = 'student';
  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse("${AppConfig.baseUrl}/register"),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'password': passwordController.text,
              'role': selectedRole,
              'driver_key':
                  selectedRole == 'driver' ? driverKeyController.text : null,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please log in."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Logic: Navigate back to LoginScreen
      } else {
        final errorMsg =
            jsonDecode(response.body)['error'] ?? "Registration failed";
        _showError(errorMsg);
      }
    } catch (e) {
      _showError("Connection error. Is the Railway server live?");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Join BusTrack",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Logic: Bus-themed header icon
              const SizedBox(height: 20),
              const Icon(
                Icons.bus_alert_rounded,
                size: 80,
                color: AppConfig.primaryColor,
              ),
              const SizedBox(height: 10),
              const Text(
                "Create Your Account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              _buildField(
                controller: nameController,
                label: "Full Name",
                icon: Icons.person_pin_rounded,
                hint: "Enter your full name",
              ),
              const SizedBox(height: 15),
              _buildField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.alternate_email_rounded,
                hint: "example@mail.com",
              ),
              const SizedBox(height: 15),
              _buildField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock_person_rounded,
                obscure: !isPasswordVisible,
                hint: "At least 8 characters",
                suffix: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed:
                      () => setState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                ),
              ),
              const SizedBox(height: 20),

              // Logic: Role selector with transit icons
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "Sign up as...",
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppConfig.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'student',
                    child: Row(
                      children: [
                        Icon(Icons.school_rounded, size: 20),
                        SizedBox(width: 10),
                        Text("Student"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'driver',
                    child: Row(
                      children: [
                        Icon(Icons.drive_eta_rounded, size: 20),
                        SizedBox(width: 10),
                        Text("Driver"),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => selectedRole = val!),
              ),

              // Logic: Appears ONLY when Driver is selected
              if (selectedRole == 'driver') ...[
                const SizedBox(height: 15),
                _buildField(
                  controller: driverKeyController,
                  label: "Driver Secret Key",
                  icon: Icons.vpn_key_rounded,
                  hint: "Provided by Admin",
                  obscure: true,
                ),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Already have an account? Login here",
                  style: TextStyle(
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppConfig.primaryColor),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
