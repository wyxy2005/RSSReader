//
//  SystemLayoutSizeCachingTableViewCell.swift
//  GEBase
//
//  Created by Grigory Entin on 08/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation
import UIKit.UITableViewCell

struct TargetSizeAndLayoutSizeDefiningValue {
	let targetSize: CGSize
	let layoutSizeDefiningValue: NSObject
}

extension TargetSizeAndLayoutSizeDefiningValue : Hashable, Equatable {
	var hashValue: Int {
		return "\(targetSize)".hash &+ layoutSizeDefiningValue.hashValue
	}
}
func == (lhs: TargetSizeAndLayoutSizeDefiningValue, rhs: TargetSizeAndLayoutSizeDefiningValue) -> Bool {
	guard lhs.targetSize == rhs.targetSize else {
		return false
	}
	guard lhs.layoutSizeDefiningValue == rhs.layoutSizeDefiningValue else {
		return false
	}
	return true
}

public class SystemLayoutSizeCachingTableViewCellDataSource {
	let layoutSizeDefiningValueForCell: (UITableViewCell) -> NSObject?
	let cellShouldBeReusedWithoutLayout: (UITableViewCell) -> Bool
	var cachedSystemLayoutSizes: [TargetSizeAndLayoutSizeDefiningValue : CGSize] = [:]
	public init(layoutSizeDefiningValueForCell: (UITableViewCell) -> NSObject?, cellShouldBeReusedWithoutLayout: (UITableViewCell) -> Bool) {
		self.layoutSizeDefiningValueForCell = layoutSizeDefiningValueForCell
		self.cellShouldBeReusedWithoutLayout = cellShouldBeReusedWithoutLayout
	}
}

public extension KVOCompliantUserDefaults {
	@NSManaged public var cellSystemLayoutSizeCachingEnabled: Bool
}

public class SystemLayoutSizeCachingTableViewCell: UITableViewCell {
	var reused = false
	public var systemLayoutSizeCachingDataSource: SystemLayoutSizeCachingTableViewCellDataSource!
	public override func systemLayoutSizeFittingSize(targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			return super.systemLayoutSizeFittingSize(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		guard let layoutSizeDefiningValue = systemLayoutSizeCachingDataSource.layoutSizeDefiningValueForCell(self) else {
			return super.systemLayoutSizeFittingSize(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		let cacheKey = TargetSizeAndLayoutSizeDefiningValue(targetSize: targetSize, layoutSizeDefiningValue: layoutSizeDefiningValue)
		if let cachedSystemLayoutSize = systemLayoutSizeCachingDataSource.cachedSystemLayoutSizes[cacheKey] {
			return cachedSystemLayoutSize
		}
		let systemLayoutSize = super.systemLayoutSizeFittingSize(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		systemLayoutSizeCachingDataSource.cachedSystemLayoutSizes[cacheKey] = systemLayoutSize
		return systemLayoutSize
	}
	public override func prepareForReuse() {
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			super.prepareForReuse()
			return
		}
		super.prepareForReuse()
		reused = true
	}
	var layoutSubviewsInvocationsCount = 0
	public override func layoutSubviews() {
		layoutSubviewsInvocationsCount += 1
		let dt = disableTrace(); defer { dt }
		$(layoutSubviewsInvocationsCount)
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			super.layoutSubviews()
			return
		}
		guard reused && systemLayoutSizeCachingDataSource.cellShouldBeReusedWithoutLayout(self) else {
			super.layoutSubviews()
			return
		}
		self.translatesAutoresizingMaskIntoConstraints = true
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: $(reuseIdentifier))
	}
	required public override init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		$(reuseIdentifier!)
	}
}