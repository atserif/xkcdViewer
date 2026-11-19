//
//  Comic.swift
//  xkcdViewer
//
//  Created by Aram Soneson on 11/18/26.
//

import UIKit

struct Comic: Codable {
	let num: Int
	let title: String
	let alt: String
	let transcript: String
	let imageURL: String
	
	let year: String
	let month: String
	let day: String
	
	var image: UIImage?
	
	enum CodingKeys: String, CodingKey {
		case num
		case title
		case alt
		case transcript
		case imageURL = "img"
		
		case year
		case month
		case day
	}
}
