//
//  _JSAsyncExecutionSetter.h
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAsyncExecutionManager.h"
NS_ASSUME_NONNULL_BEGIN
@class JSExecutor;
@interface _JSAsyncExecutionSetter : NSObject


/// Current sentinel.
@property (nonatomic, readonly) int32_t sentinel;
@property (nonatomic, strong, readonly) JSExecutor *executor;

- (int32_t) setOperationWithSentinel:(int32_t) sentinel
                            executor:(JSExecutor *) executor
                             manager:(JSAsyncExecutionManager *) manager
                         completioin:(AsyncCompletion) completion;

/// Cancel and return a sentinel value. The imageURL will be set to nil.
- (int32_t)cancel;

/// Cancel and return a sentinel value. The imageURL will be set to new value.
- (int32_t)cancelWithNewExecutor:(nullable JSExecutor *) executor;

/// A queue to set operation.
+ (dispatch_queue_t)setterQueue;

@end

NS_ASSUME_NONNULL_END
