//
//  Song.swift
//
//
//  Created by Valerie Song on 11/5/25.
//

struct MyItem: Identifiable {
    let id = UUID() // Use a UUID for a globally unique identifier
    var name: String
    var description: String
}
