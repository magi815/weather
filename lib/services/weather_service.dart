import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // OpenWeatherMap free API key - users should replace with their own
  static const String _apiKey = '0c1b8f8f4e8d6a9b3c5e7f2a1d4b6c8e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> getWeatherByCity(String cityName) async {
    final url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=ko';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      WeatherData weather = WeatherData.fromJson(data);

      // Get forecast data
      final forecastUrl =
          '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric&lang=ko';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        final hourly = _parseHourlyForecast(forecastData);
        final daily = _parseDailyForecast(forecastData);
        weather = weather.copyWith(
          hourlyForecast: hourly,
          dailyForecast: daily,
        );
      }

      return weather;
    } else {
      throw Exception('도시를 찾을 수 없습니다');
    }
  }

  Future<WeatherData> getWeatherByLocation(double lat, double lon) async {
    final url =
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ko';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      WeatherData weather = WeatherData.fromJson(data);

      final forecastUrl =
          '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ko';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        final hourly = _parseHourlyForecast(forecastData);
        final daily = _parseDailyForecast(forecastData);
        weather = weather.copyWith(
          hourlyForecast: hourly,
          dailyForecast: daily,
        );
      }

      return weather;
    } else {
      throw Exception('날씨 정보를 가져올 수 없습니다');
    }
  }

  List<HourlyForecast> _parseHourlyForecast(Map<String, dynamic> data) {
    final list = data['list'] as List;
    return list
        .take(8)
        .map((item) => HourlyForecast.fromJson(item))
        .toList();
  }

  List<DailyForecast> _parseDailyForecast(Map<String, dynamic> data) {
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
