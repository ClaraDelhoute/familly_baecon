import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/config/app_config.dart';
import 'package:familly_baecon/core/mqtt/mqtt_service.dart';
import 'package:familly_baecon/core/network/dio_provider.dart';
import 'package:familly_baecon/core/services/settings_service.dart';
import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/journal/data/models/routine_activity_model.dart';
import 'package:familly_baecon/features/journal/data/datasources/journal_remote_datasource.dart';
import 'package:familly_baecon/features/journal/data/models/mqtt_alert_model.dart';
import 'package:familly_baecon/features/journal/data/models/notification_model.dart';
import 'package:familly_baecon/features/journal/data/models/sensor_event_model.dart';

final backendApiConnectedProvider = StateProvider<bool>((ref) => false);
final backendMqttConnectedProvider = StateProvider<bool>((ref) => false);
final backendLastSyncAtProvider = StateProvider<DateTime?>((ref) => null);
final backendSyncCounterProvider = StateProvider<int>((ref) => 0);

final _dioProvider = Provider((ref) => DioProvider.instance);
final _journalRemoteDataSourceProvider = Provider((ref) {
  return JournalRemoteDataSource(ref.watch(_dioProvider));
});
final _mqttServiceProvider = Provider((ref) {
  final suffix = Random().nextInt(1000000);
  return MqttService(
    server: AppConfig.mqttHost,
    port: AppConfig.mqttPort,
    clientId: 'familly_baecon_mobile_$suffix',
  );
});

final _settingsServiceProvider = Provider((ref) => SettingsService());

final forceBackendSyncProvider = Provider<Future<void> Function()>((ref) {
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  final settings = ref.watch(_settingsServiceProvider);

  return () async {
    final inAbsence = await settings.isInAbsence();
    if (inAbsence) return;

    try {
      await datasource.fetchActivities();
      ref.read(backendApiConnectedProvider.notifier).state = true;
      ref.read(backendLastSyncAtProvider.notifier).state = DateTime.now();
    } catch (error) {
      ref.read(backendApiConnectedProvider.notifier).state = false;
      rethrow;
    }
  };
});

final liveObservedActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  ref.watch(backendSyncCounterProvider);
  final controller = StreamController<List<Activity>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  final settings = ref.read(_settingsServiceProvider);
  Timer? timer;
  var disposed = false;
  var lastData = const <Activity>[];

  Future<void> load() async {
    if (disposed) return;
    try {
      final inAbsence = await settings.isInAbsence();
      if (disposed) return;
      if (inAbsence) {
        controller.add(lastData);
        return;
      }

      final now = DateTime.now();
      final activities = await datasource.fetchActivities(sinceHours: 48);
      if (disposed) return;
      final mapped = activities
          .map((activity) => activity.toDomain(fallbackDate: now))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      ref.read(backendApiConnectedProvider.notifier).state = true;
      ref.read(backendLastSyncAtProvider.notifier).state = DateTime.now();
      lastData = mapped;
      controller.add(lastData);
    } catch (error) {
      if (disposed) return;
      if (error is DioException) {
        ref.read(backendApiConnectedProvider.notifier).state = false;
      }
      controller.add(lastData);
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 45), (_) => unawaited(load()));

  ref.onDispose(() async {
    disposed = true;
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

final liveAlertsProvider = StreamProvider<List<AlertItem>>((ref) {
  ref.watch(backendSyncCounterProvider);
  final controller = StreamController<List<AlertItem>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  final mqttService = ref.watch(_mqttServiceProvider);
  final settings = ref.read(_settingsServiceProvider);
  var mqttAlerts = <AlertItem>[];
  var lastData = <AlertItem>[];
  Timer? timer;
  Timer? mqttDebounce;
  StreamSubscription<AlertItem>? mqttSubscription;
  var disposed = false;

  Future<void> load() async {
    if (disposed) return;
    try {
      final inAbsence = await settings.isInAbsence();
      if (disposed) return;
      if (inAbsence) {
        controller.add(_deduplicateAlerts(mqttAlerts).isEmpty ? lastData : _deduplicateAlerts(mqttAlerts));
        return;
      }

      final notifications = await datasource.fetchNotifications(limit: 100, sinceHours: 48);
      if (disposed) return;
      final mapped = [
        ...notifications.map(_notificationToAlert),
        ...mqttAlerts,
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final deduplicated = _deduplicateAlerts(mapped)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      ref.read(backendApiConnectedProvider.notifier).state = true;
      ref.read(backendLastSyncAtProvider.notifier).state = DateTime.now();
      lastData = deduplicated;
      controller.add(lastData);
    } catch (error) {
      if (disposed) return;
      if (error is DioException) {
        ref.read(backendApiConnectedProvider.notifier).state = false;
      }
      controller.add(lastData);
    }
  }

  unawaited(load());
  unawaited(() async {
    try {
      await mqttService.connect();
      if (disposed) return;
      ref.read(backendMqttConnectedProvider.notifier).state = true;
      mqttSubscription = mqttService
          .jsonMessages(AppConfig.mqttTopicAlerts)
          .map(MqttAlertModel.fromJson)
          .map((alert) => alert.toAlertItem())
          .listen((alert) {
            if (disposed) return;
            mqttAlerts = [alert, ...mqttAlerts].take(100).toList();
            // Debounce: batch rapid MQTT messages into a single reload
            mqttDebounce?.cancel();
            mqttDebounce = Timer(const Duration(milliseconds: 500), () {
              if (disposed) return;
              ref.read(backendSyncCounterProvider.notifier).state++;
              unawaited(load());
            });
          });
    } catch (_) {
      if (disposed) return;
      ref.read(backendMqttConnectedProvider.notifier).state = false;
    }
  }());
  timer = Timer.periodic(const Duration(seconds: 45), (_) => unawaited(load()));

  ref.onDispose(() async {
    disposed = true;
    mqttDebounce?.cancel();
    await mqttSubscription?.cancel();
    mqttService.disconnect();
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

final liveSensorEventsProvider = StreamProvider<List<SensorEventModel>>((ref) {
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  final controller = StreamController<List<SensorEventModel>>();
  Timer? timer;
  var disposed = false;
  var lastData = const <SensorEventModel>[];

  Future<void> load() async {
    if (disposed) return;
    try {
      final events = await datasource.fetchSensorEvents(days: 1, limit: 100);
      if (disposed) return;
      lastData = events;
      controller.add(lastData);
    } catch (error) {
      if (disposed) return;
      if (error is DioException) {
        ref.read(backendApiConnectedProvider.notifier).state = false;
      }
      controller.add(lastData);
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 60), (_) => unawaited(load()));

  ref.onDispose(() async {
    disposed = true;
    timer?.cancel();
    await controller.close();
  });
  return controller.stream;
});

final liveAnomaliesProvider = StreamProvider<List<AnomalyHistoryModel>>((ref) {
  ref.watch(backendSyncCounterProvider);
  final controller = StreamController<List<AnomalyHistoryModel>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  Timer? timer;
  var disposed = false;
  var lastData = const <AnomalyHistoryModel>[];

  Future<void> load() async {
    if (disposed) return;
    try {
      final anomalies = await datasource.fetchAnomalies(limit: 50);
      if (disposed) return;
      anomalies.sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
      lastData = anomalies;
      controller.add(lastData);
    } catch (error) {
      if (disposed) return;
      if (error is DioException) {
        ref.read(backendApiConnectedProvider.notifier).state = false;
      }
      controller.add(lastData);
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 60), (_) => unawaited(load()));
  ref.onDispose(() async {
    disposed = true;
    timer?.cancel();
    await controller.close();
  });
  return controller.stream;
});

final liveRoutineProvider =
    StreamProvider<List<RoutineActivityModel>>((ref) {
  ref.watch(backendSyncCounterProvider);
  final controller = StreamController<List<RoutineActivityModel>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  Timer? timer;
  var disposed = false;
  var lastData = const <RoutineActivityModel>[];
  // Routine calculée rarement côté backend — polling long suffit.
  const pollInterval = Duration(seconds: 120);

  Future<void> load() async {
    if (disposed) return;
    try {
      final routine = await datasource.fetchRoutine();
      if (disposed) return;
      // Ne pas écraser une routine non vide par [] (bref trou côté backend).
      if (routine.isEmpty && lastData.isNotEmpty) {
        controller.add(lastData);
        return;
      }
      lastData = routine;
      controller.add(lastData);
    } catch (error) {
      if (disposed) return;
      if (error is DioException) {
        ref.read(backendApiConnectedProvider.notifier).state = false;
      }
      controller.add(lastData);
    }
  }

  unawaited(load());
  timer = Timer.periodic(pollInterval, (_) => unawaited(load()));

  ref.onDispose(() async {
    disposed = true;
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

AlertItem _notificationToAlert(NotificationModel notification) {
  final lower = notification.message.toLowerCase();
  final anomalyType = _inferAnomalyTypeFromMessage(lower);
  final severity = _severityFromAnomalyType(anomalyType);

  return AlertItem(
    id: notification.id.toString(),
    title: _extractTitle(notification.message),
    description: notification.message,
    severity: severity,
    anomalyType: anomalyType,
    timestamp: notification.timestamp,
  );
}

String _extractTitle(String message) {
  if (message.contains('petit_dejeuner')) return 'Anomalie petit-déjeuner';
  if (message.contains('dejeuner')) return 'Anomalie déjeuner';
  if (message.contains('souper')) return 'Anomalie souper';
  if (message.contains('toilette')) return 'Anomalie toilettes';
  return 'Alerte activité';
}

List<AlertItem> _deduplicateAlerts(List<AlertItem> alerts) {
  final seen = <String>{};
  final deduplicated = <AlertItem>[];
  for (final alert in alerts) {
    final key = '${alert.description}_${alert.timestamp.toIso8601String()}';
    if (seen.add(key)) {
      deduplicated.add(alert);
    }
  }
  return deduplicated;
}

String _inferAnomalyTypeFromMessage(String lowerMessage) {
  if (lowerMessage.contains('missing') || lowerMessage.contains('manquant')) {
    return 'missing';
  }
  if (lowerMessage.contains('duration_long') ||
      lowerMessage.contains('durée longue') ||
      lowerMessage.contains('anormalement longue') ||
      lowerMessage.contains('trop long')) {
    return 'duration_long';
  }
  if (lowerMessage.contains('duration_short') ||
      lowerMessage.contains('durée courte') ||
      lowerMessage.contains('anormalement courte') ||
      lowerMessage.contains('trop court') ||
      lowerMessage.contains('trop courte')) {
    return 'duration_short';
  }
  if (lowerMessage.contains('freq_high') ||
      lowerMessage.contains('fréquence élevée') ||
      lowerMessage.contains('trop fréquent')) {
    return 'freq_high';
  }
  if (lowerMessage.contains('freq_low') ||
      lowerMessage.contains('fréquence faible') ||
      lowerMessage.contains('rare')) {
    return 'freq_low';
  }
  if (lowerMessage.contains('timing') ||
      lowerMessage.contains('horaire') ||
      lowerMessage.contains('inhabituel')) {
    return 'timing';
  }
  return 'timing';
}

String _severityFromAnomalyType(String anomalyType) {
  return switch (anomalyType) {
    'missing' || 'duration_long' || 'freq_high' => 'high',
    'timing' || 'duration_short' || 'freq_low' => 'medium',
    _ => 'medium',
  };
}
