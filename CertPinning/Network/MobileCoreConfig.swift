//
//  SafeNetworkConfig.swift
//  MobileCore
//
//  Created by Michael Thornton on 8/13/19.
//  Copyright © 2019 Michael Thornton. All rights reserved.
//

import Foundation



public class MobileCoreConfig {
    
    public static let shared = MobileCoreConfig()
    
    var hashes = [String]()

    /**
     Private to enforce singleton pattern
     */
    private init() { }
    

    
    public func addPinnedHash(_ hash: String) {
        hashes.append(hash)
    }
    
} // end class

