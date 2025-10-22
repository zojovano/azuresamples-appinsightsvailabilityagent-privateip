# Contributing to Azure Availability Agent

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include detailed reproduction steps
4. Provide logs and configuration (sanitized)

### Suggesting Features

1. Check existing feature requests
2. Use the feature request template
3. Describe the use case clearly
4. Consider implementation complexity

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

### Code Style

- Follow C# coding conventions
- Use meaningful variable and method names
- Add XML documentation for public APIs
- Keep methods focused and concise

### Terraform

- Format code: `terraform fmt`
- Validate: `terraform validate`
- Use Azure Verified Modules where possible
- Document variables and outputs

### Testing

- Test locally before submitting
- Verify Docker container builds
- Test Terraform changes in isolated environment
- Include unit tests for new features

### Documentation

- Update README.md if needed
- Add configuration examples
- Document breaking changes
- Update DEPLOYMENT.md for infrastructure changes

## Pull Request Process

1. **Ensure tests pass**: All builds and tests should succeed
2. **Update documentation**: README, CONFIGURATION, or DEPLOYMENT guides
3. **Describe changes**: Clear PR description with context
4. **Link issues**: Reference related issues in PR
5. **Request review**: Wait for maintainer review
6. **Address feedback**: Make requested changes
7. **Merge**: Maintainer will merge when approved

## Project Structure

- `app/` - Function App code (.NET C#)
- `infra/` - Terraform infrastructure
- `.github/workflows/` - CI/CD pipelines
- `docs/` - Additional documentation

## Key Areas for Contribution

### High Priority
- Unit and integration tests
- Additional probe types (TCP, custom protocols)
- Enhanced error handling
- Performance optimizations

### Medium Priority
- Multi-region deployments
- Advanced alerting configurations
- Metrics dashboard templates
- Azure Key Vault integration

### Documentation
- More configuration examples
- Troubleshooting guides
- Architecture diagrams
- Video tutorials

## Questions?

- Open a discussion in GitHub Discussions
- Check existing documentation
- Review closed issues and PRs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉
