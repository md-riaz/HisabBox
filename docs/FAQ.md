# Frequently Asked Questions (FAQ)

## General Questions

### What is HisabBox?

HisabBox is an offline-first Android app that automatically parses financial SMS messages from bKash, Nagad, Rocket, and banks to track your transactions. It stores everything locally and optionally syncs to your own webhook for backup.

### Is HisabBox free?

Yes, HisabBox is completely free and open-source under the MIT License.

### Which platforms are supported?

Currently, only Android (API 21+) is supported. iOS support may be added in the future.

## Privacy & Security

### Is my data safe?

Yes! All your transaction data is stored locally on your device using SQLite. Data is never sent anywhere unless you explicitly enable webhook sync.

### What data does HisabBox collect?

HisabBox does not collect any data. There are no analytics, tracking, or telemetry. Your financial data stays on your device.

### Can I use HisabBox without internet?

Absolutely! HisabBox is designed to work offline. Internet is only needed if you enable webhook sync.

### Is webhook sync secure?

Webhook sync uses HTTPS POST requests. We recommend:
- Using HTTPS URLs only
- Implementing authentication on your endpoint
- Keeping your webhook URL private
- Using a trusted server

### What permissions does HisabBox need?

- **SMS (READ_SMS, RECEIVE_SMS)**: To read and monitor transaction messages
- **Notifications**: For background service
- **Internet**: For optional webhook sync

We don't request any other permissions.

## Features

### Which providers are supported?

Currently supported:
- bKash
- Nagad
- Rocket
- Banks (DBBL, City Bank, BRAC Bank, EBL, Standard Chartered, and more)

### Can I add custom providers?

Yes! See the [Contributing Guide](../CONTRIBUTING.md) for instructions on adding new providers.

### Does HisabBox work when closed?

Yes! HisabBox monitors SMS in the background even when the app is closed or after device reboot.

### Can I export my data?

Currently, there's no built-in export feature, but you can:
- Use webhook to backup data
- Access the SQLite database directly (advanced users)
- Export feature is planned for future release

### Can I edit transactions?

Currently, manual editing is not supported. Transactions are parsed automatically from SMS.

### Can I delete transactions?

This feature is not yet implemented but is planned for future releases.

## Usage

### Why are some SMS not being parsed?

Possible reasons:
1. SMS format is not recognized
2. Sender is not identified as a financial provider
3. SMS doesn't contain transaction information

You can report unrecognized formats on GitHub.

### How do I import old messages?

1. Tap the upload icon in the dashboard
2. Select date range
3. Tap "Import SMS"
4. Wait for processing

### What if the amount is incorrect?

If you see incorrect amounts:
1. Check the raw SMS in transaction details
2. Verify the SMS format is standard
3. Report the issue with SMS sample on GitHub

### How do I set up webhook?

1. Go to Settings
2. Enable "Enable Webhook"
3. Enter your webhook URL (must be HTTPS)
4. Test the connection
5. Enable "Auto Sync" if desired

### What happens if webhook sync fails?

Transactions remain marked as "unsynced" and will be retried during the next sync attempt.

## Technical Questions

### What database does HisabBox use?

SQLite via the sqflite Flutter package.

### How are SMS patterns matched?

Using regular expressions (regex) tailored for each provider's SMS format.

### Can I run HisabBox on emulator?

Yes, but you'll need to simulate SMS messages using the emulator's controls.

### What Flutter version is required?

Flutter SDK >=3.0.0

### What's the minimum Android version?

Android 5.0 (API 21) or higher.

### How big is the app?

The APK is approximately 15-20 MB depending on architecture.

## Troubleshooting

### App crashes on startup

Try:
1. Clear app data
2. Reinstall the app
3. Check Android version compatibility
4. Report the issue with crash logs

### Permissions not working

Solution:
1. Open Android Settings
2. Apps → HisabBox → Permissions
3. Grant all required permissions
4. Restart the app

### Transactions not appearing

Check:
1. SMS permission is granted
2. SMS is from a supported provider
3. Try manual import
4. Restart the app

### Webhook sync not working

Verify:
1. Internet connection is active
2. Webhook URL is correct and uses HTTPS
3. Endpoint is accessible
4. Test webhook in settings

### Import taking too long

This is normal if you have many SMS messages. The app processes each message to find transactions. Wait for completion or restart import with a smaller date range.

### Balance seems incorrect

The balance calculation is: Received - Sent

Make sure you understand what counts as "received" vs "sent":
- **Received**: Money coming in (received, cash-in, refunds)
- **Sent**: Money going out (sent, cash-out, payments, fees)

### App draining battery

HisabBox is designed to be battery-efficient. If you experience issues:
1. Check for other apps draining battery
2. Restart the device
3. Report the issue if persistent

## Development

### How can I contribute?

See the [Contributing Guide](../CONTRIBUTING.md) for detailed instructions.

### Can I fork the project?

Yes! HisabBox is open-source under MIT License. Feel free to fork and modify.

### How do I report bugs?

Open an issue on [GitHub](https://github.com/md-riaz/HisabBox/issues) with:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Device and Android version

### How do I request features?

Open an issue on GitHub with:
- Feature description
- Use case
- Why it would be useful

### Can I donate?

Currently, we don't accept donations. Contributing code, documentation, or spreading the word helps more!

## Future Plans

### What features are planned?

- Export to CSV/JSON
- Transaction editing
- Manual transaction entry
- Categories and tags
- Budget tracking
- Analytics and reports
- Multi-language support
- iOS version

### When will [feature] be released?

Check the [GitHub Issues](https://github.com/md-riaz/HisabBox/issues) and [Milestones](https://github.com/md-riaz/HisabBox/milestones) for planned features and timelines.

## Webhook Integration

### What format does webhook receive?

JSON format with all transaction fields:
```json
{
  "id": "1234567890",
  "provider": "bkash",
  "type": "sent",
  "amount": 1500.0,
  "recipient": "01712345678",
  "transactionId": "ABC123XYZ",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "rawMessage": "Original SMS here",
  "synced": true,
  "createdAt": "2024-01-01T12:00:00.000Z"
}
```

### How often does webhook sync?

- Automatically when new transaction is received (if auto-sync enabled)
- Manually when you tap the sync button
- On app startup (if enabled)

### Can I use multiple webhooks?

Currently, only one webhook URL is supported.

### What if my webhook is down?

Transactions remain marked as unsynced and will be retried later.

### Can I authenticate my webhook?

You need to implement authentication on your webhook endpoint. Consider:
- API keys
- OAuth tokens
- Basic authentication
- IP whitelisting

## Miscellaneous

### Who maintains HisabBox?

HisabBox is maintained by md-riaz and the open-source community.

### Is there a desktop version?

Not currently. HisabBox is designed for Android where SMS messages are received.

### Can I use HisabBox for business?

Yes! HisabBox is free to use for personal and commercial purposes under the MIT License.

### How do I stay updated?

- Watch the GitHub repository
- Check releases for new versions
- Follow the changelog

### Where can I get help?

- Read the documentation
- Check this FAQ
- Open an issue on GitHub
- Check existing issues for solutions

---

**Don't see your question?** Open an issue on GitHub and we'll add it to the FAQ!
