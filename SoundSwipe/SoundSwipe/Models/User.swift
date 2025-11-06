//
//  User.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation

struct User : Identifiable {
  
  let id : UUID;
  let username : String;
  let email : String;
  
  let likedSongs : [Song];
  let playlists : [Playlist];
  let friends : [User];
  
}
