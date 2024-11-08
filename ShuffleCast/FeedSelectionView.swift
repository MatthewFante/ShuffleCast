//
//  FeedSelectionView.swift
//  ShuffleCast
//
//  Created by Matthew Fante on 11/8/24.
//

import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer

struct FeedSelectionView: View {
    @ObservedObject var podcastFeeds: PodcastFeeds
    @ObservedObject var podcastPlayer: PodcastPlayer
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List(podcastFeeds.feeds) { feed in
                Button(action: {
                    if let randomEpisode = feed.episodes.randomElement() {
                        podcastPlayer.selectedFeed = feed
                        podcastPlayer.playEpisode(randomEpisode, fromFeed: feed)
                        isPresented = false // Close the modal after selection
                    }
                }) {
                    Text(feed.name)
                }
            }
            .navigationTitle("Select a Feed")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
