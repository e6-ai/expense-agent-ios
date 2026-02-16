import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Binding var showCamera: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]

    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedMonth: Date?
    @State private var capturedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var showProcessing = false

    private var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            if !searchText.isEmpty {
                guard receipt.vendor.localizedCaseInsensitiveContains(searchText) else { return false }
            }
            if let cat = selectedCategory {
                guard receipt.category == cat else { return false }
            }
            if let month = selectedMonth {
                let cal = Calendar.current
                guard cal.isDate(receipt.date, equalTo: month, toGranularity: .month) else { return false }
            }
            return true
        }
    }

    private var availableMonths: [Date] {
        let cal = Calendar.current
        let months = Set(receipts.map { cal.dateInterval(of: .month, for: $0.date)!.start })
        return months.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            Group {
                if receipts.isEmpty {
                    ContentUnavailableView {
                        Label("No Receipts", systemImage: "receipt")
                    } description: {
                        Text("Tap the camera button to scan your first receipt.")
                    }
                } else {
                    List {
                        // Filters
                        if !receipts.isEmpty {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                            selectedCategory = nil
                                        }
                                        ForEach(ExpenseCategory.allCases) { cat in
                                            FilterChip(
                                                title: cat.rawValue,
                                                icon: cat.icon,
                                                isSelected: selectedCategory == cat
                                            ) {
                                                selectedCategory = selectedCategory == cat ? nil : cat
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }

                                if !availableMonths.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            FilterChip(title: "All Time", isSelected: selectedMonth == nil) {
                                                selectedMonth = nil
                                            }
                                            ForEach(availableMonths, id: \.self) { month in
                                                FilterChip(
                                                    title: month.formatted(.dateTime.month(.abbreviated).year()),
                                                    isSelected: selectedMonth == month
                                                ) {
                                                    selectedMonth = selectedMonth == month ? nil : month
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .padding(.horizontal)
                        }

                        // Receipt list
                        Section {
                            ForEach(filteredReceipts) { receipt in
                                NavigationLink {
                                    ReceiptDetailView(receipt: receipt)
                                } label: {
                                    ReceiptRow(receipt: receipt)
                                }
                            }
                            .onDelete(perform: deleteReceipts)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search vendors")
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showCamera = true }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                        Button(action: { showPhotoPicker = true }) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(image: $capturedImage)
            }
            .sheet(isPresented: $showProcessing) {
                if let img = capturedImage {
                    ProcessingView(image: img) {
                        showProcessing = false
                        capturedImage = nil
                    }
                }
            }
            .onChange(of: capturedImage) { _, newValue in
                if newValue != nil {
                    showProcessing = true
                }
            }
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredReceipts[index])
        }
    }
}

struct ReceiptRow: View {
    let receipt: Receipt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: receipt.category.icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.vendor)
                    .font(.headline)
                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(receipt.currency) \(receipt.amount, specifier: "%.2f")")
                .font(.headline.monospacedDigit())
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.orange : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
