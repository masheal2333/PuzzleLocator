import Foundation
import Combine

class UserService: ObservableObject {
    static let shared = UserService()
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - 用户认证
    func register(username: String, password: String, email: String) {
        let registration = UserRegistration(username: username, password: password, email: email)
        networkManager.register(user: registration)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                self?.currentUser = ModelConverter.convertToUserModel(response)
                self?.isAuthenticated = true
            })
            .store(in: &cancellables)
    }
    
    func login(username: String, password: String) {
        let credentials = UserCredentials(username: username, password: password)
        networkManager.login(credentials: credentials)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                self?.currentUser = ModelConverter.convertToUserModel(response.user)
                self?.isAuthenticated = true
                // 保存token
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
            })
            .store(in: &cancellables)
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "accessToken")
    }
    
    // MARK: - 用户信息更新
    func updateUserInfo(username: String? = nil, email: String? = nil) {
        guard let currentUser = currentUser else { return }
        
        let updateData = UserUpdate(
            id: currentUser.id,
            username: username ?? currentUser.username,
            email: email ?? currentUser.email
        )
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(updateData) else { return }
        
        networkManager.request("/api/users/update", method: "PUT", body: data)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                self?.currentUser = ModelConverter.convertToUserModel(response)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - 历史记录查询
    func fetchHistory() -> AnyPublisher<[HistoryRecord], Error> {
        return networkManager.request("/api/users/history")
    }
}

// MARK: - 数据模型
struct UserUpdate: Codable {
    let id: Int
    let username: String
    let email: String
}

struct HistoryRecord: Codable {
    let id: Int
    let puzzleId: Int
    let matchTime: Date
    let confidence: Double
} 