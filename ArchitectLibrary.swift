import Foundation

struct ArchitectProfile {
    let name: String
    let bio: String?
    let courses: [CourseProfile]
}

enum ArchitectLibrary {

    // MARK: - Bio blurbs
    // Keys match the architect string exactly as it appears in CourseLibrary.
    static let bios: [String: String] = [
        "A.W. Pollard":
            "Early American architect known for accessible public course design. Gus Wortham Park reflects his practical approach to municipal golf.",

        "A.W. Tillinghast":
            "One of America's greatest golden age architects, active 1905–1940. Known for dramatic bunkering, demanding par 3s, and courses that reward strategic play over power. Designed Winged Foot, Bethpage Black, and Ridgewood.",

        "Alister MacKenzie":
            "Scottish-born architect celebrated for natural terrain routing and deceptive green complexes. Co-designed Augusta National with Bobby Jones. His courses reward thoughtful play over brute force. Designed Palmetto, Alwoodley, and Moortown.",

        "Andy Dye":
            "Member of the Dye design family, known for challenging layouts with dramatic water features and strategic bunkering.",

        "Arnold Palmer":
            "Seven-time major champion turned course designer. Palmer courses emphasize playability and fan enjoyment over pure difficulty. Designed Classic Club, SilverRock, and Shingle Creek.",

        "Arthur Hills":
            "Michigan-based architect known for designs that blend naturally into their surroundings. Prolific Midwest designer with over 200 courses to his credit. Known for Boyne Highlands and Stonewall Orchard.",

        "Arthur Schaupeter":
            "Contemporary architect known for TPC Colorado, a dramatic design along the Front Range of the Rocky Mountains.",

        "Arthur Spring (1989)":
            "Irish architect known for links-style designs along Ireland's rugged coastlines. Designed Castlegregory Golf & Fishing Club in County Kerry.",

        "Ault, Clark & Associates":
            "Virginia-based design firm known for thoughtful layouts in the Mid-Atlantic region. Designed Worthington Manor in Maryland.",

        "Bear Dance (original design team)":
            "Colorado mountain course known for dramatic elevation changes and stunning Rocky Mountain scenery.",

        "Big Cedar Lodge":
            "Resort design team behind Cliffhangers, one of Johnny Morris's acclaimed Big Cedar Lodge courses in the Ozarks.",

        "Bill Coore & Ben Crenshaw":
            "Celebrated modern architects known for minimalist designs that work with natural terrain rather than against it. Disciples of the golden age philosophy. Designed Bandon Trails, Sand Hills, Sand Valley, and Friar's Head.",

        "Billy Casper & Greg Nash":
            "Collaboration between Hall of Fame player Billy Casper and Nevada architect Greg Nash. Known for desert resort designs including the Revere Golf Club courses in Las Vegas.",

        "Bob Cupp":
            "Former Jack Nicklaus design associate who launched his own firm. Known for creative hole routing and strategic variety. Designed courses at Reynolds Lake Oconee.",

        "Bobby Weed":
            "Florida-based architect and former PGA Tour agronomist. Known for TPC Summerlin and expertise in tournament-quality course conditioning.",

        "Bobby Weed / Raymond Floyd":
            "Collaboration producing TPC Las Vegas, a desert layout blending Weed's design expertise with Floyd's player perspective.",

        "Brad Bell":
            "California-based architect known for Yocha Dehe Golf Club, a highly regarded public course at Cache Creek in Northern California.",

        "Brian Huntley":
            "Canadian architect known for creative designs in Ontario including Deer Ridge and The Quarry Golf Club.",

        "Brian Schneider & Blake Conant":
            "Design team behind Old Barnwell in South Carolina, a minimalist layout drawing comparisons to the golden age designs of the Lowcountry.",

        "Bruce Devlin":
            "Australian PGA Tour champion turned architect. Known for Secession Golf Club, one of South Carolina's most exclusive private clubs.",

        "C.B. Macdonald (1895) / Seth Raynor (1923)":
            "Pioneer partnership that established American golf architecture. Macdonald brought Scottish hole templates to America; Raynor refined and expanded them. Chicago Golf Club is one of America's oldest courses.",

        "Charles Blair Macdonald":
            "Father of American golf course architecture. Introduced Scottish template holes — Redan, Alps, Eden, Biarritz — to the United States. Designed National Golf Links of America, widely considered America's first great course.",

        "Charles Blair Macdonald / Seth Raynor":
            "Partnership responsible for The Creek Club, featuring classic template holes in a refined Long Island setting.",

        "Charles Hugh Alison":
            "British architect and partner of H.S. Colt. Known for international designs including Hirono Golf Club in Japan, considered Asia's finest course.",

        "Chet Williams (Nicklaus Design)":
            "Nicklaus Design associate known for Whispering Pines Golf Club in Texas, one of the most acclaimed private clubs in the South.",

        "Chris Lutzke":
            "Midwest architect known for Eagle Eye Golf Club in Michigan, a well-regarded public layout.",

        "Christy O'Connor Jr.":
            "Irish Ryder Cup player turned architect. Known for Esker Hills Golf Club, a parkland design in County Offaly, Ireland.",

        "Chuck Smith":
            "Regional architect known for Branson Hills Golf Club in Missouri.",

        "Dan Hixson":
            "Pacific Northwest architect known for minimalist designs that work with natural landscapes. Designed Wine Valley Golf Club and Silvies Valley Resort in Oregon.",

        "Dave Axland & Dan Proctor":
            "Design team known for Wild Horse Golf Club in Nebraska, a celebrated sand hills layout built on a shoestring budget.",

        "David McLay Kidd":
            "Scottish architect who designed the original Bandon Dunes course that launched the Bandon Dunes Golf Resort. Known for rugged links-inspired designs. Also designed Gamble Sands and Mammoth Dunes.",

        "David McLay Kidd / Nick Schaan":
            "Collaboration producing Gamble Sands Scarecrow, a short course companion to the main Gamble Sands layout in Washington state.",

        "Denis Griffiths":
            "Architect known for resort designs in the Southeast including Brasstown Valley Resort in Georgia.",

        "Dennis Rider":
            "Nevada architect known for Wolf Creek Golf Club, a dramatic red rock canyon layout in Mesquite.",

        "Desmond Muirhead":
            "Eccentric architect known for avant-garde designs with sculptural bunkers and artistic flair. Designed the Ironwood Country Club courses in California.",

        "Devereux Emmet":
            "Early American architect active in the golden age. Known for Garden City Golf Club on Long Island, a classic design from 1899.",

        "Dick Nugent":
            "Chicago-area architect known for numerous Midwest designs including Kemper Lakes and White Deer Run. Long-time collaborator with Ken Killian.",

        "Donald Ross":
            "Scottish-born architect who became America's most prolific golden age designer with over 400 courses. Signature style features crowned greens that deflect errant approaches, natural bunkering, and strategic routing. Designed Pinehurst No. 2, Aronimink, and Pine Needles.",

        "Donald Ross & Tom Bendelow":
            "Collaborative design of Cedar Rapids Country Club, blending Ross's strategic genius with Bendelow's early American style.",

        "Donald Ross / C.H. Alison":
            "Partnership responsible for Bob O'Link Golf Club in Highland Park, Illinois.",

        "Donald Ross / Gil Hanse":
            "Collaboration at Plainfield Country Club in New Jersey, where Hanse restored Ross's original design intent.",

        "Donald Steel":
            "British architect known for links designs and sensitive restorations. Designed Primland Resort's Highland Course in Virginia.",

        "Dye Designs International":
            "Design firm extending Pete Dye's legacy. Known for Desert Pines Golf Club in Las Vegas, a pine tree-lined desert oasis.",

        "Ed Carton":
            "Regional architect known for Spring Creek Golf Club.",

        "Eddie Hackett / Tom Fazio redesign":
            "Irish architect Eddie Hackett's original Waterville Golf Links was later refined by Tom Fazio, preserving its links character on Ireland's Ring of Kerry.",

        "Edward Ryder":
            "Connecticut architect known for Richter Park Golf Course, a public layout in Danbury.",

        "Frank P. McDonald / A.W. Tillinghast":
            "Collaboration at River Forest Country Club in Illinois, blending early American design with Tillinghast's strategic sensibility.",

        "Fred Couples / Schmidt-Curley":
            "Collaboration between Hall of Fame player Fred Couples and design firm Schmidt-Curley at Ak-Chin Southern Dunes in Arizona.",

        "Fred Morris":
            "Scottish architect known for Western Gailes Golf Club, a classic links on the Ayrshire coast of Scotland.",

        "Frederick G. Hawtree / J.H. Taylor":
            "Frederick Hawtree and five-time Open Champion J.H. Taylor collaborated on Royal Birkdale's 1932 redesign, creating one of England's premier championship links. Birkdale has since hosted ten Open Championships and is celebrated for its flat fairways set between sandhills.",

        "Gary Kern":
            "Regional architect known for Harrison Lake Country Club.",

        "Gary Panks":
            "Arizona-based architect known for desert course design including Conestoga Golf Club in Nevada.",

        "Gary Player":
            "South African major champion and prolific course designer. Known for dramatic layouts emphasizing fitness and challenge. Designed Geneva National Player Course in Wisconsin.",

        "Gene Bates":
            "Florida-based architect known for resort and destination designs including Salish Cliffs Golf Club in Washington state.",

        "Geoffrey Cornish":
            "Prolific New England architect who designed hundreds of courses across the Northeast. Known for Sterling Farms Golf Course in Connecticut.",

        "George Crump / Harry Colt":
            "George Crump conceived and built Pine Valley, widely considered the world's greatest golf course, before his death. Harry Colt helped complete the final holes. A masterpiece of penal design.",

        "George Fazio":
            "PGA Tour player turned architect, uncle of Tom Fazio. Known for Crane's Landing and laying the groundwork for the Fazio design dynasty.",

        "George O'Neil":
            "Chicago-area architect known for Barrington Hills Country Club in Illinois.",

        "Gil Hanse":
            "One of the most respected contemporary architects known for minimalist designs that restore natural terrain. Designed the 2016 Olympic Golf Course in Rio. Known for Castle Stuart, Pinehurst No. 4, and Rustic Canyon.",

        "Gil Hanse / Geoff Shackelford / Jim Wagner":
            "Collaboration producing Rustic Canyon Golf Course in California, a celebrated public layout known for its natural minimalist design and affordable green fees.",

        "Gil Hanse / Jim Wagner":
            "Design partnership responsible for CapRock Ranch in Texas.",

        "Graham Marsh":
            "Australian PGA Tour player turned architect. Known for The Prairie Club Pines Course in Nebraska's sandhills.",

        "Graham Webster":
            "Scottish architect known for links-style designs. Designed Kings Links Golf Centre in Aberdeen, Scotland.",

        "Greg Norman":
            "The Shark's design firm known for dramatic, visually striking layouts. Designed Champions Gate, Tennessee National, and Cornerstone.",

        "H. Chandler Egan":
            "Early American architect and amateur champion. Known for Indian Canyon Golf Course in Spokane, Washington.",

        "H.C. Fownes":
            "Pittsburgh industrialist who designed Oakmont Country Club in 1903. Known for creating one of America's most demanding courses with deep furrow bunkers and lightning-fast greens.",

        "H.S. Colt / C.H. Alison":
            "British partnership responsible for Knollwood Club in Illinois, bringing refined British design principles to American soil.",

        "Harry Bowers / Arthur Hills":
            "Collaboration producing Crooked Tree Golf Club in Michigan.",

        "Hugh Moore":
            "Regional architect known for Dothan Country Club in Alabama.",

        "Jack Neville & Douglas Grant":
            "Amateur golfers who designed Pebble Beach Golf Links in 1919 along the Monterey Peninsula's dramatic coastline. One of the world's most iconic golf holes.",

        "Jack Nicklaus":
            "The Golden Bear's prolific design firm has produced over 300 courses worldwide. Known for dramatic risk-reward layouts, strategic water hazards, and demanding but fair designs. Signature courses include Valhalla, Harbour Town, and American Dunes.",

        "Jack Nicklaus / Tom Doak":
            "Collaboration at Sebonack Golf Club on Long Island, blending Nicklaus's dramatic style with Doak's minimalist approach.",

        "Jack Nicklaus / Tony Jacklin":
            "Collaboration at The Concession Golf Club in Florida, named for Nicklaus's famous concession of a putt to Jacklin in the 1969 Ryder Cup.",

        "Jay Riviere":
            "Houston-area architect known for Sharpstown Park Golf Course.",

        "Jeff Osterfeld":
            "Ohio architect known for Stonelick Hills Golf Club.",

        "Jeffrey Brauer":
            "Texas-based architect known for value-priced public designs that punch above their weight. Designed Giants Ridge and Wildhorse Golf Course.",

        "Jerry Matthews":
            "Michigan architect known for Gull Lake View East Course.",

        "Jerry Pate":
            "1976 US Open champion turned architect. Known for Steelwood Country Club in Alabama.",

        "Jerry Rich / Greg Martin":
            "Collaboration at Rich Harvest Farms in Illinois, a private club that hosted the Solheim Cup.",

        "Jim Bevins":
            "Georgia architect known for Black Creek Golf Club.",

        "Jim Engh":
            "Colorado-based architect known for bold, creative designs with dramatic terrain movement. Known for Fossil Trace, Sanctuary, and Tullymore Golf Club.",

        "Jim Fazio":
            "Member of the Fazio design family. Known for Trump International Golf Club Championship Course in West Palm Beach.",

        "Joe Salemi":
            "Nevada architect known for Boulder Creek Golf Club.",

        "Joel Goldstrand":
            "Minnesota architect known for Whitebirch Golf Course.",

        "John Bredemus":
            "Texas architect known for Memorial Park Golf Course in Houston, a municipal layout that hosted PGA Tour events.",

        "John Bredemus / Perry Maxwell":
            "Collaboration at Colonial Country Club in Fort Worth, home of the PGA Tour's Charles Schwab Challenge.",

        "John Cochran":
            "Colorado architect known for Golf Club at Fox Acres.",

        "John Harbottle III":
            "Pacific Northwest architect known for Palouse Ridge Golf Club at Washington State University.",

        "Kelby Hughes":
            "Nevada architect known for Falcon Ridge Golf Course.",

        "Ken Kavanaugh":
            "Colorado architect known for Murphy Creek Golf Course in Aurora.",

        "Ken Killian & Dick Nugent":
            "Chicago-area design partnership responsible for Kemper Lakes Golf Club, host of the 1989 PGA Championship.",

        "Ken Killian / Greg Martin (2012)":
            "Chicago-area collaboration responsible for Arrowhead Golf Club in Wheaton, Illinois.",

        "King-Collins Golf Course Design":
            "Design firm known for minimalist, naturalistic designs. Created Sweetens Cove Golf Club in Tennessee, one of America's most acclaimed 9-hole courses.",

        "Komei Otani (1939) / Gil Hanse redesign":
            "Historic 1939 Japanese design at Tokyo Golf Club, sensitively restored by Gil Hanse to honor the original intent.",

        "Kris Spence":
            "North Carolina architect known for Quixote Club.",

        "Kyle Phillips":
            "American architect known for European-style links designs. Designed Kingsbarns Golf Links in Scotland, widely considered one of the world's finest modern links courses.",

        "Larry Nelson":
            "Two-time PGA Champion turned architect. Known for Gaylord Springs Golf Links in Tennessee.",

        "Lee Trevino":
            "Hall of Fame player who designed Geneva National Trevino Course in Wisconsin.",

        "Lester George":
            "Virginia-based architect known for Ballyhack Golf Club and Kinloch Golf Club, two of the Mid-Atlantic's most exclusive private clubs.",

        "Mark Rathert":
            "Nevada architect known for Boulder Creek Golf Club.",

        "Maurice McCarthy":
            "Pennsylvania architect known for the Hershey Country Club courses in Hershey, Pennsylvania.",

        "Michael Hurdzan":
            "Ohio-based architect known for environmentally sensitive designs that work with natural landforms. Known for Olde Stonewall and numerous public layouts.",

        "Michael Hurdzan & Dana Fry":
            "Design partnership known for accessible public courses that offer genuine strategic challenge. Known for Harbor Links and Wildcat Golf Club.",

        "Michael Hurdzan & Dana Fry / Tom Lehman":
            "Three-way collaboration at Raven Golf Club at Three Peaks in Colorado.",

        "Michael Zikorus (2004)":
            "Connecticut architect known for Tashua Glen Golf Course.",

        "Mike Asmundson":
            "Pacific Northwest architect known for The Home Course in DuPont, Washington, home of the Washington State Golf Association.",

        "Mike DeVries":
            "Michigan architect known for naturalistic designs that minimize earth movement. Known for Greywalls Golf Course in Marquette, Michigan.",

        "Mike DeVries & Kris Shumacker":
            "Collaboration at Pilgrim's Run Golf Club in Michigan.",

        "Mike Strantz":
            "Visionary architect known for bold, artistic designs before his untimely death in 2005. Known for Bulls Bay and Tobacco Road, two of the Carolinas' most distinctive layouts.",

        "Nelson & Haworth":
            "Canadian design firm known for Warren Golf & Country Club.",

        "Old Tom Morris":
            "Four-time Open Championship winner and father of modern golf course design. Laid out courses across Scotland in the 1800s using minimal earth movement and natural terrain. Known for Muirfield, Prestwick, and Machrihanish.",

        "Osamu Ueda":
            "Japanese architect known for Nara Kokusai GC in Japan.",

        "Pat Ruddy":
            "Irish architect and golf journalist known for links-style designs along Ireland's coasts. Designed The European Club in County Wicklow, considered one of Ireland's finest courses.",

        "Perry Maxwell":
            "Oklahoma-based architect known for undulating 'Maxwell rolls' on his greens. Designed Southern Hills Country Club, host of multiple major championships.",

        "Pete Dye":
            "One of America's most influential and provocative architects. Known for railroad tie bulkheads, island greens, and courses that challenge conventional design thinking. Designed TPC Sawgrass, Harbour Town, and French Lick Pete Dye Course.",

        "Pete Dye & Greg Norman":
            "Collaboration at Medalist Golf Club in Florida, one of the world's most exclusive private clubs.",

        "Pete Dye / Jack Nicklaus":
            "Legendary collaboration at Harbour Town Golf Links on Hilton Head Island, home of the PGA Tour's RBC Heritage.",

        "Peter Jacobsen & Jim Hardy":
            "PGA Tour player Peter Jacobsen and instructor Jim Hardy designed the BlackHorse Golf Club courses near Houston.",

        "Phil Jacobs":
            "Singapore-based architect known for Keppel Club and Tanah Merah Country Club in Singapore.",

        "Philip Walton & Ken Kearney":
            "Irish design team known for Co. Tipperary Golf & Country Club.",

        "Pierre Fulke / Adam Mednickson":
            "Swedish design team known for Visby Golf Club on the island of Gotland, Sweden.",

        "Rees Jones":
            "Son of Robert Trent Jones Sr. known as 'The Open Doctor' for his major championship course renovations. Known for Cascata, Rio Secco, and Quintero Golf Club.",

        "Rees Jones & David Toms":
            "Collaboration at Golf Club of Houston Tournament Course, host of the PGA Tour's Houston Open.",

        "Rick Jacobson":
            "Midwest architect known for Bowes Creek Country Club in Illinois and Spirit Hollow Golf Course in Iowa.",

        "Robert Bruce Harris":
            "Wisconsin architect known for Grand Geneva's The Brute course in Lake Geneva.",

        "Robert Trent Jones Jr.":
            "Son of Robert Trent Jones Sr. with a prolific international design portfolio. Known for Chambers Bay, host of the 2015 US Open, and SentryWorld in Wisconsin.",

        "Robert Trent Jones Jr. / Tom Watson / Sandy Tatum":
            "Collaboration at The Links at Spanish Bay in Pebble Beach, a links-style course along the Pacific coast.",

        "Robert Trent Jones, Sr.":
            "One of America's most prolific architects who shaped post-war golf course design. Known for long par 4s, heroic water carries, and demanding layouts. Designed Spyglass Hill, Hazeltine, and Bellerive.",

        "Robert Turnbull / Gunnar Bauer / Peter Nordwall / Peter Chamberlain":
            "Design team behind Falsterbo Golf Club in Sweden, one of Scandinavia's finest links courses.",

        "Ron Fream & Gene Bates":
            "Collaboration at Sentosa Golf Club's Tanjong Course in Singapore.",

        "Ron Kirby / Eddie Hackett":
            "Design partnership responsible for Old Head Golf Links in County Cork, Ireland, dramatically perched on a cliff above the Atlantic Ocean.",

        "Ronald Fream":
            "International architect known for Asian resort designs including Sentosa Golf Club's New Tanjong Course in Singapore.",

        "Roy Case":
            "Houston-area architect known for Wildcat Golf Club's Lakes Course.",

        "Schmidt & Curley":
            "International design firm known for resort layouts worldwide including Bali Hai Golf Club in Las Vegas.",

        "Seth Raynor":
            "Disciple of C.B. Macdonald who refined and popularized template hole designs across America. Known for Fishers Island, Shoreacres, and Camargo Club — all considered among America's finest courses.",

        "Seth Raynor & Charles Banks":
            "Collaboration at Yeamans Hall Club in South Carolina, one of the Southeast's most celebrated private clubs.",

        "Seth Raynor & Jack Nicklaus":
            "Historic combination at The Greenbrier Course in West Virginia, blending Raynor's golden age templates with Nicklaus's modern sensibility.",

        "Stanley Thompson":
            "Canada's greatest architect known for dramatic mountain and lakeside designs. Known for Banff Springs and Jasper Park. Designed Sleepy Hollow Golf Course.",

        "Steve Smyers":
            "Florida architect known for strategic designs that reward thoughtful play. Known for Old Memorial Golf Club in Tampa.",

        "Ted Robinson Jr.":
            "Son of Ted Robinson Sr. continuing the family design tradition. Known for Chimera Golf Club in Nevada.",

        "Ted Robinson Sr.":
            "Las Vegas-area architect known for desert resort designs including Rhodes Ranch Golf Club.",

        "Tiger Woods":
            "The greatest player of his generation turned course designer. Bluejack National in Texas is his debut design, widely praised for its playability and strategic variety.",

        "Todd Eckenrode":
            "Colorado architect known for RainDance National Golf Course.",

        "Tom Bendelow":
            "Scottish immigrant known as 'the Johnny Appleseed of American golf' for designing hundreds of affordable courses across America in the early 1900s. Known for Glen Oak and Elgin Country Club.",

        "Tom Doak":
            "Michigan-based architect and golf historian known for minimalist designs that rely on natural terrain. Wrote the definitive history of golf course architecture. Known for Pacific Dunes, Lost Dunes, and Old Macdonald.",

        "Tom Doak & Jim Urbina":
            "Collaboration at Old Macdonald at Bandon Dunes, a tribute to C.B. Macdonald's template hole philosophy.",

        "Tom Doak & Kye Goalby":
            "Collaboration at The Tree Farm in Michigan.",

        "Tom Doak / Robert Trent Jones Jr.":
            "Collaboration at CommonGround Golf Course in Colorado, the home course of the Colorado Golf Association.",

        "Tom Fazio":
            "America's most commercially successful contemporary architect known for visually stunning, immaculately conditioned layouts. Designed Shadow Creek, Whisper Rock, and Victoria National. Over 100 courses in his portfolio.",

        "Tom Fazio / Dennis Wise":
            "Collaboration at Karsten Creek in Oklahoma, home course of Oklahoma State University and consistently ranked among America's top collegiate courses.",

        "Tom Kite / Bob Cupp":
            "Collaboration at Liberty National Golf Club in New Jersey, a dramatic layout overlooking the Statue of Liberty and Manhattan skyline.",

        "Tom Lehman / Chris Brands":
            "PGA Tour champion Tom Lehman and design partner Chris Brands created The Prairie Club Dunes Course in Nebraska's sandhills.",

        "Tom Simpson / Herbert Fowler":
            "British design partnership responsible for Cruden Bay Golf Club in Scotland, a dramatic links on the Aberdeenshire coast.",

        "Tom Weiskopf":
            "PGA Tour champion and respected architect known for designs that balance beauty with strategic challenge. Known for Forest Dunes, Frost Creek, and Black Desert Resort.",

        "Tom Weiskopf & Jay Morrish":
            "Design partnership responsible for Troon Country Club in Arizona and numerous acclaimed desert layouts.",

        "Tommy Pegram":
            "Michigan architect known for Crooked Tree Golf Course.",

        "William B. Langford":
            "Chicago-area architect active in the 1920s–1940s known for strategic designs across the Midwest. Known for Wakonda Club in Iowa.",

        "William C. Pickeman & George Coburn (1894)":
            "Scottish architects responsible for Portmarnock Golf Club in Dublin, one of Ireland's most celebrated links courses, founded in 1894.",

        "William Flynn / Tom Doak":
            "Historic combination at Cherry Hills Country Club in Denver, where Doak restored Flynn's original golden age design. Host of multiple US Opens.",

        "William J. Spear":
            "Regional architect known for Amana Colonies Golf Club in Iowa.",

        "William Laidlaw Purves":
            "Scottish architect known for Royal St George's Golf Club in Sandwich, England, host of multiple Open Championships.",

        "William Langford & Theodore Moreau":
            "Chicago-area partnership known for Midwest designs including Biltmore Country Club and Lawsonia Links in Wisconsin.",

        "William Newcomb":
            "Michigan architect known for Polo Fields Golf & Country Club.",

        "William S. Flynn":
            "Philadelphia-area architect known for Shinnecock Hills Golf Club, host of multiple US Opens, and Bedford Springs Resort in Pennsylvania.",

        "Willie Park Jr. & Robert White":
            "Willie Park Jr. was a two-time Open Champion who became one of golf's first professional architects. Known for Shorehaven Golf Club.",
    ]

    // MARK: - Lookup

    static func bio(for architectString: String) -> String? {
        if let b = bios[architectString] { return b }
        return bios[primaryName(from: architectString)]
    }

    static func profile(name: String, courses: [CourseProfile]) -> ArchitectProfile {
        ArchitectProfile(name: name, bio: bio(for: name), courses: courses)
    }

    // All courses grouped under this primary name (matches architect section headers).
    static func coursesForSection(primaryName name: String) -> [CourseProfile] {
        CourseLibrary.shared.allSorted().filter {
            guard let raw = $0.architect else { return false }
            return primaryName(from: raw) == name
        }
    }

    // All courses with this exact architect string.
    static func coursesForExact(name: String) -> [CourseProfile] {
        CourseLibrary.shared.allSorted().filter { $0.architect == name }
    }

    // MARK: - Private

    static func primaryName(from raw: String) -> String {
        let first = raw
            .components(separatedBy: CharacterSet(charactersIn: "&/"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
        return first.isEmpty ? raw : first
    }
}
