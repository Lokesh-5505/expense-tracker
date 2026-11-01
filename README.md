# 💎 Expense Tracker — Offline-First Personal Finance App

A complete, production-quality, premium fintech mobile application built purely with **Flutter & Dart**, adhering strictly to Material 3 design tokens. The app is fully self-contained, offline-first, requiring no backend, no cloud services, and no authentication.

---

## 📱 Visual Preview & UI Showcase

The app features a modern, dark-first fintech design with subtle gradients, responsive typography (tabular figures for currency alignment), and smooth micro-interactions.

- **Theme Engine**: Material 3 with Dynamic Light and Dark modes.
- **Custom Accent Seeds**: Deep Indigo, Emerald Green, Royal Blue, Sunset Amber, Crimson Rose, Violet Purple, Teal Cyan, Coral Orange.
- **Zero Glitch Data Pipeline**: Debounced local JSON storage ensuring continuous 60fps frame rates.

---

## 🌟 Key Features

### 1. 💳 Core Transactions Management
- **Type Toggle**: Expense, Income, and Account Transfers with dynamic accent colors (Red for Expense, Green for Income, Blue for Transfer).
- **Fast Numeric Keypad**: In-app custom numeric keypad with decimal support and real-time validation.
- **Swipe-to-Delete**: Smooth swipe dismiss with an instant **Undo** SnackBar that restores the transaction.
- **Quick Action Sheet**: Long-press any transaction to edit, duplicate, or delete.
- **Interactive Search & Multi-Filters**: Filter by keyword, transaction type, category multi-select, wallet account, date range, and amount range. Sort by newest, oldest, highest amount, and lowest amount.

### 2. 🏦 Multi-Account / Wallets
- Multiple accounts: Cash, Bank Account, Credit Cards, UPI, Debit Cards, and Custom Wallets.
- Dynamic balance calculation computed automatically from income, expense, and inter-wallet transfers.
- **Safe Wallet Deletion**: If an account has associated transactions, the user is required to safely reassign them to another wallet before deletion.

### 3. 🏷️ Categories Management
- 14 built-in categories (Food & Dining, Transport, Shopping, Bills & Utilities, Health, Entertainment, Education, Groceries, Rent, Travel, Salary, Freelance, Gift, Other).
- **Custom Category Creator**: Add custom categories with custom name, icon picker (over 20 icons), and color palette.
- **Cascading Fallback**: Deleting a category automatically moves transactions to the fallback **"Other"** category.

### 4. 📊 Interactive Analytics & Charts (`fl_chart`)
- **Interactive Donut Chart**: Touch slices to reveal category spend totals and percentage contributions.
- **Trend Bar Chart**: Weekly, monthly, and yearly spending distribution with high-water marks.
- **Cumulative Spending Curve**: Line chart tracking cumulative expenditure over the selected timeframe.
- **Category Ranking**: Visual progress bars displaying top-spending areas.

### 5. 🎯 Budgets & Pacing Alerts
- Overall monthly budget and category-specific budgets.
- **Visual Thresholds**:
  - 🟢 Green below 70%
  - 🟠 Orange at 80%+
  - 🔴 Red when budget limit is exceeded
- Real-time **"Remaining per day"** calculation to help pace spending throughout the month.

### 6. 🏆 Savings Goals
- Target amounts with optional completion target dates.
- Add or withdraw contributions on demand.
- Animated progress bars, remaining amounts, and a celebration dialog when a goal is reached.

### 7. 🔄 Automated Recurring Transactions
- Rules for subscriptions, rent, salary, and bills (daily, weekly, monthly, yearly intervals).
- **Auto-catch-up Engine**: Runs automatically on app launch and lifecycle resume, backfilling missed transactions without creating duplicates.
- Pause, resume, edit, or delete recurring rules.

### 8. 🧠 Local Smart Insights (Zero External AI/API Dependencies)
- Local heuristics analyzing monthly cashflow, category trends ("Spent 18% more on Food vs last month"), peak spending days of the week, and savings rates.

