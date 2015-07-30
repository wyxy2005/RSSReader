//
//  Descriptions.swift
//  RSSReader
//
//  Created by Grigory Entin on 29/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func description(value: NSIndexPath) -> String {
	var components = [String]()
	for var i = 0; i < value.length; ++i {
		components += ["\(value.indexAtPosition(i))"]
	}
	return ", ".join(components)
}

func trace(value: NSIndexPath, startLocation: SourceLocation, endLocation: SourceLocation) -> NSIndexPath {
	traceString(description(value), location: startLocation, lastLocation: endLocation)
	return value
}