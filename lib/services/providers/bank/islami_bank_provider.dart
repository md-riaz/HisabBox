import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class IslamiBankProvider extends BankSmsProvider {
  IslamiBankProvider() : super(Provider.islamiBank, _senderIds, _senderIds);

  static const Set<String> _senderIds = {'islami', 'ibbl', 'islami-bank'};

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'islami\s+bank', caseSensitive: false),
    RegExp(r'\bibbl\b', caseSensitive: false),
  ];

  @override
  Set<String> get senderIds => _senderIds;

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
