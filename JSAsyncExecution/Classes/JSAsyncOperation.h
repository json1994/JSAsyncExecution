//
//  JSAsyncOperation.h
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class JSExecutor;
typedef void(^AsyncCompletion)(JSExecutor *_Nullable);

@interface JSAsyncOperation : NSOperation

@property (nonatomic, copy, readonly) AsyncCompletion asyncCompletion;
@property (nonatomic, strong, readonly) JSExecutor *executor;

- (instancetype) initWithExecutor:(JSExecutor *) executor completion:(AsyncCompletion) completoin;

@end

NS_ASSUME_NONNULL_END
