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
              
              
              VStack(alignment: .leading, spacing: 8) {
                Text("Song Title")
                  .font(.custom("Rokkitt-Regular", size: 22))
                HStack(spacing: 8) {
                  Text("Artist")
                    .font(.custom("Rokkitt-Regular", size: 14))
                  
                  Circle() // Changed to Circle for better look
                    .frame(width: 5, height: 5)
                  
                  Text("3:02")
                    .font(.custom("Rokkitt-Regular", size: 14))
                }
                
                Spacer()
                
                Rectangle()
                  .frame(height: 1)
                  .frame(maxWidth: .infinity) // Makes it fill available width
              }
              .padding(.vertical, 8)
              
              Spacer()
            }
            .padding(15)
              
             
          }
          .frame(height: 130)
          .padding(.horizontal, 5) // Added horizontal padding
          .padding(.vertical, 15)
          .background(Color.black)
      }
}

#Preview {
    SongCardView()
}
