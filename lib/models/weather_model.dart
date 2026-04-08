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
  final String providerName;
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
    this.providerName = '',
    this.hourlyForecast = const [],
    this.dailyForecast = const [],
  });

  WeatherData copyWith({
    String? cityName,
    String? providerName,
    List<HourlyForecast>? hourlyForecast,
    List<DailyForecast>? dailyForecast,
  }) {
    return WeatherData(
      cityName: cityName ?? this.cityName,
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
      providerName: providerName ?? this.providerName,
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
