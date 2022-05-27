#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JSAsyncExecutionManager.h"
#import "JSAsyncOperation.h"
#import "JSExecutor.h"
#import "NSObject+AsyncExecution.h"
#import "_JSAsyncExecutionSetter.h"

FOUNDATION_EXPORT double JSAsyncExecutionVersionNumber;
FOUNDATION_EXPORT const unsigned char JSAsyncExecutionVersionString[];

