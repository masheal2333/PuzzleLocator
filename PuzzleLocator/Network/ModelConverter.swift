import Foundation

class ModelConverter {
    static func convertToUserModel(_ response: UserResponse) -> User {
        return User(
            id: response.id,
            username: response.username,
            email: response.email
        )
    }
    
    static func convertToPuzzleModel(_ response: PuzzleResponse) -> Puzzle {
        return Puzzle(
            id: response.id,
            imageUrl: URL(string: response.imageUrl)!,
            createdAt: response.createdAt
        )
    }
    
    static func convertToMatchResult(_ response: MatchResponse) -> MatchResult {
        return MatchResult(
            puzzleId: response.puzzleId,
            confidence: response.confidence,
            location: response.location,
            timestamp: response.timestamp
        )
    }
}

// MARK: - 后端响应模型
struct MatchResponse: Codable {
    let puzzleId: Int
    let confidence: Double
    let location: Location
    let timestamp: Date
    
    struct Location: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
}

// MARK: - 本地模型
struct User {
    let id: Int
    let username: String
    let email: String
}

struct Puzzle {
    let id: Int
    let imageUrl: URL
    let createdAt: Date
}

struct MatchResult {
    let puzzleId: Int
    let confidence: Double
    let location: MatchResponse.Location
    let timestamp: Date
} 