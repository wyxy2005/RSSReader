//
//  KVOCompliantUserDefaults+RSSReader.h
//  RSSReader
//
//  Created by Grigory Entin on 25.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KVOCompliantUserDefaults.h"

@interface KVOCompliantUserDefaults (RSSReader)

@property (nonatomic) BOOL showUnreadOnly;
@property (copy, nonatomic) NSString *authToken;
@property (copy, nonatomic) NSString *login;
@property (copy, nonatomic) NSString *password;

@end