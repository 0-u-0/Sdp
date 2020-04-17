//
//  File.swift
//  
//
//  Created by cong chen on 2020/4/17.
//

import Foundation


struct Rtp{
    public let payload:Int
    public var codec:String?
    public var rate:Int?
    public var encoding:Int?
    public var rtcpFb = [String]()
    public var fmtp = [String]()
    
    
    public func toString() -> String{
        var lines = [String]()
        if encoding != nil {
            lines.append("a=rtpmap:\(payload) \(codec!)/\(rate!)/\(encoding!)")
        }else{
            lines.append("a=rtpmap:\(payload) \(codec!)/\(rate!)")
        }
        
        for rf in rtcpFb {
            lines.append("a=rtcp-fb:\(payload) \(rf)")
        }
        
        for f in fmtp {
            lines.append("a=fmtp:\(payload) \(f)")
        }

        let rtpSdp = lines.joined(separator: "\n")
        return rtpSdp
    }
}

struct Fingerprint{
    public let type:String
    public let hash:String
}

struct Extension{
    public let value:String
    public let uri:String
}

struct Ssrc{
    public let id:Int
    public let attribute:String
    public let value:String
}

struct SsrcGroup{
    public let semantics:String
    public var ssrcs:[Int]
    
    func toString() -> String {
        return "a=ssrc-group:\(semantics) \(ssrcs.map{String($0)}.joined(separator: " "))"
    }
}

class Media{
    var type:String?
    var port:Int?
    var mid:Int?
    //protocol
    var proto:String?
    var connection:String?
    var direction:String?
    var iceUfrag:String?
    var icePwd:String?
    var iceOptions:String?
    var setup:String?
    var rtcp:String?
    var msid:String?
    
    var fingerprint:Fingerprint?
    
    var extensions = [Extension]()
    var rtps = [Rtp]()
    var ssrcs = [Ssrc]()
    var ssrcGroups = [SsrcGroup]()

    
    var rtcpMux:Bool = false
    var rtcpRsize:Bool = false

    
    func getRtpIndex(payload:Int) -> Int?{
        return rtps.firstIndex(where: {$0.payload == payload})
    }
    
    func toString() -> String {
        /*

         */
        var lines = [String]()
        let payloads = rtps.map{String($0.payload)}
        lines.append("m=\(type!) \(port!) \(proto!) \(payloads.joined(separator: " "))")
        if connection != nil {
            lines.append("c=\(connection!)")
        }
        
        if rtcp != nil {
            lines.append("a=rtcp:\(rtcp!)")
        }
        
        if iceUfrag != nil {
            lines.append("a=ice-ufrag:\(iceUfrag!)")
        }
        
        if icePwd != nil {
            lines.append("a=ice-pwd:\(icePwd!)")
        }
        
        if iceOptions != nil {
            lines.append("a=ice-options:\(iceOptions!)")
        }
        
        if fingerprint != nil {
            lines.append("a=fingerprint:\(fingerprint!.type) \(fingerprint!.hash)")
        }
        
        if setup != nil {
            lines.append("a=setup:\(setup!)")
        }
        
        if mid != nil {
            lines.append("a=mid:\(mid!)")
        }
        
        if msid != nil {
            lines.append("a=msid:\(msid!)")
        }
        
        if direction != nil {
            lines.append("a=\(direction!)")
        }
        
        if rtcpMux {
            lines.append("a=rtcp-mux")
        }
        
        if rtcpRsize {
            lines.append("a=rtcp-rsize")
        }
        
        for ext in extensions {
            lines.append("a=extmap:\(ext.value) \(ext.uri)")
        }
        
        for rtp in rtps {
            lines.append(rtp.toString())
        }
        
        for sg in ssrcGroups {
            lines.append(sg.toString())
        }
        
        for ssrc in ssrcs {
            lines.append("a=ssrc:\(ssrc.id) \(ssrc.attribute):\(ssrc.value)")
        }
        

        let mediaSdp = lines.joined(separator: "\n")
        return mediaSdp
    }
}
