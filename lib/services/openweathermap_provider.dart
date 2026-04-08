import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'weather_provider.dart';

class OpenWeatherMapProvider extends WeatherProvider {
  static const String _apiKey = '5dc22e4c9efa9e54f2d1b9915ac70f8b';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  @override
  WeatherProviderType get type => WeatherProviderType.openWeatherMap;
  @override
  String get name => 'OpenWeatherMap';

  @override
  Future<WeatherData> getWeatherByCity(String cityName) async {
    final url =
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=ko';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      WeatherData weather = _parseCurrentWeather(data);
      return await _addForecast(weather, 'q=$cityName');
    } else {
      throw Exception('도시를 찾을 수 없습니다');
    }
  }

  @override
  Future<WeatherData> getWeatherByLocation(double lat, double lon) async {
    final url =
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ko';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      WeatherData weather = _parseCurrentWeather(data);
      return await _addForecast(weather, 'lat=$lat&lon=$lon');
    } else {
      throw Exception('날씨 정보를 가져올 수 없습니다');
    }
  }

  WeatherData _parseCurrentWeather(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      pressure: json['main']['pressure'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      main: json['weather'][0]['main'] ?? '',
      sunrise: json['sys']['sunrise'] as int,
      sunset: json['sys']['sunset'] as int,
      visibility: json['visibility'] ?? 10000,
      providerName: 'OpenWeatherMap',
    );
  }

  Future<WeatherData> _addForecast(
      WeatherData weather, String queryParams) async {
    try {
      final forecastUrl =
          '$_baseUrl/forecast?$queryParams&appid=$_apiKey&units=metric&lang=ko';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        return weather.copyWith(
          hourlyForecast: _parseHourly(forecastData),
          dailyForecast: _parseDaily(forecastData),
        );
      }
    } catch (_) {}
    return weather;
  }

  List<HourlyForecast> _parseHourly(Map<String, dynamic> data) {
    final list = data['list'] as List;
    return list.take(8).map((item) {
      return HourlyForecast(
        dateTime: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
        temperature: (item['main']['temp'] as num).toDouble(),
        icon: item['weather'][0]['icon'] ?? '01d',
        description: item['weather'][0]['description'] ?? '',
      );
    }).toList();
  }

  List<DailyForecast> _parseDaily(Map<String, dynamic> data) {
    final list = data['list'] as List;
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in list) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final key = '${date.year}-${date.month}-${date.day}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item as Map<String, dynamic>);
    }

    return grouped.entries.take(5).map((entry) {
      final items = entry.value;
      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;

      for (var item in items) {
        final temp = (item['main']['temp'] as num).toDouble();
        if (temp < minTemp) minTemp = temp;
        if (temp > maxTemp) maxTemp = temp;
      }

      final midItem = items[items.length ~/ 2];
      return DailyForecast(
        dateTime: DateTime.fromMillisecondsSinceEpoch(midItem['dt'] * 1000),
        tempMin: minTemp,
        tempMax: maxTemp,
        icon: midItem['weather'][0]['icon'],
        description: midItem['weather'][0]['description'],
      );
    }).toList();
  }
}
