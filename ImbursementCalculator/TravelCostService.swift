import Foundation

class TravelCostService {
    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/distancematrix/json"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func calculateTravelTime(from startPostcode: String, to endPostcode: String) async throws -> Int {
        let urlString = "\(baseURL)?origins=\(startPostcode)&destinations=\(endPostcode)&mode=driving&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw TravelCostError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelCostError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                print("API Error: Status code \(httpResponse.statusCode)")
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("API Error details: \(errorJson)")
                }
                throw TravelCostError.networkError
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(jsonString)")
            }
            
            let mapsResponse = try JSONDecoder().decode(GoogleMapsResponse.self, from: data)
            
            // Check overall API status
            if mapsResponse.status != "OK" {
                print("API returned non-OK status: \(mapsResponse.status)")
                throw TravelCostError.invalidResponse
            }
            
            // Check if we have rows and elements
            guard let firstRow = mapsResponse.rows.first,
                  let firstElement = firstRow.elements.first else {
                print("No rows or elements in response")
                throw TravelCostError.invalidResponse
            }
            
            // Check element status
            if firstElement.status != "OK" {
                print("Element status is not OK: \(firstElement.status)")
                throw TravelCostError.invalidResponse
            }
            
            // Get duration
            guard let duration = firstElement.duration?.value else {
                print("No duration value in response")
                throw TravelCostError.invalidResponse
            }
            
            return duration // Duration in seconds
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw TravelCostError.invalidResponse
        } catch {
            print("Network error: \(error)")
            throw TravelCostError.networkError
        }
    }
}

enum TravelCostError: Error {
    case invalidURL
    case invalidResponse
    case networkError
}

struct GoogleMapsResponse: Codable {
    let status: String
    let rows: [Row]
    
    struct Row: Codable {
        let elements: [Element]
    }
    
    struct Element: Codable {
        let status: String
        let duration: Duration?
        let distance: Distance?
        
        enum CodingKeys: String, CodingKey {
            case status
            case duration
            case distance
        }
    }
    
    struct Duration: Codable {
        let value: Int // Duration in seconds
        let text: String
    }
    
    struct Distance: Codable {
        let value: Int // Distance in meters
        let text: String
    }
} 