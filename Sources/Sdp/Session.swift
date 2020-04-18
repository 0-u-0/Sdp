//
//  File.swift
//  
//
//  Created by cong chen on 2020/4/17.
//

import Foundation

public class Session{
    var version:Int?
    var origin:String?
    var name:String?
    var timing:String?
    var group:String?
    var msidSemantic:String?
    var medias = [Media]()

    public func toString() -> String {
        var lines = [String]()
        if version != nil {
            lines.append("v=\(version!)")
        }
        
        if origin != nil {
            lines.append("o=\(origin!)")
        }
        
        if name != nil {
            lines.append("s=\(name!)")
        }
        
        if timing != nil {
            lines.append("t=\(timing!)")
        }
        
        if group != nil {
            lines.append("a=group:\(group!)")
        }
        if msidSemantic != nil {
            lines.append("a=msid-semantic:\(msidSemantic!)")
        }
        
        for media in medias {
            lines.append(media.toString())
        }
        let sdp = lines.joined(separator: "\n")
        return sdp
    }

}
