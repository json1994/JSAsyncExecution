//
//  JSAsyncExecutionManager.h
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAsyncOperation.h"
#import "JSExecutor.h"
NS_ASSUME_NONNULL_BEGIN

@interface JSAsyncExecutionManager : NSObject

@property (nonatomic, strong, readonly, nullable) NSOperationQueue *queue;

+ (instancetype)sharedManager;

- (instancetype) initWithQueue:(nullable NSOperationQueue *)queue;

- (nullable JSAsyncOperation *) asyncWithExexut:(JSExecutor *) executor completion:(AsyncCompletion) completion;
@end

NS_ASSUME_NONNULL_END
