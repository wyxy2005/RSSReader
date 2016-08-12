//
//  RSSSessionCommands.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import Result
import CoreData
import Foundation

public protocol AbstractPersistentDataUpdateCommand {}

/// Defines URL request, and the way to import request result into the given managed context and generate (successfull) value as necessary.
protocol PersistentDataUpdateCommand : AbstractPersistentDataUpdateCommand {
	associatedtype ResultType
	var request: URLRequest { get }
	func preprocessedRequestError(_ error: Error) -> RSSSessionError
	func validate(data: Data) throws
	func push(_ data: Data, through: ((NSManagedObjectContext) throws -> ResultType) -> Void)
	func taskForSession(_ session: RSSSession, completionHandler: RSSSessionTaskCompletionHandler) -> URLSessionTask
}
/// Default behaviour for `PersistentDataUpdateCommand`.
extension PersistentDataUpdateCommand {
	var baseURL: URL {
		let components = NSURLComponents() … {
			$0.scheme = "https"
			$0.host = "www.inoreader.com"
			$0.path = "/"
		}
		return components.url!
	}
	//
	func preprocessedRequestError(_ error: Error) -> RSSSessionError {
		return .requestFailed(underlyingError: error)
	}
	func validate(data: Data) throws {
	}
	func taskForSession(_ session: RSSSession, completionHandler: RSSSessionTaskCompletionHandler) -> URLSessionTask {
		return session.dataTask(with: self.request, completionHandler: completionHandler)
	}
}

// MARK: -

/// A command that defines its request by relative url string (and http method).
protocol RelativeStringBasedDataUpdateCommand  {
	var requestRelativeString: String { get }
	var httpMethod: String? { get }
}
/// Default behavior for `RelativeStringBasedDataUpdateCommand`.
extension PersistentDataUpdateCommand where Self: RelativeStringBasedDataUpdateCommand {
	var httpMethod: String? { return "GET" }
	var request: URLRequest {
		let url = URL(string: requestRelativeString, relativeTo: baseURL)!
		var $ = URLRequest(url: url)
		$.httpMethod = self.httpMethod
		return $
	}
}

// MARK: -

/// A command that processes the data simply by importing it in the given context.
protocol SimpleDispatchingDataUpdateCommand {
	associatedtype DispatchResultType
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws -> DispatchResultType
}
/// Default behaviour for `SimpleDispatchingDataUpdateCommand` with no value generated by import.
extension PersistentDataUpdateCommand where Self: SimpleDispatchingDataUpdateCommand, Self.ResultType == Self.DispatchResultType, Self.DispatchResultType == Void {
	func push(_ data: Data, through: ((NSManagedObjectContext) throws -> Void) -> Void) {
		through { managedObjectContext in
			try self.importResult(data, into: managedObjectContext)
		}
	}
}
/// Default behaviour for `SimpleDispatchingDataUpdateCommand` with some value generated by import.
extension PersistentDataUpdateCommand where Self: SimpleDispatchingDataUpdateCommand, Self.ResultType == Self.DispatchResultType {
	func push(_ data: Data, through: ((NSManagedObjectContext) throws -> Self.ResultType) -> Void) {
		through { managedObjectContext in
			return try self.importResult(data, into: managedObjectContext)
		}
	}
}

// MARK: -

/// A command that should run only with authentication.
protocol AuthenticatedDataUpdateCommand {}
/// Default behaviour for `AuthenticatedDataUpdateCommand`.
extension PersistentDataUpdateCommand where Self: AuthenticatedDataUpdateCommand {
	func taskForSession(_ session: RSSSession, completionHandler: RSSSessionTaskCompletionHandler) -> URLSessionTask {
		return session.authenticatedDataTask(with: self.request, completionHandler: completionHandler)
	}
}

// MARK: -

/// Most common variant of `PersistentDataUpdateCommand`.
protocol MostCommonDataUpdateCommand : RelativeStringBasedDataUpdateCommand, SimpleDispatchingDataUpdateCommand, AuthenticatedDataUpdateCommand {
}

// MARK: -

struct UpdateSubscriptions : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	let requestRelativeString = "/reader/api/0/subscription/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let subscriptions = try importedSubscriptionsFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(subscriptions)
	}
}

struct UpdateUserInfo : PersistentDataUpdateCommand, MostCommonDataUpdateCommand, AuthenticatedDataUpdateCommand {
	let requestRelativeString = "/reader/api/0/user-info"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let readFolder = try readFolderImportedFromUserInfoData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(readFolder)
	}
}

struct UpdateUnreadCounts : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	let requestRelativeString = "/reader/api/0/unread-count"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let containers = try containersImportedFromUnreadCountsData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(containers)
	}
}

struct PullTags : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	let requestRelativeString = "/reader/api/0/tag/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		try! data.write(to: lastTagsFileURL, options: .atomic)
		let tags = try tagsImportedFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(tags)
	}
}

