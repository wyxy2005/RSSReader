//
//  KeyPathRecordingProxy.h
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyPathRecordingProxy : NSProxy

@property (copy, nonatomic) NSArray *keyPathComponents;

@end

#if 0
extern NSUInteger keyPathRecordingProxyLiveCount;
#endif
