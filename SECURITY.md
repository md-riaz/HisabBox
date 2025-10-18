# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of HisabBox seriously. If you discover a security vulnerability, please follow these steps:

### Do Not

- Do not open a public GitHub issue
- Do not disclose the vulnerability publicly until it has been addressed

### Do

1. Email the maintainers with details of the vulnerability
2. Include steps to reproduce the issue
3. Provide any relevant code snippets or proof of concept
4. Wait for acknowledgment (we aim to respond within 48 hours)

### What to Expect

- Acknowledgment of your report within 48 hours
- Regular updates on the progress of addressing the vulnerability
- Credit for the discovery (if desired) when the fix is published
- Notification when the vulnerability is fixed

## Security Best Practices

### For Users

- Keep the app updated to the latest version
- Only enable webhook sync if you trust the endpoint
- Use HTTPS for webhook URLs
- Review SMS permissions carefully
- Don't share your webhook URL publicly

### For Developers

- Never commit sensitive data or credentials
- Use HTTPS for all webhook communications
- Validate all user inputs
- Follow secure coding practices
- Keep dependencies updated
- Run security analysis regularly

## Data Privacy

HisabBox is designed with privacy in mind:

- All transaction data is stored locally on the device
- Webhook sync is optional and disabled by default
- No analytics or tracking is implemented
- No data is collected by the app developers
- Users have complete control over their data

## Webhook Security

If you enable webhook sync:

- Use HTTPS endpoints only
- Implement authentication on your webhook endpoint
- Validate incoming data
- Use secure servers
- Monitor for unusual activity
- Keep your webhook URL confidential

## SMS Permissions

The app requires SMS permissions to:

- Read transaction SMS messages
- Monitor new incoming SMS
- Import historical SMS data

These permissions are used solely for transaction parsing and are never used to:

- Access personal messages
- Share SMS data with third parties
- Store non-financial SMS messages

## Updates and Patches

Security updates will be released as soon as possible after a vulnerability is confirmed. Users are encouraged to:

- Enable automatic updates
- Check for updates regularly
- Read release notes for security fixes

## Contact

For security concerns, please contact the maintainers through GitHub.

## Acknowledgments

We appreciate responsible disclosure and will acknowledge security researchers who help improve HisabBox's security.
