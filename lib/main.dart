import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://hatscaabqgcrvrxxszco.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhdHNjYWFicWdjcnZyeHhzemNvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mjg3NjQ2NSwiZXhwIjoyMDY4NDUyNDY1fQ.pORc19pRuQU5ish1qIVMeDwV56ZoGCZc1dwMke4RqXs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakib',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF32C156),
        ),
        useMaterial3: true,
      ),
      routes: appRoutes,
      initialRoute: '/home', // Changed from '/' to '/home'
    );
  }
}