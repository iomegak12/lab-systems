# Contributing to Lab Systems Environment Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

If you encounter any problems with the installation or verification scripts:

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (Windows version, installed software)
   - Relevant log files

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

1. Check if the enhancement has already been suggested
2. Create an issue describing:
   - The enhancement in detail
   - Why it would be useful
   - Possible implementation approach

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/iomegak12/lab-systems.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Test your changes thoroughly
   - Update documentation if needed

4. **Commit your changes**
   ```bash
   git commit -m "Add: Brief description of changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure all tests pass

## Development Guidelines

### Script Standards

#### Batch Scripts (.cmd)
- Use clear comments for each section
- Include error handling
- Provide user-friendly output messages
- Log important operations

#### PowerShell Scripts (.ps1)
- Follow PowerShell best practices
- Use approved verbs for function names
- Include parameter validation
- Write help documentation for functions

### Testing

Before submitting a pull request:

1. Test on a clean Windows installation (if possible)
2. Test both installation and verification scripts
3. Verify log files are generated correctly
4. Check for any error messages or warnings

### Documentation

- Update README.md for new features
- Add comments for complex logic
- Update installation instructions if needed
- Document any new parameters or options

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Collaborate openly

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

## Questions?

Feel free to open an issue for:
- Questions about the codebase
- Clarification on contribution process
- Discussion of potential features

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
