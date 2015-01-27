//
//  MarkingAsRead.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

let rootTagSuffix = "state/com.google/root"
let readTagSuffix = "state/com.google/read"
let canonicalReadTag = "user/-/state/com.google/read"

extension Folder {
	class func predicateForFetchingFolderWithTagSuffix(tagSuffix: String) -> NSPredicate {
		return NSPredicate(format: "id ENDSWITH %@", argumentArray: [tagSuffix])
	}
	class func fetchRequestForFolderWithTagSuffix(tagSuffix: String) -> NSFetchRequest {
		let $ = NSFetchRequest(entityName: Folder.entityName())
		$.predicate = self.predicateForFetchingFolderWithTagSuffix(tagSuffix)
		$.fetchLimit = 1
		return $
	}
	class func folderWithTagSuffix(tagSuffix: String, managedObjectContext: NSManagedObjectContext) -> Folder? {
		let fetchRequest = self.fetchRequestForFolderWithTagSuffix(tagSuffix)
		var executeFetchRequestError: NSError?
		let folder = managedObjectContext.executeFetchRequest(fetchRequest, error: &executeFetchRequestError)?.first as Folder?
		return folder
	}
}

extension Item {
	var categoryForReadTag: Folder? {
		let matchingCategories = filter(self.categories.allObjects as [Folder]) { folder in folder.id.hasSuffix(readTagSuffix) }
		return matchingCategories.first?
	}
	var markedAsRead: Bool {
		get {
			let markedAsRead = nil != self.categoryForReadTag
			return markedAsRead
		}
		set {
			if (newValue && self.markedAsRead) || (!newValue && !self.markedAsRead) {
			}
			else {
				let unreadCountDelta = newValue ? -1 : 1
				self.subscription.unreadCount += unreadCountDelta
				for category in self.categories.allObjects as [Folder] {
					category.unreadCount += unreadCountDelta
				}
				let mutableCategories = self.mutableCategories
				if newValue {
					let markedAsReadFolder = Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: self.managedObjectContext!)!
					mutableCategories.addObject(markedAsReadFolder)
				}
				else {
					mutableCategories.removeObject(self.categoryForReadTag!)
				}
			}
		}
	}
}
