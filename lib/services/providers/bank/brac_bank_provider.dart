import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class BracBankProvider extends BankSmsProvider {
  BracBankProvider({Iterable<String>? senderIds})
    : super(Provider.bracBank, senderIds ?? defaultSenderIds, defaultSenderIds);

  static const List<String> defaultSenderIds = [
    'bracbank',
    'brac-bank',
    'brac',
  ];

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'brac\s+bank', caseSensitive: false),
  ];

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
