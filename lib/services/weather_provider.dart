import '../models/weather_model.dart';

enum WeatherProviderType {
  openMeteo,
  openWeatherMap,
  wttrIn,
}

class WeatherProviderInfo {
  final WeatherProviderType type;
  final String name;
  final String description;
  final String dataSources;
  final bool requiresApiKey;

  const WeatherProviderInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.dataSources,
    this.requiresApiKey = false,
  });
}

const weatherProviders = [
  WeatherProviderInfo(
    type: WeatherProviderType.openMeteo,
    name: 'Open-Meteo',
    description: '오픈소스 날씨 API (API 키 불필요)',
    dataSources:
        'DWD (독일), NOAA (미국), ECMWF (유럽), Météo-France, '
        'Environment Canada, JMA (일본), KMA (한국), BOM (호주), Met Norway 등 '
        '각국 기상청의 수치예보 모델을 직접 통합',
  ),
  WeatherProviderInfo(
    type: WeatherProviderType.openWeatherMap,
    name: 'OpenWeatherMap',
    description: '82,000개 관측소 + 자체 AI 모델',
    dataSources:
        '전 세계 82,000개 지상 관측소, 기상위성, 레이더 네트워크, '
        'GFS/ECMWF 글로벌 모델 + 자체 OWHL™ 수치예보 모델. '
        'CNN 머신러닝으로 다중 소스 융합, 10분마다 갱신',
    requiresApiKey: true,
  ),
  WeatherProviderInfo(
    type: WeatherProviderType.wttrIn,
    name: 'wttr.in',
    description: '콘솔 친화적 날씨 서비스 (API 키 불필요)',
    dataSources:
        'Open-Meteo 등 외부 날씨 API를 백엔드로 사용하여 '
        '데이터를 가공/표시하는 프론트엔드 서비스. '
        '자체 데이터 수집 없이 다른 소스를 중계',
  ),
];

abstract class WeatherProvider {
  WeatherProviderType get type;
  String get name;

  Future<WeatherData> getWeatherByCity(String cityName);
  Future<WeatherData> getWeatherByLocation(double lat, double lon);
}
