//
//  FoldersController.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import PromiseKit
import Foundation

@objc public enum FoldersUpdateState: Int {
	case unknown
	case completed
	case updatingUserInfo
	case pushingTags
	case pullingTags
	case updatingSubscriptions
	case updatingUnreadCounts
	case updatingStreamPreferences
	case prefetching
}

public protocol FoldersController : class {
	var foldersLastUpdateDate: Date? { get set }
	var foldersLastUpdateError: Error? { get set }
	var foldersUpdateState: FoldersUpdateState { get set }
	var rssSession: RSSSession { get }
}

extension KVOCompliantUserDefaults {
	@NSManaged var streamPrefetchingEnabled: Bool
}

public extension FoldersController {
	public final func updateFolders() -> Promise<Void> {
		let rssSession = self.rssSession
		precondition(rssSession.authenticated)
		return firstly {
			self.foldersLastUpdateError = nil
			self.foldersUpdateState = .updatingUserInfo
			return rssSession.updateUserInfo()
		}.then {
			self.foldersUpdateState = .pushingTags
			return rssSession.pushTags()
		}.then {
			self.foldersUpdateState = .pullingTags
			return rssSession.pullTags()
		}.then {
			self.foldersUpdateState = .updatingSubscriptions
			return rssSession.updateSubscriptions()
		}.then {
			self.foldersUpdateState = .updatingUnreadCounts
			return rssSession.updateUnreadCounts()
		}.then {
			self.foldersUpdateState = .updatingStreamPreferences
			return rssSession.updateStreamPreferences()
		}.then {
			guard defaults.streamPrefetchingEnabled else {
				return Promise(value: ())
			}
			self.foldersUpdateState = .prefetching
			return Promise { fulfill, reject in
				performBackgroundMOCTask { managedObjectContext in
					let container = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: managedObjectContext)!
					let containerLoadController = ContainerLoadController(session: rssSession, container: container, unreadOnly: true)
					containerLoadController.loadMore { error in
						guard let error = error else {
							fulfill()
							return
						}
						reject(error)
					}
				}
			}
		}.always {
			self.foldersLastUpdateDate = Date()
			self.foldersUpdateState = .completed
		}.recover { error -> Void in
			self.foldersLastUpdateError = error
			throw $(error)
		}
	}
}
