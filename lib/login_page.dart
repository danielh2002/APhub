import 'package:flutter/material.dart';
import 'dart:math';
import '../models/login_model.dart'; // Import login model
import 'package:aphub/utils/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController tpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LoginModel loginModel = LoginModel(); // Instance of LoginModel

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -10 * pi / 180,
      end: 10 * pi / 180,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await loginModel.login(
      context: context,
      tpNumber: tpController.text,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value,
                    child: Image.asset(
                      'assets/images/MAE_GLOBE_ICON.png',
                      width: 400,
                      height: 300,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              Image.asset(
                'assets/images/MAE_APHUB_WORD.png',
                width: 180,
                height: 50,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: tpController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'TP Number',
                  labelStyle: const TextStyle(color: AppColors.lightgrey),
                  filled: true,
                  fillColor: AppColors.darkdarkgrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: AppColors.white),
                  filled: true,
                  fillColor: AppColors.darkdarkgrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              ElevatedButton(
                onPressed: _login, // Calls _login function
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkdarkgrey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: AppColors.lightgrey.withOpacity(0.5),
                  elevation: 5,
                ),
                child: const Text('Login',
                    style: TextStyle(fontSize: 16, color: AppColors.lightgrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}