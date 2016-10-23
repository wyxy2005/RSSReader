//
//  DefaultLogger.swift
//  GEBase
//
//  Created by Grigory Entin on 14/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation
import os

private var bundleLogAssoc: Void?

@available(iOS 10.0, *)
extension Bundle {
	public var log: OSLog {
		return associatedObjectRegeneratedAsNecessary(obj: self, key: &bundleLogAssoc) {
			OSLog(subsystem: self.bundleIdentifier!, category: "default")
		}
	}
}

let dateFormatter = DateFormatter() … {
	$0.dateFormat = "HH:mm.ss.SSS"
}

enum DefaultLogKind: String {
	case none, oslog, nslog, print
}

extension KVOCompliantUserDefaults {
	@NSManaged var defaultLogKind: String?
}

private let traceToNSLogEnabled = false

public func defaultLoggedText(date: Date, label: String?, location: SourceLocation, message: String) -> String {
	let locationDescription = "\(location.function), \(location.fileURL.lastPathComponent):\(location.line)"
	guard let label = label else {
		return "\(locationDescription) ◾︎ \(message)"
	}
	return "\(locationDescription) ◾︎ \(label): \(message)"
}

public func defaultLoggedTextWithTimestampAndThread(date: Date, label: String?, location: SourceLocation, message: String) -> String {
	let text = defaultLoggedText(date: date, label: label, location: location, message: message)
	let dateDescription = dateFormatter.string(from: date)
	let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
	let textWithTimestampAndThread = "\(dateDescription) [\(threadDescription)] \(text)"
	return textWithTimestampAndThread
}

public func defaultLoggedTextWithThread(date: Date, label: String?, location: SourceLocation, message: String) -> String {
	let text = defaultLoggedText(date: date, label: label, location: location, message: message)
	let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
	let textWithThread = "[\(threadDescription)] \(text)"
	return textWithThread
}

func defaultLogger(date: Date, label: String?, location: SourceLocation, message: String) {
	guard let defaultLogKind = defaults.defaultLogKind else { return }
	switch DefaultLogKind(rawValue: defaultLogKind)! {
	case .none: ()
	case .oslog:
		let text = defaultLoggedText(date: date, label: label, location: location, message: message)
		if #available(iOS 10.0, *) {
			let dso = location.dso
			let bundle = Bundle(for: dso)!
			rdar_os_log_object_with_type(dso, bundle.log, .default, text)
		} else {
			fallthrough
		}
	case .nslog:
		let text = defaultLoggedText(date: date, label: label, location: location, message: message)
		NSLog("%@", text)
	case .print:
		let textWithTimestampAndThread = defaultLoggedTextWithTimestampAndThread(date: date, label: label, location: location, message: message)
		print(textWithTimestampAndThread)
	}
}