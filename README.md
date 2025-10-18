# HisabBox

An offline-first SMS parser that tracks bKash, Nagad, Rocket, and bank messages, converting them into structured transactions.

## Features

- **Offline-First Architecture**: All data is stored locally using SQLite for maximum privacy and zero data loss
- **SMS Parsing**: Automatically parses financial SMS from multiple providers:
  - bKash
  - Nagad
  - Rocket
  - Bank transactions
- **Material 3 Dashboard**: Modern, intuitive interface built with Material Design 3
- **Provider Filtering**: Filter transactions by payment provider
- **Webhook Sync**: Securely push transaction updates to your webhook endpoint
- **Import Historical Data**: Import and parse past SMS messages
- **Background Monitoring**: Continuously monitors new SMS even when app is closed
- **Persistent Storage**: Data persists across app restarts and device reboots
- **Privacy-First**: All data stored locally, webhook sync is optional

## Architecture

### Data Flow
1. SMS received on device
2. SMS parser extracts transaction details
3. Transaction saved to local SQLite database
4. If webhook enabled, transaction synced to remote endpoint
5. Dashboard displays transactions with filters

### Key Components

#### Models
- `Transaction`: Core data model for financial transactions
- Enums: `Provider` (bKash, Nagad, Rocket, Bank), `TransactionType` (sent, received, cashout, etc.)

#### Services
- `DatabaseService`: SQLite database management
- `SmsParser`: Regex-based parser for different SMS formats
- `SmsService`: SMS monitoring and historical import
- `WebhookService`: Secure webhook synchronization
- `PermissionService`: Runtime permission handling

#### Providers (State Management)
- `TransactionProvider`: Manages transaction state and filtering
- `SettingsProvider`: Manages app settings and webhook configuration

#### Screens
- `DashboardScreen`: Main screen with transaction list and summary
- `SettingsScreen`: Configure webhook and sync settings
- `ImportScreen`: Import historical SMS messages

## Setup

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android SDK (minSdk 21, targetSdk 34)
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
├── providers/                # State management
│   ├── transaction_provider.dart
│   └── settings_provider.dart
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── settings_screen.dart
│   └── import_screen.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── sms_parser.dart
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.