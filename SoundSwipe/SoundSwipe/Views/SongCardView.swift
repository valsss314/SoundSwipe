//
//  SongView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation
import SwiftUI

struct SongCardView : View {
 
  var body: some View {
          ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray5))
                .shadow(radius: 3)
          
            HStack {
              RoundedRectangle(cornerRadius: 20)
                .fill(Color(.black))
                .shadow(radius: 2)
                .frame(width: 100, height: 100)
              
              
              VStack(alignment: .leading) {
                Text("Song Title")
                  .font(.custom("Rokkitt-Regular", size: 24))
              }
              Spacer()
            }
            .padding(15)
              
             
          }
          .frame(width: .infinity, height: 130)
          .padding(.vertical, 15)
          .padding(.horizontal, 5)
          .background(Color.black)
      }
}

#Preview {
    SongCardView()
}
