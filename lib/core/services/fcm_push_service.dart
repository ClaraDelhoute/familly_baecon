import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:familly_baecon/core/config/app_config.dart';
import 'package:familly_baecon/core/network/dio_provider.dart';
import 'package:familly_baecon/core/services/anomaly_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmPushService {
  const FcmPushService._();

  static const String _logName = 'FcmPushService';
  static const String _pendingTokenKey = 'fcm_pending_token';
  static const String _registeredTokenKey = 'fcm_registered_token';
  static const Duration _firebaseTimeout = Duration(seconds: 12);
  static const Duration _tokenTimeout = Duration(seconds: 12);
  static const Duration _registerTimeout = Duration(seconds: 10);
  static const Duration _retryInterval = Duration(seconds: 60);
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final _FcmLifecycleObserver _lifecycleObserver =
      _FcmLifecycleObserver();
  static Timer? _retryTimer;
  static bool _isRegistering = false;
  static bool _isLifecycleObserverRegistered = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp().timeout(_firebaseTimeout);
      developer.log('Firebase initialized', name: _logName);
      await _requestPermission();
      await _retryPendingToken();
      await _registerCurrentToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        developer.log('FCM token refreshed', name: _logName);
        unawaited(_queueTokenForRegistration(token));
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _registerLifecycleObserver();
      _startRetryTimer();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Firebase disabled or failed to initialize. '
        'Check android/app/google-services.json and Google Play Services.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void retryPendingRegistration() {
    unawaited(_retryPendingToken());
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging
        .requestPermission(alert: true, badge: true, sound: true)
        .timeout(_tokenTimeout);
    developer.log(
      'Notification permission: ${settings.authorizationStatus.name}',
      name: _logName,
    );
  }

  static Future<void> _registerCurrentToken() async {
    final token = await _messaging.getToken().timeout(_tokenTimeout);
    if (token == null || token.isEmpty) {
      developer.log('No FCM token returned by Firebase', name: _logName);
      return;
    }
    developer.log('FCM token preview: ${_previewToken(token)}', name: _logName);
    developer.log(
      'FCM token received, registering to ${AppConfig.fcmTokenRegisterPath}',
      name: _logName,
    );
    await _queueTokenForRegistration(token);
  }

  static Future<void> _queueTokenForRegistration(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingTokenKey, token);
    unawaited(_retryPendingToken());
  }

  static Future<void> _retryPendingToken() async {
    if (_isRegistering) return;
    _isRegistering = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_pendingTokenKey);
      if (token == null || token.isEmpty) return;

      final registeredToken = prefs.getString(_registeredTokenKey);
      if (registeredToken == token) {
        developer.log(
          'Pending FCM token already registered, clearing queue',
          name: _logName,
        );
        await prefs.remove(_pendingTokenKey);
        return;
      }

      developer.log(
        'Retrying pending FCM token registration: ${_previewToken(token)}',
        name: _logName,
      );
      final registered = await _sendTokenToBackend(token);
      if (!registered) return;

      await prefs.setString(_registeredTokenKey, token);
      await prefs.remove(_pendingTokenKey);
    } finally {
      _isRegistering = false;
    }
  }

  static Future<bool> _sendTokenToBackend(String token) async {
    try {
      final response = await DioProvider.instance
          .post(
            AppConfig.fcmTokenRegisterPath,
            data: {
              'token': token,
              'platform': Platform.operatingSystem,
              'app': 'family_beacon',
            },
          )
          .timeout(_registerTimeout);
      developer.log(
        'FCM token registered, status ${response.statusCode}',
        name: _logName,
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (error, stackTrace) {
      developer.log(
        'Failed to register FCM token to backend',
        name: _logName,
        error: '${error.response?.statusCode} ${error.message}',
        stackTrace: stackTrace,
      );
      return false;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timed out while registering FCM token to backend',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      unawaited(_retryPendingToken());
    });
  }

  static void _registerLifecycleObserver() {
    if (_isLifecycleObserverRegistered) return;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _isLifecycleObserverRegistered = true;
  }

  static String _previewToken(String token) {
    if (token.length <= 16) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Alerte anomalie';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    if (body.isEmpty) return;

    unawaited(
      AnomalyNotificationService.showAnomalyAlert(
        id:
            message.messageId ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        message: body,
        severity: message.data['severity']?.toString() ?? 'medium',
      ),
    );
  }
}

class _FcmLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FcmPushService.retryPendingRegistration();
    }
  }
}
