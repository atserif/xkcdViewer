//
//  ContentView.swift
//  xkcdViewer
//
//  Created by Aram Soneson on 11/19/26.
//

import SwiftUI

struct ContentView: View {
	@AppStorage("comicsData") private var comicsData: Data = Data()
	@AppStorage("latestComicNumber") private var latestComicNumber: Int = 1
	
	@State private var hasLaunched: Bool = false
	
	@State private var comics: [Comic] = []
	
	private var loadedComicNumber: Int {
		if comics.count < 404 {
			comics.count
		} else {
			comics.count + 1
		}
	}
	
	func fetchComic(_ num: Int? = nil) async throws -> Comic {
		let urlString: String
		
		if let num {
			urlString = "https://xkcd.com/\(num)/info.0.json"
		} else {
			urlString = "https://xkcd.com/info.0.json"
		}
		
		guard let url = URL(string: urlString) else {
			throw URLError(.badURL)
		}
		
		let (data, response) = try await URLSession.shared.data(from: url)
		
		guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
			throw URLError(.badServerResponse)
		}
		
		var comic = try JSONDecoder().decode(Comic.self, from: data)
		
		if let imageURL = URL(string: comic.imageURL), let (imageData, _) = try? await URLSession.shared.data(from: imageURL) {
			comic.image = UIImage(data: imageData)
		}
		
		return comic
	}
	
    var body: some View {
		NavigationStack {
			if loadedComicNumber == latestComicNumber {
				
			} else {
				ProgressView(value: Double(loadedComicNumber) / Double(latestComicNumber)) {
					Text("Fetching comics...")
				} currentValueLabel: {
					Text(Double(loadedComicNumber) / Double(latestComicNumber), format: .percent.precision(.fractionLength(1)))
						.monospacedDigit()
						.contentTransition(.numericText(value: Double(loadedComicNumber)))
						.animation(.default, value: loadedComicNumber)
				}
				.padding(.horizontal, 20)
			}
		}
		.onAppear {
			guard !hasLaunched else { return }
			hasLaunched = true
			
			loadComics()
		}
		.onChange(of: comics) {
			saveComics()
		}
		.task {
			do {
				if latestComicNumber == 1 {
					try await comics.append(fetchComic())
					latestComicNumber = comics[0].num
				}
				
				for comicNumber in loadedComicNumber..<latestComicNumber {
					do {
						try await comics.append(fetchComic(comicNumber))
					} catch {
						print("Failed to fetch comic #\(comicNumber): \(error)")
					}
				}
				
				print(comics)
			} catch {
				print(error)
			}
			
			comics.sort { $0.num < $1.num }
		}
    }
	
	private func loadComics() {
		if let decoded = try? JSONDecoder().decode([Comic].self, from: comicsData) {
			comics = decoded
		}
	}
	private func saveComics() {
		if let encoded = try? JSONEncoder().encode(comics) {
			comicsData = encoded
		}
	}
}

#Preview {
    ContentView()
}
