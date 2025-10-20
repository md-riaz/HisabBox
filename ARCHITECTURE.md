# HisabBox Architecture

## Overview

HisabBox is an offline-first Flutter application designed to parse financial SMS messages from Bangladeshi mobile financial services (bKash, Nagad, Rocket) and banks. The architecture emphasizes data persistence, privacy, and zero data loss.

## Design Principles

1. **Offline-First**: All data is stored locally first, sync is optional
2. **Privacy-First**: User data stays on device unless explicitly synced
3. **Zero Data Loss**: Robust persistence across app restarts and reboots
4. **Separation of Concerns**: Clean separation between UI, business logic, and data layers

## Architecture Layers

### Presentation Layer
- **Screens**: User-facing pages (Dashboard, Settings, Import)
- **Widgets**: Reusable UI components
- **Controllers**: State management using GetX

### Business Logic Layer
- **Services**: Core business logic and external integrations
  - SMS parsing
  - Database operations
  - Webhook synchronization
  - Permission handling

### Data Layer
- **Models**: Data structures and entities
- **Local Storage**: SQLite database for persistence
- **Shared Preferences**: Simple key-value storage for settings

## Component Details

### SMS Parser Service

**Purpose**: Extract structured transaction data from SMS messages

**Pattern Matching Strategy**:
- Regex-based patterns for each provider
- Provider detection using sender address and message content
- Flexible patterns to handle variations in SMS formats

**Supported Providers**:
1. bKash (patterns for sent, received, cashout, payment)
2. Nagad (patterns for sent, received, cashout)
3. Rocket (patterns for sent, received, cashout)
4. Banks (generic patterns for debit/credit)

**Extension Points**:
- Easy to add new providers by adding patterns
- Pattern matching is modular and testable

### Database Service

**Technology**: SQLite via sqflite package

**Schema**:
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  recipient TEXT,
  sender TEXT,
  transactionId TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  note TEXT,
  rawMessage TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL
)
```

**Indexes**:
- provider: Fast filtering by payment provider
- timestamp: Chronological ordering
- synced: Quick lookup of unsynced transactions

**Operations**:
- Insert: Add new transactions
- Query: Filter by provider, date range
- Update: Mark transactions as synced
- Delete: Remove transactions
- Aggregate: Calculate totals and balances

### SMS Service

**Responsibilities**:
- Monitor incoming SMS messages
- Process new messages in real-time
- Import historical SMS from inbox
- Work in foreground and background

**Integration**:
- Uses another_telephony package for SMS access
- Delegates parsing to SMS Parser
- Saves results to Database Service

**Background Handling**:
- Background message receiver for 24/7 monitoring
- Survives app termination
- Restarts after device reboot

### Webhook Service

**Purpose**: Optional cloud synchronization

**Features**:
- Configurable webhook URL
- Enable/disable toggle
- Test webhook connectivity
- Batch sync of unsynced transactions
- Retry logic for failed syncs

**Security**:
- HTTPS recommended
- No credentials stored (user configures endpoint)
- Optional feature (disabled by default)

**Data Format**:
- JSON serialization of Transaction model
- Includes all transaction fields

### State Management

**Pattern**: GetX controllers and reactive streams

**Controllers**:

1. **TransactionController**
   - Manages transaction list
   - Handles filtering by provider
   - Calculates summary statistics
   - Coordinates with Database Service and Webhook Service

2. **SettingsController**
   - Manages app settings
   - Webhook configuration
   - Auto-sync preferences
   - Persists preferences via SharedPreferences

### Permission Handling

**Required Permissions**:
- READ_SMS: Read SMS inbox
- RECEIVE_SMS: Receive new messages
- SEND_SMS: (Listed but not actively used)
- INTERNET: For webhook sync
- POST_NOTIFICATIONS: For background notifications
- WAKE_LOCK: Keep background service alive
- RECEIVE_BOOT_COMPLETED: Restart monitoring after reboot

**Strategy**:
- Request permissions at startup
- Graceful degradation if denied
- Easy access to permission settings

## Data Flow

### New SMS Received
```
SMS Received 
  → SMS Service receives notification
  → SMS Parser extracts transaction data
  → Database Service stores transaction
  → (Optional) Webhook Service syncs to cloud
  → UI updates via GetX
