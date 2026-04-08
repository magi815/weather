import 'package:flutter/material.dart';
import '../services/weather_provider.dart';

class SettingsScreen extends StatelessWidget {
  final WeatherProviderType currentProvider;

  const SettingsScreen({super.key, required this.currentProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('데이터 제공기관 설정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: weatherProviders.length,
          itemBuilder: (context, index) {
            final provider = weatherProviders[index];
            final isSelected = provider.type == currentProvider;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(40)
                    : Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: Colors.white54, width: 1.5)
                    : Border.all(color: Colors.white12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context, provider.type),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? Colors.white : Colors.white54,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (provider.requiresApiKey)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(60),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'API 키 필요',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(60),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '무료',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          provider.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.source, color: Colors.white54, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    '데이터 출처',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.dataSources,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
