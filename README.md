# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a psychologist booking application ("Психолог Майя Кондрук | додаток") built with Flutter. The app allows clients to book therapy sessions through a multi-step wizard interface with calendar selection, and integrates with Supabase for backend data management. UI strings are in Ukrainian (Cyrillic).

## Common Commands

### Development

```bash
# Install dependencies
flutter pub get

# Run the app (development mode)
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload (during development): press 'r' in terminal
# Hot restart: press 'R' in terminal
```

### Building

```bash
# Build for Android (APK)
flutter build apk --release

# Build for Android (App Bundle for Google Play)
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release
```

### Code Quality

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Format code
flutter format lib/
```

### Icon Generation

```bash
# Generate launcher icons (configured in pubspec.yaml)
flutter pub run flutter_launcher_icons
```

### Dependencies

```bash
# Update dependencies to latest compatible versions
flutter pub upgrade

# Get outdated dependencies
flutter pub outdated
```

## Architecture Overview

### Layered Architecture

The app follows a clear separation of concerns:

```
lib/
├── main.dart                    # Entry point with Riverpod ProviderScope
├── config/                      # Configuration (Supabase URLs, keys)
├── services/                    # Backend integration (SupabaseService)
├── models/                      # Data models (Appointment, TimeSlot)
├── screens/                     # UI screens organized by feature
│   ├── home_screen.dart         # Main menu hub
│   ├── booking/                 # Multi-step booking flow (4 screens)
│   └── webview_screen.dart      # Generic external content container
├── constants/                   # App-wide constants (colors, gradients)
└── theme/                       # Material 3 theme configuration
```

### Technology Stack

- **State Management**: Flutter Riverpod 2.6.1 (reactive, provider-based)
- **Backend**: Supabase (PostgreSQL-based BaaS)
- **UI Framework**: Material 3 design system
- **Typography**: Google Fonts (Playfair Display for headers, Inter for body)
- **WebView**: webview_flutter for embedded external content

### Key Architectural Patterns

1. **Singleton Pattern**: `SupabaseService` provides single shared instance
2. **Provider/DI**: Riverpod `FutureProvider.family` for parameterized data queries
3. **Multi-step Wizard**: 4-screen booking flow with state passing between screens
4. **Repository Pattern**: `SupabaseService` abstracts all database operations
5. **Widget Composition**: Reusable theme system with centralized colors/styles

## Data Flow & State Management

### Booking Flow (4 Steps)

1. **HomeScreen** → Main menu with 4 options (Booking, Lessons, Tests, Cabinet)
2. **BookingDurationScreen** → Session type selection (15min/60min/90min)
   - Invalidates Riverpod providers before navigation to ensure fresh data
3. **BookingCalendarScreen** → Date & time selection
   - Uses two FutureProviders: `timeSlotsProvider` and `appointmentsProvider`
   - Complex client-side logic generates bookable slots and checks overlaps
   - Week-based calendar (7 days), business hours 8:00-20:00
4. **BookingFormScreen** → Client details collection & appointment creation
   - Validates form (name required, email OR phone required)
   - Converts UI session types to database format
   - Creates appointment with exact start/end times
5. **BookingConfirmationScreen** → Success confirmation

### Riverpod State Management

- **FutureProvider.family**: Used for parameterized queries (different session types/durations)
- **Manual Invalidation**: Call `ref.invalidate(provider)` when data needs to be refreshed
- **StatefulWidget**: Only for local UI state (date selection, form input), NOT for data
- **ConsumerWidget/ConsumerStatefulWidget**: Use for watching Riverpod providers

Example:

```dart
// Define provider with parameters
final timeSlotsProvider = FutureProvider.family<List<TimeSlot>, SlotQueryParams>((ref, params) async {
  return SupabaseService.getAvailableTimeSlots(params.sessionType, params.durationMinutes);
});

// Watch provider in widget
final timeSlotsAsync = ref.watch(timeSlotsProvider(queryParams));

