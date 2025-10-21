import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class BankAsiaProvider extends BankSmsProvider {
  BankAsiaProvider() : super(Provider.bankAsia, _senderIds, _senderIds);

  static const Set<String> _senderIds = {'bankasia', 'bank-asia'};

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'bank\s+asia', caseSensitive: false),
  ];

  @override
  Set<String> get senderIds => _senderIds;

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
