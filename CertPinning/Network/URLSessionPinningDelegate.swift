//
//  URLSessionPinningDelegate.swift
//  MobileCore
//
//  Created by Michael Thornton on 8/10/19.
//  Copyright © 2019 Michael Thornton. All rights reserved.
//

/**
 Based on : https://www.bugsee.com/blog/ssl-certificate-pinning-in-mobile-applications/
 
 
 openssl s_client -connect insights.clover.com:443 -showcerts < /dev/null | openssl x509 -outform DER > site_cert.der
 openssl x509 -pubkey -noout -in site_cert.der -inform DER | openssl rsa -outform DER -pubin -in /dev/stdin 2>/dev/null > site_key.der
 python -sBc "from __future__ import print_function;import hashlib;print(hashlib.sha256(open('site_key.der','rb').read()).digest(), end='')" | base64
 Cb48lPngKS2C18DmSlxbZNktoEYvuiWLE4TqyWNC7+E=
 
 We are pinning to the value : Cb48lPngKS2C18DmSlxbZNktoEYvuiWLE4TqyWNC7+E=
 */

import Foundation
import Security
import CommonCrypto



private extension Data {
    
    func sha256() -> String {
        
        let rsa2048Asn1Header:[UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]
        
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(self)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        
        
        return Data(hash).base64EncodedString()
    }
    
} // end extension



class URLSessionPinningDelegate: NSObject, URLSessionDelegate {
    

    private var hashes: [String] {
        get {
            return MobileCoreConfig.shared.hashes
        }
    }

    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
        validateChallenge(challenge, completionHandler: completionHandler)
    }
    
    
    
    /**
     Check the certificates public key hash against cached list of valid public keys.  This was split into a seperate function from the normal urlSession
     method so that it can be easily used from the simililar WKWebView navigation delegate method.
     */
    func validateChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
                
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                var secresult = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &secresult)
                
                if(errSecSuccess == status) {
                    let serverHashes = getPublicKeysFromTrust(serverTrust)
                    
                    for keyHash in serverHashes {
                        if isHashPinned(keyHash: keyHash) {
                            completionHandler(.useCredential, URLCredential(trust:serverTrust))
                            return
                        }
                    }
                }
            }
        }
        
        // Pinning failed
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    
    
    fileprivate func isHashPinned(keyHash: String) -> Bool {

        for pinnedKey in hashes {
            //print("pin test of \(keyHash) against pinned \(pinnedKey)")
            if (keyHash == pinnedKey) {
                return true
            }
        }
        
        return false
    }
    
    
    
    fileprivate func getPublicKeysFromTrust(_ trust: SecTrust) -> [String] {
        
        var hashedKeys : [String] = []
        
        for index in 0..<SecTrustGetCertificateCount(trust) {
            if let serverCertificate = SecTrustGetCertificateAtIndex(trust, index) {

                let serverPublicKey = SecCertificateCopyKey(serverCertificate)
                let serverPublicKeyData:NSData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil )!
                let keyHash = (serverPublicKeyData as Data).sha256()

                hashedKeys.append(keyHash)
            }
        }
        
        return hashedKeys
    }
    

} // end class

