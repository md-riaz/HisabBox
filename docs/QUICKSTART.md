# Quick Start Guide

Get HisabBox up and running in 5 minutes!

## Prerequisites

- Android device (minimum API 21, Android 5.0+)
- SMS permission access
- Basic understanding of the app purpose

## Installation Steps

### Option 1: Using Pre-built APK (Recommended for Users)

1. Download the latest APK from [Releases](https://github.com/md-riaz/HisabBox/releases)
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK
4. Open HisabBox

### Option 2: Building from Source (For Developers)

```bash
# 1. Clone the repository
git clone https://github.com/md-riaz/HisabBox.git
cd HisabBox

# 2. Install dependencies
flutter pub get

# 3. Connect your Android device or start an emulator
flutter devices

# 4. Run the app
flutter run
```

## First Time Setup

### Step 1: Grant Permissions

When you first open HisabBox, you'll be asked for permissions:

1. **SMS Permission**: Required to read transaction messages
   - Tap "Allow" when prompted
   - If denied, the app will prompt you to open settings

2. **Notification Permission**: Required for background monitoring
   - Tap "Allow" when prompted

### Step 2: Import Historical Transactions (Optional)

To import past transactions:

1. Tap the upload icon (📤) in the top-right corner
2. Select date range (e.g., last 30 days)
3. Tap "Import SMS"
4. Wait for processing (may take 1-2 minutes depending on SMS count)

### Step 3: Configure Webhook (Optional)

If you want to sync to a cloud service:

1. Tap the settings icon (⚙️)
2. Enable "Enable Webhook"
3. Enter your webhook URL (e.g., `https://your-server.com/webhook`)
4. Tap "Test Webhook" to verify connection
5. Enable "Auto Sync" if desired

## Basic Usage

### View Transactions

The dashboard shows:
- **Summary Card**: Total received, sent, and current balance
- **Provider Filter**: Tap chips to filter by bKash, Nagad, Rocket, or Bank
- **Transaction List**: All transactions in chronological order

### Filter by Provider

1. Locate the filter chips below the summary
2. Tap a provider chip to toggle it on/off
3. Selected providers show with colored background
4. Transactions update automatically

### Pull to Refresh

Swipe down on the dashboard to refresh transactions.

### Sync Transactions

Tap the sync icon (🔄) to manually sync with your webhook.

### View Transaction Details

Tap any transaction card to see:
- Full transaction details
- Provider information
- Transaction ID
- Raw SMS message
- Sync status

## Understanding the Dashboard

### Summary Card

```
┌─────────────────────────────────────┐
│ Summary                             │
│                                     │
│ Received: ৳12,500.00                │
│ Sent: ৳8,300.00                     │
│                                     │
│ Balance: ৳4,200.00                  │
└─────────────────────────────────────┘
```

- **Received**: Total money received (received, cash-in, refunds)
- **Sent**: Total money sent (sent, cash-out, payments, fees)
- **Balance**: Net amount (received - sent)

### Transaction Card

```
┌─────────────────────────────────────┐
│ 🔴 ৳1,500.00              [bKash]   │
│ To: 01712345678                     │
│ TrxID: ABC123XYZ                    │
│ Jan 15, 2024 02:30 PM               │
│ ✅ Synced                           │
└─────────────────────────────────────┘
```

- **Red Arrow (↑)**: Money sent/paid
- **Green Arrow (↓)**: Money received
- **Provider Badge**: Color-coded (pink=bKash, orange=Nagad, purple=Rocket, blue=Bank)
- **Sync Status**: ✅ if synced to webhook

## Common Tasks

### Import Recent Transactions

1. Open Import screen
2. Set start date to 7 days ago
3. Set end date to today
4. Import

### Check Webhook Status

1. Open Settings
2. Look for webhook status
3. Test connection if needed

### Filter for Specific Provider

1. Tap provider chip (e.g., bKash)
2. View filtered transactions
3. Tap again to include all providers

## Tips & Tricks

### Automatic Monitoring

- HisabBox monitors new SMS automatically
- No need to manually import after setup
- Transactions appear within seconds of SMS arrival

### Background Operation

- The app works even when closed
- Survives device reboot
- No battery drain

### Privacy

- All data stored locally
- Webhook sync is optional
- You control your data

### Offline Mode

- Works without internet
- Sync when online
- No data loss

## Troubleshooting

### SMS Not Being Detected

**Problem**: New transaction SMS not showing up

**Solutions**:
1. Check SMS permission is granted
2. Verify sender is bKash, Nagad, Rocket, or a bank
3. Restart the app
4. Try manual import

### Incorrect Amount

**Problem**: Transaction shows wrong amount

**Solution**:
1. Check raw SMS in transaction details
2. Report format if not recognized
3. Manual correction not yet supported

### Webhook Sync Failing

**Problem**: Transactions not syncing

**Solutions**:
1. Check internet connection
2. Verify webhook URL is correct (must be HTTPS)
3. Test webhook in settings
4. Check webhook endpoint is accessible

### Permission Denied

**Problem**: Can't grant SMS permission

**Solution**:
1. Open Android Settings
2. Go to Apps → HisabBox → Permissions
3. Grant SMS and Notification permissions
4. Restart HisabBox

## Support Providers

Currently supported:
- ✅ bKash (16247)
- ✅ Nagad (16167)
- ✅ Rocket (16216)
- ✅ Banks (DBBL, City Bank, BRAC Bank, EBL, etc.)

## What's Next?

- Explore the settings to customize behavior
- Set up webhook for cloud backup
- Review transaction history
- Check out the documentation for advanced features

## Need Help?

- Check the [FAQ](./FAQ.md)
- Read the [Architecture](../ARCHITECTURE.md) document
- View [SMS Format Examples](./SMS_FORMATS.md)
- Open an [issue](https://github.com/md-riaz/HisabBox/issues) on GitHub

## Security Note

HisabBox is designed with privacy in mind:
- Your SMS data never leaves your device unless you enable webhook
- Use HTTPS for webhook URLs
- Keep your webhook URL private
- No analytics or tracking

---

**Congratulations!** 🎉 You're now ready to track your financial transactions with HisabBox.
