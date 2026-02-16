import SwiftUI
import SwiftData

struct ProcessingView: View {
    let image: UIImage
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isProcessing = true
    @State private var result: ExtractionResult?
    @State private var error: String?

    // Editable fields
    @State private var vendor = ""
    @State private var amount = ""
    @State private var currency = "USD"
    @State private var date = Date()
    @State private var category: ExpenseCategory = .other
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Receipt image preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)

                    if isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Extracting receipt data…")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if let error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        // Editable fields
                        VStack(spacing: 16) {
                            LabeledField("Vendor", text: $vendor)

                            HStack(spacing: 12) {
                                LabeledField("Amount", text: $amount)
                                    .keyboardType(.decimalPad)
                                LabeledField("Currency", text: $currency)
                                    .frame(width: 80)
                            }

                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .padding(.horizontal)

                            Picker("Category", selection: $category) {
                                ForEach(ExpenseCategory.allCases) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal)
                        }

                        Button(action: save) {
                            Label(saved ? "Saved!" : "Save Receipt", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(saved ? Color.green : Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(saved)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
        }
        .task { await extract() }
    }

    private func extract() async {
        do {
            let r = try await ReceiptExtractionService.shared.extract(image: image)
            result = r
            vendor = r.vendor
            amount = String(format: "%.2f", r.amount)
            currency = r.currency
            date = r.date
            category = r.category
            isProcessing = false
        } catch {
            self.error = error.localizedDescription
            isProcessing = false
        }
    }

    private func save() {
        let receipt = Receipt(
            vendor: vendor,
            amount: Double(amount) ?? 0,
            currency: currency,
            date: date,
            category: category,
            imageData: image.jpegData(compressionQuality: 0.7)
        )
        modelContext.insert(receipt)
        saved = true
        // Auto-dismiss after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onDismiss()
        }
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }
}
