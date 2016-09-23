//
//  WindowViewController.swift
//  SwiftMessages
//
//  Created by Timothy Moose on 8/1/16.
//  Copyright © 2016 SwiftKick Mobile LLC. All rights reserved.
//

import UIKit

class WindowViewController: UIViewController
{
    fileprivate var window: UIWindow?
    
    let windowLevel: UIWindowLevel
    var statusBarStyle: UIStatusBarStyle?
    
    init(windowLevel: UIWindowLevel = UIWindowLevelNormal)
    {
        self.windowLevel = windowLevel
        let window = PassthroughWindow(frame: UIScreen.main.bounds)
        self.window = window
        super.init(nibName: nil, bundle: nil)
        self.view = PassthroughView()
        window.rootViewController = self
        window.windowLevel = windowLevel
    }
    
    func install() {
        guard let window = window else { return }
        window.makeKeyAndVisible()
    }
    
    func uninstall() {
        window?.isHidden = true
        window = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle ?? UIApplication.shared.statusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }
}
