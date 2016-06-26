//
//  FoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

enum FoldersUpdateState: Int {
	case unknown
	case completed
	case authenticating
	case updatingUserInfo
	case pushingTags
	case pullingTags
	case updatingSubscriptions
	case updatingUnreadCounts
	case updatingStreamPreferences
}

extension FoldersUpdateState: CustomStringConvertible {
	var description: String {
		switch self {
		case .unknown:
			return NSLocalizedString("Unknown", comment: "Folders Update State")
		case .authenticating:
			return NSLocalizedString("Authenticating", comment: "Folders Update State")
		case .updatingUserInfo:
			return NSLocalizedString("Updating User Info", comment: "Folders Update State")
		case .pushingTags:
			return NSLocalizedString("Pushing Tags", comment: "Folders Update State")
		case .pullingTags:
			return NSLocalizedString("Pulling Tags", comment: "Folders Update State")
		case .updatingSubscriptions:
			return NSLocalizedString("Updating Subscriptions", comment: "Folders Update State")
		case .updatingUnreadCounts:
			return NSLocalizedString("Updating Unread Counts", comment: "Folders Update State")
		case .updatingStreamPreferences:
			return NSLocalizedString("Updating Folder List", comment: "Folders Update State")
		case .completed:
			return NSLocalizedString("Completed", comment: "Folders Update State")
		}
	}
}

enum FoldersControllerError: ErrorProtocol {
	case userInfoRetrieval(underlyingError: ErrorProtocol)
	case pushTags(underlyingError: ErrorProtocol)
	case pullTags(underlyingError: ErrorProtocol)
	case subscriptionsUpdate(underlyingError: ErrorProtocol)
	case dataDoesNotMatchTextEncoding
	case unreadCountsUpdate(underlyingError: ErrorProtocol)
	case streamPreferencesUpdate(underlyingError: ErrorProtocol)
}

@objc protocol FoldersController {
#if false
	func updateFoldersAuthenticated(completionHandler: (ErrorType?) -> Void)
	func updateFolders(completionHandler: (ErrorType?) -> Void)
#endif
	var rssSession: RSSSession? { get }
	var foldersLastUpdateDate: Date? { get set }
	var foldersLastUpdateErrorRaw: NSError? { get set }
	var foldersUpdateStateRaw: Int { get set }
}

extension FoldersController {
	final var foldersUpdateState: FoldersUpdateState {
		set {
			foldersUpdateStateRaw = newValue.rawValue
		}
		get {
			return FoldersUpdateState(rawValue: foldersUpdateStateRaw)!
		}
	}
	final var foldersLastUpdateError: ErrorProtocol? {
		set {
			foldersLastUpdateErrorRaw = NSError(domain: "", code: 1, userInfo: ["swiftError": "\(newValue)"])
		}
		get {
			return nil
		}
	}
	typealias Error = FoldersControllerError
	final func updateFoldersAuthenticated(_ completionHandler: (ErrorProtocol?) -> Void) {
		let rssSession = self.rssSession!
		foldersUpdateState = .updatingUserInfo
		let errorCompletionHandler = { (error: ErrorProtocol) -> Void in
			self.foldersLastUpdateError = error
			self.foldersLastUpdateDate = Date()
			self.foldersUpdateState = .completed
			completionHandler(error)
		}
		let successCompletionHandler: () -> Void = {
			self.foldersLastUpdateDate = Date()
			self.foldersUpdateState = .completed
			completionHandler(nil)
		}
		self.foldersLastUpdateError = nil
		rssSession.updateUserInfo { updateUserInfoError in DispatchQueue.main.async {
			if let updateUserInfoError = updateUserInfoError {
				errorCompletionHandler(Error.userInfoRetrieval(underlyingError: $(updateUserInfoError)))
				return
			}
			self.foldersUpdateState = .pushingTags
			rssSession.pushTags { pushTagsError in DispatchQueue.main.async {
				if let pushTagsError = pushTagsError {
					errorCompletionHandler(Error.pushTags(underlyingError: $(pushTagsError)))
					return
				}
				self.foldersUpdateState = .pullingTags
				rssSession.pullTags { pullTagsError in DispatchQueue.main.async {
					if let pullTagsError = pullTagsError {
						errorCompletionHandler(Error.pullTags(underlyingError: $(pullTagsError)))
						return
					}
					self.foldersUpdateState = .updatingSubscriptions
					rssSession.updateSubscriptions { updateSubscriptionsError in DispatchQueue.main.async {
						if let updateSubscriptionsError = updateSubscriptionsError {
							errorCompletionHandler(Error.subscriptionsUpdate(underlyingError: $(updateSubscriptionsError)))
							return
						}
						self.foldersUpdateState = .updatingUnreadCounts
						rssSession.updateUnreadCounts { updateUnreadCountsError in DispatchQueue.main.async {
							if let updateUnreadCountsError = updateUnreadCountsError {
							errorCompletionHandler(Error.pullTags(underlyingError: $(updateUnreadCountsError)))
								return
							}
							self.foldersUpdateState = .updatingStreamPreferences
							rssSession.updateStreamPreferences { updateStreamPreferencesError in DispatchQueue.main.async {
								if let updateStreamPreferencesError = updateStreamPreferencesError {
									errorCompletionHandler(Error.streamPreferencesUpdate(underlyingError: $(updateStreamPreferencesError)))
									return
								}
								successCompletionHandler()
							}}
						}}
					}}
				}}
			}}
		}}
	}
	final func updateFolders(_ completionHandler: (ErrorProtocol?) -> Void) {
		let rssSession = self.rssSession!
		let postAuthenticate = { () -> Void in
			self.updateFoldersAuthenticated(completionHandler)
		}
		if (rssSession.authToken == nil) {
			self.foldersUpdateState = .authenticating
			rssSession.authenticate { error in DispatchQueue.main.async {
				if let authenticationError = error {
					completionHandler(authenticationError)
					self.foldersUpdateState = .completed
				}
				else {
					postAuthenticate()
				}
			}}
		}
		else {
			postAuthenticate()
		}
	}
}
