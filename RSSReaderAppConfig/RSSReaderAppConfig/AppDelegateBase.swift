//
//  AppDelegateBase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 08/10/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import FBAllocationTracker
import FBMemoryProfiler
import GEBase
import UIKit

extension KVOCompliantUserDefaults {
	@NSManaged public var memoryProfilingEnabled: Bool
}

open class AppDelegateBase : UIResponder, UIApplicationDelegate {
	public var window: UIWindow?
	final var retainedObjects = [Any]()
	// MARK: -
	@IBAction public func openSettings(_ sender: AnyObject?) {
		let url = URL(string: UIApplicationOpenSettingsURLString)!
		let application = UIApplication.shared
		if #available(iOS 10.0, *) {
			application.open(url, options: [:], completionHandler: nil)
		} else {
			application.openURL(url)
		}
	}
	@IBAction public func crash(_ sender: AnyObject?) {
		fatalError()
	}
	// MARK: -
	open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		if _1 {
			if defaults.memoryProfilingEnabled {
				let memoryProfiler = FBMemoryProfiler()
				memoryProfiler.enable()
				retainedObjects += [memoryProfiler]
			}
		}
		else {
			var memoryProfiler: FBMemoryProfiler!
			retainedObjects += [KVOBinding(defaults•#keyPath(KVOCompliantUserDefaults.memoryProfilingEnabled), options: .initial) { change in
				if defaults.memoryProfilingEnabled {
					guard nil == memoryProfiler else {
						return
					}
					memoryProfiler = FBMemoryProfiler()
					memoryProfiler.enable()
				}
				else {
					guard nil != memoryProfiler else {
						return
					}
					memoryProfiler.disable()
					memoryProfiler = nil
				}
			}]
		}
		return true
	}
	// MARK: -
	public override init() {
		super.init()
		let defaultsPlistURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
		try! loadDefaultsFromSettingsPlistAtURL(defaultsPlistURL)
		if defaults.memoryProfilingEnabled {
			FBAllocationTrackerManager.shared()!.startTrackingAllocations()
			FBAllocationTrackerManager.shared()!.enableGenerations()
		}
		let fileManager = FileManager()
		let libraryDirectoryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).last!
		let libraryDirectory = libraryDirectoryURL.path
        $(libraryDirectory)
	}
	// MARK: -
	static private let initializeOnce: Void = {
		if $(versionIsClean) {
			_ = crashlyticsInitializer
			_ = appseeInitializer
			_ = uxcamInitializer
			_ = flurryInitializer
		}
	}()
	override open class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}