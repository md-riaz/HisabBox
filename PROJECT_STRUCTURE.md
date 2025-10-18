# Project Structure

```
HisabBox/
├── android/                          # Android-specific configuration
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/com/hisabbox/app/
│   │   │   │   └── MainActivity.kt   # Android activity entry point
│   │   │   └── AndroidManifest.xml   # Permissions and components
│   │   └── build.gradle              # App-level build config
│   ├── build.gradle                  # Project-level build config
│   ├── gradle.properties             # Gradle settings
│   └── settings.gradle               # Gradle plugins
│
├── docs/                             # Documentation
│   ├── API.md                        # API reference
│   ├── FAQ.md                        # Frequently asked questions
│   ├── QUICKSTART.md                 # Quick start guide
│   └── SMS_FORMATS.md                # SMS format examples
│
├── lib/                              # Flutter source code
│   ├── models/                       # Data models
│   │   ├── transaction.dart          # Transaction model
│   │   └── transaction.g.dart        # Generated JSON serialization
│   │
│   ├── providers/                    # State management
│   │   ├── settings_provider.dart    # Settings state
│   │   └── transaction_provider.dart # Transaction state
│   │
│   ├── screens/                      # UI screens
│   │   ├── dashboard_screen.dart     # Main dashboard
│   │   ├── import_screen.dart        # SMS import screen
│   │   └── settings_screen.dart      # Settings screen
│   │
│   ├── services/                     # Business logic
│   │   ├── database_service.dart     # SQLite operations
│   │   ├── permission_service.dart   # Permission handling
│   │   ├── sms_parser.dart           # SMS parsing logic
│   │   ├── sms_service.dart          # SMS monitoring
│   │   └── webhook_service.dart      # Webhook sync
│   │
│   ├── widgets/                      # Reusable UI components
│   │   ├── provider_filter.dart      # Provider filter chips
│   │   ├── summary_card.dart         # Summary statistics card
│   │   └── transaction_card.dart     # Transaction list item
│   │
│   ├── main.dart                     # App entry point
│   └── README.md                     # Lib directory documentation
│
├── test/                             # Tests
│   ├── sms_parser_test.dart          # SMS parser unit tests
│   ├── transaction_model_test.dart   # Model unit tests
│   └── widget_test.dart              # Widget tests
│
├── .gitignore                        # Git ignore rules
├── .metadata                         # Flutter metadata
├── analysis_options.yaml             # Dart analyzer config
├── ARCHITECTURE.md                   # Architecture documentation
├── CHANGELOG.md                      # Version history
├── CONTRIBUTING.md                   # Contribution guidelines
├── LICENSE                           # MIT License
├── pubspec.yaml                      # Project dependencies
├── README.md                         # Main documentation
└── SECURITY.md                       # Security policy
```

## File Descriptions

### Root Level

- **pubspec.yaml**: Project configuration and dependencies
- **analysis_options.yaml**: Dart/Flutter linting rules
- **.gitignore**: Files excluded from version control
- **.metadata**: Flutter project metadata
- **LICENSE**: MIT License text
- **README.md**: Main project documentation
- **ARCHITECTURE.md**: Detailed architecture guide
- **CONTRIBUTING.md**: How to contribute
- **SECURITY.md**: Security policy
- **CHANGELOG.md**: Version history

### Android Directory

- **AndroidManifest.xml**: App permissions and components
- **MainActivity.kt**: Android app entry point
- **build.gradle**: Build configuration
- **gradle.properties**: Build properties
- **settings.gradle**: Plugin configuration

### Lib Directory

#### Models
- **transaction.dart**: Core data model for transactions
- **transaction.g.dart**: Auto-generated JSON serialization code

#### Providers
- **transaction_provider.dart**: Manages transaction state and filtering
- **settings_provider.dart**: Manages app settings

#### Screens
- **dashboard_screen.dart**: Main screen with transactions and summary
- **import_screen.dart**: Historical SMS import interface
- **settings_screen.dart**: App configuration screen

