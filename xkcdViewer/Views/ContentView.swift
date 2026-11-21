//
//  ContentView.swift
//  xkcdViewer
//
//  Created by Aram Soneson on 11/19/26.
//

import SwiftUI

struct ContentView: View {
	@AppStorage("comicsData") private var comicsData: Data = Data()
	
	@State private var comics: [Comic] = []
	@State private var latestComic: Comic?
	
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
			if let latestComic {
				if comics.last?.num == latestComic.num {
					
				} else {
					ProgressView(value: Double(comics.last?.num ?? 0), total: Double(latestComic.num)) {
						Text("Fetching comics...")
					} currentValueLabel: {
						Text(Double(comics.last?.num ?? 0) / Double(latestComic.num), format: .percent.precision(.fractionLength(1)))
							.monospacedDigit()
							.contentTransition(.numericText(value: Double(comics.last?.num ?? 0)))
							.animation(.default, value: comics.last?.num)
					}
					.padding()
				}
			}
		}
		.task {
			loadComics()
			
			do {
				// Defines the latest comic as a non-optional type so it can be easily called later on
				let latest = try await fetchComic()
				latestComic = latest
				
				// Checks if there are more comics to fetch
				// If the last comic number in the array is less than the latest comic number in the API, fetching is incomplete
				// The check for the last comic number has a fallback of 0 because if there are no items in the array and thus no last item, fetching is clearly incomplete
				if (comics.last?.num ?? 0) < latest.num {
					// Adds 1 to refer to the next comic that needs to be fetched
					// Doesn't include the latest comic number in the API because that has already been fetched and will be appended to the array later
					for comicNumber in (comics.last?.num ?? 0) + 1..<latest.num {
						do {
							try Task.checkCancellation()
							
							comics.append(try await fetchComic(comicNumber))
							// Save comics on change of comics array
							saveComics()
						} catch is CancellationError {
							return
						} catch {
							print("Failed to fetch comic #\(comicNumber): \(error)")
						}
						
						print(comicNumber)
					}
				}
				
				if comics.last?.num != latest.num {
					comics.append(latest)
					// Save comics on change of comics array
					saveComics()
				}
			} catch is CancellationError {
				return
			} catch {
				print(error)
			}
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
