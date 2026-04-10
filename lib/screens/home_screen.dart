import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../models/weather_agency.dart';
import '../services/open_meteo_provider.dart';
import '../widgets/weather_icon_helper.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAgencyId = 'best_match';
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  String _lastCity = '';

  WeatherAgency get _currentAgency =>
      weatherAgencies.firstWhere((a) => a.id == _currentAgencyId);

  OpenMeteoProvider get _provider =>
      OpenMeteoProvider(agency: _currentAgency);

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Position position = await _getCurrentPosition();
      final weather = await _provider.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _weatherData = weather;
        _lastCity = '';
        _isLoading = false;
      });
    } catch (e) {
      try {
        final weather = await _provider.getWeatherByCity('Seoul');
        setState(() {
          _weatherData = weather;
          _lastCity = 'Seoul';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              '${_currentAgency.name} 모델에서\n날씨 정보를 불러올 수 없습니다.';
        });
      }
    }
  }

  Future<void> _reloadWithAgency(String agencyId) async {
    setState(() {
      _currentAgencyId = agencyId;
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      WeatherData weather;
      if (_lastCity.isNotEmpty) {
        weather = await _provider.getWeatherByCity(_lastCity);
      } else if (_weatherData != null) {
        weather = await _provider.getWeatherByCity(_weatherData!.cityName);
      } else {
        weather = await _provider.getWeatherByCity('Seoul');
      }
      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            '${_currentAgency.name} 모델에서\n해당 지역의 데이터를 제공하지 않습니다.\n다른 기관을 선택해주세요.';
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('위치 서비스가 비활성화되어 있습니다');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _searchCity() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        final weather = await _provider.getWeatherByCity(result);
        setState(() {
          _weatherData = weather;
          _lastCity = result;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = '"$result" 도시를 찾을 수 없습니다';
        });
      }
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SettingsScreen(currentAgencyId: _currentAgencyId),
      ),
    );
    if (result != null && result != _currentAgencyId) {
      _reloadWithAgency(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _openSettings,
          tooltip: '기상 데이터 기관 선택',
        ),
        title: Text(
          _weatherData?.cityName ?? '날씨',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _searchCity),
          IconButton(
              icon: const Icon(Icons.my_location), onPressed: _loadWeather),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: WeatherIconHelper.getWeatherGradient('clear'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                '${_currentAgency.flag} ${_currentAgency.name}',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: WeatherIconHelper.getWeatherGradient('clear'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadWeather,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.tune),
                    label: const Text('기관 변경'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final weather = _weatherData!;
    return Container(
      decoration: BoxDecoration(
        gradient: WeatherIconHelper.getWeatherGradient(weather.main),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildCurrentWeather(weather),
                const SizedBox(height: 30),
                _buildHourlyForecast(weather),
                const SizedBox(height: 20),
                _buildDailyForecast(weather),
                const SizedBox(height: 20),
                _buildWeatherDetails(weather),
                const SizedBox(height: 12),
                _buildAgencyBadge(weather),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyBadge(WeatherData weather) {
    return GestureDetector(
      onTap: _openSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(weather.providerName,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(WeatherData weather) {
    return Column(
      children: [
        Icon(WeatherIconHelper.getWeatherIcon(weather.icon),
            size: 100, color: Colors.white),
        const SizedBox(height: 10),
        Text('${weather.temperature.round()}°',
            style: const TextStyle(
                fontSize: 80, fontWeight: FontWeight.w200, color: Colors.white)),
        Text(weather.description,
            style: const TextStyle(
                fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text('최고 ${weather.tempMax.round()}° / 최저 ${weather.tempMin.round()}°',
            style: const TextStyle(fontSize: 16, color: Colors.white60)),
        const SizedBox(height: 4),
        Text('체감온도 ${weather.feelsLike.round()}°',
            style: const TextStyle(fontSize: 14, color: Colors.white54)),
      ],
    );
  }

  Widget _buildHourlyForecast(WeatherData weather) {
    if (weather.hourlyForecast.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('시간별 예보',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weather.hourlyForecast.length,
              itemBuilder: (context, index) {
                final hourly = weather.hourlyForecast[index];
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(DateFormat('HH시').format(hourly.dateTime),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Icon(WeatherIconHelper.getWeatherIcon(hourly.icon),
                          color: Colors.white, size: 28),
                      Text('${hourly.temperature.round()}°',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast(WeatherData weather) {
    if (weather.dailyForecast.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('일별 예보',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...weather.dailyForecast.map((daily) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(DateFormat('E', 'ko').format(daily.dateTime),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                    ),
                    Icon(WeatherIconHelper.getWeatherIcon(daily.icon),
                        color: Colors.white, size: 24),
                    const Spacer(),
                    Text('${daily.tempMax.round()}°',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Text('${daily.tempMin.round()}°',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherData weather) {
    final sunrise =
        DateTime.fromMillisecondsSinceEpoch(weather.sunrise * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(weather.sunset * 1000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('상세 정보',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _detailItem(Icons.water_drop, '습도', '${weather.humidity}%')),
            Expanded(child: _detailItem(Icons.air, '바람', '${weather.windSpeed.toStringAsFixed(1)} m/s')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _detailItem(Icons.compress, '기압', '${weather.pressure} hPa')),
            Expanded(child: _detailItem(Icons.visibility, '가시거리', '${(weather.visibility / 1000).toStringAsFixed(1)} km')),
          ]),
          if (weather.sunrise > 0) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _detailItem(Icons.wb_twilight, '일출', DateFormat('HH:mm').format(sunrise))),
              Expanded(child: _detailItem(Icons.nightlight_round, '일몰', DateFormat('HH:mm').format(sunset))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.white60, size: 20),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}
