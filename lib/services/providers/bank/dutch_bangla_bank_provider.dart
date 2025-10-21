import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class DutchBanglaBankProvider extends BankSmsProvider {
  DutchBanglaBankProvider()
      : super(Provider.dutchBanglaBank, _senderIds, _senderIds);

  static const Set<String> _senderIds = {'dbbl', 'dutch-bangla', 'dutchbangla'};

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'dutch[-\s]?bangla', caseSensitive: false),
    RegExp(r'\bdbbl\b', caseSensitive: false),
  ];

  @override
  Set<String> get senderIds => _senderIds;

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
