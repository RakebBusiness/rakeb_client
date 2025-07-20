import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../widgets/App.header.dart';
import '../../services/auth_service.dart';
import '../../models/auth_state.dart';
import '../home/home_screen.dart';
import '../auth/username_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int remaining = 60;
  Timer? timer;
  String otpCode = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().addListener(_authStateListener);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    context.read<AuthService>().removeListener(_authStateListener);
    super.dispose();
  }

  void _authStateListener() {
    final authState = context.read<AuthService>().state;
    
    if (authState.status == AppAuthStatus.verified) {
      // Check if user needs to complete profile
      final user = context.read<AuthService>().currentUser;
      if (user?.userMetadata?['display_name'] == null || 
          user!.userMetadata!['display_name']?.toString().isEmpty == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UsernameScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (authState.status == AppAuthStatus.error) {
      setState(() {
        _error = authState.error;
      });
    }
  }

  void _startTimer() {
    remaining = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining > 0) {
        setState(() => remaining--);
      } else {
        t.cancel();
      }
    });
  }

  void _verifyOTP() {
    if (otpCode.length == 6) {
      context.read<AuthService>().verifyOTP(otpCode);
    } else {
      setState(() {
        _error = 'Veuillez entrer le code complet';
      });
    }
  }

  void _resendCode() {
    final authService = context.read<AuthService>();
    if (authService.state.phoneNumber != null) {
      authService.requestOTP(authService.state.phoneNumber!);
      _startTimer();
      setState(() {
        _error = null;
        otpCode = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final isLoading = authService.state.status == AppAuthStatus.loading;
          final phoneNumber = authService.state.phoneNumber ?? '';
          
          return Column(
            children: [
              const AppHeader(title: 'Rakib'),
              const SizedBox(height: 30),
              const Text(
                'Entrer votre code de confirmation',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (phoneNumber.isNotEmpty)
                Text(
                  'Code envoyé au $phoneNumber',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 20),

              // OTP Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  enabled: !isLoading,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 60,
                    fieldWidth: 50,
                    activeFillColor: Colors.white,
                    selectedColor: Colors.green,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    errorBorderColor: Colors.red,
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: false,
                  onChanged: (value) {
                    setState(() {
                      otpCode = value;
                      _error = null;
                    });
                  },
                  onCompleted: (value) {
                    otpCode = value;
                    _verifyOTP();
                  },
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 20),

              // Timer and Resend
              if (remaining > 0)
                Text(
                  'Renvoyer dans $remaining sec',
                  style: const TextStyle(fontSize: 12),
                ),
              if (remaining == 0)
                TextButton(
                  onPressed: isLoading ? null : _resendCode,
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(color: Colors.green),
                  ),
                ),

              const SizedBox(height: 20),

              // Verify Button
              ElevatedButton(
                onPressed: isLoading || otpCode.length != 6 ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32C156),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Vérifier',
                        style: TextStyle(color: Colors.white),
                      ),
              ),

              const SizedBox(height: 20),

              // Back Button
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Retour',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}