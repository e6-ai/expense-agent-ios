import Foundation
import UIKit

struct ExtractionResult {
    var vendor: String
    var amount: Double
    var currency: String
    var date: Date
    var category: ExpenseCategory
}

final class ReceiptExtractionService {
    static let shared = ReceiptExtractionService()

    func extract(image: UIImage) async throws -> ExtractionResult {
        let apiKey = APIKeyManager.shared.apiKey
        guard !apiKey.isEmpty else {
            throw ExtractionError.noAPIKey
        }

        guard let jpeg = image.jpegData(compressionQuality: 0.6) else {
            throw ExtractionError.imageEncodingFailed
        }

        let base64 = jpeg.base64EncodedString()
        let prompt = """
        Extract receipt information from this image. Return ONLY valid JSON with these fields:
        {
          "vendor": "store name",
          "amount": 12.99,
          "currency": "USD",
          "date": "2025-01-15",
          "category": "Food & Drink"
        }
        Category must be one of: Food & Drink, Transport, Office, Shopping, Entertainment, Health, Travel, Utilities, Other.
        If you can't determine a field, use reasonable defaults. Amount must be a number. Date must be YYYY-MM-DD.
        """

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "low"]]
                    ]
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.1
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ExtractionError.apiError(errorBody)
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> ExtractionResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ExtractionError.parseFailed
        }

        // Extract JSON from content (may be wrapped in markdown code block)
        let jsonString: String
        if let range = content.range(of: "\\{[^{}]*\\}", options: .regularExpression) {
            jsonString = String(content[range])
        } else {
            jsonString = content
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let result = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ExtractionError.parseFailed
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let vendor = result["vendor"] as? String ?? "Unknown"
        let amount = (result["amount"] as? Double) ?? (result["amount"] as? Int).map(Double.init) ?? 0
        let currency = result["currency"] as? String ?? "USD"
        let dateStr = result["date"] as? String ?? ""
        let date = dateFormatter.date(from: dateStr) ?? Date()
        let catStr = result["category"] as? String ?? "Other"
        let category = ExpenseCategory(rawValue: catStr) ?? .other

        return ExtractionResult(vendor: vendor, amount: amount, currency: currency, date: date, category: category)
    }
}

enum ExtractionError: LocalizedError {
    case noAPIKey
    case imageEncodingFailed
    case apiError(String)
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "Please set your OpenAI API key in Settings."
        case .imageEncodingFailed: return "Failed to encode image."
        case .apiError(let msg): return "API error: \(msg)"
        case .parseFailed: return "Failed to parse receipt data."
        }
    }
}
