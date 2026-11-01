import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig({
    this.mode = 'search',
    this.language = 'ar',
    this.theme = 'system',
    this.proxyUrl = '',
    this.model = '',
    this.historyLimit = 12,
  });
  final String mode;
  final String language;
  final String theme;
  final String proxyUrl;
  final String model;
  final int historyLimit;
  ThemeMode get themeMode => switch (theme) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
  AppConfig withMode(String mode) => AppConfig(
    mode: mode,
    language: language,
    theme: theme,
    proxyUrl: proxyUrl,
    model: model,
    historyLimit: historyLimit,
  );
  factory AppConfig.fromMap(Map<String, String> map) => AppConfig(
    mode: map['mode'] == 'chat' ? 'chat' : 'search',
    language: map['language'] == 'en' ? 'en' : 'ar',
    theme: map['theme'] ?? 'system',
    proxyUrl: map['proxyUrl'] ?? '',
    model: map['model'] ?? '',
    historyLimit: (int.tryParse(map['historyLimit'] ?? '') ?? 12).clamp(1, 50),
  );
  Map<String, String> toMap() => {
    'mode': mode,
    'language': language,
    'theme': theme,
    'proxyUrl': proxyUrl,
    'model': model,
    'historyLimit': '$historyLimit',
  };
}
