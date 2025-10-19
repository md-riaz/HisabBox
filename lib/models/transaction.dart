import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('sent')
  sent,
  @JsonValue('received')
  received,
  @JsonValue('cashout')
  cashout,
  @JsonValue('cashin')
  cashin,
  @JsonValue('payment')
  payment,
  @JsonValue('refund')
  refund,
  @JsonValue('fee')
  fee,
  @JsonValue('other')
  other,
}

enum Provider {
  @JsonValue('bkash')
  bkash,
  @JsonValue('nagad')
  nagad,
  @JsonValue('rocket')
  rocket,
  @JsonValue('bank')
  bank,
  @JsonValue('other')
  other,
}

@JsonSerializable()
class Transaction {
  final String id;
  final Provider provider;
  final TransactionType type;
  final double amount;
  final String? recipient;
  final String? sender;
  final String transactionId;
  final String transactionHash;
  final DateTime timestamp;
  final String? note;
  final String rawMessage;
  final bool synced;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.provider,
    required this.type,
    required this.amount,
    this.recipient,
    this.sender,
    required this.transactionId,
    required this.transactionHash,
    required this.timestamp,
    this.note,
    required this.rawMessage,
    this.synced = false,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider.name,
      'type': type.name,
      'amount': amount,
      'recipient': recipient,
      'sender': sender,
      'transactionId': transactionId,
      'transactionHash': transactionHash,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'rawMessage': rawMessage,
      'synced': synced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    final timestamp = DateTime.parse(map['timestamp'] as String);
    final hash = (map['transactionHash'] as String?) ??
        Transaction.generateHash(
          counterparty:
              (map['sender'] as String?) ?? (map['recipient'] as String?),
          messageBody: map['rawMessage'] as String,
          timestamp: timestamp,
        );

    return Transaction(
      id: map['id'] as String,
      provider: Provider.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => Provider.other,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.other,
      ),
      amount: (map['amount'] as num).toDouble(),
      recipient: map['recipient'] as String?,
      sender: map['sender'] as String?,
      transactionId: map['transactionId'] as String,
      transactionHash: hash,
      timestamp: timestamp,
      note: map['note'] as String?,
      rawMessage: map['rawMessage'] as String,
      synced: (map['synced'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Transaction copyWith({
    String? id,
    Provider? provider,
    TransactionType? type,
    double? amount,
    String? recipient,
    String? sender,
    String? transactionId,
    String? transactionHash,
    DateTime? timestamp,
    String? note,
    String? rawMessage,
    bool? synced,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      sender: sender ?? this.sender,
      transactionId: transactionId ?? this.transactionId,
      transactionHash: transactionHash ?? this.transactionHash,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      rawMessage: rawMessage ?? this.rawMessage,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String generateHash({
    String? counterparty,
    required String messageBody,
    required DateTime timestamp,
  }) {
    final buffer = StringBuffer()
      ..write(counterparty ?? '')
      ..write('|')
      ..write(messageBody)
      ..write('|')
      ..write(timestamp.toIso8601String());
    final bytes = utf8.encode(buffer.toString());
    return sha256.convert(bytes).toString();
  }
}
