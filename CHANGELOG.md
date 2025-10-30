# Changelog

All notable changes to HisabBox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-18

### Added
- Initial release of HisabBox
- Offline-first SMS parser for financial transactions
- Support for bKash, Nagad, and Rocket SMS parsing
- SQLite database for local storage
- Material 3 dashboard with transaction summary
- Provider filtering functionality
- Webhook synchronization for remote backup
- Historical SMS import feature
- Permission handling for SMS access
- Background SMS monitoring
- Settings screen for webhook configuration
- Comprehensive test suite for SMS parser and models
- Complete documentation in README.md

### Features
- Parse financial SMS from multiple providers
- Store transactions locally with zero data loss
- Filter transactions by provider (bKash, Nagad, Rocket)
- View transaction summary with balance calculation
- Sync transactions to secure webhook endpoint
- Import historical SMS messages
- Persist data across app restarts and device reboots
- Privacy-first architecture with optional cloud sync