struct UpdateStreamPreferences : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	let requestRelativeString = "/reader/api/0/preference/stream/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		try! data.write(to: lastTagsFileURL, options: .atomic)
		let streamPreferences: () = try streamPreferencesImportedFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(streamPreferences)
	}
}

struct MarkAllAsRead : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	let container: Container
	func validate(data: Data) throws {
		guard let body = String(data: data, encoding: String.Encoding.utf8) else {
			throw RSSSessionError.badResponseDataForMarkAsRead(data: data)
		}
		guard body == "OK" else {
			throw RSSSessionError.unexpectedResponseTextForMarkAsRead(body: body as String)
		}
	}
	var requestRelativeString: String {
		let containerIDPercentEncoded = self.container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics)!
		let newestItemTimestampUsec = self.container.newestItemDate.timestampUsec
		return "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
	}
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
	}
}

struct PushTags : PersistentDataUpdateCommand, MostCommonDataUpdateCommand {
	var httpMethod: String? { return "POST" }
	let items: Set<Item>, category: Folder, excluded: Bool
	//
	var requestRelativeString: String {
		let urlArguments: [String] = {
			assert(0 < items.count)
			let itemIDsComponents = items.map { "i=\($0.shortID)" }
			let command = excluded ? "r" : "a"
			let tag = category.tag()!
			let urlArguments = ["\(command)=\(tag)"] + itemIDsComponents
			return urlArguments
		}()
		let urlArgumentsJoined = urlArguments.joined(separator: "&")
		return "/reader/api/0/edit-tag?\(urlArgumentsJoined)"
	}
	func importResult(_ data: Data, into context: NSManagedObjectContext) throws {
		if (excluded) {
			category.itemsToBeExcluded.subtract(items)
		}
		else {
			category.itemsToBeIncluded.subtract(items)
		}
		assert(try! !Folder.allWithItems(toBeExcluded: excluded, in: context).contains(category))
	}
}

public struct StreamContents : PersistentDataUpdateCommand, AuthenticatedDataUpdateCommand, RelativeStringBasedDataUpdateCommand  {
	public typealias ResultType = (NSManagedObjectContext, (continuation: String?, items: [Item]))
	let excludedCategory: Folder?, container: Container, continuation: String?, count: Int, loadDate: Date
	var requestRelativeString: String {
		let querySuffix = URLQuerySuffixFromComponents([String]() … {
			if let continuation = continuation {
				$0 += ["c=\($(continuation))"]
			}
			if let excludedCategory = excludedCategory {
				$0 += ["xt=\($(excludedCategory.streamID))"]
			}
			$0 += ["n=\(count)"]
		})
		let streamIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics)!
		return "/reader/api/0/stream/contents/\(streamIDPercentEncoded)\(querySuffix)"
	}
	func push(_ data: Data, through: ((NSManagedObjectContext) throws -> ResultType) -> Void) {
		try! data.write(to: lastTagsFileURL, options: .atomic)
		let excludedCategoryObjectID = typedObjectID(for: excludedCategory)
		let containerObjectID = typedObjectID(for: container)
		through { managedObjectContext in
			let container = containerObjectID.object(in: managedObjectContext)
			let excludedCategory = excludedCategoryObjectID?.object(in: managedObjectContext)
			return (managedObjectContext, try continuationAndItemsImportedFromStreamData(data, loadDate: self.loadDate, container: container, excludedCategory: excludedCategory, managedObjectContext: managedObjectContext))
		}
	}
}

struct Authenticate : PersistentDataUpdateCommand, SimpleDispatchingDataUpdateCommand {
	typealias ResultType = String
	let loginAndPassword: LoginAndPassword
	func preprocessed(_ error: Error) -> Error {
		switch error {
		case GEBase.URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(let httpResponse):
			guard httpResponse.statusCode == 401 else {
				return error
			}
			return RSSSessionError.authenticationFailed(underlyingError: error)
		default:
			return error
		}
	}
	var request: URLRequest {
		let url = URL(string: "/accounts/ClientLogin", relativeTo: baseURL)!
		let request = URLRequest(url: url) … {
			$0.httpMethod = "POST"
			$0.httpBody = {
				let allowedCharacters = NSCharacterSet.alphanumerics
				let loginEncoded = self.loginAndPassword.login?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let passwordEncoded = self.loginAndPassword.password?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let body: String = {
					if passwordEncoded == nil && loginEncoded == nil {
						return ""
					}
					return "Email=\(loginEncoded!)&Passwd=\(passwordEncoded!)"
				}()
				return body.data(using: String.Encoding.utf8, allowLossyConversion: false)
			}()
		}
		return request
	}
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws -> String {
		return try authTokenImportedFromJsonData(data)
	}
}
