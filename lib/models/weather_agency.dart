class WeatherAgency {
  final String id;
  final String name;
  final String country;
  final String flag;
  final String description;
  final String modelParam; // Open-Meteo API models= parameter value
  final String resolution;
  final String coverage;

  const WeatherAgency({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.description,
    required this.modelParam,
    required this.resolution,
    required this.coverage,
  });
}

const List<WeatherAgency> weatherAgencies = [
  WeatherAgency(
    id: 'best_match',
    name: '자동 (최적 조합)',
    country: '글로벌',
    flag: '🌍',
    description: 'Open-Meteo가 위치에 따라 최적의 모델을 자동 선택합니다',
    modelParam: 'best_match',
    resolution: '1~11 km',
    coverage: '전 세계',
  ),
  WeatherAgency(
    id: 'kma',
    name: 'KMA 기상청',
    country: '한국',
    flag: '🇰🇷',
    description: '한국기상청 GDPS + LDPS (자동 통합)',
    modelParam: 'kma_seamless',
    resolution: '12 km / 1.5 km',
    coverage: '전 세계 + 한반도 상세',
  ),
  WeatherAgency(
    id: 'dwd',
    name: 'DWD',
    country: '독일',
    flag: '🇩🇪',
    description: '독일기상청 ICON 글로벌 + 유럽 + D2',
    modelParam: 'icon_seamless',
    resolution: '11 km / 7 km / 2 km',
    coverage: '전 세계 + 유럽 상세',
  ),
  WeatherAgency(
    id: 'noaa',
    name: 'NOAA',
    country: '미국',
    flag: '🇺🇸',
    description: '미국 해양대기청 GFS + HRRR (자동 통합)',
    modelParam: 'gfs_seamless',
    resolution: '13 km / 3 km',
    coverage: '전 세계 + 북미 상세',
  ),
  WeatherAgency(
    id: 'ecmwf',
    name: 'ECMWF',
    country: '유럽',
    flag: '🇪🇺',
    description: '유럽 중기예보센터 IFS',
    modelParam: 'ecmwf_ifs025',
    resolution: '25 km',
    coverage: '전 세계',
  ),
  WeatherAgency(
    id: 'meteofrance',
    name: 'Météo-France',
    country: '프랑스',
    flag: '🇫🇷',
    description: '프랑스 기상청 ARPEGE + AROME (자동 통합)',
    modelParam: 'meteofrance_seamless',
    resolution: '25 km / 2.5 km',
    coverage: '전 세계 + 유럽 상세',
  ),
  WeatherAgency(
    id: 'jma',
    name: 'JMA',
    country: '일본',
    flag: '🇯🇵',
    description: '일본 기상청 GSM + MSM (자동 통합)',
    modelParam: 'jma_seamless',
    resolution: '55 km / 5 km',
    coverage: '전 세계 + 일본 상세',
  ),
  WeatherAgency(
    id: 'ukmo',
    name: 'Met Office',
    country: '영국',
    flag: '🇬🇧',
    description: '영국 기상청 UKMO (자동 통합)',
    modelParam: 'ukmo_seamless',
    resolution: '10 km / 2 km',
    coverage: '전 세계 + 영국 상세',
  ),
  WeatherAgency(
    id: 'cmc',
    name: 'CMC',
    country: '캐나다',
    flag: '🇨🇦',
    description: '캐나다 기상센터 GEM (자동 통합)',
    modelParam: 'gem_seamless',
    resolution: '15 km / 2.5 km',
    coverage: '전 세계 + 캐나다 상세',
  ),
  WeatherAgency(
    id: 'bom',
    name: 'BOM',
    country: '호주',
    flag: '🇦🇺',
    description: '호주 기상국 ACCESS 글로벌',
    modelParam: 'bom_access_global',
    resolution: '15 km',
    coverage: '전 세계',
  ),
  WeatherAgency(
    id: 'cma',
    name: 'CMA',
    country: '중국',
    flag: '🇨🇳',
    description: '중국 기상국 GRAPES 글로벌',
    modelParam: 'cma_grapes_global',
    resolution: '13 km',
    coverage: '전 세계',
  ),
  WeatherAgency(
    id: 'metno',
    name: 'MET Norway',
    country: '노르웨이',
    flag: '🇳🇴',
    description: '노르웨이 기상연구소 Nordic (자동 통합)',
    modelParam: 'metno_seamless',
    resolution: '1 km',
    coverage: '북유럽 전용',
  ),
];
