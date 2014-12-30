//
//  GenericExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func trace<T>(label: String, value: T) -> T {
	println("\(label): \(value)")
	return value
}

func void<T>(value: T) {
}
