import 'package:flutter/material.dart';

class AppConstants {
  // App name and version
  static const String appName = 'CampusVibe';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const Color primaryColor = Color(0xFF4A6572);
  static const Color accentColor = Color(0xFFFF8A65);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  
  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;
  
  // Padding and margins
  static const double paddingSmall = 8.0;
  static const double paddingRegular = 16.0;
  static const double paddingLarge = 24.0;
  
  // Content types for dual-purpose feed
  static const String contentTypeAcademic = 'academic';
  static const String contentTypeSocial = 'social';
  
  // User verification status
  static const String verificationStatusPending = 'pending';
  static const String verificationStatusVerified = 'verified';
  static const String verificationStatusRejected = 'rejected';
  
  // List of supported universities in Pakistan
  static const List<String> supportedUniversities = [
    'NUST - National University of Sciences and Technology',
    'LUMS - Lahore University of Management Sciences',
    'IBA - Institute of Business Administration',
    'FAST - National University of Computer and Emerging Sciences',
    'COMSATS University Islamabad',
    'UET - University of Engineering and Technology, Lahore',
    'Punjab University',
    'Quaid-i-Azam University',
    'Aga Khan University',
    'Bahria University',
    // Add more universities as needed
  ];
  
  // Email domains for university verification
  static const Map<String, String> universityEmailDomains = {
    'NUST': 'nust.edu.pk',
    'LUMS': 'lums.edu.pk',
    'IBA': 'iba.edu.pk',
    'FAST': 'nu.edu.pk',
    'COMSATS': 'comsats.edu.pk',
    // Add more domains as needed
  };
}
