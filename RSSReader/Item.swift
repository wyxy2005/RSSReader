//
//  Item.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

class Item: NSManagedObject {
    @NSManaged var id: String
	@NSManaged var date: NSDate
	@NSManaged var loadDate: NSDate
	@NSManaged var lastOpenedDate: NSDate
    @NSManaged var title: String?
    @NSManaged var summary: NSString?
	@NSManaged var categories: NSSet
	var mutableCategories: NSMutableSet {
		return mutableSetValueForKey("categories")
	}
	@NSManaged var subscription: Subscription
	@NSManaged var canonical: [[String: String]]?
}
