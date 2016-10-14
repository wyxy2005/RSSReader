//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import RSSReaderAppConfig
import RSSReaderData
import Loggy
import GEBase
import UIKit
import CoreData

extension KVOCompliantUserDefaults {
	@NSManaged var hideBarsOnSwipe: Bool
}

class AppDelegateInternals {
	var rssSession: RSSSession?
	private let urlTaskGeneratorProgressKVOBinding: KVOBinding
	init() {
		let taskGenerator = progressEnabledURLSessionTaskGenerator
		urlTaskGeneratorProgressKVOBinding = KVOBinding(taskGenerator•#keyPath(ProgressEnabledURLSessionTaskGenerator.progresses), options: []) { change in
			let networkActivityIndicatorShouldBeVisible = 0 < taskGenerator.progresses.count
			UIApplication.shared.isNetworkActivityIndicatorVisible = (networkActivityIndicatorShouldBeVisible)
		}
	}
}

class AppDelegate: AppDelegateBase, FoldersController {
	typealias _Self = AppDelegate
	final var retainedObjects = [Any]()
#if false
	var foldersLastUpdateDate: NSDate?
#else
	final var foldersLastUpdateDate: Date? {
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
				return NSKeyedUnarchiver.unarchiveObject(with: data) as! NSError?
			}
			else {
				return nil
			}
		}
		set {
			defaults.foldersLastUpdateErrorEncoded = {
				if let error = newValue {
					return NSKeyedArchiver.archivedData(withRootObject: error)
				}
				else {
					return nil
				}
			}()
		}
	}
	let internals = AppDelegateInternals()
	dynamic var foldersUpdateStateRaw = FoldersUpdateState.completed.rawValue
	var foldersUpdateState = FoldersUpdateState.completed {
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
		let self_ = UIApplication.shared.delegate! as! AppDelegate
		let $ = (self_.tabBarController.viewControllers![1] as! UINavigationController).viewControllers.first as! ItemsListViewController
		configureFavoritesItemsListViewController($)
		return $
	}()
	var loginAndPassword: LoginAndPassword!
	// MARK: -
	lazy var fetchedRootFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(rootTagSuffix)) { folders in
		let foldersViewController = self.foldersViewController
		foldersViewController.rootFolder = folders.last!
	}
	lazy var fetchedFavoritesFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(favoriteTagSuffix)) { folders in
		let foldersViewController = self.favoritesViewController
		foldersViewController.container = folders.last!
	}
	//
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
		$(self)
		return true
	}
	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		defer { launchingScope.leave() }
		var scope = Activity("Finishing Launching").enter(); defer { scope.leave() }
		filesWithTracingDisabled += [
			"TableViewFetchedResultsControllerDelegate.swift",
			"KVOCompliantUserDefaults.swift"
		]
		hideBarsOnSwipe = (nil == self.tabBarController) && defaults.hideBarsOnSwipe
		guard nil == managedObjectContextError else {
			$(managedObjectContextError)
			presentErrorMessage(NSLocalizedString("Something went wrong.", comment: ""))
			return false
		}
		if nil != self.tabBarController {
			•(self.fetchedRootFolderBinding)
			•(self.fetchedFavoritesFolderBinding)
			foldersViewController.hidesBottomBarWhenPushed = false
			favoritesViewController.navigationItem.backBarButtonItem = {
				let title = NSLocalizedString("Favorites", comment: "");
				return UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
			}()
		}
		let notificationCenter = NotificationCenter.default
		let updateLoginAndPassword = {
			self.loginAndPassword = $(defaults.loginAndPassword)
			guard let loginAndPassword = self.loginAndPassword, loginAndPassword.isValid() else {
				rssSession = nil
				self.openSettings(nil)
				return
			}
			rssSession = RSSSession(loginAndPassword: loginAndPassword)
		}
		updateLoginAndPassword()
		retainedObjects += [notificationCenter.addObserver(forName: UserDefaults.didChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			if defaults.loginAndPassword != self.loginAndPassword {
				updateLoginAndPassword()
			}
		}]
		return true
	}
	// MARK: -
	override init() {
		super.init()
		configureAppearance()
	}
}

extension KVOCompliantUserDefaults {
	@NSManaged var stateRestorationEnabled: Bool
}

// MARK: - State Restoration

private var appStateRestorationScope: Activity.Scope!

extension AppDelegate {
	private static let currentRestorationFormatVersion = Int32(1)
	private enum Restorable: String {
		case restorationFormatVersion
	}
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		$(self)
		coder.encode(_Self.currentRestorationFormatVersion, forKey: Restorable.restorationFormatVersion.rawValue)
		return true
	}
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		appStateRestorationScope = Activity("State Restoration").enter()
		$(self)
		let restorationFormatVersion = coder.decodeInt32(forKey: Restorable.restorationFormatVersion.rawValue)
		if $(restorationFormatVersion) < _Self.currentRestorationFormatVersion {
			return false
		}
		return $(defaults.stateRestorationEnabled)
	}
	func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
		appStateRestorationScope.leave()
	}
}
