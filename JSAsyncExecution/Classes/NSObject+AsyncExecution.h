//
//  NSObject+AsyncExecution.h
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAsyncExecutionManager.h"

NS_ASSUME_NONNULL_BEGIN
@class JSExecutor;

@interface NSObject (AsyncExecution)


- (void)setAsyncExector:(nullable JSExecutor *) executor completion:(AsyncCompletion) completion;
- (JSExecutor *)executor;

/// 子类实现
- (void)asyncExcutionDidFinish:(JSExecutor *) executor sentinelChanged:(BOOL) change;

@end

NS_ASSUME_NONNULL_END
