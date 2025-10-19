import 'package:hisabbox/models/transaction.dart';

abstract class SmsProvider {
  Provider get provider;

  /// Returns `true` when the provider recognises the SMS sender or body.
  bool matches(String address, String message);

  /// Attempts to parse a [Transaction] from the SMS contents.
  Transaction? parse(String address, String message, DateTime timestamp);
}
