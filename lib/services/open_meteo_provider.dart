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
    String cityName = '현재 위치';
    try {
      // Use reverse geocoding via nearby city search
      final geoUrl =
          'https://geocoding-api.open-meteo.com/v1/search?name=&count=1&language=ko&format=json&latitude=$lat&longitude=$lon';
      final geoResponse = await http.get(Uri.parse(geoUrl));
      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        if (geoData['results'] != null &&
            (geoData['results'] as List).isNotEmpty) {
          cityName = geoData['results'][0]['name'] ?? cityName;
        }
      }
    } catch (_) {}

    final weather = await _fetchWeather(lat, lon);
    return weather.copyWith(
      cityName: weather.cityName.isEmpty ? cityName : weather.cityName,
    );
  }

  Future<WeatherData> _fetchWeather(double lat, double lon) async {
    // Build model parameter
    final modelParam = agency.globalModel == 'best_match'
        ? ''
        : '&models=${agency.globalModel}';

    final url = 'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'weather_code,surface_pressure,wind_speed_10m,visibility'
        '&hourly=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset'
        '&timezone=auto'
        '&forecast_days=7'
        '$modelParam';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('${agency.name} 모델에서 날씨 정보를 가져올 수 없습니다');
    }

    final data = json.decode(response.body);
    return _parseWeatherData(data);
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final current = data['current'];
    final daily = data['daily'];
    final hourly = data['hourly'];

    final weatherCode = current['weather_code'] as int;
    final weatherInfo = _getWeatherInfo(weatherCode);

    int sunrise = 0;
    int sunset = 0;
    if (daily != null &&
        daily['sunrise'] != null &&
        (daily['sunrise'] as List).isNotEmpty) {
      sunrise =
          DateTime.parse(daily['sunrise'][0]).millisecondsSinceEpoch ~/ 1000;
      sunset =
          DateTime.parse(daily['sunset'][0]).millisecondsSinceEpoch ~/ 1000;
    }

    // Hourly forecast
    List<HourlyForecast> hourlyForecast = [];
    if (hourly != null) {
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] as List;
      final codes = hourly['weather_code'] as List;
      final now = DateTime.now();

      for (int i = 0; i < times.length && hourlyForecast.length < 12; i++) {
        final dt = DateTime.parse(times[i]);
        if (dt.isAfter(now)) {
          final info = _getWeatherInfo(codes[i] as int);
          hourlyForecast.add(HourlyForecast(
            dateTime: dt,
            temperature: (temps[i] as num).toDouble(),
            icon: info['icon']!,
            description: info['description']!,
          ));
        }
      }
    }

    // Daily forecast
    List<DailyForecast> dailyForecast = [];
    if (daily != null) {
      final times = daily['time'] as List;
      final maxTemps = daily['temperature_2m_max'] as List;
      final minTemps = daily['temperature_2m_min'] as List;
      final codes = daily['weather_code'] as List;

      for (int i = 0; i < times.length; i++) {
        final info = _getWeatherInfo(codes[i] as int);
        dailyForecast.add(DailyForecast(
          dateTime: DateTime.parse(times[i]),
          tempMax: (maxTemps[i] as num).toDouble(),
          tempMin: (minTemps[i] as num).toDouble(),
          icon: info['icon']!,
          description: info['description']!,
        ));
      }
    }

    return WeatherData(
      cityName: '',
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      tempMin: daily != null
          ? (daily['temperature_2m_min'][0] as num).toDouble()
          : 0,
      tempMax: daily != null
          ? (daily['temperature_2m_max'][0] as num).toDouble()
          : 0,
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      pressure: (current['surface_pressure'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble() / 3.6,
      description: weatherInfo['description']!,
      icon: weatherInfo['icon']!,
      main: weatherInfo['main']!,
      sunrise: sunrise,
      sunset: sunset,
      visibility: ((current['visibility'] ?? 10000) as num).toInt(),
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
        return {
          'main': 'Thunderstorm',
          'description': '뇌우',
          'icon': '11d'
        };
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
