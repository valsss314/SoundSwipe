//
//  FilterView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct MusicFilter: Codable {
    var selectedGenres: [String] = []
    var yearRange: ClosedRange<Int> = 2020...2024

    var isActive: Bool {
        !selectedGenres.isEmpty || yearRange != 2020...2024
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filter: MusicFilter
    @State private var tempFilter: MusicFilter

    let availableGenres = [
        "pop", "rock", "indie", "hip-hop", "r&b",
        "electronic", "jazz", "classical", "country", "latin",
        "metal", "punk", "reggae", "blues", "soul",
        "folk", "edm", "house", "techno", "alternative"
    ]

    init(filter: Binding<MusicFilter>) {
        self._filter = filter
        self._tempFilter = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // Genres Section
                        genresSection

                        Divider().background(Color.white.opacity(0.2))

                        // Year Range Section
                        yearRangeSection

                        Divider().background(Color.white.opacity(0.2))

                        // Apply Button
                        applyButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilter = MusicFilter()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.green)
                Text("Genres")
                    .font(.custom("Rokkitt-Regular", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                if !tempFilter.selectedGenres.isEmpty {
                    Text("\(tempFilter.selectedGenres.count) selected")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.green)
                }
            }

            Text("Select genres you want to discover")
                .font(.custom("Rokkitt-Regular", size: 14))
                .foregroundColor(.secondary)

            // Genre chips
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                ForEach(availableGenres, id: \.self) { genre in
                    GenreChip(
                        genre: genre,
                        isSelected: tempFilter.selectedGenres.contains(genre)
                    ) {
                        toggleGenre(genre)
                    }
                }
            }
        }
    }

    private var yearRangeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Year Range")
                    .font(.custom("Rokkitt-Regular", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(tempFilter.yearRange.lowerBound)) - \(Int(tempFilter.yearRange.upperBound))")
                    .font(.custom("Rokkitt-Regular", size: 16))
                    .foregroundColor(.blue)
            }

            Text("Filter music by release year")
                .font(.custom("Rokkitt-Regular", size: 14))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                HStack {
                    Text("From: \(Int(tempFilter.yearRange.lowerBound))")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.white)
                    Spacer()
                }

                Slider(
                    value: Binding(
                        get: { Double(tempFilter.yearRange.lowerBound) },
                        set: { tempFilter.yearRange = Int($0)...Int(tempFilter.yearRange.upperBound) }
                    ),
                    in: 1960...2024,
                    step: 1
                )
                .accentColor(.blue)

                HStack {
                    Text("To: \(Int(tempFilter.yearRange.upperBound))")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.white)
                    Spacer()
                }

                Slider(
                    value: Binding(
                        get: { Double(tempFilter.yearRange.upperBound) },
                        set: { tempFilter.yearRange = Int(tempFilter.yearRange.lowerBound)...Int($0) }
                    ),
                    in: 1960...2024,
                    step: 1
                )
                .accentColor(.blue)
            }
        }
    }

    private var applyButton: some View {
        Button(action: {
            filter = tempFilter
            dismiss()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Apply Filters")
                    .font(.custom("Rokkitt-Regular", size: 20))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(15)
        }
        .padding(.top, 20)
    }

    private func toggleGenre(_ genre: String) {
        if let index = tempFilter.selectedGenres.firstIndex(of: genre) {
            tempFilter.selectedGenres.remove(at: index)
        } else {
            tempFilter.selectedGenres.append(genre)
        }
    }
}

// MARK: - Genre Chip
struct GenreChip: View {
    let genre: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(genre.capitalized)
                .font(.custom("Rokkitt-Regular", size: 14))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.white.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.5), lineWidth: isSelected ? 2 : 0)
                )
        }
    }
}

// MARK: - Filter Toggle
struct FilterToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Rokkitt-Regular", size: 16))
                    .foregroundColor(.white)

                Text(description)
                    .font(.custom("Rokkitt-Regular", size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    FilterView(filter: .constant(MusicFilter()))
}
