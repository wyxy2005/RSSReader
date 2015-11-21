//
//  KVOCompliantUserDefaults+RSSReaderData.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 21/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation

extension KVOCompliantUserDefaults {

	@NSManaged var itemsAreSortedByLoadDate: Bool
	@NSManaged var authToken: String?
	@NSManaged var batchSavingDisabled: Bool

}
