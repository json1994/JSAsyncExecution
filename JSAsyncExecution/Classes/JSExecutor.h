//
//  JSExecutor.h
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class JSExecutor;

typedef NS_ENUM(NSUInteger, JSExecutStatus) {
    JSExecutStatusNone,
    JSExecutStatusExecuting,
    JSExecutStatusFinish,
    JSExecutStatusCancel,
};

@protocol JSExecutorDelegate <NSObject>

- (void)executionDidFinish:(JSExecutor *) executor error:(nullable NSError *)error;

@end

@interface JSExecutor : NSObject

@property (nonatomic, assign) JSExecutStatus executionStatus;
@property (nonatomic, weak) id<JSExecutorDelegate> delegate;

- (void)excution;
- (void)cancel;

/// 是否可被执行
- (BOOL)excutable;

/// 操作结束后 需要调用这个方法
- (void)completed:(nullable id) result error:(nullable NSError *)error;

@end

@interface JSExecutor (Completion)

@property (nonatomic, strong, nullable) id response;
@property (nonatomic, strong, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