### 9. 🔒 Privacy, Security & Data Backup
- **4-Digit PIN Lock**: Gatekeeper with shake animation on incorrect PIN and Forgot PIN recovery.
- **CSV Export**: Export filtered transactions into a formatted CSV and share via native system share sheet.
- **Offline JSON Backup & Restore**: Create full offline backup snapshots and restore by pasting backup JSON.
- **Double Confirmation Wipe**: Erase all data and return the app to initial factory state.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── main.dart                      # Root entry point, orientation lock, theme switcher & AppRootGate
├── models/                        # Immutable data models with toJson/fromJson & copyWith
│   ├── budget.dart                # Budget entity (overall & category budgets)
│   ├── category.dart              # Category entity with default categories
│   ├── goal.dart                  # Savings goal entity
│   ├── recurring_rule.dart        # Recurring transaction rule entity
│   ├── transaction.dart           # Transaction entity (Expense, Income, Transfer)
│   └── wallet.dart                # Wallet account entity
├── screens/                       # Presentation screens
│   ├── add_edit_transaction_screen.dart # Transaction form with custom keypad
│   ├── budgets_screen.dart        # Monthly & category budget tracker
│   ├── goals_screen.dart          # Savings goals with deposit/withdraw
│   ├── home_screen.dart           # Dashboard with balance card, quick stats, & insights
│   ├── lock_screen.dart           # 4-Digit PIN lock with shake animation
│   ├── more_screen.dart           # Navigation hub for budgets, goals, recurring, settings
│   ├── onboarding_screen.dart     # First-time user setup flow
│   ├── recurring_screen.dart      # Recurring transaction rules manager
│   ├── settings_screen.dart       # Preferences, currency, export/backup, PIN setup
│   ├── stats_screen.dart          # fl_chart analytics (donut, bar, line curves)
│   ├── transactions_screen.dart   # Searchable & filterable transaction ledger
│   └── wallets_screen.dart        # Accounts & wallet balance manager
├── services/                      # Application state & business logic
│   ├── app_state.dart             # Root ChangeNotifier + AppStateScope InheritedNotifier
│   ├── export_service.dart        # CSV generation & JSON backup/restore validation
│   ├── insights_service.dart      # Offline analytics & spending heuristics
│   └── storage_service.dart       # SharedPreferences debounced JSON storage engine
├── theme/                         # Styling & Design System
│   ├── app_colors.dart            # Semantic colors & accent seed palettes
│   ├── app_text_styles.dart       # Typography with tabular figure formatting
│   └── app_theme.dart             # Material 3 Light & Dark themes
├── utils/                         # Utilities & Helper functions
│   ├── constants.dart             # App constants, defaults, and currency definitions
│   ├── formatters.dart            # Indian number system, compact numbers, date helpers
│   └── validators.dart            # Input validation routines
└── widgets/                       # Reusable UI components
    ├── animated_counter.dart      # Smooth rolling number counter
    ├── balance_card.dart          # Gradient account balance card
    ├── budget_progress_bar.dart   # Color-coded budget threshold bar
    ├── category_chip.dart         # Selectable category badge
    ├── category_icon_picker.dart  # Modal dialog for icon selection
    ├── color_picker.dart          # Palette selector for custom categories
    ├── empty_state.dart           # Clean placeholder for empty lists
    ├── filter_bottom_sheet.dart   # Transaction filter & sorting sheet
    ├── goal_progress.dart         # Savings goal card with contribution actions
    ├── insight_card.dart          # Smart heuristic advice banner
    ├── numeric_keypad.dart        # In-app keypad with decimal support
    ├── period_selector.dart       # Day/Week/Month/Year toggle
    ├── quick_stats_row.dart       # Today / This Week / Daily Avg cards
    ├── stat_charts.dart           # fl_chart Donut, Bar, and Line curve wrappers
    ├── transaction_tile.dart      # Swipe-to-delete transaction item with undo
    └── wallet_card.dart           # Account balance card with edit/delete
```

### Constraints & Architectural Patterns:
- **State Management**: Built-in `ChangeNotifier` + `InheritedNotifier<AppState>` (`AppStateScope`) + `ListenableBuilder`. No third-party state managers (No Bloc, Riverpod, GetX, or Provider).
- **Data Persistence**: `shared_preferences` storing atomic JSON documents with a 400ms debouncing pipeline to prevent I/O blocking during fast transaction entries.
- **Design System**: Material 3 (`useMaterial3: true`), null-safe Dart 3, zero analyzer errors.

---

## 📦 Dependencies

The project strictly utilizes only the approved minimal set of production-grade packages:

| Package | Version | Purpose in Application |
|---|---|---|
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `^2.5.6` | Offline local persistence of transactions, wallets, categories, budgets, goals, and settings. |
| [`intl`](https://pub.dev/packages/intl) | `^0.20.3` | Multi-currency formatting, Indian number system (Lakhs/Crores), compact values, and localized date parsing. |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | `^1.3.0` | High-performance interactive Donut Charts, Weekly/Monthly Spending Bar Charts, and Cumulative Line Curves. |
| [`uuid`](https://pub.dev/packages/uuid) | `^4.6.0` | Cryptographically secure UUIDv4 generation for unique entity IDs. |
| [`path_provider`](https://pub.dev/packages/path_provider) | `^2.1.6` | Locates temporary directory for saving generated CSV export files prior to sharing. |
| [`share_plus`](https://pub.dev/packages/share_plus) | `^13.3.1` | Native Android/iOS system share sheet integration for exporting CSV files. |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | `^1.0.8` | Default icon assets. |

---

## 🚀 Local Setup & Running Instructions

### System Prerequisites
1. **Flutter SDK**: Version `3.13.0` or higher (tested with Flutter 3.47.8 / Dart 3.13.7).
   - Verify by running `flutter --version`.
2. **Editor**: VS Code or Android Studio with Flutter and Dart extensions.
3. **Environment Check**:
   ```bash
   flutter doctor
   ```

### 1. Clone & Install Dependencies
```bash
git clone <repository_url>
cd expense-tracker
flutter pub get
```

### 2. Verify Code Quality & Static Analysis
Run static analysis (must report zero warnings and zero errors):
```bash
flutter analyze
```

### 3. Run Automated Unit & Widget Tests
Execute the comprehensive test suite (13/13 passing):
```bash
flutter test
```

### 4. Run Locally Across Targets

#### Run on Web (Google Chrome):
```bash
flutter run -d chrome --web-port=5000
```
Then visit `http://localhost:5000/` in your browser.

