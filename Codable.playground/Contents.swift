import UIKit

let json = "[{\"id\": \"pos_1\",\"title\": \"Codable: Tips and Tricks\"},{\"id\": \"pos_2\"}]"

final class Post: Decodable {
  let id: String
  let title: String
  let subtitle: String?
}

public struct Safe<Base: Decodable>: Decodable {
  public let value: Base?
  
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      self.value = try container.decode(Base.self)
    } catch {
      print("ERROR: \(error)")
      // TODO: automatically send a report about a corrupted data
      // self.value = nil
    }
  }
}

do {
  let posts = try JSONDecoder().decode([Safe<Post>].self, from: json.data(using: .utf8)!)
  print(posts[0].value!.title)    // prints "Codable: Tips and Tricks"
  print(posts[1].value)           // prints "nil"
} catch {
  print(error)
}
