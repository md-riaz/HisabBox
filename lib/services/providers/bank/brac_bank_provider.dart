import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class BracBankProvider extends BankSmsProvider {
  BracBankProvider() : super(Provider.bracBank);

  static const Set<String> _senderIds = {'bracbank', 'brac-bank', 'brac'};

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'brac\s+bank', caseSensitive: false),
  ];

  @override
  Set<String> get senderIds => _senderIds;

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
