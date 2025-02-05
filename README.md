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

### Source Code Availability

In compliance with the GNU Affero General Public License (AGPL-3.0):

- The complete source code for this application is available in this repository
- Any modifications made to this software must be made available under the same license
- If you deploy this software as a network service, you must make the complete source code of your modified version available to users of that service
- The source code must be provided in a format that is readable and modifiable

### How to Obtain and Modify the Source Code

1. Clone this repository:
   ```bash
   git clone [repository-url]
   ```
2. Make your modifications
3. If you distribute the software or run it as a network service, you must:
   - Make your modified source code available under the AGPL-3.0
   - Include a prominent notice stating that the code is available
   - Provide clear instructions for obtaining the source code

### Additional Permissions

This program includes additional permissions under GNU AGPL version 3 section 7 to combine this program with free software programs or libraries that are released under the GNU LGPL and with code included in the standard release of the "Flutter" library under the BSD-3-Clause License.

See the [LICENSE](LICENSE) file for the complete terms and conditions.
