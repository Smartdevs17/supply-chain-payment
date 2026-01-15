# Contributing to Supply Chain Payment Automation

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/supply-chain-payment.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests: `npm test`
6. Commit your changes: `git commit -m "feat: add new feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

```bash
npm install
cp .env.example .env
# Add your test private key to .env
npm run compile
npm test
```

## Commit Message Convention

We follow conventional commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `style:` - Code style changes

Example: `feat: add multi-token support for orders`

## Code Style

- Use Solidity 0.8.20
- Follow OpenZeppelin style guide
- Add NatSpec comments to all functions
- Keep functions focused and small
- Use descriptive variable names

## Testing Requirements

- All new features must include tests
- Maintain or improve code coverage
- Test edge cases and error conditions
- Run `npm run test:coverage` before submitting

## Pull Request Process

1. Update README.md if needed
2. Update CONTRACTS.md for contract changes
3. Ensure all tests pass
4. Request review from maintainers
5. Address review feedback
6. Squash commits if requested

## Security

- Never commit private keys or sensitive data
- Report security issues privately to maintainers
- Follow security best practices
- Consider gas optimization

## Questions?

Open an issue for discussion before starting major changes.

Thank you for contributing! 🚀
