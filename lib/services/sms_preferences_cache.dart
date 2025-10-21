typedef SmsPreferencesInvalidator = void Function();

SmsPreferencesInvalidator? _invalidateCallback;

/// Registers the callback that invalidates the SMS preferences cache.
///
/// Returns `true` when the callback is registered for the first time and
/// `false` when an existing callback is kept. This keeps the registration
/// idempotent even if multiple parts of the app attempt to register an
/// invalidator concurrently (for example during hot reloads).
bool registerSmsPreferencesInvalidator(
  SmsPreferencesInvalidator callback,
) {
  if (_invalidateCallback == null) {
    _invalidateCallback = callback;
    return true;
  }

  return identical(_invalidateCallback, callback);
}

void invalidateSmsPreferencesCache() {
  _invalidateCallback?.call();
}
