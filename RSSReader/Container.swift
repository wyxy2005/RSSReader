//
//  Container.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

class Container: NSManagedObject {
    @NSManaged var streamID: String
    @NSManaged var unreadCount: Int32
    @NSManaged var newestItemDate: NSDate
    @NSManaged var sortID: Int32
	@NSManaged var parentFolder: Folder?
	@NSManaged var viewStates: Set<ContainerViewState>
}

@objc protocol Titled {
	var visibleTitle: String? { get }
}

@objc protocol ItemsOwner {
	var ownItems: Set<Item> { get }
}

extension Container: DefaultSortable {
	class func defaultSortDescriptor() -> NSSortDescriptor {
		return NSSortDescriptor(key: self••{$0.streamID}, ascending: true)
	}
}

extension Container: ManagedIdentifiable {
	class func identifierKey() -> String {
		return "streamID"
	}
	class func entityName() -> String {
		return "Container"
	}
	func importFromJson(jsonObject: AnyObject) throws {
		self.sortID = try {
			guard let json = jsonObject as? [String: AnyObject] else {
				throw JsonImportError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
			}
			guard let sortIDString = $(json).$()["sortid"] as? String else {
				throw JsonImportError.MissingSortID(json: json)
			}
			var sortIDUnsigned : UInt32 = 0
			guard NSScanner(string: sortIDString).scanHexInt(&sortIDUnsigned) else {
				throw JsonImportError.SortIDIsNotHex(json: json)
			}
			let sortID = Int32(bitPattern: sortIDUnsigned)
			return $(sortID).$()
		}()
	}
	func importFromUnreadCountJson(jsonObject: AnyObject) {
		let json = jsonObject as! [String: AnyObject]
		self.streamID = {
			let streamID = json["id"] as! String
			return $(streamID).$()
		}()
		self.unreadCount = (json["count"] as! NSNumber).intValue
		self.newestItemDate = NSDate(timestampUsec: json["newestItemTimestampUsec"] as! String)
	}
	class func importStreamPreferencesJson(jsonObject: AnyObject, managedObjectContext: NSManagedObjectContext) throws {
		guard let json = jsonObject as? [String : [[String : AnyObject]]] else {
			throw JsonImportError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
		}
		for (folderID, prefs) in json {
			$(folderID).$()
			$(prefs).$()
			for prefs in prefs {
				guard let id = prefs["id"] as? String else {
					throw JsonImportError.MissingPrefsID(json: prefs)
				}
				if id != "subscription-ordering" {
					continue
				}
				guard let value = prefs["value"] as? String else {
					throw JsonImportError.PrefsMissingValue(prefs: prefs)
				}
				$(value).$()
				let folder = try insertedObjectUnlessFetchedWithID(Folder.self, id: folderID, managedObjectContext: managedObjectContext)
				assert(folder.streamID == folderID)
				let characterCountInValue = value.characters.count
				guard characterCountInValue % 8 == 0 else {
					throw JsonImportError.PrefsValueLengthIsNotFactorOf8(prefs: prefs)
				}
				var sortIDs = [Int32]()
				for var startIndex = value.startIndex; startIndex != value.endIndex; startIndex = advance(startIndex, 8) {
					let range = startIndex..<advance(startIndex, 8)
					let sortIDString = value[range]
					var sortIDUnsigned : UInt32 = 0
					guard NSScanner(string: sortIDString).scanHexInt(&sortIDUnsigned) else {
						throw JsonImportError.SortIDInPrefsValueIsNotHex(prefs: prefs, range: range)
					}
					let sortID = Int32(bitPattern: sortIDUnsigned)
					sortIDs += [sortID]
				}
				let request: NSFetchRequest = {
					let E = Container.self
					let $ = NSFetchRequest(entityName: E.entityName())
					$.predicate = NSPredicate(format: "\(E••{$0.sortID}) IN %@", argumentArray: [sortIDs.map { NSNumber(int: $0) }])
					return $
				}()
				let unorderedChildContainers = try managedObjectContext.executeFetchRequest(request) as! [Container]
				$(unorderedChildContainers).$()
				let childContainers = sortIDs.map { sortID in
					return unorderedChildContainers.filter { $0.sortID == sortID }.first!
				}
				folder.childContainers = NSOrderedSet(array: childContainers)
			}
		}
	}
}
