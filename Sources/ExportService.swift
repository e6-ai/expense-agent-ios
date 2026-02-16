import Foundation
import UIKit

enum ExportService {
    static func generateCSV(receipts: [Receipt], month: Date) -> String {
        var csv = "Date,Vendor,Category,Amount,Currency\n"
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for r in receipts.sorted(by: { $0.date < $1.date }) {
            let line = "\(df.string(from: r.date)),\"\(r.vendor)\",\"\(r.category.rawValue)\",\(String(format: "%.2f", r.amount)),\(r.currency)"
            csv += line + "\n"
        }
        return csv
    }

    static func writeTemp(content: String, filename: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func generatePDF(receipts: [Receipt], totals: [(category: ExpenseCategory, total: Double)], month: Date, total: Double) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("expenses-\(month.formatted(.dateTime.year().month(.twoDigits))).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let headingFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)

            var y: CGFloat = 40

            // Title
            let title = "Expense Report — \(month.formatted(.dateTime.month(.wide).year()))"
            title.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: titleFont])
            y += 40

            // Total
            let totalStr = "Total: $\(String(format: "%.2f", total))"
            totalStr.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: headingFont])
            y += 30

            // Category breakdown
            "Category Breakdown".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: headingFont])
            y += 22
            for item in totals {
                let line = "\(item.category.rawValue): $\(String(format: "%.2f", item.total))"
                line.draw(at: CGPoint(x: 56, y: y), withAttributes: [.font: bodyFont])
                y += 18
            }
            y += 20

            // Receipt table
            "Receipts".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: headingFont])
            y += 22

            let df = DateFormatter()
            df.dateFormat = "MMM d"

            for r in receipts.sorted(by: { $0.date < $1.date }) {
                if y > 740 {
                    context.beginPage()
                    y = 40
                }
                let line = "\(df.string(from: r.date))  \(r.vendor)  \(r.category.rawValue)  \(r.currency) \(String(format: "%.2f", r.amount))"
                line.draw(at: CGPoint(x: 56, y: y), withAttributes: [.font: bodyFont])
                y += 18
            }
        }

        try? data.write(to: url)
        return url
    }
}
