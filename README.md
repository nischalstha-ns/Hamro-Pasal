# Digital Khata - डिजिटल खाता

A fully offline, Material 3, production-grade mobile business management app for Nepal's SME market.

## 🚀 Features

- ✅ **Offline-First**: Zero network requirement for core features
- ✅ **Material 3 Design**: Modern, beautiful UI with Nepal green theme
- ✅ **Nepali Support**: Full Nepali language and Bikram Sambat calendar
- ✅ **Business Management**: Products, Customers, Transactions, Reports
- ✅ **Nepal-Specific**: VAT (13%), IRD-compliant invoices, local payment methods
- ✅ **Responsive**: Mobile-first with tablet support (600px+ breakpoint)

## 🛠️ Tech Stack

- **Flutter**: 3.24+
- **Dart**: 3.4+
- **State Management**: flutter_riverpod 2.x
- **Database**: drift 2.x (SQLite)
- **Navigation**: go_router 14.x
- **PDF**: pdf + printing
- **Charts**: fl_chart
- **Barcode**: mobile_scanner
- **Calendar**: nepali_utils

## 📦 Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

Run code generation for Drift, Riverpod, and Freezed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch for changes:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Generate Localizations

```bash
flutter gen-l10n
```

### 4. Run the App

```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App configuration
├── core/                     # Shared code
│   ├── theme/               # Material 3 theme
│   ├── router/              # Navigation
│   ├── database/            # Drift database
│   ├── utils/               # Utilities
│   ├── constants/           # Constants
│   └── widgets/             # Shared widgets
├── features/                # Feature modules
│   ├── dashboard/
│   ├── products/
│   ├── customers/
│   └── transactions/
└── l10n/                    # Localization files
```

## 🎨 Material 3 Theme

- **Seed Color**: `0xFF1D9E75` (Nepal Green)
- **Components**: NavigationBar, FilledButton, Cards with M3 elevation
- **Dynamic Color**: Android 12+ support

## 🇳🇵 Nepal-Specific Features

- **Currency**: Nepali Rupee (Rs. / रु) with format: Rs. 1,23,456.00
- **VAT**: 13% default (configurable)
- **Calendar**: Bikram Sambat (BS) primary, AD secondary
- **Languages**: Nepali (Devanagari) + English
- **Payment Methods**: Cash, eSewa, Khalti, fonepay, Bank Transfer
- **Fiscal Year**: Shrawan 1 to Ashadh end (BS)

## 🔧 Development Commands

### Code Generation
```bash
# Generate once
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch --delete-conflicting-outputs
```

### Localization
```bash
flutter gen-l10n
```

### Clean Build
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 📱 Responsive Design

- **Mobile**: 360px minimum width
- **Tablet**: 600px+ (NavigationRail + master-detail)
- **Adaptive**: LayoutBuilder for all screens

## 🗄️ Database Schema

### Tables
- **Products**: id, name, price, stock, category, etc.
- **Customers**: id, name, phone, email, balance, etc.
- **Transactions**: id, type, amount, payment method, etc.
- **TransactionItems**: id, transaction_id, product_id, quantity, etc.
- **Settings**: key-value pairs

## 🔐 Offline-First Architecture

- All data stored in SQLite via Drift
- Images in `getApplicationDocumentsDirectory()`
- Background sync when connectivity detected
- Offline indicator in AppBar

## 📝 TODO

- [ ] Complete Products CRUD
- [ ] Complete Customers CRUD
- [ ] Transaction management
- [ ] Reports & Analytics
- [ ] PDF Invoice generation
- [ ] Barcode scanning
- [ ] Cloud backup (Google Drive)
- [ ] Bluetooth printing
- [ ] Multi-language toggle
- [ ] Settings screen

## 🤝 Contributing

This is a production app for Nepal's SME market. Follow the architecture rules strictly.

## 📄 License

Private project - All rights reserved
