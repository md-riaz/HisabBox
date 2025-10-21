import 'package:hisabbox/models/transaction.dart';
import 'package:hisabbox/services/providers/bank/bank_sms_provider.dart';

class CityBankProvider extends BankSmsProvider {
  CityBankProvider() : super(Provider.cityBank, _senderIds, _senderIds);

  static const Set<String> _senderIds = {
    'citybank',
    'city-bank',
    'thecitybank',
    'cbl',
  };

  static final List<RegExp> _bodyIdentifiers = [
    RegExp(r'city\s+bank', caseSensitive: false),
    RegExp(r'\bcbl\b', caseSensitive: false),
  ];

  @override
  Set<String> get senderIds => _senderIds;

  @override
  List<RegExp> get bodyIdentifiers => _bodyIdentifiers;
}
