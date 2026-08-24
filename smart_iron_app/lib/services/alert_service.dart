import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/iron_status.dart';

abstract class AlertSink {
  Future<void> show(String key, String title, String body);
}

class LocalNotificationSink implements AlertSink {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> show(String key, String title, String body) => _plugin.show(
    key.hashCode & 0x7fffffff,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'smart_iron_safety',
        'Smart Iron safety alerts',
        channelDescription: 'Handle, shutdown, fault, and connection warnings',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    ),
  );
}

class AlertService {
  AlertService(this.sink);
  final AlertSink sink;
  final Set<String> _active = {};

  Future<void> evaluate(
    IronStatus? previous,
    IronStatus current, {
    required bool enabled,
  }) async {
    if (!enabled) return;
    final events = <String, (String, String)>{};
    if (current.power && !current.handle && current.countdown > 0) {
      events['handle'] = (
        'Handle released',
        'Automatic shutdown in ${current.countdown} seconds.',
      );
    }
    if (previous?.power == true &&
        !current.power &&
        current.fault == 'HANDLE INACTIVITY') {
      events['shutdown'] = (
        'Iron shut down',
        'The handle inactivity timer switched the iron off.',
      );
    }
    if (current.hasFault) {
      events['fault:${current.fault}'] = ('Smart Iron fault', current.fault);
    }
    for (final entry in events.entries) {
      if (_active.add(entry.key)) {
        await sink.show(entry.key, entry.value.$1, entry.value.$2);
      }
    }
    _active.removeWhere((key) => !events.containsKey(key));
  }

  Future<void> disconnectedWhileActive({required bool enabled}) async {
    if (enabled && _active.add('disconnect')) {
      await sink.show(
        'disconnect',
        'Smart Iron disconnected',
        'The connection was lost while the iron was active. Check it in person.',
      );
    }
  }
}
