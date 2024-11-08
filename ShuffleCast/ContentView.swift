import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var podcastFeeds = PodcastFeeds()
    @StateObject private var podcastPlayer = PodcastPlayer()
    @State private var showFeedSelection = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let currentEpisode = podcastPlayer.currentEpisode {
                    VStack(spacing: 16) {
                        Text(currentEpisode.podcastName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.top)
                        
                        Text(currentEpisode.title)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                        
                        if let albumArtURL = currentEpisode.albumArtURL {
                            AsyncImage(url: albumArtURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200, height: 200)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200, height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        
                        Text(currentEpisode.description)
                            .font(.body)
                            .padding(.horizontal)
                            .multilineTextAlignment(.leading)
                        
                        Slider(value: Binding(
                            get: { podcastPlayer.playbackProgress },
                            set: { newValue in
                                podcastPlayer.seek(to: newValue)
                            }),
                        in: 0...1)
                        .padding(.horizontal)
                        
                        HStack(spacing: 40) {
                            Button(action: {
                                podcastPlayer.togglePlayPause()
                            }) {
                                Image(systemName: podcastPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                            
                            Button(action: {
                                if podcastPlayer.selectedFeed != nil {
                                    podcastPlayer.skipToNext()
                                }
                            }) {
                                Image(systemName: "shuffle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                    .padding()
                } else {
                    ProgressView("Loading episode...")
                        .font(.title2)
                        .padding()
                }
            }
            .onAppear {
                // Move the episode selection logic here
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let firstFeed = podcastFeeds.feeds.first, let randomEpisode = firstFeed.episodes.randomElement() {
                        podcastPlayer.selectedFeed = firstFeed
                        podcastPlayer.currentEpisode = randomEpisode
                        podcastPlayer.playEpisode(randomEpisode, fromFeed: firstFeed)
                    }
                }
            }
            .navigationTitle("ShuffleCast")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFeedSelection = true
                    }) {
                        Image(systemName: "text.badge.plus")
                    }
                }
            }.sheet(isPresented: $showFeedSelection) {
                FeedSelectionView(podcastFeeds: podcastFeeds, podcastPlayer: podcastPlayer, isPresented: $showFeedSelection)
            }
        }
    }
    
    private func addFeed() {
        // This will present an alert or another view to input feed URL and name
        // Update logic for adding feed in PodcastFeeds class
        podcastFeeds.addFeed(name: "New Podcast", urlString: "https://example.com/feed.xml")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
