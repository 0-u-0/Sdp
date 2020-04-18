import Foundation

extension String {
    subscript (i: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: i)])
    }
    
    subscript (r: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start...end])
    }
    
    subscript(value: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: value.lowerBound)
        return String(self[start...])
    }
}

extension String {
    func matchingStrings(regex: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        if results.count > 0 {
            var filterResult = [String]()
            for r in 0..<results[0].numberOfRanges {
                if results[0].range(at: r).location != NSNotFound{
                    filterResult.append(nsString.substring(with: results[0].range(at: r )))
                }
            }
            return filterResult
        }else{
            return []
        }
    }
    func splitOnce(separator:Character) -> [String] {
        return split(separator:separator,maxSplits:1,omittingEmptySubsequences:true).map{String($0)}
    }
    
    func split(separator:Character) -> [String] {
        return split(separator:separator,omittingEmptySubsequences:true).map{String($0)}
    }
    
}

//https://tools.ietf.org/html/rfc4566
public struct Sdp {
    public static func parse(sdpStr:String) -> Session {
        //TODO: make separator as parameters
        let lines  = sdpStr.split(separator: "\r\n")
        //find indexs of medias
        var mediaIndexs = [Int]()
        for (index,line) in lines.enumerated() {
            if line.starts(with: "m=") {
                mediaIndexs.append(index)
            }
        }
        //TODO: no session
        var session:Session
        if 0 == mediaIndexs.count {
            //no media
            session = handleSession(lines: lines)
        }else{
            let sessionLines  = Array(lines[..<mediaIndexs[0]])
            session = handleSession(lines: sessionLines)
            
            for i in 0..<mediaIndexs.count {
                var mediaLines:[String];
                if i == (mediaIndexs.count - 1){
                    mediaLines  = Array(lines[mediaIndexs[i]..<(lines.count)])
                }else{
                    mediaLines  = Array(lines[mediaIndexs[i]..<mediaIndexs[i+1]])
                }
                let media = handleMedia(lines: mediaLines)
                session.medias.append(media)
            }
        }
        return session
    }
//    
//    public static func stringify( sdpDic:[String:Any]) -> String{
//
//    }
//    
    static func handleSession(lines:[String]) -> Session {
        let session = Session()
        for line in lines{
            let type = line[line.startIndex]
            let value = line[2...]

            switch type {
            case "v":
                //%x76 "=" 1*DIGIT CRLF
                session.version = Int(line[2])
            case "o":
                session.origin = value
            case "s":
                session.name = value
            case "t":
                session.timing = value
            case "a":
                let attrPair  = value.components(separatedBy: ":")
                if attrPair.count == 2 {
                    let attrKey = attrPair[0]
                    let attrValue = attrPair[1]
                    switch attrKey {
                        case "group":
                            //TODO:
                            session.group = attrValue
                        case "msid-semantic":
                            session.msidSemantic = attrValue
                        default:
                            print("unknown attr \(attrKey)")
                    }
                }
            default:
                print("unknown  type \(type)")
            }
        }
        
        return session
    }
    
    static func handleMedia(lines:[String]) -> Media {
        let media = Media()
        for line in lines{
            let type = line[line.startIndex]
            let value = line[2...]

            switch type {
            case "m":
                let pattern = #"(video|audio|application) ([0-9]+) ([A-Z/]+) ([[0-9]|\s]+)"#
                let result = value.matchingStrings(regex: pattern)
                if result.count == 5 {
                    media.type = result[1]
                    //TODO: Int
                    media.port = Int(result[2])
                    media.proto = result[3]
                    //FIXME: use array
                    let payloads = result[4].components(separatedBy: " ")
                    for payload in payloads {
                        let rtp = Rtp(payload: Int(payload)!)
                        media.rtps.append(rtp)
                    }
                }
            case "c":
                media.connection = value
            case "a":
                let attrPair  = value.splitOnce(separator: ":")
                if attrPair.count == 1{
                    switch value {
                    case "rtcp-mux":
                        media.rtcpMux = true
                    case "rtcp-rsize":
                        media.rtcpRsize = true
                    case "sendrecv","sendonly","recvonly","inactive":
                        media.direction = value
                    default:
                        print("unknown attr \(value)")
                     }
                }else if attrPair.count == 2{
                    let attrKey = attrPair[0]
                    let attrValue = attrPair[1]
                    switch attrKey {
                    case "ice-ufrag":
                        media.iceUfrag = attrValue
                    case "ice-pwd":
                        media.icePwd = attrValue
                    case "ice-options":
                        media.iceOptions = attrValue
                    case "setup":
                        media.setup = attrValue
                    case "mid":
                        //TODO: to Int
                        media.mid = Int(attrValue)
                    case "rtcp":
                        //TODO: destruct
                        media.rtcp = attrValue
                    case "msid":
                        media.msid = attrValue
                    case "fingerprint":
                        let fingerprintPair = attrValue.splitOnce(separator: " ")
                        //TODO: check pair count
                        media.fingerprint = Fingerprint(type: fingerprintPair[0], hash: fingerprintPair[1])
                    case "extmap":
                         let pattern = #"([0-9]+) (\S+)"#
                         let result = value.matchingStrings(regex: pattern)
                         if result.count == 3 {
                            let ext = Extension(value: result[1], uri: result[2])
                            media.extensions.append(ext)
                         }
                        
                    case "rtpmap":
                        let pattern = #"([0-9]+) ([\w-]+)/([0-9]+)(?:/([0-9]+))?"#
                        let result = value.matchingStrings(regex: pattern)
                        if result.count >= 4 {
                            if let index = media.getRtpIndex(payload: Int(result[1])!)  {
                                media.rtps[index].codec = result[2]
                                media.rtps[index].rate = Int(result[3])
                                if result.count == 5 {
                                    media.rtps[index].encoding = Int(result[4])
                                }
                            }
                        }
                    case "rtcp-fb":
                          let pattern = #"([0-9]+) ([\w\p{Z}-]+)"#
                          let result = value.matchingStrings(regex: pattern)
                          //TODO: check count
                          if let index = media.getRtpIndex(payload: Int(result[1])!)  {
                            media.rtps[index].rtcpFb.append(result[2])
                          }
                    case "fmtp":
                        let pattern = #"([0-9]+) ([\w-;=]+)"#
                        let result = value.matchingStrings(regex: pattern)
                        //TODO: check count
                
                        if let index = media.getRtpIndex(payload: Int(result[1])!)  {
                            media.rtps[index].fmtp.append(result[2])
                        }
                    case "ssrc":
                        //https://tools.ietf.org/html/rfc5576#page-5
                        let pattern = #"([0-9]+) ([\w]+):([\w-\p{Z}]+)$"#
                        let result = value.matchingStrings(regex: pattern)
                        //TODO: check count
                        let ssrc = Ssrc(id: Int(result[1])!, attribute: result[2], value: result[3])
                        media.ssrcs.append(ssrc)
                    case "ssrc-group":
                        let pattern = #"([\w]+) ([0-9\p{Z}]+)"#
                        let result = value.matchingStrings(regex: pattern)
                        if result.count == 3 {
                            let ssrcs = result[2].components(separatedBy: " ").map {Int($0)!}
                            let sg = SsrcGroup(semantics: result[1], ssrcs: ssrcs)
                            media.ssrcGroups.append(sg)
                        }
                    default:
                       print("unknown attr \(attrKey)")
                    }
                }
               
            default:
                print("unknown  type \(type)")
            }
        }
        return media
    }
}
