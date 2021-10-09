//  Created by Andromeda on 09/10/2021.
//

import UIKit

public class EvanderImageView: UIImageView {
    
    public var url: URL? {
        didSet {
            reloadImage(for: url)
        }
    }
    public var cache: Bool = true
    public var size: CGSize?
    
    public convenience init(size: CGSize? = nil, url: URL? = nil, cache: Bool = true) {
        self.init(frame: .zero)
        self.size = size
        self.url = url
        self.cache = cache
    }
    
    private func reloadImage(for url: URL?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.reloadImage(for: url)
            }
            return
        }
        guard let url = url else { image = nil; return }
        image = EvanderNetworking.shared.image(url, cache: cache, size: size, { [weak self] reload, image in
            guard self.url == url,
                  reload,
                  let image = image {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    self.image = image
                }
            }
        })
    }
    
}
