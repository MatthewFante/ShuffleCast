import Foundation
import Combine

struct PodcastFeed: Identifiable {
    let id: UUID
    let name: String
    let feedURL: URL
    var episodes: [PodcastEpisode]
    
    init(name: String, feedURL: URL, episodes: [PodcastEpisode] = []) {
        self.id = UUID()
        self.name = name
        self.feedURL = feedURL
        self.episodes = episodes
    }
}

class PodcastFeeds: ObservableObject {
    @Published var feeds: [PodcastFeed] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Add default feed
        addFeed(name: "This American Life", urlString: "https://awk.space/tal.xml")
        addFeed(name: "Stuff You Should Know", urlString: "https://omnycontent.com/d/playlist/e73c998e-6e60-432f-8610-ae210140c5b1/A91018A4-EA4F-4130-BF55-AE270180C327/44710ECC-10BB-48D1-93C7-AE270180C33E/podcast.rss")
        fetchAllFeeds()  // Fetch the episodes for the default feed
    }
    
    func addFeed(name: String, urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let newFeed = PodcastFeed(name: name, feedURL: url)
        feeds.append(newFeed)
    }
    
    func removeFeed(feed: PodcastFeed) {
        feeds.removeAll { $0.id == feed.id }
    }
    
    func updateEpisodes(for feed: PodcastFeed, newEpisodes: [PodcastEpisode]) {
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            feeds[index].episodes = newEpisodes
        }
    }
    
    func fetchEpisodes(for feed: PodcastFeed, completion: @escaping ([PodcastEpisode]) -> Void) {
        let session = URLSession.shared
        let request = URLRequest(url: feed.feedURL)
        
        session.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error fetching episodes: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] data in
                let parser = RSSFeedParser(data: data)
                if let rssFeed = parser.parse() {
                    let episodes = rssFeed.items.map { item in
                        PodcastEpisode(title: item.title, description: item.description, audioURL: item.audioURL, podcastName: feed.name)
                    }
                    self?.updateEpisodes(for: feed, newEpisodes: episodes)
                    completion(episodes)
                }
            })
            .store(in: &cancellables)
    }
    
    func fetchAllFeeds() {
        feeds.forEach { feed in
            fetchEpisodes(for: feed) { _ in }
        }
    }
}

struct RSSFeed {
    var items: [RSSEpisode] = []
}

struct RSSEpisode {
    let title: String
    let description: String
    let audioURL: URL
}

class RSSFeedParser: NSObject, XMLParserDelegate {
    private var parser: XMLParser
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentDescription: String = ""
    private var currentAudioURL: String = ""
    private var items: [RSSEpisode] = []
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
    }
    
    func parse() -> RSSFeed? {
        parser.delegate = self
        if parser.parse() {
            return RSSFeed(items: items)
        } else {
            return nil
        }
    }
    
    // MARK: - XMLParserDelegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "enclosure", let urlString = attributeDict["url"] {
            currentAudioURL = urlString
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if let audioURL = URL(string: currentAudioURL) {
                let episode = RSSEpisode(title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                                         description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                                         audioURL: audioURL)
                items.append(episode)
            }
            currentTitle = ""
            currentDescription = ""
            currentAudioURL = ""
        }
    }
}
