//
//  GenericCoreDataExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

enum GenericCoreDataExtensionsError: ErrorType {
	case JsonObjectIsNotDictionary(jsonObject: AnyObject)
	case ElementNotFoundOrInvalidInJson(json: [String: AnyObject], elementName: String)
}

protocol Managed {
	static func entityName() -> String
}

protocol DefaultSortable {
	static func defaultSortDescriptor() -> NSSortDescriptor
}

protocol Identifiable {
	static func identifierKey() -> String
}

protocol ManagedIdentifiable: Managed, Identifiable {
}

func insertedObjectUnlessFetchedWithPredicate<T: ManagedIdentifiable>(cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext, newObjectInitializationHandler: (T) -> Void) throws -> T {
	let entityName = cls.entityName()
	let existingObject: T? = try {
		let request: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: entityName)
			$.predicate = predicate
			$.fetchLimit = 1
			return $
		}()
		let objects = try managedObjectContext.executeFetchRequest(request)
		let existingObject = objects.last as! T?
		return existingObject
	}()
	let object: T = nil != existingObject ? existingObject! : {
		let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}()
	return object
}
func insertedObjectUnlessFetchedWithID<T: ManagedIdentifiable where T: NSManagedObject>(cls: T.Type, id: String, managedObjectContext: NSManagedObjectContext) throws -> T {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return try insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) { newObject in
		(newObject as NSManagedObject).setValue(id, forKey:identifierKey)
	}
}
func importItemsFromJson<T: ManagedIdentifiable where T : NSManagedObject>(json: [String : AnyObject], type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
	var items = [T]()
	guard let itemJsons = json[elementName] as? [[String : AnyObject]] else {
		throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: elementName)
	}
	for itemJson in itemJsons {
		guard let itemID = itemJson["id"] as? String else {
			throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: "id")
		}
		let item = try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext)
		try importFromJson(item, itemJson)
		items += [item]
	}
	return items
}
func importItemsFromJsonData<T: ManagedIdentifiable where T : NSManagedObject>(data: NSData, type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
	let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
	guard let json = jsonObject as? [String : AnyObject] else {
		throw GenericCoreDataExtensionsError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	return try importItemsFromJson(json, type: type, elementName: elementName, managedObjectContext: managedObjectContext, importFromJson: importFromJson)
}

extension NSManagedObject {
	func encodeObjectIDWithCoder(coder: NSCoder, key: String) {
		coder.encodeObject(objectID.URIRepresentation(), forKey: key)
	}
}
extension NSManagedObjectContext {
	class func objectWithIDDecodedWithCoder(coder: NSCoder, key: String, managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		if let objectIDURL = coder.decodeObjectForKey(key) as! NSURL? {
            if let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL) {
                return managedObjectContext.objectWithID(objectID)
            }
			else {
				$(objectIDURL).$()
			}
        }
        else {
			$(key).$()
		}
		return nil
	}
}