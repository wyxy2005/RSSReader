//
//  ModuleExports-GEFoundation.swift
//  GEFoundation
//
//  Created by Grigory Entin on 09.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation

infix operator …

#if false
internal func …<T>(value: T, initialize: (inout T) throws -> Void) rethrows -> T {
	return try with(value, initialize)
}
#endif

@discardableResult
internal func …<T: AnyObject>(obj: T, initialize: (T) throws -> Void) rethrows -> T {
	return try with(obj, initialize)
}

@discardableResult
internal func …<T: AnyObject>(obj: T?, initialize: (T?) throws -> Void) rethrows -> T? {
	guard let obj = obj else {
		return nil
	}
	return try with(obj, initialize)
}

// MARK: -

import struct Foundation.URLRequest

extension URLRequest {
	static func …(x: URLRequest, _ modify: (inout URLRequest) throws -> Void) rethrows -> URLRequest {
		return try with(x, modify)
	}
}
extension Array {
	static func …(x: Array, _ modify: (inout Array) throws -> Void) rethrows -> Array {
		return try with(x, modify)
	}
}
extension Set {
	static func …(x: Set, _ modify: (inout Set) throws -> Void) rethrows -> Set {
		return try with(x, modify)
	}
}
extension ScheduledHandlers {
	static func …(x: ScheduledHandlers, _ modify: (inout ScheduledHandlers	) throws -> Void) rethrows -> ScheduledHandlers {
		return try with(x, modify)
	}
}

// MARK: -

typealias KVOCompliantUserDefaults = GEFoundation.KVOCompliantUserDefaults
typealias ProgressEnabledURLSessionTaskGenerator = GEFoundation.ProgressEnabledURLSessionTaskGenerator
typealias URLSessionTaskGeneratorError = GEFoundation.URLSessionTaskGeneratorError

typealias Ignored = GEFoundation.Ignored
typealias Handler = GEFoundation.Handler
typealias ScheduledHandlers = GEFoundation.ScheduledHandlers
typealias KVOBinding = GEFoundation.KVOBinding
typealias Json = GEFoundation.Json

var defaults: KVOCompliantUserDefaults {
	return GEFoundation.defaults
}

var _1: Bool { return GEFoundation._1 }
var _0: Bool { return GEFoundation._0 }

var progressEnabledURLSessionTaskGenerator: ProgressEnabledURLSessionTaskGenerator {
	return GEFoundation.progressEnabledURLSessionTaskGenerator
}

infix operator •

internal func •(object: NSObject, keyPath: String) -> ObjectAndKeyPath {
	return GEFoundation.objectAndKeyPath(object, keyPath)
}

internal func nilForNull(_ object: Any) -> Any? {
	return GEFoundation.nilForNull(object)
}

internal func filterObjectsByType<T>(_ objects: [Any]) -> [T] {
	return GEFoundation.filterObjectsByType(objects)
}

internal func invoke(handler: Handler) {
	return GEFoundation.invoke(handler: handler)
}

internal func += (handlers: inout ScheduledHandlers, _ extraHandlers: [Handler]) {
	handlers.append(contentsOf: extraHandlers)
}
