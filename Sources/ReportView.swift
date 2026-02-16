import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        return cal.dateInterval(of: .month, for: .now)!.start
    }()

    private var monthReceipts: [Receipt] {
        let cal = Calendar.current
        return receipts.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        var totals: [ExpenseCategory: Double] = [:]
        for r in monthReceipts {
            totals[r.category, default: 0] += r.amount
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
    }

    private var totalSpend: Double {
        monthReceipts.reduce(0) { $0 + $1.amount }
    }

    private var availableMonths: [Date] {
        let cal = Calendar.current
        let months = Set(receipts.map { cal.dateInterval(of: .month, for: $0.date)!.start })
        return months.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month picker
                    if !availableMonths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableMonths, id: \.self) { month in
                                    FilterChip(
                                        title: month.formatted(.dateTime.month(.abbreviated).year()),
                                        isSelected: selectedMonth == month
                                    ) {
                                        selectedMonth = month
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Total
                    VStack(spacing: 4) {
                        Text("Total Spend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "$%.2f", totalSpend))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    // Pie chart
                    if !categoryTotals.isEmpty {
                        Chart(categoryTotals, id: \.category) { item in
                            SectorMark(
                                angle: .value("Amount", item.total),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Category", item.category.rawValue))
                            .cornerRadius(4)
                        }
                        .chartLegend(position: .bottom, spacing: 12)
                        .frame(height: 250)
                        .padding(.horizontal)

                        // Breakdown list
                        VStack(spacing: 0) {
                            ForEach(categoryTotals, id: \.category) { item in
                                HStack {
                                    Image(systemName: item.category.icon)
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text(item.category.rawValue)
                                    Spacer()
                                    Text(String(format: "$%.2f", item.total))
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                if item.category != categoryTotals.last?.category {
                                    Divider().padding(.leading, 48)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else {
                        ContentUnavailableView {
                            Label("No Data", systemImage: "chart.pie")
                        } description: {
                            Text("No receipts for this month.")
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: shareCSV) {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        Button(action: sharePDF) {
                            Label("Export PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(monthReceipts.isEmpty)
                }
            }
        }
    }

    private func shareCSV() {
        let csv = ExportService.generateCSV(receipts: monthReceipts, month: selectedMonth)
        let url = ExportService.writeTemp(content: csv, filename: "expenses-\(monthFilename()).csv")
        share(url: url)
    }

    private func sharePDF() {
        let url = ExportService.generatePDF(receipts: monthReceipts, totals: categoryTotals, month: selectedMonth, total: totalSpend)
        share(url: url)
    }

    private func monthFilename() -> String {
        selectedMonth.formatted(.dateTime.year().month(.twoDigits))
    }

    private func share(url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(ac, animated: true)
    }
}
