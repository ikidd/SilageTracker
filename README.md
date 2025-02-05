# Silage Tracker

A Flutter application for tracking silage feeding operations.

## Features

- Track multiple herds
- Record silage feeding amounts and grain percentages
- View feeding history
- Automatic APK builds via GitHub Actions

## Development

### Building

The app uses GitHub Actions to automatically build APKs on each push to the main branch. The workflow:
1. Sets up the build environment
2. Configures signing keys
3. Builds a release APK
4. Makes the APK available as a workflow artifact

### Requirements

- Flutter 3.16.5
- Android SDK
- Java Development Kit 17

## Source Code and License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See the [LICENSE](LICENSE) file for the complete terms and conditions.
