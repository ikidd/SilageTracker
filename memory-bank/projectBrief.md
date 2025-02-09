# Silage Tracker Project Brief

## Project Overview
Silage Tracker is a Flutter-based mobile application designed to help farmers and ranchers track their silage feeding operations for cattle. The application provides a streamlined way to manage multiple herds and record their feeding data, ensuring accurate tracking of silage usage and feed ratios.

## Core Features
- Multi-herd management system
- Silage feeding amount tracking
- Grain percentage recording
- Feeding history visualization
- Real-time data updates via Supabase
- Filtering and sorting capabilities

## Technical Stack
- **Frontend Framework**: Flutter 3.16.5
- **Backend Service**: Supabase
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth (planned)
- **Build/CI**: GitHub Actions
- **Platform**: Mobile-first (Android primary focus)

## Target Platform
The application is primarily designed for mobile devices, with a specific focus on Android deployment. The mobile-first approach ensures optimal usability in farm/ranch environments where desktop access may be limited.

## Key Architectural Decisions
1. **Backend Choice**: Supabase selected for:
   - Built-in real-time capabilities
   - PostgreSQL database support
   - Simplified authentication system
   - Row-level security

2. **Mobile-First Design**:
   - Touch-friendly interface
   - Compact, efficient data entry forms
   - Responsive layouts
   - Optimized data tables

3. **Data Architecture**:
   - Direct Supabase integration
   - Real-time data updates
   - Efficient data validation
   - Error handling and recovery

4. **Build and Deployment**:
   - Automated builds via GitHub Actions
   - APK generation for easy distribution
   - Signing key management in CI/CD pipeline

## Development Requirements
- Flutter SDK 3.16.5
- Android SDK
- JDK 17
- Supabase project configuration
- GitHub repository for CI/CD

## License
GNU Affero General Public License v3.0 or later