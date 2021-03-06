//
//  CoreData.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GECoreData
import CoreData
import Foundation

extension Date {
	init(timestampUsec: String) {
		let timeIntervalSince1970 = (timestampUsec as NSString).doubleValue * 1e-6
		self.init(timeIntervalSince1970: timeIntervalSince1970)
	}
	var timestampUsec: String {
		get {
			return "\(timeIntervalSince1970 * 1e6)"
		}
	}
	var timestampMsec: String {
		get {
			return "\(timeIntervalSince1970 * 1e3)"
		}
	}
	var timestamp: String {
		get {
			return "\(timeIntervalSince1970)"
		}
	}
}
extension Item : ManagedIdentifiable {
	public enum ItemError: Error {
		case CategoriesMissingOrInvalidInJson(json: [String: AnyObject])
	}
	public class func identifierKey() -> String {
		return #keyPath(id)
	}
	public class func entityName() -> String {
		return "Item"
	}
	var categories: Set<Folder> {
		set {
			let oldValue = categories
			let categoryItemsForDeletion = categoryItems.filter { !newValue.contains($0.category) }
			let insertedCategories = newValue … {
				$0.subtract(oldValue)
				()
			}
			for categoryItem in categoryItemsForDeletion {
				managedObjectContext!.delete(categoryItem)
			}
			for category in insertedCategories {
				let categoryItem = (NSEntityDescription.insertNewObject(forEntityName: CategoryItem.entityName(), into: managedObjectContext!) as! CategoryItem)
				categoryItem … {
					$0.item = self
					$0.category = category
				}
			}
		}
		get {
			return Set(categoryItems.map { $0.category })
		}
	}
	func importFromJson(_ jsonObject: Any, subscription: Subscription? = nil, categoriesByID: [String : Folder]) throws {
		let json = jsonObject as! Json
		// Track changes in the categories (not reflected in the update date).
		do {
			let categoryIDs: [String] = json["categories"] as! [String]
			let shouldUpdateCategories: Bool = {
				guard let json = self.json else {
					return true
				}
				let oldCategoryIDs = json["categories"] as! [String]
				return oldCategoryIDs != categoryIDs
			}()
			if shouldUpdateCategories {
				let categories = Set(categoryIDs.map { return categoriesByID[$0]! })
				self.categories = categories
			}
		}
		let managedObjectContext = self.managedObjectContext!
		let updatedDate: Date? = {
			if let updatedTimeIntervalSince1970 = json["updated"] as! TimeInterval? {
				return Date(timeIntervalSince1970: updatedTimeIntervalSince1970)
			}
			return nil
		}()
		guard (nil == updatedDate) || (updatedDate != self.updatedDate) else {
			•(self)
			return
		}
		let date = Date(timestampUsec: json["timestampUsec"] as! String)
		self.updatedDate = updatedDate
		self.date = date
		self.title = json["title"] as! String
		self.author = json["author"] as! String
		let summary = (json["summary"] as! [String: AnyObject])["content"] as! String?
		self.summary = summary
		let streamID = (json["origin"] as? NSDictionary)?["streamId"] as! String
		assert(nil == subscription || streamID == subscription?.streamID)
		let subscription = try subscription ?? insertedObjectUnlessFetchedWithID(Subscription.self, id: streamID, managedObjectContext: managedObjectContext)
		self.subscription = subscription
		self.canonical = json["canonical"] as! [[String : String]]?
		self.json = json
	}
}

extension Subscription {
	override public class func entityName() -> String {
		return "Subscription"
	}
	class func sortDescriptorsVariants() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: #keyPath(sortID), ascending: true)]]
	}
	override func importFromJson(_ jsonObject: Any) throws {
		try super.importFromJson(jsonObject)
		let json = jsonObject as! [String: AnyObject]
		self.title = json["title"] as! String
		self.url = NSURL(string: json["url"] as! String)
		self.iconURL = NSURL(string: json["iconUrl"] as! String)
		self.htmlURL = NSURL(string: json["htmlUrl"] as! String)
		if let categories = json["categories"] as? [[String: AnyObject]] {
			for category in categories {
				let id = category["id"] as! String
				let folder = try insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: self.managedObjectContext!)
				self.categories.insert(folder)
			}
		}
	}
}
enum JsonImportError: Error {
	case JsonObjectIsNotDictionary(jsonObject: Any)
	case MissingSortID(json: [String: AnyObject])
	case SortIDIsNotHex(json: [String: AnyObject])
	case SubscriptionOrderingMissingValue(json: [String: AnyObject])
	case MissingPrefsID(json: [String: AnyObject])
	case PrefsMissingValue(prefs: [String: AnyObject])
	case PrefsValueLengthIsNotFactorOf8(prefs: [String: AnyObject])
	case SortIDInPrefsValueIsNotHex(prefs: [String: AnyObject], value: String)
}

extension Folder {
	override public static func entityName() -> String {
		return "Folder"
	}
	class func sortDescriptors() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: #keyPath(newestItemDate), ascending: false)]]
	}
}
