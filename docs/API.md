# API Documentation

## Database Service

### `DatabaseService.instance`

Singleton instance of the database service.

### Methods

#### `insertTransaction(Transaction transaction)`
Insert a new transaction into the database.

**Parameters:**
- `transaction`: Transaction object to insert

**Returns:** `Future<String>` - ID of the inserted transaction

**Example:**
```dart
final transaction = Transaction(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  provider: Provider.bkash,
  type: TransactionType.sent,
  amount: 1000.0,
  transactionId: 'TRX123',
  timestamp: DateTime.now(),
  rawMessage: 'SMS message here',
  createdAt: DateTime.now(),
);
await DatabaseService.instance.insertTransaction(transaction);
```

#### `getTransactions({providers, types, startDate, endDate, limit, offset})`
Retrieve transactions with optional filtering.

**Parameters:**
- `providers`: List<Provider>? - Filter by providers
- `types`: List<TransactionType>? - Filter by transaction types
- `startDate`: DateTime? - Start date filter
- `endDate`: DateTime? - End date filter
- `limit`: int? - Maximum number of results
- `offset`: int? - Pagination offset

**Returns:** `Future<List<Transaction>>`

**Example:**
```dart
final transactions = await DatabaseService.instance.getTransactions(
  providers: [Provider.bkash, Provider.nagad],
  types: [TransactionType.received, TransactionType.sent],
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime.now(),
  limit: 50,
);
```

#### `getUnsyncedTransactions()`
Get all transactions that haven't been synced to webhook.

**Returns:** `Future<List<Transaction>>`

#### `markAsSynced(String id)`
Mark a transaction as synced.

**Parameters:**
- `id`: Transaction ID

**Returns:** `Future<int>` - Number of rows updated

#### `deleteTransaction(String id)`
Delete a transaction.

**Parameters:**
- `id`: Transaction ID

**Returns:** `Future<int>` - Number of rows deleted

#### `getTransactionCount({providers})`
Get total count of transactions.

**Parameters:**
- `providers`: List<Provider>? - Filter by providers

**Returns:** `Future<int>`

#### `getTotalAmount({providers, type})`
Calculate total amount for transactions.

**Parameters:**
- `providers`: List<Provider>? - Filter by providers
- `type`: TransactionType? - Filter by transaction type

**Returns:** `Future<double>`

---

## SMS Parser Service

### `SmsParser.parse(address, message, timestamp)`

Parse an SMS message into a Transaction object.

**Parameters:**
- `address`: String - SMS sender address
- `message`: String - SMS message body
- `timestamp`: DateTime - Message timestamp

**Returns:** `Transaction?` - Parsed transaction or null if not recognized

**Example:**
```dart
final transaction = SmsParser.parse(
  'bKash',
  'You have sent Tk1,500.00 to 01712345678. TrxID ABC123',
  DateTime.now(),
);
```

---

## SMS Service

### `SmsService.instance`

Singleton instance of the SMS service.

### Methods

#### `initialize()`
Initialize SMS monitoring.

**Returns:** `Future<void>`

#### `importHistoricalSms({startDate, endDate})`
Import historical SMS messages from inbox.

**Parameters:**
- `startDate`: DateTime? - Start date for import
- `endDate`: DateTime? - End date for import

**Returns:** `Future<void>`

**Example:**
```dart
await SmsService.instance.importHistoricalSms(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime.now(),
);
```

---

## Webhook Service

### Static Methods

#### `getWebhookUrl()`
Get the configured webhook URL.

**Returns:** `Future<String?>`

#### `setWebhookUrl(String url)`
Set the webhook URL.

**Parameters:**
- `url`: Webhook endpoint URL

**Returns:** `Future<void>`

#### `isWebhookEnabled()`
Check if webhook sync is enabled.

**Returns:** `Future<bool>`

#### `setWebhookEnabled(bool enabled)`
Enable or disable webhook sync.

**Parameters:**
- `enabled`: Boolean flag

**Returns:** `Future<void>`

#### `isAutoSyncEnabled()`
Check whether automatic syncing is enabled.

**Returns:** `Future<bool>`

#### `setAutoSyncEnabled(bool enabled)`
Update the auto-sync flag stored in shared preferences.

**Parameters:**
- `enabled`: Boolean flag

**Returns:** `Future<void>`

#### `processNewTransaction(Transaction transaction)`
Process a newly captured transaction and trigger background sync when auto-sync is enabled.

**Parameters:**
- `transaction`: Newly inserted transaction

**Returns:** `Future<void>`

#### `syncTransactions()`
Sync all unsynced transactions to webhook.

**Returns:** `Future<void>`

**Example:**
```dart
await WebhookService.setWebhookUrl('https://example.com/webhook');
await WebhookService.setWebhookEnabled(true);
await WebhookService.syncTransactions();
```

#### `testWebhook(String url)`
Test webhook connectivity.

**Parameters:**
- `url`: Webhook URL to test

**Returns:** `Future<bool>` - True if successful

---

## Provider Settings Service

### Overview

Utility for persisting enabled/disabled flags for each SMS provider. These
preferences are accessible from both the UI and background isolates to ensure
disabled providers are ignored everywhere.

### Static Methods

#### `isProviderEnabled(Provider provider)`
Check whether a provider is enabled.

**Parameters:**
- `provider`: Provider to check

**Returns:** `Future<bool>`

#### `setProviderEnabled(Provider provider, bool enabled)`
Persist the enabled state for a provider.

**Parameters:**
- `provider`: Provider to update
- `enabled`: Boolean flag

**Returns:** `Future<void>`

#### `getProviderSettings()`
Return a map containing the enabled flag for every provider.

