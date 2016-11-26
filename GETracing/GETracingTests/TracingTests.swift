//
//  TracingTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import GETracing
import XCTest

class TraceAndLabelTestsBase: XCTestCase {
	let foo = "bar"
	let bar = "baz"
	var blocksForTearDown = [() -> Void]()
	// MARK:-
	override func setUp() {
		super.setUp()
		let sourceLabelsEnabledEnforcedOldValue = sourceLabelsEnabledEnforced
		blocksForTearDown += [{
			sourceLabelsEnabledEnforced = sourceLabelsEnabledEnforcedOldValue
		}]
		let traceEnabledEnforcedOldValue = traceEnabledEnforced
		blocksForTearDown += [{
			traceEnabledEnforced = traceEnabledEnforcedOldValue
		}]
		let swiftHashColumnMatchesLastComponentInCompoundExpressionsOldValue = swiftHashColumnMatchesLastComponentInCompoundExpressions
		blocksForTearDown += [{
			swiftHashColumnMatchesLastComponentInCompoundExpressions = swiftHashColumnMatchesLastComponentInCompoundExpressionsOldValue
		}]
	}
	override func tearDown() {
		blocksForTearDown.forEach {$0()}
		blocksForTearDown = []
		super.tearDown()
	}
}

class TraceTests : TraceAndLabelTestsBase {
	var tracedRecords = [LogRecord]()
	override func setUp() {
		super.setUp()
		let oldLoggers = loggers
		loggers.append({ record in
			self.tracedRecords += [record]
		})
		blocksForTearDown += [{
			loggers = oldLoggers
		}]
	}
	// MARK: -
    func testTraceWithAllThingsDisabled() {
		var evaluated = false
		$({evaluated = true}())
		XCTAssertTrue(tracedRecords.isEmpty)
		XCTAssertTrue(evaluated)
	}
    func testNotraceWithAllThingsDisabled() {
		var evaluated = false
		•({evaluated = true}())
		XCTAssertTrue(tracedRecords.isEmpty)
		XCTAssertFalse(evaluated)
	}
	func testWithTraceEnabled() {
		traceEnabledEnforced = true
		let column =  #column
		let value = $(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, foo)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, [".\(column)"])
	}
	func testNestedWithTraceEnabled() {
		traceEnabledEnforced = true
		let column =  #column
		let column_2 =  #column
		let value = $($(foo)); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, foo)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line, line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL, fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar", "bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, [".\(column_2)", ".\(column)"])
	}
	func testComplexNestedWithTraceEnabled() {
		traceEnabledEnforced = true
		let innerColumn =       #column
		let column =  #column
		let badColumn =              #column
		let value = $("xxx" + $(foo) + "baz"); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, "xxx" + foo + "baz")
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line, line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL, fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, [foo, "xxx" + foo + "baz"])
		let outerColumn = true ? badColumn : column
		XCTAssertEqual(tracedRecords.map {$0.label!}, [".\(innerColumn)", ".\(outerColumn)"])
	}
	func testComplexWithTraceEnabled() {
		traceEnabledEnforced = true
		let column =  #column
		let badColumn =           #column
		let value = $("xxx" + foo + "baz"); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, "xxx" + foo + "baz")
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["xxx" + foo + "baz"])
		let outerColumn = swiftHashColumnMatchesLastComponentInCompoundExpressions ? badColumn : column
		XCTAssertEqual(tracedRecords.map {$0.label!}, [".\(outerColumn)"])
	}
	func testComplexWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let value = $("xxx" + (foo) + "baz"); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, "xxx" + (foo) + "baz")
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["xxx" + foo + "baz"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["\"xxx\" + (foo) + \"baz\""])
	}
	func testWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testNestedWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let value = $($(foo)); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(value, foo)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line, line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL, fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar", "bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo", "$(foo)"])
	}
	func testTraceWithTraceAndLabelsEnabledAndDumpInTraceEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		dumpInTraceEnabledEnforced = true; defer { dumpInTraceEnabledEnforced = nil }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["- \"bar\"\n"])
		XCTAssertEqual(tracedRecords.flatMap {$0.label}, ["foo"])
	}
	func testWithTraceLockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let dt = disableTrace(); defer { _ = dt }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithTraceLockAndTracingDisabled() {
		let dt = disableTrace(); defer { _ = dt }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithTraceUnlockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let dt = disableTrace(); defer { _ = dt }
		$(bar)
		let et = enableTrace(); defer { _ = et }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testWithTraceUnlockWithoutLockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let et = enableTrace(); defer { _ = et }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testWithTraceUnlockAndTracingDisabled() {
		let dt = disableTrace(); defer { _ = dt }
		$(bar)
		let et = enableTrace(); defer { _ = et }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithDisabledFile() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let oldFilesWithTracingDisabled = filesWithTracingDisabled
		defer { filesWithTracingDisabled = oldFilesWithTracingDisabled }
		filesWithTracingDisabled += [
			URL(fileURLWithPath: #file).lastPathComponent
		]
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
}

class LabelTests : TraceAndLabelTestsBase {
    func testLabeledString() {
		let foo = "bar"
		sourceLabelsEnabledEnforced = true
		XCTAssertEqual(L(foo), "foo: bar")
		sourceLabelsEnabledEnforced = false
		let cln = #column
		let l = L(foo);
		XCTAssertEqual(l, ".\(cln): bar")
    }
    func testNestedLabeledString() {
		let foo = "bar"
		sourceLabelsEnabledEnforced = true
		XCTAssertEqual(L(L(foo)), "L(foo): foo: bar")
		sourceLabelsEnabledEnforced = false
		let cln = #column
		let cln_2 = #column
		let l = L(L(foo));
		XCTAssertEqual(l, ".\(cln): .\(cln_2): bar")
    }
	func testLabelWithMissingSource() {
		sourceLabelsEnabledEnforced = true
		let s = "foo"
		let sourceFile = "/tmp/Missing.swift"
		let sourceFilename = URL(fileURLWithPath: sourceFile).lastPathComponent
		let cls = type(of: self)
		let bundleFilename = Bundle(for: cls).bundleURL.lastPathComponent
		let cln = #column - 1
		let l = L(s, file: sourceFile)
		XCTAssertEqual(l, "\(bundleFilename)/\(sourceFilename)[missing]:.\(cln):?: foo")
	}
	func testLabelWithNoSource() {
		sourceLabelsEnabledEnforced = true
		let s = "foo"
		var v = "foo"
		let sourceFilename = URL(fileURLWithPath: #file).lastPathComponent
		withUnsafePointer(to: &v) { p in
			let l = L(s, dso: p)
			XCTAssertEqual(l, "\(sourceFilename):?: foo")
		}
	}
	func testLabeledCompoundExpressions() {
		let foo = "bar"
		let optionalFoo = Optional("bar")
		swiftHashColumnMatchesLastComponentInCompoundExpressions = true
		sourceLabelsEnabledEnforced = true
		XCTAssertEqual(L(String(foo.characters.reversed())), "String(foo.characters.reversed()): rab")
		XCTAssertEqual(L("baz" + String(foo.characters.reversed())), "\"baz\" + String(foo.characters.reversed()): bazrab")
		XCTAssertEqual(L(optionalFoo!), "optionalFoo!: bar")
		swiftHashColumnMatchesLastComponentInCompoundExpressions = false
		XCTAssertEqual(L(String(foo.characters.reversed())), "String(foo.characters.reversed()): rab")
		XCTAssertEqual(L("baz" + String(foo.characters.reversed())), "\"baz\" + String(foo.characters.reversed()): bazrab")
		XCTAssertEqual(L(optionalFoo!), "optionalFoo!: bar")
		let fileManager = FileManager.default
		let storePath = "/tmp/xxx"
		XCTAssertEqual(L(fileManager.fileExists(atPath: storePath)), "fileManager.fileExists(atPath: storePath): false")
	}
}
