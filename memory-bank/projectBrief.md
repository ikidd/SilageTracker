# Silage Tracker Project Brief

## Project Overview
Silage Tracker is a Flutter-based mobile application designed to help farmers and ranchers track their silage feeding operations for cattle. The application provides a streamlined way to manage multiple herds and record their feeding data, ensuring accurate tracking of silage usage and feed ratios.

## Core Features
- Multi-herd management system
- Silage feeding amount tracking
- Grain percentage recording
- Feeding history visualization
- Offline-capable data management
- Automatic synchronization with Supabase backend

## Technical Stack
- **Frontend Framework**: Flutter 3.16.5
- **Backend Service**: Supabase
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth
- **Build/CI**: GitHub Actions
- **Platform**: Mobile-first (Android primary focus)

## Target Platform
The application is primarily designed for mobile devices, with a specific focus on Android deployment. The mobile-first approach ensures optimal usability in farm/ranch environments where desktop access may be limited.

## Key Architectural Decisions
1. **Backend Choice**: Supabase selected for:
   - Built-in real-time capabilities
   - PostgreSQL database support
   - Simplified authentication system
   - Offline data sync capabilities

2. **Mobile-First Design**:
   - Optimized for use in varying network conditions
   - Touch-friendly interface
   - Compact, efficient data entry forms

3. **Data Architecture**:
   - Local storage for offline operation
   - Background synchronization with Supabase
   - Conflict resolution strategies for data consistency

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