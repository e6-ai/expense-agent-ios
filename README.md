# Expense Agent

AI-powered receipt scanning and expense tracking. Snap a photo → done.

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate project: `xcodegen generate`
3. Open `ExpenseAgent.xcodeproj` in Xcode
4. Run on device (camera requires physical device)
5. Add your OpenAI API key in Settings

## Features

- **Camera-first UX** — app opens to camera, snap a receipt
- **AI extraction** — GPT-4o Vision extracts vendor, amount, date, category
- **Receipt list** — filter by month, category, search by vendor
- **Monthly reports** — pie chart breakdown, total spend
- **Export** — CSV and PDF via share sheet
- **Secure** — API key stored in iOS Keychain, all data on-device

## Tech Stack

- SwiftUI + SwiftData (iOS 17+)
- OpenAI GPT-4o Vision API
- Swift Charts framework
- XcodeGen for project generation
- Codemagic CI/CD
