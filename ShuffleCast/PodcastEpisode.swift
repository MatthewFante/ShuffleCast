import Foundation

struct PodcastEpisode: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let audioURL: URL
    let podcastName: String
    let albumArtURL: URL?
    
    init(title: String, description: String, audioURL: URL, podcastName: String, albumArtURL: URL? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.audioURL = audioURL
        self.podcastName = podcastName
        self.albumArtURL = albumArtURL
    }
}

extension PodcastEpisode {
    static func sampleEpisodes() -> [PodcastEpisode] {
        return [
            PodcastEpisode(title: "Episode 1: Getting Started with ShuffleCast", description: "An introductory episode about ShuffleCast.", audioURL: URL(string: "https://example.com/episode1.mp3")!, podcastName: "ShuffleCast Originals", albumArtURL: URL(string: "https://example.com/albumArt1.jpg")),
            PodcastEpisode(title: "Episode 2: Advanced Shuffle Techniques", description: "We dive deeper into shuffle algorithms.", audioURL: URL(string: "https://example.com/episode2.mp3")!, podcastName: "ShuffleCast Originals", albumArtURL: URL(string: "https://example.com/albumArt2.jpg")),
            PodcastEpisode(title: "Episode 3: The Future of Podcasts", description: "Discussing the trends and future of podcasting.", audioURL: URL(string: "https://example.com/episode3.mp3")!, podcastName: "ShuffleCast Originals", albumArtURL: URL(string: "https://example.com/albumArt3.jpg"))
        ]
    }
}