#### Services
- **database_service.dart**: SQLite database operations
- **sms_parser.dart**: Parses SMS into transactions
- **sms_service.dart**: Monitors and processes SMS
- **webhook_service.dart**: Syncs transactions to webhook
- **permission_service.dart**: Handles runtime permissions

#### Widgets
- **transaction_card.dart**: Individual transaction display
- **summary_card.dart**: Financial summary display
- **provider_filter.dart**: Provider filter chips

### Test Directory

- **sms_parser_test.dart**: Tests for SMS parsing logic
- **transaction_model_test.dart**: Tests for data model
- **widget_test.dart**: Tests for UI components

### Docs Directory

- **API.md**: Complete API reference
- **FAQ.md**: Frequently asked questions
- **QUICKSTART.md**: Getting started guide
- **SMS_FORMATS.md**: SMS format examples

## Key Design Decisions

### 1. Offline-First Architecture
- SQLite for local storage
- Webhook sync is optional
- No external dependencies for core functionality

### 2. Clean Architecture
- Separation of concerns (UI, Business Logic, Data)
- Services handle business logic
- Providers manage state
- Widgets are reusable

### 3. Provider State Management
- Lightweight and efficient
- Easy to understand
- Good for this app's complexity

### 4. Regex-Based Parsing
- Flexible for variations in SMS formats
- Easy to extend with new providers
- Testable in isolation

### 5. Material 3 Design
- Modern, clean interface
- Platform-consistent
- Accessible and responsive

## Dependencies

### Core Dependencies
- **flutter**: Framework
- **sqflite**: Local database
- **telephony**: SMS access
- **provider**: State management
- **http**: Webhook communication
- **permission_handler**: Permissions

### UI Dependencies
- **material_color_utilities**: Material 3 colors
- **intl**: Date/number formatting

### Storage Dependencies
- **path_provider**: File system paths
- **shared_preferences**: Simple persistence

### Dev Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code quality
- **build_runner**: Code generation
- **json_serializable**: JSON serialization

## Code Organization Principles

1. **Single Responsibility**: Each file has one clear purpose
2. **DRY (Don't Repeat Yourself)**: Reusable widgets and services
3. **Separation of Concerns**: UI, logic, and data are separate
4. **Testability**: Services and parsers are unit-testable
5. **Extensibility**: Easy to add new providers or features

## Adding New Files

### New Provider
1. Add patterns to `lib/services/sms_parser.dart`
2. Add tests to `test/sms_parser_test.dart`

### New Screen
1. Create file in `lib/screens/`
2. Add navigation from existing screen
3. Add tests in `test/`

### New Widget
1. Create file in `lib/widgets/`
2. Import and use in screens
3. Keep widgets reusable

### New Service
1. Create file in `lib/services/`
2. Use singleton pattern if needed
3. Add tests in `test/`

### New Documentation
1. Add markdown file in `docs/`
2. Link from README.md
3. Keep format consistent

## Build Artifacts (Not in Git)

The following are generated and excluded:
- `.dart_tool/`: Dart tooling
- `build/`: Build output
- `.flutter-plugins`: Plugin registry
- `.flutter-plugins-dependencies`: Plugin dependencies
- `.packages`: Package references
- `android/app/src/main/java/`: Generated Java
- `android/local.properties`: Local SDK paths

## Best Practices

1. **Keep files focused**: One responsibility per file
2. **Use meaningful names**: Clear, descriptive names
3. **Document complex logic**: Add comments where needed
4. **Write tests**: Especially for parsers and services
5. **Follow style guide**: Use flutter_lints rules
6. **Update documentation**: Keep docs in sync with code

## Navigation Flow

```
main.dart
  └─> DashboardScreen (home)
       ├─> ImportScreen (import icon)
       ├─> SettingsScreen (settings icon)
       └─> TransactionCard (list items)
```

## Data Flow

```
SMS → SmsService → SmsParser → Transaction Model → DatabaseService
                                                           ↓
                                                    TransactionProvider
                                                           ↓
                                                      UI Updates
```

## State Management Flow

```
User Action → Screen → Provider → Service → Database
                          ↓
                    notifyListeners()
                          ↓
                    UI Rebuilds
```

This structure ensures maintainability, testability, and scalability of the HisabBox application.
