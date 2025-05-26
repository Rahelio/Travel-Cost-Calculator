//
//  ContentView.swift
//  ImbursementCalculator
//
//  Created by Rahelio on 26/05/2025.
//

import SwiftUI
import CoreData

// Helper function for time formatting
func formatTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes) minutes"
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(.white)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
        .frame(width: 30, height: 30)
    }
}

struct CalculationBreakdown: View {
    let travelTime: Int
    let baseRate: Double
    
    private var minutes: Double {
        Double(travelTime) / 60.0
    }
    
    private var costPerMinute: Double {
        baseRate / 60.0
    }
    
    private var timeBasedCost: Double {
        minutes * costPerMinute
    }
    
    private var totalCost: Double {
        timeBasedCost + baseRate
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Calculation Breakdown")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 8) {
                BreakdownRow(title: "Travel Time", value: formatTime(travelTime))
                BreakdownRow(title: "Hourly Rate", value: "£\(String(format: "%.2f", baseRate))")
                BreakdownRow(title: "Minute Rate", value: "£\(String(format: "%.2f", costPerMinute))")
                BreakdownRow(title: "Time Cost", value: "£\(String(format: "%.2f", timeBasedCost))")
                BreakdownRow(title: "Base Rate", value: "£\(String(format: "%.2f", baseRate))")
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                BreakdownRow(
                    title: "Total Cost",
                    value: "£\(String(format: "%.2f", totalCost))",
                    isTotal: true
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

struct BreakdownRow: View {
    let title: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 16 : 14, weight: isTotal ? .semibold : .regular))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: isTotal ? 16 : 14, weight: isTotal ? .semibold : .regular))
                .foregroundColor(.white)
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FocusState private var isInputActive: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State private var startPostcode: String = ""
    @State private var endPostcode: String = ""
    @State private var baseRate: String = ""
    @State private var travelCost: Double?
    @State private var travelTime: Int?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let travelService = TravelCostService(apiKey: "AIzaSyALkxcIXwV3UOuNlLT36zdVfwxxXbxcZ5Y")

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Travel Cost Calculator")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        VStack(spacing: 15) {
                            PostcodeTextField(text: $startPostcode, placeholder: "Start Postcode")
                                .focused($isInputActive)
                            PostcodeTextField(text: $endPostcode, placeholder: "End Postcode")
                                .focused($isInputActive)
                            
                            HStack {
                                Text("£")
                                    .foregroundColor(.white)
                                TextField("Base Rate per Hour", text: $baseRate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .focused($isInputActive)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                isInputActive = false // Dismiss keyboard
                                await calculateTravelCost()
                            }
                        }) {
                            if isLoading {
                                HStack {
                                    LoadingView()
                                    Text("Calculating...")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            } else {
                                Text("Calculate Cost")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
                        if let time = travelTime, let baseRateValue = Double(baseRate), baseRateValue > 0 {
                            CalculationBreakdown(travelTime: time, baseRate: baseRateValue)
                                .transition(.opacity)
                                .animation(.easeInOut, value: travelTime)
                        }
                        
                        Spacer()
                    }
                }
                .onTapGesture {
                    isInputActive = false // Dismiss keyboard when tapping outside
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func calculateTravelCost() async {
        guard isValidUKPostcode(startPostcode) else {
            errorMessage = "Invalid start postcode"
            showingError = true
            return
        }
        
        guard isValidUKPostcode(endPostcode) else {
            errorMessage = "Invalid end postcode"
            showingError = true
            return
        }
        
        guard let baseRateValue = Double(baseRate), baseRateValue > 0 else {
            errorMessage = "Please enter a valid base rate"
            showingError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let durationInSeconds = try await travelService.calculateTravelTime(
                from: startPostcode,
                to: endPostcode
            )
            
            travelTime = durationInSeconds
            
            // Calculate cost based on time
            let minutes = Double(durationInSeconds) / 60.0
            let costPerMinute = baseRateValue / 60.0
            let timeBasedCost = minutes * costPerMinute
            
            // Add the base rate to the time-based cost
            travelCost = timeBasedCost + baseRateValue
        } catch TravelCostError.invalidURL {
            errorMessage = "Invalid URL. Please check your postcodes."
            showingError = true
        } catch TravelCostError.invalidResponse {
            errorMessage = "Could not calculate travel time. Please try again."
            showingError = true
        } catch TravelCostError.networkError {
            errorMessage = "Network error. Please check your internet connection."
            showingError = true
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            showingError = true
        }
    }
    
    private func isValidUKPostcode(_ postcode: String) -> Bool {
        let pattern = "^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: postcode.utf16.count)
        return regex?.firstMatch(in: postcode, range: range) != nil
    }
}

struct PostcodeTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .textInputAutocapitalization(.characters)
            .onChange(of: text) { oldValue, newValue in
                // Force uppercase and handle space formatting
                let uppercaseText = newValue.uppercased()
                let filtered = uppercaseText.filter { $0 != " " }
                if filtered.count > 4 {
                    let index = filtered.index(filtered.startIndex, offsetBy: 4)
                    text = filtered[..<index] + " " + filtered[index...]
                } else {
                    text = uppercaseText
                }
            }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
