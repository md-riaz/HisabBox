# HisabBox

HisabBox is a persistent, webhook-driven SMS automation hub for Bangladesh’s mobile money ecosystem. It converts bKash, Nagad, Rocket, and bank alerts into structured JSON, stores them locally, and pushes each transaction to your webhook the moment connectivity is available.

## Vision

Deliver a **local-first transaction gateway** that never misses a financial SMS, keeps the data in the user’s control, and provides a push-only bridge to downstream automation or accounting systems.

## Product Pillars

1. **Persistent Capture** – Native receivers and a foreground service keep listening even after app kills or device reboots.
2. **Provider Control** – Users decide which mobile financial services and banks are parsed.
3. **Offline Resilience** – Transactions are stored in SQLite/Drift and queued until the internet returns.
4. **Webhook-Only Automation** – Structured payloads are POSTed to the user’s endpoint with WorkManager retries and no polling.
5. **Privacy & Transparency** – Data never leaves the device unless a webhook is explicitly configured.

## Feature Highlights

- **Automatic SMS Parsing** for bKash, Nagad, Rocket, and Bangladeshi bank alerts with Bangla/English digit normalization.
- **Provider Toggles** so Rocket or any other sender can be paused without uninstalling the app.
- **Historical Imports** by message count or time range to backfill older statements.
- **Material 3 Dashboard** showing the most recent 20–30 transactions with provider colors, amounts, balances, and TrxIDs.
- **Webhook Push Engine** powered by Dio + WorkManager, featuring exponential backoff and idempotent transaction hashes.
- **Offline Queueing & Recovery** to guarantee delivery once connectivity resumes.
- **Error Log & Privacy Controls** including optional app lock and local-only diagnostics.

## Core Scenarios

### Dashboard
View the latest transactions in a responsive list with provider filters and Bangla/English language toggle. Cards surface transaction type, amount, balance (when available), timestamp, and TrxID at a glance.

### Provider Control
Enable or disable individual providers from Settings. Disabled senders are ignored during live listening and historical imports.

### SMS Capture Control
Choose between **Start Listening Now** for future messages or **Import History** to backfill the last _N_ messages per provider.

### Persistent Background Operation
The `another_telephony` plugin delivers SMS to a Dart background isolate that inserts transactions into Drift instantly, ensuring persistence even when the Flutter runtime is stopped or the device reboots.

### Webhook Push
Configure a webhook URL to receive JSON payloads for every new transaction. Failed deliveries retry automatically with exponential backoff until acknowledged.

### Maintenance Utilities
Reimport recent SMS, purge old data to reclaim space, or export CSV backups for manual bookkeeping.

## Goals & Success Criteria

The product roadmap is anchored by twelve acceptance criteria:

1. Capture and display SMS in real time.
2. Continue ingesting after the app is killed.
3. Respect provider disablement settings.
4. Parse historical messages on demand.
5. Push to webhook immediately when configured.
6. Retry failures without data loss.
7. Resume seamlessly after device reboot.
8. Deduplicate duplicate SMS by transaction hash.
9. Queue offline transactions until connectivity returns.
10. Refresh regex registries dynamically when updated.
11. Provide clear guidance when permissions are missing.
12. Operate through power-saving constraints.

## System Architecture

### End-to-End Flow
```
[SMS Provider]
     ↓
[another_telephony plugin background isolate]
     ↓
[Parser Engine & Provider Registry]
     ↓
[SQLite (Drift) Persistence]
     ↓
[Dashboard UI / Settings]
     ↓
[Webhook Sync Worker (Dio + WorkManager)]
     ↓
[User Webhook Endpoint]
```

### Key Components

- **Models** – `Transaction` aggregates parsed metadata plus raw SMS and MD5-based transaction hash.
- **Services** – `SmsService`, `ProviderSettingsService`, `WebhookService`, `DatabaseService`, and `PermissionService` encapsulate business logic.
- **Controllers** – `TransactionController` and `SettingsController` expose reactive state via GetX.
- **UI Screens** – Dashboard, Settings, Import, and optional Error Log/App Lock surfaces.

### Technology Stack

| Domain | Technology |
| --- | --- |
| Framework | Flutter ≥ 3.24 (Dart 3) |
| State Management | GetX |
| Persistence | Drift (SQLite) |
| Settings | SharedPreferences |
| Background Tasks | WorkManager + another_telephony background isolate |
| Networking | Dio |
| SMS Handling | another_telephony plugin (Dart background callback) |
| Dependency Injection | GetX service locator |
| Logging | Local-only logger |

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android SDK (minSdk 23, targetSdk 36)
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/md-riaz/HisabBox.git
cd HisabBox
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Permissions

The app requires the following Android permissions:
- `READ_SMS`: To read SMS messages
- `RECEIVE_SMS`: To receive new SMS messages
- `POST_NOTIFICATIONS`: For background notifications
- `INTERNET`: For webhook synchronization
- `WAKE_LOCK`: To keep service running
- `RECEIVE_BOOT_COMPLETED`: To restart monitoring after reboot

## Usage

### First Time Setup
1. Launch the app
2. Grant SMS and notification permissions
3. Optionally configure webhook in Settings
4. Import historical SMS messages if needed

### Webhook Configuration
1. Go to Settings
2. Enable webhook
3. Enter your webhook URL
4. Test the connection
5. Enable auto-sync if desired

### Filtering Transactions
- Use provider filter chips on dashboard
- Select/deselect providers (bKash, Nagad, Rocket, Bank)
- Transactions update automatically

### Provider Toggles & Import Controls
- Navigate to **Settings → Provider Control** to disable Rocket or any other sender.
- Choose **Start Listening Now** for live capture or **Import History** to backfill older messages.

### Importing Historical Data
1. Tap import icon in dashboard
2. Select date range
3. Tap "Import SMS"
4. Wait for processing to complete

## Data Privacy

- All transaction data is stored locally on device
- Webhook sync is optional and disabled by default
- No data is collected or stored by the app developers
- Users have complete control over their data

## Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── transaction.dart
├── controllers/              # State management
│   ├── transaction_controller.dart
│   └── settings_controller.dart
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── settings_screen.dart
│   └── import_screen.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── providers/
│   │   ├── base_sms_provider.dart
│   │   └── ...
│   ├── sms_service.dart
│   ├── webhook_service.dart
│   └── permission_service.dart
└── widgets/                  # Reusable widgets
    ├── transaction_card.dart
    ├── summary_card.dart
    └── provider_filter.dart
```

### Building for Production

```bash
flutter build apk --release
```

### Android signing

This repository intentionally includes a release keystore for convenience because the app is not distributed via public app stores:

- Keystore: `android/app/keystore/release.keystore`
- Config: `android/key.properties`

If you ever move to a public distribution, rotate the key and stop committing signing materials by restoring the default ignore rules.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.
