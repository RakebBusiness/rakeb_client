import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/App.header.dart';
import '../../services/auth_service.dart';
import '../../models/auth_state.dart';
import '../otp/otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _acceptedTerms = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().addListener(_authStateListener);
    });
  }

  @override
  void dispose() {
    context.read<AuthService>().removeListener(_authStateListener);
    _phoneController.dispose();
    super.dispose();
  }

  void _authStateListener() {
    final authState = context.read<AuthService>().state;
    
    if (authState.status == AppAuthStatus.codeSent) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpScreen()),
      );
    } else if (authState.status == AppAuthStatus.error) {
      setState(() {
        _error = authState.error;
      });
    }
  }

  void _validateAndProceed() {
    String phone = _phoneController.text.trim();

    // Enhanced validation for Algerian mobile numbers
    // Clean the input first
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check various valid formats
    final validPrefixes = ['05', '06', '07'];
    bool isValid = false;
    
    if (cleanPhone.length == 10 && cleanPhone.startsWith('0')) {
      // Format: 0512345678
      isValid = validPrefixes.contains(cleanPhone.substring(0, 2));
    } else if (cleanPhone.length == 9 && (cleanPhone.startsWith('5') || cleanPhone.startsWith('6') || cleanPhone.startsWith('7'))) {
      // Format: 512345678
      isValid = true;
    } else if (cleanPhone.startsWith('+213') && cleanPhone.length == 13) {
      // Format: +213512345678
      String localPart = cleanPhone.substring(4);
      isValid = localPart.length == 9 && (localPart.startsWith('5') || localPart.startsWith('6') || localPart.startsWith('7'));
    }

    if (!_acceptedTerms) {
      setState(() => _error = 'Vous devez accepter les conditions.');
      return;
    }

    if (!isValid) {
      setState(() => _error = 'Numéro invalide. Formats acceptés: 05XXXXXXXX, 06XXXXXXXX, 07XXXXXXXX, 5XXXXXXXX, 6XXXXXXXX, 7XXXXXXXX ou +213XXXXXXXXX');
    } else {
      setState(() => _error = null);
      _showChannelChoiceMenu(context);
    }
  }

  void _showChannelChoiceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comment voulez-vous recevoir le code ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  _requestOTP();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.green),
                title: const Text('SMS'),
                onTap: () {
                  Navigator.pop(context);
                  _requestOTP();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _requestOTP() {
    final phoneNumber = _phoneController.text.trim();
    context.read<AuthService>().requestOTP(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final isLoading = authService.state.status == AppAuthStatus.loading;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                const AppHeader(title: 'Rakib'),
                const SizedBox(height: 30),
                const Text('Hello nice to meet you !'),
                const SizedBox(height: 10),
                const Text(
                  'Get moving with Rakeb',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _error != null ? Colors.red : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        // Country code prefix
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Text(
                            '+213',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !isLoading,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0512345678',
                                counterText: '',
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : _validateAndProceed,
                          child: Container(
                            height: 50,
                            width: 50,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: isLoading 
                                  ? Colors.grey 
                                  : const Color(0xFF32C156),
                              borderRadius: BorderRadius.circular(25),
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
                                : const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: isLoading 
                            ? null 
                            : (val) => setState(() => _acceptedTerms = val!),
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        shape: const CircleBorder(),
                      ),
                      const Expanded(
                        child: Text("Accepter les termes et conditions"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: isLoading 
                      ? null 
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    'Pas de compte ? S\'inscrire',
                    style: TextStyle(color: Color(0xFF32C156)),
                  ),
                ),
                // Add some space for reCAPTCHA container on web
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}