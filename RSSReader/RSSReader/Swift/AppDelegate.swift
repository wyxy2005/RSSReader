//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import GEKeyPaths
import UIKit
import CoreData
import FBAllocationTracker
import FBMemoryProfiler
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
import Fabric
import Crashlytics
#endif
#if APPSEE_ENABLED
import Appsee
#endif
#endif

class AppDelegateInternals {
	var rssSession: RSSSession?
	private let urlTaskGeneratorProgressKVOBinding: KVOBinding
	init() {
		let taskGenerator = progressEnabledURLSessionTaskGenerator
		urlTaskGeneratorProgressKVOBinding = KVOBinding(taskGenerator•{$0.progresses}, options: []) { change in
			let networkActivityIndicatorShouldBeVisible = 0 < taskGenerator.progresses.count
			UIApplication.sharedApplication().networkActivityIndicatorVisible = (networkActivityIndicatorShouldBeVisible)
		}
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FoldersController {
	var window: UIWindow?
	final var retainedObjects = [AnyObject]()
#if false
	var foldersLastUpdateDate: NSDate?
#else
	final var foldersLastUpdateDate: NSDate? {
		get {
			return defaults.foldersLastUpdateDate
		}
		set {
			defaults.foldersLastUpdateDate = newValue
		}
	}
#endif
	final var foldersLastUpdateErrorRaw: NSError? {
		get {
			if let data = defaults.foldersLastUpdateErrorEncoded {
				return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSError?
			}
			else {
				return nil
			}
		}
		set {
			defaults.foldersLastUpdateErrorEncoded = {
				if let error = newValue {
					return NSKeyedArchiver.archivedDataWithRootObject(error)
				}
				else {
					return nil
				}
			}()
		}
	}
	let internals = AppDelegateInternals()
	dynamic var foldersUpdateStateRaw = FoldersUpdateState.Completed.rawValue
	var foldersUpdateState = FoldersUpdateState.Completed {
		didSet {
			foldersUpdateStateRaw = foldersUpdateState.rawValue
		}
	}
	var tabBarController: UITabBarController! {
		if let tabBarController = window!.rootViewController! as? UITabBarController {
			return tabBarController
		}
		return nil
	}
	var navigationController: UINavigationController! {
		if let navigationController = window!.rootViewController! as? UINavigationController {
			return navigationController
		}
		return nil
	}
	var foldersNavigationController: UINavigationController {
		if let tabBarController = self.tabBarController {
			return tabBarController.viewControllers![0] as! UINavigationController
		}
		else {
			return navigationController
		}
	}
	var foldersViewController: FoldersListTableViewController {
		return foldersNavigationController.viewControllers.first as! FoldersListTableViewController
	}
	lazy var favoritesViewController: ItemsListViewController = {
		let self_ = UIApplication.sharedApplication().delegate! as! AppDelegate
		let $ = (self_.tabBarController.viewControllers![1] as! UINavigationController).viewControllers.first as! ItemsListViewController
		configureFavoritesItemsListViewController($)
		return $
	}()
	var loginAndPassword: LoginAndPassword!
	// MARK: -
	@IBAction func openSettings(sender: AnyObject?) {
		UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
	}
	@IBAction func crash(sender: AnyObject?) {
		let _ = "foo" as AnyObject as! Int
	}
	// MARK: -
	lazy var fetchedRootFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(rootTagSuffix)) { folder in
		let foldersViewController = self.foldersViewController
		foldersViewController.rootFolder = folder
	}
	lazy var fetchedFavoritesFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(favoriteTagSuffix)) { folder in
		let foldersViewController = self.favoritesViewController
		foldersViewController.container = folder
	}
	// MARK: -
	private let currentRestorationFormatVersion = 1
	private enum Restorable: String {
		case restorationFormatVersion
	}
	func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		$(self)
		coder.encodeObject(currentRestorationFormatVersion, forKey: Restorable.restorationFormatVersion.rawValue)
		return true
	}
	func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		$(self)
		let restorationFormatVersion = (coder.decodeObjectForKey(Restorable.restorationFormatVersion.rawValue) as! Int?) ?? 0
		if $(restorationFormatVersion) < currentRestorationFormatVersion {
			return false
		}
		return $(defaults.stateRestorationEnabled)
	}
	//
	func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		$(self)
		return true
	}
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		filesWithTracingDisabled += [
			"TableViewFetchedResultsControllerDelegate.swift",
			"KVOCompliantUserDefaults.swift"
		]
		if _1 {
			if defaults.memoryProfilingEnabled {
				let memoryProfiler = FBMemoryProfiler()
				memoryProfiler.enable()
				retainedObjects += [memoryProfiler]
			}
		}
		else {
			var memoryProfiler: FBMemoryProfiler!
			retainedObjects += [KVOBinding(defaults•{$0.memoryProfilingEnabled}, options: .Initial) { change in
				if defaults.memoryProfilingEnabled {
					guard (memoryProfiler == nil) else {
						return
					}
					memoryProfiler = FBMemoryProfiler()
					memoryProfiler.enable()
				}
				else {
					guard (memoryProfiler != nil) else {
						return
					}
					memoryProfiler.disable()
					memoryProfiler = nil
				}
			}]
		}
		hideBarsOnSwipe = (nil == self.tabBarController) && defaults.hideBarsOnSwipe
		guard nil == managedObjectContextError else {
			$(managedObjectContextError)
			presentErrorMessage(NSLocalizedString("Something went wrong.", comment: ""))
			return false
		}
		if nil != self.tabBarController {
			void(self.fetchedRootFolderBinding)
			void(self.fetchedFavoritesFolderBinding)
			foldersViewController.hidesBottomBarWhenPushed = false
			favoritesViewController.navigationItem.backBarButtonItem = {
				let title = NSLocalizedString("Favorites", comment: "");
				return UIBarButtonItem(title: title, style: .Plain, target: nil, action: nil)
			}()
		}
		let notificationCenter = NSNotificationCenter.defaultCenter()
		let updateLoginAndPassword = {
			self.loginAndPassword = $(defaults.loginAndPassword)
			guard let loginAndPassword = self.loginAndPassword where loginAndPassword.isValid() else {
				self.rssSession = nil
				self.openSettings(nil)
				return
			}
			self.rssSession = RSSSession(loginAndPassword: loginAndPassword)
		}
		updateLoginAndPassword()
		retainedObjects += [notificationCenter.addObserverForName(NSUserDefaultsDidChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			if defaults.loginAndPassword != self.loginAndPassword {
				updateLoginAndPassword()
			}
		}]
		return true
	}
	// MARK: -
	override init() {
		super.init()
		let defaultsPlistURL = NSBundle.mainBundle().URLForResource("Settings", withExtension: "bundle")!.URLByAppendingPathComponent("Root.plist")
		try! loadDefaultsFromSettingsPlistAtURL(defaultsPlistURL)
		if defaults.memoryProfilingEnabled {
			FBAllocationTrackerManager.sharedManager()!.startTrackingAllocations()
			FBAllocationTrackerManager.sharedManager()!.enableGenerations()
		}
		RSSReader.foldersController = self
		let version = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! NSString
		$(version)
		let buildDate = try! NSFileManager().attributesOfItemAtPath(NSBundle.mainBundle().bundlePath)[NSFileModificationDate] as! NSDate
		let buildAge = NSDate().timeIntervalSinceDate(buildDate)
		$(buildAge)
#if ANALYTICS_ENABLED
		let versionIsClean = NSNotFound == version.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).location
		if (versionIsClean) && $(defaults.analyticsEnabled) {
#if CRASHLYTICS_ENABLED
			Fabric.with([Crashlytics()])
#endif
#if UXCAM_ENABLED
			UXCam.startWithKey("0fc8e6e128fa538")
#endif
#if FLURRY_ENABLED
			Flurry.startSession("TSPCHYJBMBGZZFM3SFDZ")
#endif
#if APPSEE_ENABLED
			Appsee.start(NSBundle.mainBundle().infoDictionary!["appseeAPIKey"] as! String)
#endif
		}
#endif
		configureAppearance()
		let fileManager = NSFileManager()
		let libraryDirectoryURL = fileManager.URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last!
		let libraryDirectory = libraryDirectoryURL.path!
        $(libraryDirectory)
	}
}