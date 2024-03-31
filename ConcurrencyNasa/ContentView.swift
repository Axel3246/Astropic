//
//  ContentView.swift
//  ConcurrencyNasa
//
//  Created by Axel Amós Hernández Cárdenas on 25/03/24.
//

import SwiftUI
import TipKit


struct ContentView: View {
    
    @State private var astroPic : [AstronomicalPicture]?
    @State var showCover: Bool = false
    @State var datePicked: Date = {
        let currentDate = Date()
        let calendar = Calendar.current
        let modifiedDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        return modifiedDate
    }()
    @State var dateString: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack (spacing: 5) {
                    AsyncImage(url: URL(string: astroPic?[0].hdurl ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                    } placeholder: {
                        ProgressView()
                        Text("Loading Image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Group {
                        Text(astroPic?[0].title ?? "Title Placeholder")
                            .font(.title.bold())
                            .padding(.vertical, 4)
                            .padding(.top, 4)
                        
                        Text("Copyright: \(astroPic?[0].copyright?.replacingOccurrences(of: "\n", with: "") ?? "None")")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 10)
                        
                        Button{
                            showCover.toggle()
                        } label: {
                            Text("Learn More")
                                .padding(8)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle("Photo - \(getDateTitle())")
                .padding()
                .onAppear{
                    getDateString()
                }
                .toolbar {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .overlay{
                            DatePicker("", selection: $datePicked, in: ...Date())
                                .blendMode(.destinationOver)
                                .onChange(of: datePicked) {
                                    getDateString()
                                    astroPic?[0].hdurl = ""
                                    Task{ // In order to call API Again
                                        try await refreshAstroPic()
                                    }
                                }
                        }
                }
                .task {
                    do {
                        try await refreshAstroPic()
                    } catch APError.invalidURL{
                        print("Invalid URL")
                    } catch APError.invalidResponse{
                        print("Invalid Response")
                    } catch APError.invalidData{
                        print("Invalid Data")
                    } catch {
                        print ("Unexpected Error")
                    }
                }
                .sheet(isPresented: $showCover){
                    VStack{
                        // Close Button
                        Text("About the Picture")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    
                        ScrollView{
                            Text(astroPic?[0].explanation.replacingOccurrences(of: ". ", with: ".\n\n") ?? "Explanation Placeholder")
                                .font(.body)
                                .padding(.vertical, 4)
                            Spacer()
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding()
                    .presentationDetents([.height(300), .fraction(0.99)])
                    .presentationContentInteraction(.scrolls)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // Change Content When a New Date is Selected
    func refreshAstroPic() async throws {
        astroPic = try await getPhoto(date: dateString)
    }
    
    // Function to parse the date required for the API Call
    func getDateString() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateString = dateFormatter.string(from: datePicked)
        print(dateString)
        
    }
    
    // Function to change the title according to the selected date
    func getDateTitle() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd"
        let date = dateFormatter.string(from: datePicked)
       // print("DATE TITLE\(date)")
        return date
    }
    
    // Function that calls the APOD NASA API
    func getPhoto(date: String) async throws -> [AstronomicalPicture] {
        let endpoint = "https://api.nasa.gov/planetary/apod?api_key=RRkvosOc85lCg4kU3qjFz9Ly6efN0ZgZyuxAnekJ&start_date=\(date)&end_date=\(date)"
        
        guard let url = URL(string: endpoint) else {
            throw APError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw APError.invalidResponse
        }
       // print(date)
        do {
            let decoder = JSONDecoder()
           // print( try decoder.decode([AstronomicalPicture].self, from: data))
            return try decoder.decode([AstronomicalPicture].self, from: data)
        } catch {
            throw APError.invalidData
        }
        
    }
}

// Struct that will hold the JSON Response
struct AstronomicalPicture : Codable {
    
    let date: String
    let explanation: String
    let title: String
    var hdurl: String
    let copyright: String? // JSON sometimes doesn't contain copyright
    
}

// Enum for possible API Call Errors
enum APError : Error {
    case invalidURL
    case invalidResponse
    case invalidData
}


#Preview {
    ContentView()
}
