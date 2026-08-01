class AppConstants {
  // Default prayer times
  static const List<Map<String, dynamic>> defaultPrayerTimes = [
    {'name': 'Fajr', 'azaan': '04:45 AM', 'time': '05:15 AM', 'hour': 4, 'minute': 45},
    {'name': 'Dhuhr', 'azaan': '12:15 PM', 'time': '12:45 PM', 'hour': 12, 'minute': 15},
    {'name': 'Asr', 'azaan': '03:30 PM', 'time': '04:00 PM', 'hour': 15, 'minute': 30},
    {'name': 'Maghrib', 'azaan': '06:22 PM', 'time': '06:27 PM', 'hour': 18, 'minute': 22},
    {'name': 'Isha', 'azaan': '07:45 PM', 'time': '08:15 PM', 'hour': 19, 'minute': 45},
  ];

  static const String defaultJumuahTime = '01:45 PM';
  static const int nisabGoldInr = 650000;
  static const int defaultFitraRate = 150;

  // Default adhkars for tasbih
  static const List<Map<String, String>> commonAdhkars = [
    {'title': 'SubhanAllah', 'arabic': 'سُبْحَانَ اللَّهِ', 'transliteration': 'Glory be to Allah'},
    {'title': 'Alhamdulillah', 'arabic': 'الْحَمْدُ لِلَّهِ', 'transliteration': 'Praise be to Allah'},
    {'title': 'Allahu Akbar', 'arabic': 'اللَّهُ أَكْبَرُ', 'transliteration': 'Allah is the Greatest'},
    {'title': 'Astaghfirullah', 'arabic': 'أَسْتَغْفِرُ اللَّهَ', 'transliteration': 'I seek Allah\'s forgiveness'},
  ];

  // Default donation causes
  static const List<Map<String, String>> defaultCauses = [
    {'title': 'General Sadaqah', 'description': 'Ongoing charity for all masjid needs.', 'upi': 'masjid@sacred', 'badge': 'Sadaqah'},
    {'title': 'Zakat Al-Mal', 'description': 'Fulfill your annual zakat obligation.', 'upi': 'zakat@noor', 'badge': 'Zakat'},
    {'title': 'Masjid Expansion', 'description': 'Help us expand prayer facilities.', 'upi': 'build@noor', 'badge': 'Waqf'},
  ];

  // Juz names
  static const List<String> juzNames = [
    'Alif-Lam-Meem', 'Sayaqool', 'Tilkal Rusul', 'Lan Tanalu', 'Wal Muhsanat',
    'La Yuhibbullah', 'Wa Iza Samiu', 'Wa Lau Annana', 'Qalal Mala\'u', 'Wa\'lamu',
    'Ya\'tazirun', 'Wa Ma Min Dabbatin', 'Wa Ma Ubarri\'u', 'Alif-Lam-Ra', 'Subhanallazi',
    'Qala Alam', 'Iqtaraba Linnasi', 'Qad Aflaha', 'Wa Qalal Lazina', 'Amman Khalaqa',
    'Utlu Ma Uhiya', 'Wa Man Yaqnut', 'Wa Ma Liya', 'Faman Azlamu', 'Ilaihi Yuraddu',
    'Ha-Meem', 'Qala Fama Khatbukum', 'Qad Sami\'Allahu', 'Tabarakallazi', 'Amma Yatasa\'alun',
  ];
}
