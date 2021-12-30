//
//  FrameRequest.swift
//  
//
//  Created by Amy While on 30/12/2021.
//

import UIKit

@available(iOS 15, *)
public final class FrameRateRequest {
    
    private let frameRateRange: CAFrameRateRange
    private let duration: TimeInterval
    
    init(preferredFrameRate: Float = 120, duration: TimeInterval) {
        frameRateRange = CAFrameRateRange(minimum: 30, maximum: Float(UIScreen.main.maximumFramesPerSecond), preferred: preferredFrameRate)
        self.duration = duration
    }
    
    public func perform() {
        let displayLink = CADisplayLink(target: self, selector: #selector(dummyFunction))
        displayLink.preferredFrameRateRange = frameRateRange
        displayLink.add(to: .current, forMode: .common)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayLink.remove(from: .current, forMode: .common)
        }
    }
    
    @objc private func dummyFunction() {}
}

public final class FRUIView {
    
    class public func animate(withDuration duration: TimeInterval,
                       delay: TimeInterval,
                       options: UIView.AnimationOptions = [],
                       animations: @escaping () -> Void,
                       completion: ((Bool) -> Void)? = nil) {
        if #available(iOS 15, *) {
            FrameRateRequest(duration: duration).perform()
        }
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
    }
    
    class public func animate(withDuration duration: TimeInterval,
                              animations: @escaping () -> Void,
                              completion: ((Bool) -> Void)? = nil) {
        if #available(iOS 15, *) {
            FrameRateRequest(duration: duration).perform()
        }
        UIView.animate(withDuration: duration, animations: animations, completion: completion)
    }
    
    class public func animate(withDuration duration: TimeInterval,
                              animations: @escaping () -> Void) {
        if #available(iOS 15, *) {
            FrameRateRequest(duration: duration).perform()
        }
        UIView.animate(withDuration: duration, animations: animations)
    }
    
}
