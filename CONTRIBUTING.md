# Contributing to HisabBox

Thank you for your interest in contributing to HisabBox! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with the following information:
- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- Device and Android version

### Suggesting Enhancements

We welcome enhancement suggestions! Please create an issue with:
- A clear and descriptive title
- Detailed description of the suggested enhancement
- Why this enhancement would be useful
- Examples of how it would work

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests to ensure nothing breaks
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow the existing code style
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features
- Ensure your code passes lint checks

### Testing

Before submitting a PR:
```bash
# Run tests
flutter test

# Check code formatting
flutter format --set-exit-if-changed .

# Run static analysis
flutter analyze
```

### Adding New SMS Providers

To add support for a new SMS provider:

1. Add patterns to `lib/services/sms_parser.dart`
2. Implement parser logic for the new provider
3. Add detection logic in the main parse method
4. Add comprehensive tests in `test/sms_parser_test.dart`

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

## Development Setup

1. Install Flutter SDK (>=3.0.0)
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run` to start the app

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and encourage diverse perspectives
- Focus on what is best for the community
- Show empathy towards other community members

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing! 🎉
