import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'screens/home/home_screen.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide a mock current user (since we're skipping authentication)
        Provider<UserModel>(
          create: (_) => UserModel(
            uid: 'mock-user-id',
            email: 'student@example.edu',
            fullName: 'Demo Student',
            university: 'Example University',
            department: 'Computer Science',
            graduationYear: 2026,
            isVerified: true,
            profileImageUrl: '',
            bio: 'A passionate computer science student',
            createdAt: DateTime.now(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
