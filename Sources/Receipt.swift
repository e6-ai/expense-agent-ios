import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food & Drink"
    case transport = "Transport"
    case office = "Office"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health"
    case travel = "Travel"
    case utilities = "Utilities"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .office: return "briefcase.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .travel: return "airplane"
        case .utilities: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Receipt {
    var vendor: String
    var amount: Double
    var currency: String
    var date: Date
    var categoryRaw: String
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date
    var notes: String

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        vendor: String = "",
        amount: Double = 0,
        currency: String = "USD",
        date: Date = .now,
        category: ExpenseCategory = .other,
        imageData: Data? = nil,
        notes: String = ""
    ) {
        self.vendor = vendor
        self.amount = amount
        self.currency = currency
        self.date = date
        self.categoryRaw = category.rawValue
        self.imageData = imageData
        self.createdAt = .now
        self.notes = notes
    }
}
