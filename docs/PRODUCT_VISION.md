# HisabBox Product Vision

This document captures the latest direction for HisabBox as a persistent SMS parser and financial automation hub for Bangladesh’s mobile money ecosystem.

## 1. Vision

HisabBox persistently ingests mobile financial service (MFS) and bank SMS alerts, stores them locally, and instantly pushes structured JSON payloads to a user-owned webhook. The app operates as a **local-first transaction gateway** that enables automation, accounting, and analytics without cloud lock-in or background battery drain.

## 2. Actors

| Actor | Role |
| --- | --- |
| User (Individual/Business) | Monitors, audits, and automates their financial SMS transactions. |
| SMS Provider | bKash, Nagad, Rocket, and banking senders that issue alerts. |
| HisabBox App | Parses SMS, stores data, and pushes transactions to the webhook. |
| External API Server | Receives transaction payloads and executes business-specific logic. |

## 3. Goals

1. **Automatic SMS Parsing** – Detect and extract transaction data even when the UI is closed.
2. **Provider Control** – Let users select which providers are monitored.
3. **Historical Import** – Allow on-demand backfills by time range or count.
4. **Dashboard Summary** – Surface 20–30 recent transactions with provider branding.
5. **Webhook Push** – Deliver JSON payloads to user-defined HTTPS endpoints in real time.
6. **Offline-First** – Queue data locally until connectivity returns.
7. **Persistence & Reliability** – Survive restarts, reboots, and process kills without data loss.
8. **Privacy & Efficiency** – Ship zero analytics, zero polling, and only user-approved traffic.

## 4. Core Scenarios

### A. Dashboard
- Present the most recent transactions with provider icons, transaction type, amount, balance, timestamp, and TrxID.
- Provide provider and transaction-type filters plus Material 3 design with Bangla/English toggle.

### B. Provider Control
- Enable or disable specific senders (e.g., pause Rocket/DBBL notifications).
- Ignored providers are excluded from live capture and historical import.

### C. SMS Capture Control
- **Start Listening Now:** Begin parsing new inbound SMS immediately.
- **Import History:** Backfill older messages per provider using trusted sender patterns.

### D. Persistent Background Operation
- Use the `telephony` plugin's background isolate to insert transactions into the local Drift database even after app termination or device reboot.
- Resume syncing when connectivity is restored.

### E. Webhook Push (Automation Setup)
- Accept webhook URL configuration in Settings.
- Serialize new transactions to JSON and POST via HTTPS.
- Retry failures using WorkManager with exponential backoff and store unsent items locally.

### F. Import & Maintenance
- Reimport the last _N_ SMS for history reconstruction.
- Purge old records to reclaim storage.
- Export CSV backups for manual bookkeeping.

### G. Privacy, Logging, and Error Handling
- Process SMS locally and push only webhook-approved data.
- Ship no analytics or ads.
- Provide optional error log viewer and PIN/biometric app lock.

## 5. Data Flow

```
SMS Provider → Telephony plugin background isolate → Parser Service → Drift SQLite
            → Dashboard UI / Settings ↔ WorkManager Sync → User Webhook
```

Persistence guarantees: every SMS is captured through the telephony plugin background isolate, committed to storage, and queued for webhook delivery even if Flutter is killed or the device restarts.

## 6. Architecture Overview

| Layer | Responsibility | Key Components |
| --- | --- | --- |
| Data Capture | Receive SMS and insert into DB | Telephony plugin background isolate |
| Persistence | Store parsed transactions | Drift (SQLite ORM) |
| Logic | Parse, deduplicate, classify | Regex parser engine, provider registry |
| Sync | Push to webhook | Dio HTTP client, WorkManager |
| UI | Dashboard & Settings | Flutter + Material 3, Provider/Riverpod |
| Config | Store toggles & metadata | SharedPreferences |

## 7. Tech Stack

| Domain | Technology |
| --- | --- |
| Framework | Flutter ≥ 3.24, Dart 3 |
| State Management | GetX or Riverpod (Provider-compatible) |
| Local Storage | Drift (SQLite) |
| Settings | SharedPreferences |
| Background Tasks | WorkManager + telephony background isolate |
| SMS Handling | telephony plugin (Dart background callback) |
| Networking | Dio |
| Dependency Injection | GetIt / Riverpod |
| Logging | Local-only logger |

## 8. Future Enhancements

- Expand bank SMS parsing (DBBL, City, BRAC, etc.).
- Add webhook security via HMAC signatures and shared secrets.
- Explore ML/NLP parsing for dynamic templates.
- Support remote regex registry updates from trusted sources.
- Deliver full Bangla/English localization.
- Enable optional analytics dashboards through external APIs.

## 9. Acceptance Criteria

1. App receives SMS → Transaction appears instantly.
2. App killed while SMS arrives → Transaction still captured.
3. Disabled provider → SMS ignored.
4. History import → Old messages parsed correctly.
5. Valid webhook URL → Data pushed immediately.
6. Webhook failure → Retry with exponential backoff.
7. Device reboot → Capture resumes automatically.
8. Duplicate SMS → Single record retained via hash.
9. Offline mode → Transactions queued locally.
10. Regex update → Parser reloads dynamically.
11. Missing permission → Guided setup displayed.
12. Power-saving mode → Receiver continues functioning.
13. Error occurred → Exposed in local error log.

---

_Last updated: aligned with revised push-only architecture briefing._

