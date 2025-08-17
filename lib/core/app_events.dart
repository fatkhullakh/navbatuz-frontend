import 'package:flutter/foundation.dart';

class AppEvents {
  /// Increment when appointments are created/cancelled so home can refresh.
  static final ValueNotifier<int> appointmentsChanged = ValueNotifier<int>(0);
}
