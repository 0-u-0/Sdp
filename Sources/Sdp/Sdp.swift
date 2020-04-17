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
            return (0..<results[0].numberOfRanges).map {
                results[0].range(at: $0).location != NSNotFound ? nsString.substring(with: results[0].range(at: $0)): ""
            }
        }else{
            return []
        }
    }
    func split(separator:Character) -> [String] {
        return split(separator:separator,maxSplits:1,omittingEmptySubsequences:true).map{String($0)}
    }
}

//https://tools.ietf.org/html/rfc4566
public struct Sdp {
    public static func parse(sdpStr:String) -> [String:Any]{
        //TODO: make separator as parameters
        let lines  = sdpStr.components(separatedBy: "\n")
        //find indexs of medias
        var mediaIndexs = [Int]()
        for (index,line) in lines.enumerated() {
            if line.starts(with: "m=") {
                mediaIndexs.append(index)
            }
        }
        
        var sessionDic = [String:Any]()
        var medias = [[String:Any]]()
        if 0 == mediaIndexs.count {
            //no media
            sessionDic = handleSession(lines: lines)
        }else{
            let sessionLines  = Array(lines[..<mediaIndexs[0]])
            sessionDic = handleSession(lines: sessionLines)
            
            for i in 0..<mediaIndexs.count {
                var mediaLines:[String];
                if i == (mediaIndexs.count - 1){
                    mediaLines  = Array(lines[mediaIndexs[i]..<(lines.count)])
                }else{
                    mediaLines  = Array(lines[mediaIndexs[i]..<mediaIndexs[i+1]])
                }
                let media = handleMedia(lines: mediaLines)
                medias.append(media)
            }
        }
        sessionDic["media"] = medias
        return sessionDic
    }
    
    public static func stringify( [String:Any]) -> String{
        
    }
    
    static func handleSession(lines:[String]) -> [String:Any]{
        var sessionDic = [String:Any]()
        for line in lines{
            let type = line[line.startIndex]
            let value = line[2...]

            switch type {
            case "v":
                //%x76 "=" 1*DIGIT CRLF
                sessionDic["version"] = Int(line[2])
            case "o":
                sessionDic["origin"] = value
            case "s":
                sessionDic["name"] = value
            case "t":
                sessionDic["timing"] = value
            case "a":
                let attrPair  = value.components(separatedBy: ":")
                if attrPair.count == 2 {
                    let attrKey = attrPair[0]
                    let attrValue = attrPair[1]
                    switch attrKey {
                        case "group":
                            //TODO:
                            sessionDic["group"] = attrValue
                        case "msid-semantic":
                            sessionDic["msidSemantic"] = attrValue
                        default:
                            print("unknown attr \(attrKey)")
                    }
                }
            default:
                print("unknown  type \(type)")
            }
        }
        
        return sessionDic
    }
    
