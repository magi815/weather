class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String description;
  final String icon;
  final String main;
  final int sunrise;
  final int sunset;
  final int visibility;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.main,
    required this.sunrise,
    required this.sunset,
    required this.visibility,
    this.hourlyForecast = const [],
    this.dailyForecast = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
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
    );
  }

  WeatherData copyWith({
    List<HourlyForecast>? hourlyForecast,
    List<DailyForecast>? dailyForecast,
  }) {
    return WeatherData(
      cityName: cityName,
      temperature: temperature,
      feelsLike: feelsLike,
      tempMin: tempMin,
      tempMax: tempMax,
      humidity: humidity,
      pressure: pressure,
      windSpeed: windSpeed,
      description: description,
      icon: icon,
      main: main,
      sunrise: sunrise,
      sunset: sunset,
      visibility: visibility,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      dailyForecast: dailyForecast ?? this.dailyForecast,
    );
  }
}

class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final String icon;
  final String description;

  HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.icon,
    required this.description,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'] ?? '01d',
      description: json['weather'][0]['description'] ?? '',
    );
  }
}

class DailyForecast {
  final DateTime dateTime;
  final double tempMin;
  final double tempMax;
  final String icon;
  final String description;

  DailyForecast({
    required this.dateTime,
    required this.tempMin,
    required this.tempMax,
    required this.icon,
    required this.description,
  });
}
