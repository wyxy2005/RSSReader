//
//  ItemsPageViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit

class ItemsPageViewController : UIPageViewController {
	var blocksDelayedTillViewWillAppear = [Handler]()
	dynamic var currentViewController: UIViewController?
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case viewControllers = "viewControllers"
		case currentViewControllerIndex = "currentViewControllerIndex"
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		let dataSource = self.dataSource as! ItemsPageViewControllerDataSource
		dataSource.decodeRestorableStateWithCoder(coder)
		if _1 {
			let viewControllers = coder.decodeObject(forKey: Restorable.viewControllers.rawValue) as! [UIViewController]
			let currentViewControllerIndex = coder.decodeObject(forKey: Restorable.currentViewControllerIndex.rawValue) as! Int
			self.currentViewController = viewControllers[currentViewControllerIndex]
			blocksDelayedTillViewWillAppear += [{
				self.setViewControllers(viewControllers, direction: .forward, animated: false) { completed in
					$(completed)
				}
			}]
		}
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		let dataSource = self.dataSource as! ItemsPageViewControllerDataSource
		dataSource.encodeRestorableStateWithCoder(coder)
		if _1 {
			coder.encode(viewControllers, forKey: Restorable.viewControllers.rawValue)
			let currentViewControllerIndex = viewControllers!.index(of: self.currentViewController!)
			coder.encode(currentViewControllerIndex, forKey: Restorable.currentViewControllerIndex.rawValue)
		}
	}
	// MARK: -
	override func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewControllerNavigationDirection, animated: Bool, completion: ((Bool) -> Void)?) {
		let currentViewController = viewControllers!.first
		super.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
		self.currentViewController = currentViewController
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(_ animated: Bool) {
		blocksDelayedTillViewWillAppear.forEach {$0()}
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
		
		viewDidDisappearRetainedObjects += [KVOBinding(self•#keyPath(currentViewController.navigationItem.rightBarButtonItems), options: .initial) { change in
			self.navigationItem.rightBarButtonItems = self.currentViewController!.navigationItem.rightBarButtonItems
		}]
		if hideBarsOnSwipe {
			viewDidDisappearRetainedObjects += [KVOBinding(self•#keyPath(currentViewController), options: .initial) { change in
				if let webView = self.currentViewController?.view.subviews.first as? UIWebView {
					let barHideOnSwipeGestureRecognizer = self.navigationController!.barHideOnSwipeGestureRecognizer
					let scrollView = webView.scrollView
					scrollView.addGestureRecognizer(barHideOnSwipeGestureRecognizer)
				}
			}]
		}
		viewDidDisappearRetainedObjects += [KVOBinding(self•#keyPath(currentViewController.toolbarItems), options: .initial) { change in
			self.toolbarItems = self.currentViewController?.toolbarItems
		}]
	}
	override var childViewControllerForStatusBarHidden: UIViewController? {
		return self.currentViewController
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let webView = self.currentViewController?.view.subviews.first as? UIWebView {
			webView.scrollView.flashScrollIndicators()
		}
	}
	override func viewDidDisappear(_ animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
}