**Returns:** `Future<Map<Provider, bool>>`

#### `getEnabledProviders()`
Convenience helper that returns just the list of enabled providers.

**Returns:** `Future<List<Provider>>`

---

## Transaction Controller

### Properties

- `transactions`: RxList<Transaction> - Current transaction list
- `isLoading`: RxBool - Loading state
- `activeProviders`: RxList<Provider> - Currently active provider filters
- `totalSent`: double - Total amount sent (computed)
- `totalReceived`: double - Total amount received (computed)
- `balance`: double - Current balance (computed)

### Methods

#### `loadTransactions({startDate, endDate, limit = 30})`
Load transactions from the database.

**Parameters:**
- `startDate`: DateTime? - Start date filter
- `endDate`: DateTime? - End date filter
- `limit`: int - Maximum number of rows to fetch (defaults to the 30 most recent transactions)

**Returns:** `Future<void>`

#### `addTransaction(Transaction transaction)`
Add a new transaction.

**Parameters:**
- `transaction`: Transaction to add

**Returns:** `Future<void>`

#### `deleteTransaction(String id)`
Delete a transaction.

**Parameters:**
- `id`: Transaction ID

**Returns:** `Future<void>`

#### `setActiveProviders(List<Provider> providers)`
Update active provider filters.

**Parameters:**
- `providers`: List of providers to show

**Returns:** `Future<void>`

#### `syncWithWebhook()`
Trigger webhook synchronization.

**Returns:** `Future<void>`

**Usage Example:**
```dart
final controller = Get.find<TransactionController>();
await controller.loadTransactions();
await controller.setActiveProviders([Provider.bkash, Provider.nagad]);
```

---

## Settings Controller

### Properties

- `webhookEnabled`: RxBool - Webhook sync enabled
- `webhookUrl`: RxString - Webhook URL
- `autoSync`: RxBool - Auto-sync enabled
- `providerSettings`: RxMap<Provider, bool> - Enabled/disabled state for each provider
- `enabledProviders`: List<Provider> - Convenience list of enabled providers

### Methods

#### `loadSettings()`
Load settings from storage.

**Returns:** `Future<void>`

#### `setWebhookEnabled(bool enabled)`
Enable/disable webhook.

**Parameters:**
- `enabled`: Boolean flag

**Returns:** `Future<void>`

#### `setWebhookUrl(String url)`
Set webhook URL.

**Parameters:**
- `url`: Webhook endpoint URL

**Returns:** `Future<void>`

#### `setAutoSync(bool enabled)`
Enable/disable auto-sync.

**Parameters:**
- `enabled`: Boolean flag

**Returns:** `Future<void>`

#### `setProviderEnabled(Provider provider, bool enabled)`
Enable or disable SMS ingestion for a provider.

**Parameters:**
- `provider`: Provider to update
- `enabled`: True to capture SMS, false to ignore

**Returns:** `Future<void>`

#### `testWebhook()`
Test configured webhook.

**Returns:** `Future<bool>`

---

## Models

### Transaction

Main data model for financial transactions.

**Properties:**
- `id`: String - Unique identifier
- `provider`: Provider - Payment provider
- `type`: TransactionType - Transaction type
- `amount`: double - Transaction amount
- `recipient`: String? - Recipient phone/account
- `sender`: String? - Sender phone/account
- `transactionId`: String - Provider transaction ID
- `timestamp`: DateTime - Transaction time
- `note`: String? - Additional notes
- `rawMessage`: String - Original SMS message
- `synced`: bool - Sync status
- `createdAt`: DateTime - Record creation time

**Methods:**
- `toMap()`: Convert to Map
- `fromMap(map)`: Create from Map
- `toJson()`: Convert to JSON
- `fromJson(json)`: Create from JSON
- `copyWith()`: Create copy with modifications

### Provider Enum

```dart
enum Provider {
  bkash,
  nagad,
  rocket,
  bank,
  other,
}
```

### TransactionType Enum

```dart
enum TransactionType {
  sent,
  received,
  cashout,
  cashin,
  payment,
  refund,
  fee,
  other,
}
```

---

## Permission Service

### Static Methods

#### `requestPermissions()`
Request all required permissions.

**Returns:** `Future<bool>` - True if all granted

#### `checkPermissions()`
Check current permission status.

**Returns:** `Future<bool>` - True if all granted

#### `openSettings()`
Open app settings for manual permission grant.

**Returns:** `Future<void>`

**Example:**
```dart
final granted = await PermissionService.requestPermissions();
if (!granted) {
  await PermissionService.openSettings();
}
```

---

## Error Handling

All async methods may throw exceptions. Wrap calls in try-catch blocks:

```dart
try {
  await DatabaseService.instance.insertTransaction(transaction);
} catch (e) {
  print('Error: $e');
  // Handle error
}
```

---

## Testing

### Mocking Services

For testing, you can mock services:

```dart
class MockDatabaseService extends DatabaseService {
  @override
  Future<List<Transaction>> getTransactions() async {
    return [/* mock data */];
  }
}
```

### Testing SMS Parser

```dart
test('parses bKash sent transaction', () {
  final transaction = SmsParser.parse(
    'bKash',
    'You have sent Tk1,500.00 to 01712345678. TrxID ABC123',
    DateTime.now(),
  );
  expect(transaction, isNotNull);
  expect(transaction!.amount, 1500.0);
});
```

---

## Best Practices

1. **Error Handling**: Always handle potential errors
2. **Resource Cleanup**: Close database connections when done
3. **Null Safety**: Check for null values
4. **Async/Await**: Use async/await for asynchronous operations
5. **State Management**: Use Provider for state updates
6. **Testing**: Write tests for critical functionality