// Invalidate to refresh
ref.invalidate(timeSlotsProvider);
```

## Backend Integration (Supabase)

### Configuration

Supabase credentials are in [lib/config/supabase_config.dart](lib/config/supabase_config.dart):

- `supabaseUrl`: Backend API URL
- `supabaseAnonKey`: Anonymous access key

### Database Schema

**time_slots table**:

- `id` (UUID, primary key)
- `start_time` (timestamp with timezone, UTC)
- `end_time` (timestamp with timezone, UTC)
- `duration_minutes` (int: 15, 60, or 90)
- `is_available` (boolean)
- `session_type` (text: 'consultation_15', 'session_60', 'session_90')
- `created_at` (timestamp)

**appointments table**:

- `id` (UUID, primary key)
- `time_slot_id` (UUID, foreign key to time_slots)
- `client_name` (text, required)
- `client_email` (text, optional)
- `client_phone` (text, optional)
- `session_type` (text: matches time_slots)
- `notes` (text, optional)
- `status` (text: 'confirmed', etc.)
- `appointment_start_time` (timestamp with timezone, UTC)
- `appointment_end_time` (timestamp with timezone, UTC)
- `created_at` (timestamp)

### SupabaseService Methods

- `initialize()`: Async initialization (called in main.dart, non-blocking)
- `getAvailableTimeSlots(String sessionType, int durationMinutes, {DateTime? startDate, DateTime? endDate})`: Query available booking ranges
- `createAppointment(Appointment appointment)`: Insert new booking (checks for overlaps)
- `getAppointments({String? status})`: Retrieve confirmed bookings with nested time_slot data

### Important Backend Logic

**Slot Availability**: The app does NOT mark time_slots as unavailable in the database. Instead, it:

1. Fetches all time_slot ranges (e.g., 8:00-20:00 with duration)
2. Generates individual bookable slots (15 or 30-min increments)
3. Fetches all confirmed appointments
4. Dynamically checks for overlaps client-side
5. For 60/90-min sessions: verifies consecutive free slots exist

**Rationale**: Time slots are ranges; multiple independent bookings can fit within one slot (e.g., 10:00-12:00 slot can have 10:00 and 10:30 bookings).

## Time Handling (Critical)

### UTC Timezone Normalization

All timestamps from Supabase arrive in UTC (+00:00). The app normalizes these:

```dart
// Input from Supabase: "2024-12-17T10:00:00+00:00"
// → Replace "+00:00" with "Z" for Dart compatibility
// → Parse as UTC DateTime
// → Display in user's local context
```

Both [TimeSlot](lib/models/time_slot.dart) and [Appointment](lib/models/appointment.dart) models handle this conversion in their `fromJson` methods.

### Dual Appointment Format Support

The [Appointment](lib/models/appointment.dart) model supports two formats for backward compatibility:

- **New format**: Uses `appointment_start_time` and `appointment_end_time` (exact booking times)
- **Legacy format**: Falls back to `time_slot` nested object if exact times unavailable

When creating appointments, always provide exact times.

## Session Type Naming

The app maintains TWO naming systems:

### UI-facing (user-friendly)

- `'15min'` - 15-minute free consultation
- `'60min'` - 60-minute paid session
- `'90min'` - 90-minute paid session

### Database format (legacy compatibility)

- `'consultation_15'`
- `'session_60'`
- `'session_90'`

Conversion happens in [booking_form_screen.dart:194-202](lib/screens/booking/booking_form_screen.dart#L194-L202) via `_convertSessionTypeForDB()` method.

**Always convert UI types to DB types before creating appointments.**

## UI/UX Conventions

### Theme & Styling

- **Theme**: Centralized in [lib/theme/app_theme.dart](lib/theme/app_theme.dart) using Material 3
- **Colors**: Defined in [lib/constants/colors.dart](lib/constants/colors.dart)
- **Gradients**: Soft pastel gradients (pinks/purples) used throughout app
- **Typography**:
  - Headlines: Playfair Display (elegant serif)
  - Body text: Inter (clean sans-serif)

### Visual Patterns

- **Loading States**: Show `CircularProgressIndicator` during async operations
- **Disabled States**: Disable buttons during form submission
- **Selection Highlighting**: Use color changes to indicate selected items
- **Error Feedback**: Display `SnackBar` with user-friendly Ukrainian messages
- **Icons + Text**: All interactive elements have both icon and text for clarity

### Navigation

- Use `Navigator.push()` for forward navigation
- Use `Navigator.pop()` to return to previous screen
- Use `Navigator.popUntil(route.isFirst)` to return to HomeScreen from deep flows

## Code Conventions

### General

- **Language**: Dart 3.9.2+
- **Naming**: camelCase for variables/functions, PascalCase for classes
- **Immutability**: Prefer immutable models with final fields
- **Null Safety**: Fully enabled, use `?` and `!` appropriately
- **Linting**: `flutter_lints` package (configured in [analysis_options.yaml](analysis_options.yaml))
  - `avoid_print: false` (debug prints are allowed)

### Logging

Debug prints use emojis for visual scanning:

- 🔄 Data loading
- 📝 Data processing
- ⛔ Errors
- ✅ Success

Example: `print('🔄 Fetching time slots...');`

### Error Handling

- Wrap async operations in `try-catch` blocks
- Check `mounted` before calling `setState()` or showing dialogs after async operations
- Display user-friendly error messages in Ukrainian
- Log errors with `print()` for debugging

Example:

```dart
try {
  await SupabaseService.createAppointment(appointment);
  if (!mounted) return;
  Navigator.push(...);
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Помилка: $e')),
  );
}
```

### Form Validation

- Use `GlobalKey<FormState>` for form validation
- Validate on submit, not on every keystroke
- Email regex: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
- Phone regex: `^\+?[0-9]{10,}$` (10+ digits)
- At least one contact method (email OR phone) must be provided

## Working with Models

### Creating Models

Models are immutable value objects with:

- `final` fields
- `fromJson` factory constructor
- `toJson` method
- Proper timezone handling for DateTime fields

Example structure:

```dart
class MyModel {
  final String id;
  final DateTime createdAt;

  const MyModel({required this.id, required this.createdAt});