```

### User Opens App
```
App Launch
  → Initialize Database
  → Request Permissions
  → Initialize SMS Monitoring
  → Load Settings
  → Load Transactions from DB
  → Display Dashboard
```

### Historical Import
```
User Initiates Import
  → SMS Service fetches inbox messages
  → Filter by date range
  → Process each message through parser
  → Save to database
  → Update UI
```

### Webhook Sync
```
Trigger Sync
  → Query unsynced transactions
  → Send to webhook endpoint (HTTPS POST)
  → On success: Mark as synced
  → On failure: Retry later
```

## UI Architecture

### Material 3 Design
- Modern, clean interface
- Responsive layout
- Dynamic theming (light/dark)
- Intuitive navigation

### Key Screens

1. **Dashboard**
   - Summary cards (sent, received, balance)
   - Provider filter chips
   - Transaction list
   - Pull-to-refresh
   - Empty state handling

2. **Settings**
   - Webhook configuration
   - Test webhook button
   - Auto-sync toggle
   - About information

3. **Import**
   - Date range selection
   - Progress indicator
   - Import button
   - Info cards

### Widgets

1. **TransactionCard**
   - Displays individual transaction
   - Provider badge
   - Sync status indicator
   - Color-coded by type

2. **SummaryCard**
   - Overview statistics
   - Visual balance display
   - Color-coded amounts

3. **ProviderFilter**
   - Filter chips for each provider
   - Multi-select capability
   - Visual feedback

## Testing Strategy

### Unit Tests
- SMS Parser: Pattern matching for all providers
- Transaction Model: Serialization and mapping
- Database operations (would require mocking)

### Widget Tests
- Basic app initialization
- Widget rendering
- User interactions (potential expansion)

### Integration Tests
- End-to-end SMS processing flow
- Database persistence
- Webhook synchronization
- (Not implemented but recommended)

## Performance Considerations

1. **Database**
   - Indexes for common queries
   - Pagination for large datasets
   - Efficient filtering

2. **SMS Processing**
   - Non-blocking parsing
   - Batch operations for imports
   - Progress feedback

3. **UI**
   - Lazy loading of transactions
   - Efficient state updates
   - Smooth scrolling

## Security Considerations

1. **Data Storage**
   - Local SQLite (device-encrypted)
   - No sensitive data in SharedPreferences
   - Secure by default

2. **Webhook**
   - User-controlled endpoint
   - HTTPS recommended
   - Optional feature

3. **Permissions**
   - Minimal required permissions
   - Clear permission requests
   - Graceful handling of denials

## Extensibility

### Adding New Providers
1. Add provider to enum in transaction.dart
2. Create a new provider class in `lib/services/providers/` with regex patterns
3. Implement detection logic
4. Add parser method
5. Write tests

### Adding New Transaction Types
1. Add type to enum in transaction.dart
2. Update UI components for icons/colors
3. Update parser to recognize new types
4. Add tests

### Adding New Features
- Modular architecture makes it easy to add:
  - Export functionality
  - Analytics/reports
  - Budget tracking
  - Notifications
  - Multi-user support

## Dependencies

**Core**:
- flutter: Framework
- sqflite: Local database
- another_telephony: SMS access
- get: State management
- dio: Webhook communication

**UI**:
- material_color_utilities: Material 3 colors
- intl: Internationalization and formatting

**Storage**:
- path_provider: File system access
- shared_preferences: Simple persistence

**Utilities**:
- permission_handler: Runtime permissions
- json_annotation: JSON serialization

## Future Enhancements

1. **Export/Backup**
   - Export to CSV/JSON
   - Backup to cloud storage
   - Restore from backup

2. **Analytics**
   - Spending reports
   - Category-wise breakdown
   - Trend analysis

3. **Notifications**
   - Transaction alerts
   - Balance warnings
   - Sync status

4. **Multi-language**
   - Localization support
   - Regional number formats

5. **Enhanced Parsing**
   - Machine learning for better accuracy
   - Support more SMS formats
   - Custom provider patterns

## Conclusion

HisabBox's architecture prioritizes user privacy, data reliability, and extensibility. The offline-first approach ensures zero data loss while maintaining user control over their financial data. The modular design makes it easy to add new features and support additional providers in the future.
