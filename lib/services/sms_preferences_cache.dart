typedef VoidCallback = void Function();

VoidCallback? _invalidateCallback;

void registerSmsPreferencesInvalidator(VoidCallback callback) {
  _invalidateCallback ??= callback;
}

void invalidateSmsPreferencesCache() {
  _invalidateCallback?.call();
}
