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
            
            let mapsResponse = try JSONDecoder().decode(GoogleMapsResponse.self, from: data)
            
            guard let duration = mapsResponse.rows.first?.elements.first?.duration.value else {
                print("No duration found in response")
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
        let duration: Duration
    }
    
    struct Duration: Codable {
        let value: Int // Duration in seconds
    }
} 