#### Run on Android Device / Emulator:
1. Connect your Android phone with **USB Debugging** enabled (or start an Android Emulator).
2. Check connected devices:
   ```bash
   flutter devices
   ```
3. Launch the app in debug mode:
   ```bash
   flutter run
   ```

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

---

## 📦 How to Generate Release Android APK

This repository includes a complete Android target. The workflow at
`.github/workflows/build-apk.yml` builds a universal APK automatically on every
push to `main`. You can download it from the completed workflow's **Artifacts**
section on GitHub.

When you are ready to produce an installable APK for Android devices:

### Option A: Build Split APKs (Smallest Download Size)
Generates separate APKs tailored for each CPU architecture (ARM64 for modern phones, ARMv7 for older phones):
```bash
flutter build apk --release --split-per-abi
```
Generated APK outputs:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Option B: Build Universal APK (Installs on Any Android Device)
Generates a single APK that contains native binaries for all architectures:
```bash
flutter build apk --release
```
Generated APK output:
- `build/app/outputs/flutter-apk/app-release.apk`

The APK uses application ID `com.lokesh5505.expensetracker` and is signed with
Flutter's default debug key for convenient direct installation. For Google Play
publishing, configure a private release keystore and signing configuration.

### Installing APK on an Android Phone
Once generated, you can install the APK directly to any connected Android phone via ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Alternatively, transfer `app-release.apk` to your phone via Google Drive, WhatsApp, or USB cable, and tap to install (enable "Install Unknown Apps" in phone settings).

---

## 🧪 Automated Test Suite Coverage

The test suite in [`test/expense_tracker_test.dart`](file:///c:/Users/ramlo/expense-tracker/test/expense_tracker_test.dart) and [`test/widget_test.dart`](file:///c:/Users/ramlo/expense-tracker/test/widget_test.dart) verifies all core application mechanics:

1. **Transactions Lifecycle**: Add expense, income, and account transfers; update balances; edit transactions; duplicate transactions; swipe-to-delete with undo restoration.
2. **Multi-Wallet Accounting**: Real-time balance calculations across accounts; atomic inter-wallet transfers; mandatory transaction reassignment when deleting a wallet with associated entries.
3. **Category Fallbacks**: Adding custom categories; deleting categories and verifying cascading transfer to "Other".
4. **Budget Alerts & Pacing**: Monthly budget pacing, category budget thresholds (Green, Orange, Red alerts).
5. **Savings Goals**: Goal creation, deposit contributions, withdrawals, target reach detection.
6. **Recurring Engine**: Automated catch-up logic backfilling missed recurring transactions without duplicate creation.
7. **Number & Currency Formatters**: Indian numbering system (`₹1,50,000.00`), compact notation (`1.5L`, `1.2Cr`), currency prefixes.
8. **Validators & Security**: Amount regex, PIN length checks, backup JSON schema validation.
9. **Smart Insights**: Local heuristic engine generating spending insights without external APIs.
10. **Widget Smoke Test**: Full root widget mounting and smoke verification.

---

## ⚙️ Configuration & Customization

### Changing the App Icon
1. Place a 1024x1024 PNG icon at `assets/icon/app_icon.png`.
2. Add `flutter_launcher_icons` to `dev_dependencies` in `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1

   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
   ```
3. Run:
   ```bash
   dart run flutter_launcher_icons
   ```

### Changing the Android Package ID
1. Open `android/app/build.gradle.kts`.
2. Change `applicationId = "com.example.expense_tracker"` to your own domain ID (e.g., `com.mycompany.expensetracker`).

---

## 📄 License
This project is open-source and free to use for personal and commercial applications.
