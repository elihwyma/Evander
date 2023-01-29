//
//  File.swift
//  
//
//  Created by Amy While on 17/01/2023.
//

import Foundation
#if canImport(ZippyJSON)
import ZippyJSON
#endif

#if canImport(ZippyJSON)
typealias mJSONDecoder = ZippyJSONDecoder
#else
typealias mJSONDecoder = JSONDecoder
#endif
