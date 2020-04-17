//
//  File.swift
//  
//
//  Created by cong chen on 2020/4/16.
//
import Foundation

extension Dictionary {

    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            if #available(iOS 13.0, macOS 10.15, *) {
                let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes])
                return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson

            } else {
                let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
                let jsonStr = String(bytes: jsonData, encoding: String.Encoding.utf8)!
                return jsonStr.replacingOccurrences(of: "\\/", with: "/")
            }
  
        } catch {
            return invalidJson
        }
    }

    func printJson() {
        print(json)
    }

}

let testSdp = """
v=0
o=- 4303111459759567207 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=msid-semantic: WMS
m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127 123 125
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:GOBI
a=ice-pwd:35cgE8nLgMzds5orV5UQ1BkM
a=ice-options:trickle renomination
a=fingerprint:sha-256 FA:05:13:F3:A0:6A:05:C0:AF:6E:9D:F1:20:F1:B3:31:33:63:94:7C:D4:A1:B7:9B:4C:DB:8B:3C:E0:FB:36:11
a=setup:actpass
a=mid:0
a=extmap:14 urn:ietf:params:rtp-hdrext:toffset
a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
a=extmap:13 urn:3gpp:video-orientation
a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
a=extmap:11 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
a=extmap:8 http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07
a=extmap:9 http://www.webrtc.org/experiments/rtp-hdrext/color-space
a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
a=sendonly
a=msid:- abc
a=rtcp-mux
a=rtcp-rsize
a=rtpmap:96 H264/90000
a=rtcp-fb:96 goog-remb
a=rtcp-fb:96 transport-cc
a=rtcp-fb:96 ccm fir
a=rtcp-fb:96 nack
a=rtcp-fb:96 nack pli
a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c34
a=rtpmap:97 rtx/90000
a=fmtp:97 apt=96
a=rtpmap:98 H264/90000
a=rtcp-fb:98 goog-remb
a=rtcp-fb:98 transport-cc
a=rtcp-fb:98 ccm fir
a=rtcp-fb:98 nack
a=rtcp-fb:98 nack pli
a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e034
a=rtpmap:99 rtx/90000
a=fmtp:99 apt=98
a=rtpmap:100 VP8/90000
a=rtcp-fb:100 goog-remb
a=rtcp-fb:100 transport-cc
a=rtcp-fb:100 ccm fir
a=rtcp-fb:100 nack
a=rtcp-fb:100 nack pli
a=rtpmap:101 rtx/90000
a=fmtp:101 apt=100
a=rtpmap:127 red/90000
a=rtpmap:123 rtx/90000
a=fmtp:123 apt=127
a=rtpmap:125 ulpfec/90000
a=ssrc-group:FID 2747663846 3643929305
a=ssrc:2747663846 cname:LxjR7vs9CB6gFDai
a=ssrc:2747663846 msid:- abc
a=ssrc:2747663846 mslabel:-
a=ssrc:2747663846 label:abc
a=ssrc:3643929305 cname:LxjR7vs9CB6gFDai
a=ssrc:3643929305 msid:- abc
a=ssrc:3643929305 mslabel:-
a=ssrc:3643929305 label:abc
"""

let result = Sdp.parse(sdpStr:testSdp)

result.printJson()

//print(result)
