import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'weather_provider.dart';

class WttrProvider extends WeatherProvider {
  @override
  WeatherProviderType get type => WeatherProviderType.wttrIn;
  @override
  String get name => 'wttr.in';

  @override
  Future<WeatherData> getWeatherByCity(String cityName) async {
    final url = 'https://wttr.in/$cityName?format=j1';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseWeatherData(data, cityName);
    } else {
      throw Exception('도시를 찾을 수 없습니다');
    }
  }

  @override
  Future<WeatherData> getWeatherByLocation(double lat, double lon) async {
    final url = 'https://wttr.in/$lat,$lon?format=j1';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String cityName = '현재 위치';
      if (data['nearest_area'] != null &&
          (data['nearest_area'] as List).isNotEmpty) {
        final area = data['nearest_area'][0];
        final areaName = area['areaName'];
        if (areaName != null && (areaName as List).isNotEmpty) {
          cityName = areaName[0]['value'] ?? cityName;
        }
      }
      return _parseWeatherData(data, cityName);
    } else {
      throw Exception('날씨 정보를 가져올 수 없습니다');
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data, String cityName) {
    final current = data['current_condition'][0];

    // Parse city name from nearest_area if available
    String resolvedName = cityName;
    if (data['nearest_area'] != null &&
        (data['nearest_area'] as List).isNotEmpty) {
      final area = data['nearest_area'][0];
      if (area['areaName'] != null &&
          (area['areaName'] as List).isNotEmpty) {
        resolvedName = area['areaName'][0]['value'] ?? cityName;
      }
    }

    final tempC = double.parse(current['temp_C']);
    final feelsLike = double.parse(current['FeelsLikeC']);
    final humidity = int.parse(current['humidity']);
    final pressure = int.parse(current['pressure']);
    final windSpeed = double.parse(current['windspeedKmph']) / 3.6;
    final visibility = int.parse(current['visibility']) * 1000;
    final weatherCode = int.parse(current['weatherCode']);

    final weatherInfo = _getWeatherInfo(weatherCode);

    // Get description in Korean if available
    String description = weatherInfo['description']!;
    if (current['lang_ko'] != null &&
        (current['lang_ko'] as List).isNotEmpty) {
      description = current['lang_ko'][0]['value'] ?? description;
    } else if (current['weatherDesc'] != null &&
        (current['weatherDesc'] as List).isNotEmpty) {
      description = current['weatherDesc'][0]['value'] ?? description;
    }

    // Parse astronomy for sunrise/sunset
    int sunrise = 0;
    int sunset = 0;
    if (data['weather'] != null && (data['weather'] as List).isNotEmpty) {
      final astronomy = data['weather'][0]['astronomy'];
      if (astronomy != null && (astronomy as List).isNotEmpty) {
        sunrise = _parseTimeToEpoch(astronomy[0]['sunrise']);
        sunset = _parseTimeToEpoch(astronomy[0]['sunset']);
      }
    }

    // Parse daily min/max from today's weather
    double tempMin = tempC;
    double tempMax = tempC;
    if (data['weather'] != null && (data['weather'] as List).isNotEmpty) {
      tempMin = double.parse(data['weather'][0]['mintempC']);
      tempMax = double.parse(data['weather'][0]['maxtempC']);
    }

    // Parse hourly forecast
    List<HourlyForecast> hourlyForecast = [];
    if (data['weather'] != null && (data['weather'] as List).isNotEmpty) {
      final todayHourly = data['weather'][0]['hourly'] as List;
      final now = DateTime.now();

      for (var h in todayHourly) {
        final timeStr = h['time'] as String;
        final hour = int.parse(timeStr) ~/ 100;
        final dt = DateTime(now.year, now.month, now.day, hour);

        if (dt.isAfter(now) && hourlyForecast.length < 8) {
          final hCode = int.parse(h['weatherCode']);
          final hInfo = _getWeatherInfo(hCode);
          String hDesc = hInfo['description']!;
          if (h['lang_ko'] != null && (h['lang_ko'] as List).isNotEmpty) {
            hDesc = h['lang_ko'][0]['value'] ?? hDesc;
          }

          hourlyForecast.add(HourlyForecast(
            dateTime: dt,
            temperature: double.parse(h['tempC']),
            icon: hInfo['icon']!,
            description: hDesc,
          ));
        }
      }

      // Add tomorrow's hours if needed
      if (hourlyForecast.length < 8 && (data['weather'] as List).length > 1) {
        final tomorrowHourly = data['weather'][1]['hourly'] as List;
        final tomorrow = now.add(const Duration(days: 1));

        for (var h in tomorrowHourly) {
          if (hourlyForecast.length >= 8) break;
          final timeStr = h['time'] as String;
          final hour = int.parse(timeStr) ~/ 100;
          final dt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
          final hCode = int.parse(h['weatherCode']);
          final hInfo = _getWeatherInfo(hCode);

          hourlyForecast.add(HourlyForecast(
            dateTime: dt,
            temperature: double.parse(h['tempC']),
            icon: hInfo['icon']!,
            description: hInfo['description']!,
          ));
        }
      }
    }

    // Parse daily forecast
    List<DailyForecast> dailyForecast = [];
    if (data['weather'] != null) {
      for (var day in data['weather'] as List) {
        final date = DateTime.parse(day['date']);
        final dayHourly = day['hourly'] as List;
        final midHour = dayHourly[dayHourly.length ~/ 2];
        final dCode = int.parse(midHour['weatherCode']);
        final dInfo = _getWeatherInfo(dCode);

        dailyForecast.add(DailyForecast(
          dateTime: date,
          tempMin: double.parse(day['mintempC']),
          tempMax: double.parse(day['maxtempC']),
          icon: dInfo['icon']!,
          description: dInfo['description']!,
        ));
      }
    }

    return WeatherData(
      cityName: resolvedName,
      temperature: tempC,
      feelsLike: feelsLike,
      tempMin: tempMin,
      tempMax: tempMax,
      humidity: humidity,
      pressure: pressure,
      windSpeed: windSpeed,
      description: description,
      icon: weatherInfo['icon']!,
      main: weatherInfo['main']!,
      sunrise: sunrise,
      sunset: sunset,
      visibility: visibility,
      providerName: 'wttr.in',
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
    );
  }

  int _parseTimeToEpoch(String timeStr) {
    // Format: "06:23 AM" or "07:15 PM"
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute)
              .millisecondsSinceEpoch ~/
          1000;
    } catch (_) {
      return 0;
    }
  }

  static Map<String, String> _getWeatherInfo(int code) {
    // WWO weather codes mapping
    if (code == 113) {
      return {'main': 'Clear', 'description': '맑음', 'icon': '01d'};
    } else if (code == 116) {
      return {'main': 'Clouds', 'description': '부분적 흐림', 'icon': '02d'};
    } else if (code == 119) {
      return {'main': 'Clouds', 'description': '흐림', 'icon': '03d'};
    } else if (code == 122) {
      return {'main': 'Clouds', 'description': '매우 흐림', 'icon': '04d'};
    } else if (code == 143 || code == 248 || code == 260) {
      return {'main': 'Mist', 'description': '안개', 'icon': '50d'};
    } else if (code >= 176 && code <= 185) {
      return {'main': 'Drizzle', 'description': '이슬비', 'icon': '09d'};
    } else if (code >= 200 && code <= 232) {
      return {
        'main': 'Thunderstorm',
        'description': '뇌우',
        'icon': '11d'
      };
    } else if (code >= 263 && code <= 314) {
      return {'main': 'Rain', 'description': '비', 'icon': '10d'};
    } else if (code >= 320 && code <= 395) {
      return {'main': 'Snow', 'description': '눈', 'icon': '13d'};
    }
    return {'main': 'Clear', 'description': '맑음', 'icon': '01d'};
  }
}
