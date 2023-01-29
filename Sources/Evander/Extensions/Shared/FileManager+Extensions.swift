//  Created by Andromeda on 01/10/2021.
//

import Foundation

public extension FileManager {
    
    var documentDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var cacheDirectory: URL {
        urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    var libraryDirectory: URL {
        urls(for: .libraryDirectory, in: .userDomainMask)[0]
    }
    
}
