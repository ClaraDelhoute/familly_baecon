import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/config/app_config.dart';
import 'package:familly_baecon/core/mqtt/mqtt_service.dart';
import 'package:familly_baecon/core/network/dio_provider.dart';
import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/journal/data/datasources/journal_remote_datasource.dart';
import 'package:familly_baecon/features/journal/data/models/mqtt_alert_model.dart';
import 'package:familly_baecon/features/journal/data/models/notification_model.dart';
import 'package:familly_baecon/features/journal/data/models/sensor_event_model.dart';

final _dioProvider = Provider((ref) => DioProvider.create());
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

final liveObservedActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  final controller = StreamController<List<Activity>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  Timer? timer;

  Future<void> load() async {
    try {
      final now = DateTime.now();
      final activities = await datasource.fetchActivities();
      final mapped = activities
          .map((activity) => activity.toDomain(fallbackDate: now))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      print('[APP] observed activities pushed=${mapped.length}');
      controller.add(mapped);
    } catch (error, stack) {
      if (error is DioException) {
        print('[APP] observed activities fallback empty (network error): ${error.message}');
        controller.add(const <Activity>[]);
      } else {
        print('[APP] observed activities stream error=$error');
        controller.addError(error, stack);
      }
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(load()));

  ref.onDispose(() async {
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

final liveAlertsProvider = StreamProvider<List<AlertItem>>((ref) {
  final controller = StreamController<List<AlertItem>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  final mqttService = ref.watch(_mqttServiceProvider);
  var mqttAlerts = <AlertItem>[];
  Timer? timer;
  StreamSubscription<AlertItem>? mqttSubscription;

  Future<void> load() async {
    try {
      final notifications = await datasource.fetchNotifications();
      final mapped = [
        ...notifications.map(_notificationToAlert),
        ...mqttAlerts,
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final deduplicated = _deduplicateAlerts(mapped)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      print('[APP] alerts pushed=${deduplicated.length} (rest=${notifications.length}, mqtt=${mqttAlerts.length})');
      controller.add(deduplicated);
    } catch (error, stack) {
      if (error is DioException) {
        print('[APP] alerts fallback mqtt-only=${mqttAlerts.length} (network error): ${error.message}');
        controller.add(_deduplicateAlerts(mqttAlerts));
      } else {
        print('[APP] alerts stream error=$error');
        controller.addError(error, stack);
      }
    }
  }

  unawaited(load());
  unawaited(() async {
    try {
      await mqttService.connect();
      print('[APP] MQTT channel connected, waiting alerts...');
      mqttSubscription = mqttService
          .jsonMessages(AppConfig.mqttTopicAlerts)
          .map(MqttAlertModel.fromJson)
          .map((alert) => alert.toAlertItem())
          .listen((alert) {
            mqttAlerts = [alert, ...mqttAlerts].take(100).toList();
            print('[APP] mqtt alert received id=${alert.id} totalMqtt=${mqttAlerts.length}');
            unawaited(load());
          });
    } catch (_) {
      print('[APP] MQTT unavailable, REST polling remains active');
      // keep REST polling active even if MQTT is unavailable
    }
  }());
  timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(load()));

  ref.onDispose(() async {
    await mqttSubscription?.cancel();
    mqttService.disconnect();
    timer?.cancel();
    await controller.close();
  });

  return controller.stream;
});

final liveSensorEventsProvider = StreamProvider<List<SensorEventModel>>((ref) {
  final controller = StreamController<List<SensorEventModel>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  Timer? timer;

  Future<void> load() async {
    try {
      final events = await datasource.fetchSensorEvents(limit: 50);
      print('[APP] sensor events pushed=${events.length}');
      controller.add(events..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
    } catch (error, stack) {
      if (error is DioException) {
        print('[APP] sensor events fallback empty (network error): ${error.message}');
        controller.add(const <SensorEventModel>[]);
      } else {
        print('[APP] sensor events stream error=$error');
        controller.addError(error, stack);
      }
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(load()));
  ref.onDispose(() async {
    timer?.cancel();
    await controller.close();
  });
  return controller.stream;
});

final liveAnomaliesProvider = StreamProvider<List<AnomalyHistoryModel>>((ref) {
  final controller = StreamController<List<AnomalyHistoryModel>>();
  final datasource = ref.watch(_journalRemoteDataSourceProvider);
  Timer? timer;

  Future<void> load() async {
    try {
      final anomalies = await datasource.fetchAnomalies(limit: 100);
      anomalies.sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
      print('[APP] anomalies pushed=${anomalies.length}');
      controller.add(anomalies);
    } catch (error, stack) {
      if (error is DioException) {
        print('[APP] anomalies fallback empty (network error): ${error.message}');
        controller.add(const <AnomalyHistoryModel>[]);
      } else {
        print('[APP] anomalies stream error=$error');
        controller.addError(error, stack);
      }
    }
  }

  unawaited(load());
  timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(load()));
  ref.onDispose(() async {
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
      lowerMessage.contains('trop long')) {
    return 'duration_long';
  }
  if (lowerMessage.contains('duration_short') ||
      lowerMessage.contains('durée courte') ||
      lowerMessage.contains('trop court')) {
    return 'duration_short';
  }
  if (lowerMessage.contains('freq_high') || lowerMessage.contains('fréquence élevée')) {
    return 'freq_high';
  }
  if (lowerMessage.contains('freq_low') || lowerMessage.contains('fréquence faible')) {
    return 'freq_low';
  }
  if (lowerMessage.contains('timing') || lowerMessage.contains('horaire')) {
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
