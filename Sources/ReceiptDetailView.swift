import SwiftUI

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let data = receipt.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }

                VStack(spacing: 16) {
                    DetailRow(label: "Vendor", value: receipt.vendor)
                    DetailRow(label: "Amount", value: "\(receipt.currency) \(String(format: "%.2f", receipt.amount))")
                    DetailRow(label: "Date", value: receipt.date.formatted(date: .long, time: .omitted))
                    DetailRow(label: "Category", value: receipt.category.rawValue, icon: receipt.category.icon)

                    if !receipt.notes.isEmpty {
                        DetailRow(label: "Notes", value: receipt.notes)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(receipt.vendor)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var icon: String?

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.orange)
                }
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
}
