//
//  Extensions.swift
//  FABDrawnView
//
//  Created by fred.a.brown on 10/20/17.
//  Copyright © 2017 Zebrasense. All rights reserved.
//

import UIKit

protocol NibInstantiable {
    
    static var nibBundle : Bundle? { get }
    static var nibName: String { get }
}

extension NibInstantiable {
    
    static var nibName: String? { return nil }
    static var nibBundle: Bundle? { return nil }
    
    static func instantiateFromNib() -> Self {
        
        let nib = UINib(nibName: nibName, bundle: nibBundle)
        
        return nib.instantiate(withOwner: nil, options: nil).first as! Self
        
        
    }
}
