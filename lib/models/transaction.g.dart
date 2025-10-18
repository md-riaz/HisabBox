// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      provider: $enumDecode(_$ProviderEnumMap, json['provider']),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      recipient: json['recipient'] as String?,
      sender: json['sender'] as String?,
      transactionId: json['transactionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
      rawMessage: json['rawMessage'] as String,
      synced: json['synced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': _$ProviderEnumMap[instance.provider]!,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'recipient': instance.recipient,
      'sender': instance.sender,
      'transactionId': instance.transactionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'note': instance.note,
      'rawMessage': instance.rawMessage,
      'synced': instance.synced,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ProviderEnumMap = {
  Provider.bkash: 'bkash',
  Provider.nagad: 'nagad',
  Provider.rocket: 'rocket',
  Provider.bank: 'bank',
  Provider.other: 'other',
};

const _$TransactionTypeEnumMap = {
  TransactionType.sent: 'sent',
  TransactionType.received: 'received',
  TransactionType.cashout: 'cashout',
  TransactionType.cashin: 'cashin',
  TransactionType.payment: 'payment',
  TransactionType.refund: 'refund',
  TransactionType.fee: 'fee',
  TransactionType.other: 'other',
};
