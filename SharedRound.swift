//
struct SharedRound: Codable {
    let playerName: String
    let courseName: String
    let pars: [Int]
    let hcs: [Int]
    let scores: [Int]
    let fairways: [Bool?]
    let girs: [Bool?]
    let putts: [Int?]
    let courseHandicap: Int
}
