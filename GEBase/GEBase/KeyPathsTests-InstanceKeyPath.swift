//
//  KeyPathsTests-InstanceKeyPath.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import XCTest
import Foundation

extension KeyPathsTests {
	func testRecordedInstanceKeyPath() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.string}, "string")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalString}, "optionalString")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.array}, "array")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalArray}, "optionalArray")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.setOfStrings}, "setOfStrings")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.set}, "set")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalSet}, "optionalSet")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.dictionary}, "dictionary")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalDictionary}, "optionalDictionary")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.computedArray}, "computedArray")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalObject.string}, "optionalObject.string")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalComputedObject.string}, "optionalComputedObject.string")
		XCTAssertEqual(recordedInstanceKeyPath(self){$0.optionalComputedObject.optionalAnotherObject.computedLength}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(recordedInstanceKeyPath(self.optionalObject){$0.string}, "string")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
	func testInstanceKeyPath() {
		XCTAssertEqual(instanceKeyPath(self){"string"}, "string")
		XCTAssertEqual(instanceKeyPath(self){"optionalString"}, "optionalString")
		XCTAssertEqual(instanceKeyPath(self){"array"}, "array")
		XCTAssertEqual(instanceKeyPath(self){"optionalArray"}, "optionalArray")
		XCTAssertEqual(instanceKeyPath(self){"setOfStrings"}, "setOfStrings")
		XCTAssertEqual(instanceKeyPath(self){"set"}, "set")
		XCTAssertEqual(instanceKeyPath(self){"optionalSet"}, "optionalSet")
		XCTAssertEqual(instanceKeyPath(self){"dictionary"}, "dictionary")
		XCTAssertEqual(instanceKeyPath(self){"optionalDictionary"}, "optionalDictionary")
		XCTAssertEqual(instanceKeyPath(self){"computedArray"}, "computedArray")
		XCTAssertEqual(instanceKeyPath(self){"optionalObject.string"}, "optionalObject.string")
		XCTAssertEqual(instanceKeyPath(self){"optionalComputedObject.string"}, "optionalComputedObject.string")
		XCTAssertEqual(instanceKeyPath(self){"optionalComputedObject.optionalAnotherObject.computedLength"}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(instanceKeyPath(self.optionalObject){"string"}, "string")
	}
}
