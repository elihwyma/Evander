//  Created by Amy While on 16/02/2021.
//  Copyright © 2021 Amy While. All rights reserved.
//


#if canImport(UIKit)
import UIKit
public typealias Image = UIImage
#else
import AppKit
public typealias Image = NSImage
#endif

final public class ImageProcessing {
    
    public static let dispatchQueue = DispatchQueue(label: "Evander/ImageProcessing")
    
    public class func downsample(image: Image, to pointSize: CGSize? = nil, scale: CGFloat? = nil, _ completion: @escaping (Image?) -> Void) {
        let size = pointSize ?? image.size
        if let pngData = image.pngData() {
            dispatchQueue.async {
                downsample(data: pngData, to: size, scale: scale, completion)
            }
        } else {
            completion(nil)
        }
    }
    
    public class func downsample(data: Data, to pointSize: CGSize? = nil, scale: CGFloat? = nil, _ completion: @escaping (Image?) -> Void) {
        dispatchQueue.async {
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions),
                  let size = pointSize ?? getSize(from: imageSource) else { return completion(nil) }
            completion(downsample(source: imageSource, size: size, scale: scale))
        }
    }
    
    public class func downsample(url: URL, to pointSize: CGSize? = nil, scale: CGFloat? = nil, _ completion: @escaping (Image?) -> Void) {
        dispatchQueue.async {
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
                  let size = pointSize ?? getSize(from: imageSource) else { return completion(nil) }
            completion(downsample(source: imageSource, size: size, scale: scale))
        }
    }
    
    private class func downsample(source: CGImageSource, size: CGSize, scale: CGFloat?) -> Image? {
        #if os(macOS)
        let maxDimentionInPixels = max(size.width, size.height)
        #else
        let maxDimentionInPixels = max(size.width, size.height)  * (scale ?? UIScreen.main.scale)
        #endif
        let downsampledOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels
        ] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampledOptions) else { return nil }
        return Image(cgImage: downScaledImage)
    }
    
    private class func getSize(from source: CGImageSource) -> CGSize? {
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil),
              let height = (metadata as NSDictionary)["PixelHeight"] as? Double,
              let width = (metadata as NSDictionary)["PixelWidth"] as? Double else { return nil }
        return CGSize(width: width, height: height)
    }
    
}

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
public extension ImageProcessing {

    class func downsample(image: Image, to pointSize: CGSize? = nil, scale: CGFloat? = nil) async -> Image? {
        let size = pointSize ?? image.size
        guard let pngData = image.pngData() else { return nil }
        return await downsample(data: pngData, to: size, scale: scale)
    }
    
    class func downsample(data: Data, to pointSize: CGSize? = nil, scale: CGFloat? = nil) async -> Image? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions),
              let size = pointSize ?? getSize(from: imageSource) else { return nil }
        return downsample(source: imageSource, size: size, scale: scale)
    }
}

final public class EvanderGIF: Image {
    
    public var calculatedDuration: Double!
    public var animatedImages: [Image]!

    convenience init?(data: Data, size: CGSize, scale: CGFloat? = nil, _ firstImage: ((Image?) -> Void)? = nil) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil),
              let delayTime = ((metadata as NSDictionary)["{GIF}"] as? NSMutableDictionary)?["DelayTime"] as? Double else {
            return nil
        }
        
        let imageCount = CGImageSourceGetCount(source)
        #if os(macOS)
        let maxDimentionInPixels = max(size.width, size.height)
        #else
        let maxDimentionInPixels = max(size.width, size.height)  * (scale ?? UIScreen.main.scale)
        #endif
        var images = [Image]()
        images.reserveCapacity(imageCount)
        
        let downsampledOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels
        ] as CFDictionary
        
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateThumbnailAtIndex(source, i, downsampledOptions) {
                images.append(Image(cgImage: image))
                if i == 0 {
                    firstImage?(images[0])
                }
            }
        }
        
        let calculatedDuration = Double(imageCount) * delayTime
        self.init()
        self.animatedImages = images
        self.calculatedDuration = calculatedDuration
    }
}

#if os(macOS)
extension NSImage {
    
    func pngData() -> Data? {
        if let tiff = tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let imageRep = bitmap.representation(using: .png, properties: [:]) {
            return imageRep
        }
        return nil
    }
    
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
    
}
#endif
