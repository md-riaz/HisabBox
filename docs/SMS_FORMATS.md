# SMS Format Examples

This document provides examples of SMS formats from different providers that HisabBox can parse.

## bKash

### Send Money
```
You have sent Tk1,500.00 to 01712345678 successfully. Fee Tk25.00. TrxID ABC123XYZ at 2024-01-01 12:00:00. Balance Tk5,000.00
```

### Receive Money
```
You have received Tk2,000.00 from 01798765432. TrxID DEF456GHI at 2024-01-02 14:30:00. Balance Tk7,000.00
```

### Cash Out
```
Cash Out Tk500.00 successful from 01612345678. Fee Tk10.00. TrxID JKL789MNO at 2024-01-03 10:15:00. Balance Tk6,490.00
```

### Payment
```
Payment of Tk750.00 to Merchant XYZ successful. TrxID PQR123STU at 2024-01-04 16:45:00. Balance Tk5,740.00
```

### Cash In
```
Cash In Tk3,000.00 successful at Agent 12345. Fee Tk15.00. TrxID UVW456XYZ at 2024-01-05 09:00:00. Balance Tk8,740.00
```

## Nagad

### Send Money
```
Send Money Tk 1,200.00 to 01812345678 successful. Fee Tk 20.00. Trx ID: VWX456YZA at 2024-01-05 09:00:00. Balance: Tk 4,520.00
```

### Receive Money
```
Received Tk 3,500.00 from 01998765432. Trx.ID: BCD789EFG at 2024-01-06 11:30:00. Balance: Tk 8,020.00
```

### Cash Out
```
Cash Out Tk 600.00 successful. Agent: 01712345678. Fee: Tk 12.00. Trx ID: HIJ012KLM at 2024-01-07 15:00:00. Balance: Tk 7,408.00
```

### Mobile Recharge
```
Mobile Recharge Tk 100.00 successful to 01812345678. Trx ID: NOP345QRS at 2024-01-08 10:30:00. Balance: Tk 7,308.00
```

## Rocket

### Send Money
```
Tk 800.00 sent to 01712345678 successfully. Charge Tk 16.00. TxnID: RST678UVW at 2024-01-09 13:00:00. Balance: Tk 6,492.00
```

### Receive Money
```
Tk 2,500.00 received from 01898765432. TxnID: XYZ901ABC at 2024-01-10 15:30:00. Balance: Tk 8,992.00
```

### Cash Out
```
Cash Out Tk 1,000.00 successful. Agent: 01612345678. Fee: Tk 20.00. TxnID: DEF234GHI at 2024-01-11 12:00:00. Balance: Tk 7,972.00
```

### Bill Payment
```
Bill Payment Tk 550.00 to DESCO successful. TxnID: JKL567MNO at 2024-01-12 14:00:00. Balance: Tk 7,422.00
```

## Important Notes

### SMS Sender Addresses

The parser identifies providers based on sender addresses:

- **bKash**: Usually from "bKash" or "16247"
- **Nagad**: Usually from "Nagad" or "16167"
- **Rocket**: Usually from "Rocket" or "16216"

### Parsing Flexibility

The SMS parser uses regular expressions with some flexibility:

1. **Amount Format**: Handles both comma-separated (1,500.00) and plain (1500.00) formats
2. **Date Format**: Various date formats are supported
3. **Whitespace**: Extra spaces are handled gracefully
4. **Case**: Parsing is case-insensitive

### Adding Custom Patterns

If your SMS format is not recognized, you can:

1. Check the raw message in the transaction details
2. Open an issue with the SMS format
3. Contribute a pattern by following the CONTRIBUTING.md guide

### Testing Your SMS Format

To test if a specific SMS will be parsed:

1. Import historical SMS
2. Check if the transaction appears
3. If not, check the raw SMS format
4. Report the format for support

## Provider-Specific Keywords

### bKash Keywords
- "sent", "send money"
- "received", "receive money"
- "cash out", "cashout"
- "cash in", "cashin"
- "payment"
- "TrxID", "Transaction ID"

### Nagad Keywords
- "send money"
- "received"
- "cash out"
- "mobile recharge"
- "Trx ID", "Trx.ID"

### Rocket Keywords
- "sent"
- "received"
- "cash out"
- "bill payment"
- "TxnID"


## Troubleshooting

### SMS Not Being Parsed

1. **Check Permissions**: Ensure SMS read permission is granted
2. **Provider Detection**: The sender address should contain provider keywords
3. **Format Mismatch**: Some custom wallet formats may not be recognized
4. **Import**: Try manual import from Settings

### Incorrect Amount

1. **Decimal Separator**: Ensure proper decimal format
2. **Currency Symbol**: Parser handles Tk, BDT, etc.
3. **Commas**: Both 1,500 and 1500 formats are supported

### Missing Transactions

1. **Date Range**: Check if SMS is within selected date range
2. **Provider Filter**: Ensure the provider is not filtered out
3. **Database**: Try restarting the app

## Request New Provider Support

To request support for a new provider:

1. Collect 5-10 sample SMS messages
2. Anonymize any personal information
3. Create a GitHub issue with:
   - Provider name
   - Sample SMS formats
   - Sender address
   - Any specific requirements

## Contributing New Patterns

See CONTRIBUTING.md for detailed instructions on adding support for new SMS formats and providers.
