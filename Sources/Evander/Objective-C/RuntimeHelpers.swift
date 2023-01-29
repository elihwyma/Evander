//
//  RuntimeHelpers.swift
//  
//
//  Created by Amy While on 28/01/2023.
//

import Foundation
import ObjectiveC.runtime

public class RuntimeHelpers {
    
    public enum RuntimeHelperError: Error {
        case invalidSelector
        case invalidIvar
    }
    
    public class func replace(_ method: Selector, with replacement: Selector, on targetClass: AnyClass) throws {
        let originalMethod: Method?
        let newMethod: Method?
        
        if targetClass.responds(to: method) {
            originalMethod = class_getClassMethod(targetClass, method)
            newMethod = class_getClassMethod(targetClass, replacement)
        } else {
            originalMethod = class_getInstanceMethod(targetClass, method)
            newMethod = class_getInstanceMethod(targetClass, replacement)
        }
        guard let originalMethod,
              let newMethod else {
            throw RuntimeHelperError.invalidSelector
        }
        method_exchangeImplementations(originalMethod, newMethod)
    }
    
    public class func get(ivar: String, on targetObject: AnyObject) throws -> Any? {
        guard let ivar = class_getInstanceVariable(type(of: targetObject), ivar) else {
            throw RuntimeHelperError.invalidIvar
        }
        return object_getIvar(targetObject, ivar)
    }
    
    public class func set(_ object: Any?, on targetObject: AnyObject, for ivar: String) throws {
        guard let ivar = class_getInstanceVariable(type(of: targetObject), ivar) else {
            throw RuntimeHelperError.invalidIvar
        }
        object_setIvar(targetObject, ivar, object)
    }
    
}