  factory MyModel.fromJson(Map<String, dynamic> json) {
    // Handle UTC timezone normalization
    String timeString = json['created_at'].replaceAll('+00:00', 'Z');
    return MyModel(
      id: json['id'],
      createdAt: DateTime.parse(timeString),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
  };
}
```

### Riverpod Provider Parameters

When passing parameters to `FutureProvider.family`, use immutable classes with proper equality:

```dart
class QueryParams {
  final String type;
  final int duration;

  const QueryParams(this.type, this.duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryParams && type == other.type && duration == other.duration;

  @override
  int get hashCode => type.hashCode ^ duration.hashCode;
}
```

This ensures Riverpod correctly caches and invalidates providers.

## Common Tasks

### Adding a New Screen

1. Create file in `lib/screens/` or appropriate subdirectory
2. Extend `StatelessWidget` or `StatefulWidget`
   - Use `ConsumerWidget`/`ConsumerStatefulWidget` if accessing Riverpod providers
3. Implement `build()` method with Material 3 components
4. Apply gradient background using `AppColors` constants
5. Add navigation from appropriate parent screen
6. Update navigation flow if part of multi-step process

### Adding a New Data Model

1. Create file in `lib/models/`
2. Define immutable class with `final` fields
3. Implement `fromJson` factory constructor
   - Handle UTC timezone normalization for DateTime fields
   - Parse nested objects if needed
4. Implement `toJson` method for database insertion
5. Use model in `SupabaseService` methods

### Adding a Riverpod Provider

1. Define provider in appropriate screen file or separate providers file:
   ```dart
   final myProvider = FutureProvider.autoDispose<MyData>((ref) async {
     return await SupabaseService.getMyData();
   });
   ```
2. Watch provider in widget:
   ```dart
   final dataAsync = ref.watch(myProvider);
   return dataAsync.when(
     data: (data) => MyWidget(data),
     loading: () => CircularProgressIndicator(),
     error: (err, stack) => Text('Error: $err'),
   );
   ```
3. Invalidate when data changes:
   ```dart
   ref.invalidate(myProvider);
   ```

### Modifying Booking Flow

The booking flow is tightly coupled across 4 screens. When modifying:

1. **Changing session types/durations**: Update both UI strings and DB conversion logic in [booking_form_screen.dart](lib/screens/booking/booking_form_screen.dart)
2. **Adding fields to form**: Update [Appointment](lib/models/appointment.dart) model, database schema, and [booking_form_screen.dart](lib/screens/booking/booking_form_screen.dart)
3. **Changing availability logic**: Modify slot generation and overlap checking in [booking_calendar_screen.dart](lib/screens/booking/booking_calendar_screen.dart)
4. **Changing business hours**: Update `_generateTimeSlots()` method in [booking_calendar_screen.dart](lib/screens/booking/booking_calendar_screen.dart)

### Adding External WebView Content

Use the existing [WebViewScreen](lib/screens/webview_screen.dart):

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WebViewScreen(
      url: 'https://example.com',
      title: 'Page Title',
    ),
  ),
);
```

WebViewController is already configured with JavaScript enabled and error handling.

## Testing

Currently minimal testing infrastructure (default widget test only). To add tests:

```dart
// Unit test example (lib/services/supabase_service.dart)
test('getAvailableTimeSlots filters by session type', () async {
  final slots = await SupabaseService.getAvailableTimeSlots('consultation_15', 15);
  expect(slots.every((s) => s.sessionType == 'consultation_15'), true);
});

// Widget test example
testWidgets('BookingDurationScreen displays session options', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Запис'));
  await tester.pumpAndSettle();
  expect(find.text('15 хвилин'), findsOneWidget);
});
```

Run tests with `flutter test`.

## Platform-Specific Notes

### Android

- Minimum SDK: 21 (Android 5.0)
- App icons configured via `flutter_launcher_icons`
- Build APK: `flutter build apk --release`
- Build App Bundle: `flutter build appbundle --release`

### iOS

- Build: `flutter build ios --release`
- Requires macOS with Xcode installed
- App icons configured via `flutter_launcher_icons`

### Web

- Build: `flutter build web --release`
- WebView functionality limited on web platform

## Troubleshooting

### Common Issues

**Provider not updating after data change**:

- Call `ref.invalidate(provider)` to force refresh
- Ensure provider is `.autoDispose` if data shouldn't persist

**Timezone issues with appointments**:

- Verify Supabase returns UTC timestamps
- Check `fromJson` methods normalize "+00:00" to "Z"
- Display times in user's local timezone

**Slot availability showing incorrect results**:

- Check overlap logic in [booking_calendar_screen.dart:300-350](lib/screens/booking/booking_calendar_screen.dart#L300-L350)
- Verify appointments table has correct `appointment_start_time` and `appointment_end_time`
- Ensure time_slots query filters by correct `session_type` and `duration_minutes`

**Form validation errors**:

- Verify at least email OR phone is provided (both can be empty individually)
- Check regex patterns match expected formats

**Build errors after dependency update**:

- Run `flutter clean` then `flutter pub get`
- Check dependency version conflicts with `flutter pub outdated`
