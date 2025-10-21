typedef VoidCallback = void Function();

VoidCallback? _invalidateCallback;

void registerSmsPreferencesInvalidator(VoidCallback callback) {
  _invalidateCallback = callback;
}

void invalidateSmsPreferencesCache() {
  final invalidate = _invalidateCallback;
  if (invalidate != null) {
    invalidate();
  }
}
