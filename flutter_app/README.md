# MyFarm Flutter migration

This directory is the parallel Flutter implementation. The existing Android
application remains in `../app` while features are migrated and checked for
parity; do not remove it until the migration is complete.

## Current migration stage

The Flutter app has generated Android and iOS hosts. Implemented flows include
Supabase configuration, session restoration, manager/supervisor/worker sign-in
routing, manager registration, farm setup, role-specific dashboards, employee
provisioning, role-aware navigation, farm activities, crops/plantings/harvests,
inventory and stock issuance, machinery and maintenance logs, storage, reports,
attendance, notifications, farm messaging, and account/farm settings.

This Flutter project targets **Android and iOS only**; web and desktop hosts
have not been generated. Android can be built on Windows, while building or
running the iOS host requires macOS with Xcode. The native Android app remains
available at `../app` during migration, and the Flutter Android application
uses a separate application ID so both can be installed for comparison.

## Android build

The Android SDK NDK `28.2.13676358` is required and is installed in the
development environment. Build a release APK from PowerShell with:

```powershell
cd flutter_app
..\flutter\bin\flutter.bat build apk
```

## Flutter source layout

The Dart folders follow the native app's package boundaries, using Dart's
conventional `snake_case.dart` file names:

- `lib/data/model`, `lib/data/remote`, and `lib/data/repository` mirror the
  Kotlin data packages.
- Typed models cover farm/division, crop lifecycle, activities, employees,
  attendance, inventory, machinery, storage, notifications, and reports.
- Repositories are separated by domain (`FarmRepository`, `CropRepository`,
  `DivisionRepository`, `FarmActivityRepository`, `EmployeeRepository`,
  `AttendanceRepository`, `InventoryRepository`, `MachineryRepository`,
  `StorageRepository`, `ReportRepository`, `NotificationRepository`, and
  `ChatRepository`).
  `FarmOperationsRepository` remains as the shared query adapter used by the
  current screens during the UI migration.
- `lib/ui/auth`, `lib/ui/farm`, `lib/ui/dashboard`, and `lib/ui/navigation`
  mirror the corresponding Kotlin UI packages.
- `lib/app/farm_app.dart` composes the Flutter app; `lib/main.dart` is its
  platform entry point.

## Supabase configuration

For Android, the Gradle build reads `SUPABASE_URL` and
`SUPABASE_ANON_KEY` from the repository-root `.env` file, matching the native
Android app. Keep `.env` local and do not commit it. The Android host passes
these public client settings to Flutter at runtime. Explicit `--dart-define`
values take precedence:

```powershell
cd flutter_app
flutter pub get
flutter run -d android
```

In VS Code, select **Flutter Android (local Supabase config)** in Run and
Debug and press F5. Android requires both settings in the repository-root
`.env`; builds without them show the configuration error screen.

On macOS, select an iOS simulator or device instead:

```powershell
flutter run -d ios --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

The `.env` file is read only by the Android Gradle build and is not copied into
Flutter assets.

## Conversion status and validation boundaries

The Flutter UI now includes searchable/status-filtered operational records,
record detail views, activity start/complete actions, machinery usage voiding
and maintenance cancellation with reasons, employee detail/edit/removal
actions, crop-yield recording and analytics, and typed report history/details
with category breakdown charts. Farm messaging includes conversation lists,
same-farm contact search, direct and group conversations, and realtime message
updates.

Employee removal follows the native repository contract
(`delete_worker_profile` / `delete_supervisor_profile`) and removes the farm
profile. It does not guarantee deletion of the linked Supabase Auth identity;
that behavior depends on the deployed database procedure.

No Supabase policy migrations or definitions are checked in, so deployed
expressions cannot be independently verified. Based on the policy inventory
provided for this migration, worker attendance and assigned-activity UI
requests are now filtered to the signed-in worker, supervisor roster reads
avoid querying other accounts, and employee editing changes only the profile
field permitted by the listed profile policies. Water issuance is hidden and
rejected because `water_issuance` has no policy in the supplied inventory.

The inventory also lists no policy for `machinery_usage`; its Flutter screens
will be denied by RLS if it is enabled without another policy. Access behavior
for `report_category_status` and the `generate_report` procedure also depends
on deployed view/function security settings that are not present here. The
listed attendance policies still grant farm-access users broad access to farm
attendance rows, regardless of the client-side worker filter; if workers
should only manage their own attendance, that restriction must be enforced in
the database. Verify these items in Supabase before treating role isolation
as complete.
Android release builds and Flutter tests/analyzer have been run locally.
Building or running the iOS host still requires macOS with Xcode and an iOS
simulator or device.