    static func handleMedia(lines:[String]) -> [String:Any] {
        print(lines)

        var mediaDic = [String:Any]()
        for line in lines{
            let type = line[line.startIndex]
            let value = line[2...]

            switch type {
            case "m":
                let pattern = #"(video|audio|application) ([0-9]+) ([A-Z/]+) ([[0-9]|\s]+)"#
                let result = value.matchingStrings(regex: pattern)
                if result.count == 5 {
                    mediaDic["type"] = result[1]
                    //TODO: Int
                    mediaDic["port"] = result[2]
                    mediaDic["protocol"] = result[3]
                    //FIXME: use array
                    mediaDic["payloads"] = result[4]
                }
                
            case "c":
                mediaDic["connection"] = value

            case "a":
                let attrPair  = value.split(separator: ":")
                if attrPair.count == 1{
                    switch value {
                    case "rtcp-mux":
                        mediaDic["rtcpMux"] = value
                    case "rtcp-rsize":
                        mediaDic["rtcpRsize"] = value
                    case "sendrecv","sendonly","recvonly","inactive":
                        mediaDic["direction"] = value
                    default:
                        print("unknown attr \(value)")
                     }
                }else if attrPair.count == 2{
                    let attrKey = attrPair[0]
                    let attrValue = attrPair[1]
                    switch attrKey {
                    case "ice-ufrag":
                       mediaDic["iceUfrag"] = attrValue
                    case "ice-pwd":
                       mediaDic["icePwd"] = attrValue
                    case "ice-options":
                       mediaDic["iceOptions"] = attrValue
                    case "setup":
                        mediaDic["setup"] = attrValue
                    case "mid":
                        //TODO: to Int
                        mediaDic["mid"] = attrValue
                    case "rtcp":
                        //TODO: destruct
                        mediaDic["rtcp"] = attrValue
                    case "msid":
                        mediaDic["msid"] = attrValue
                    case "fingerprint":
                        let fingerprintPair = attrValue.split(separator: " ")
                        //TODO: check pair count
                        mediaDic["fingerprint"] = ["type":fingerprintPair[0],"hash":fingerprintPair[1]]
                    case "extmap":
                        if mediaDic["ext"] == nil {
                            mediaDic["ext"] = [[String:Any]]()
                        }
                        if var dict = mediaDic["ext"] as? [[String:Any]]
                        {
                            let pattern = #"([0-9]+) (\S+)"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count == 3 {
                                dict.append(["value":result[1],"uri":result[2]])
                            }
                            mediaDic["ext"] = dict
                        }
                    case "rtpmap":
                        if mediaDic["rtp"] == nil {
                            mediaDic["rtp"] = [[String:Any]]()
                        }
                        if var dict = mediaDic["rtp"] as? [[String:Any]]
                        {
                            let pattern = #"([0-9]+) ([\w]+)/([0-9]+)"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count == 4 {
                                dict.append(["payload":result[1],"codec":result[2],"rate":result[3]])
                            }
                            mediaDic["rtp"] = dict
                        }
                    case "rtcp-fb":
                        if mediaDic["rtcpFb"] == nil {
                              mediaDic["rtcpFb"] = [[String:Any]]()
                          }
                          if var dict = mediaDic["rtcpFb"] as? [[String:Any]]
                          {
                              let pattern = #"([0-9]+) ([\w\p{Z}-]+)"#
                              let result = value.matchingStrings(regex: pattern)
                              if result.count == 3 {
                                  dict.append(["payload":result[1],"type":result[2]])
                              }
                              mediaDic["rtcpFb"] = dict
                          }
                    case "fmtp":
                        if mediaDic["fmtp"] == nil {
                              mediaDic["fmtp"] = [[String:Any]]()
                          }
                          if var dict = mediaDic["fmtp"] as? [[String:Any]]
                          {
                              let pattern = #"([0-9]+) ([\w-;=]+)"#
                              let result = value.matchingStrings(regex: pattern)
                              if result.count == 3 {
                                  dict.append(["payload":result[1],"config":result[2]])
                              }
                              mediaDic["fmtp"] = dict
                          }
                    case "ssrc":
                        //https://tools.ietf.org/html/rfc5576#page-5

                        if mediaDic["ssrc"] == nil {
                            mediaDic["ssrc"] = [[String:Any]]()
                        }
                        if var dict = mediaDic["ssrc"] as? [[String:Any]]
                        {
                            let pattern = #"([0-9]+) ([\w]+):([\w-\p{Z}]+)$"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count == 4 {
                                dict.append(["id":result[1],"attribute":result[2],"value":result[3]])
                            }
                            mediaDic["ssrc"] = dict
                        }
                    case "ssrc-group":

                        if mediaDic["ssrcGroup"] == nil {
                            mediaDic["ssrcGroup"] = [[String:Any]]()
                        }
                        if var dict = mediaDic["ssrcGroup"] as? [[String:Any]]
                        {
                            let pattern = #"([\w]+) ([0-9\p{Z}]+)"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count == 3 {
                                dict.append(["semantics":result[1],"ssrc":result[2]])
                            }
                            mediaDic["ssrcGroup"] = dict
                        }
                    default:
                       print("unknown attr \(attrKey)")
                    }
                }
               
            default:
                print("unknown  type \(type)")
            }
        }
        return mediaDic
    }
}
