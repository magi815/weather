import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/weather_agency.dart';

class OpenMeteoProvider {
  final WeatherAgency agency;

  OpenMeteoProvider({required this.agency});

  Future<WeatherData> getWeatherByCity(String cityName) async {
    final geoUrl =
        'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=ko&format=json';
    final geoResponse = await http.get(Uri.parse(geoUrl));

    if (geoResponse.statusCode != 200) {
      throw Exception('도시를 찾을 수 없습니다');
    }

    final geoData = json.decode(geoResponse.body);
    if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
      throw Exception('"$cityName" 도시를 찾을 수 없습니다');
    }

    final location = geoData['results'][0];
    final double lat = (location['latitude'] as num).toDouble();
    final double lon = (location['longitude'] as num).toDouble();
    final String resolvedName = location['name'] ?? cityName;

    final weather = await _fetchWeather(lat, lon);
    return weather.copyWith(cityName: resolvedName);
  }

  Future<WeatherData> getWeatherByLocation(double lat, double lon) async {
    final weather = await _fetchWeather(lat, lon);
    return weather.copyWith(
      cityName: weather.cityName.isEmpty ? '현재 위치' : weather.cityName,
    );
  }

  Future<WeatherData> _fetchWeather(double lat, double lon) async {
    // Build model parameter - only add for non-best_match
    final modelParam = agency.modelParam == 'best_match'
        ? ''
        : '&models=${agency.modelParam}';

    // Use minimal variables that are supported across all models
    final url = 'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'weather_code,surface_pressure,wind_speed_10m'
        '&hourly=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset'
        '&timezone=auto'
        '&forecast_days=7'
        '$modelParam';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      final body = response.body;
      // Parse error message from API
      try {
        final errorData = json.decode(body);
        if (errorData['reason'] != null) {
          throw Exception(
              '${agency.name}: ${errorData['reason']}');
        }
      } catch (_) {}
      throw Exception(
          '${agency.name} 모델에서 날씨 정보를 가져올 수 없습니다 (${response.statusCode})');
    }

    final data = json.decode(response.body);

    // Check if current data is valid
    final current = data['current'];
    if (current == null ||
        current['temperature_2m'] == null) {
      throw Exception(
          '${agency.name} 모델은 이 지역의 데이터를 제공하지 않습니다.\n다른 기관을 선택해주세요.');
    }

    return _parseWeatherData(data);
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final current = data['current'];
    final daily = data['daily'];
    final hourly = data['hourly'];

    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final weatherInfo = _getWeatherInfo(weatherCode);

    int sunrise = 0;
    int sunset = 0;
    if (daily != null &&
        daily['sunrise'] != null &&
        (daily['sunrise'] as List).isNotEmpty &&
        daily['sunrise'][0] != null) {
      try {
        sunrise =
            DateTime.parse(daily['sunrise'][0]).millisecondsSinceEpoch ~/ 1000;
        sunset =
            DateTime.parse(daily['sunset'][0]).millisecondsSinceEpoch ~/ 1000;
      } catch (_) {}
    }

    // Hourly forecast (null-safe)
    List<HourlyForecast> hourlyForecast = [];
    if (hourly != null &&
        hourly['time'] != null &&
        hourly['temperature_2m'] != null) {
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] as List;
      final codes = (hourly['weather_code'] as List?) ?? [];
      final now = DateTime.now();

      for (int i = 0; i < times.length && hourlyForecast.length < 12; i++) {
        if (temps[i] == null) continue;
        final dt = DateTime.parse(times[i]);
        if (dt.isAfter(now)) {
          final code = i < codes.length && codes[i] != null
              ? (codes[i] as num).toInt()
              : 0;
          final info = _getWeatherInfo(code);
          hourlyForecast.add(HourlyForecast(
            dateTime: dt,
            temperature: (temps[i] as num).toDouble(),
            icon: info['icon']!,
            description: info['description']!,
          ));
        }
      }
    }

    // Daily forecast (null-safe)
    List<DailyForecast> dailyForecast = [];
    if (daily != null &&
        daily['time'] != null &&
        daily['temperature_2m_max'] != null) {
      final times = daily['time'] as List;
      final maxTemps = daily['temperature_2m_max'] as List;
      final minTemps = daily['temperature_2m_min'] as List;
      final codes = (daily['weather_code'] as List?) ?? [];

      for (int i = 0; i < times.length; i++) {
        if (maxTemps[i] == null || minTemps[i] == null) continue;
        final code = i < codes.length && codes[i] != null
            ? (codes[i] as num).toInt()
            : 0;
        final info = _getWeatherInfo(code);
        dailyForecast.add(DailyForecast(
          dateTime: DateTime.parse(times[i]),
          tempMax: (maxTemps[i] as num).toDouble(),
          tempMin: (minTemps[i] as num).toDouble(),
          icon: info['icon']!,
          description: info['description']!,
        ));
      }
    }

    double safeDouble(dynamic v, [double def = 0]) =>
        v == null ? def : (v as num).toDouble();
    int safeInt(dynamic v, [int def = 0]) =>
        v == null ? def : (v as num).toInt();

    final tempMin = daily != null &&
            daily['temperature_2m_min'] != null &&
            (daily['temperature_2m_min'] as List).isNotEmpty
        ? safeDouble(daily['temperature_2m_min'][0])
        : safeDouble(current['temperature_2m']);
    final tempMax = daily != null &&
            daily['temperature_2m_max'] != null &&
            (daily['temperature_2m_max'] as List).isNotEmpty
        ? safeDouble(daily['temperature_2m_max'][0])
        : safeDouble(current['temperature_2m']);

    return WeatherData(
      cityName: '',
      temperature: safeDouble(current['temperature_2m']),
      feelsLike: safeDouble(
          current['apparent_temperature'], safeDouble(current['temperature_2m'])),
      tempMin: tempMin,
      tempMax: tempMax,
      humidity: safeInt(current['relative_humidity_2m']),
      pressure: safeInt(current['surface_pressure'], 1013),
      windSpeed: safeDouble(current['wind_speed_10m']) / 3.6,
      description: weatherInfo['description']!,
      icon: weatherInfo['icon']!,
      main: weatherInfo['main']!,
      sunrise: sunrise,
      sunset: sunset,
      visibility: 10000,
      providerName: '${agency.flag} ${agency.name}',
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
    );
  }

  static Map<String, String> _getWeatherInfo(int code) {
    switch (code) {
      case 0:
        return {'main': 'Clear', 'description': '맑음', 'icon': '01d'};
      case 1:
        return {'main': 'Clear', 'description': '대체로 맑음', 'icon': '01d'};
      case 2:
        return {'main': 'Clouds', 'description': '부분적 흐림', 'icon': '02d'};
      case 3:
        return {'main': 'Clouds', 'description': '흐림', 'icon': '04d'};
      case 45:
      case 48:
        return {'main': 'Mist', 'description': '안개', 'icon': '50d'};
      case 51:
      case 53:
      case 55:
        return {'main': 'Drizzle', 'description': '이슬비', 'icon': '09d'};
      case 56:
      case 57:
        return {'main': 'Drizzle', 'description': '결빙 이슬비', 'icon': '09d'};
      case 61:
        return {'main': 'Rain', 'description': '약한 비', 'icon': '10d'};
      case 63:
        return {'main': 'Rain', 'description': '비', 'icon': '10d'};
      case 65:
        return {'main': 'Rain', 'description': '강한 비', 'icon': '10d'};
      case 66:
      case 67:
        return {'main': 'Rain', 'description': '결빙 비', 'icon': '10d'};
      case 71:
        return {'main': 'Snow', 'description': '약한 눈', 'icon': '13d'};
      case 73:
        return {'main': 'Snow', 'description': '눈', 'icon': '13d'};
      case 75:
        return {'main': 'Snow', 'description': '강한 눈', 'icon': '13d'};
      case 77:
        return {'main': 'Snow', 'description': '싸락눈', 'icon': '13d'};
      case 80:
      case 81:
      case 82:
        return {'main': 'Rain', 'description': '소나기', 'icon': '09d'};
      case 85:
      case 86:
        return {'main': 'Snow', 'description': '눈 소나기', 'icon': '13d'};
      case 95:
        return {'main': 'Thunderstorm', 'description': '뇌우', 'icon': '11d'};
      case 96:
      case 99:
        return {
          'main': 'Thunderstorm',
          'description': '우박 동반 뇌우',
          'icon': '11d'
        };
      default:
        return {'main': 'Clear', 'description': '맑음', 'icon': '01d'};
    }
  }
}
