import 'package:flutter/material.dart';

class WeatherIconHelper {
  static IconData getWeatherIcon(String iconCode) {
    switch (iconCode.substring(0, 2)) {
      case '01':
        return Icons.wb_sunny;
      case '02':
        return Icons.cloud_queue;
      case '03':
        return Icons.cloud;
      case '04':
        return Icons.cloud;
      case '09':
        return Icons.grain;
      case '10':
        return Icons.beach_access;
      case '11':
        return Icons.flash_on;
      case '13':
        return Icons.ac_unit;
      case '50':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }

  static Color getWeatherColor(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return const Color(0xFF2196F3);
      case 'clouds':
        return const Color(0xFF607D8B);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF455A64);
      case 'thunderstorm':
        return const Color(0xFF37474F);
      case 'snow':
        return const Color(0xFF90A4AE);
      case 'mist':
      case 'haze':
      case 'fog':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF2196F3);
    }
  }

  static LinearGradient getWeatherGradient(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5), Color(0xFF90CAF9)],
        );
      case 'clouds':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF546E7A), Color(0xFF78909C), Color(0xFFB0BEC5)],
        );
      case 'rain':
      case 'drizzle':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)],
        );
      case 'thunderstorm':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF546E7A)],
        );
      case 'snow':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF78909C), Color(0xFFB0BEC5), Color(0xFFECEFF1)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF64B5F6)],
        );
    }
  }
}
