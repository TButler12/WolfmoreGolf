//
struct SharedRound: Codable {
    let playerName: String
    let courseName: String
    let courseId: String?       // UUID string; nil on records created before this field was added
    let pars: [Int]
    let hcs: [Int]
    let scores: [Int?]
    let fairways: [Bool?]
    let girs: [Bool?]
    let putts: [Int?]
    let courseHandicap: Int
    let stake: Int?             // set by originator; nil on records created before this field was added

    init(
        playerName: String,
        courseName: String,
        courseId: String? = nil,
        pars: [Int],
        hcs: [Int],
        scores: [Int?],
        fairways: [Bool?],
        girs: [Bool?],
        putts: [Int?],
        courseHandicap: Int,
        stake: Int? = nil
    ) {
        self.playerName     = playerName
        self.courseName     = courseName
        self.courseId       = courseId
        self.pars           = pars
        self.hcs            = hcs
        self.scores         = scores
        self.fairways       = fairways
        self.girs           = girs
        self.putts          = putts
        self.courseHandicap = courseHandicap
        self.stake          = stake
    }

    private enum CodingKeys: String, CodingKey {
        case playerName, courseName, courseId
        case pars, hcs, scores, fairways, girs, putts, courseHandicap
        case stake
    }

    init(from decoder: Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        playerName      = try c.decode(String.self,  forKey: .playerName)
        courseName      = try c.decode(String.self,  forKey: .courseName)
        courseId        = try c.decodeIfPresent(String.self, forKey: .courseId)
        pars            = try c.decode([Int].self,   forKey: .pars)
        hcs             = try c.decode([Int].self,   forKey: .hcs)
        scores          = try c.decode([Int?].self,  forKey: .scores)
        fairways        = try c.decode([Bool?].self, forKey: .fairways)
        girs            = try c.decode([Bool?].self, forKey: .girs)
        putts           = try c.decode([Int?].self,  forKey: .putts)
        courseHandicap  = try c.decode(Int.self,     forKey: .courseHandicap)
        stake           = try c.decodeIfPresent(Int.self, forKey: .stake)
    }
}
