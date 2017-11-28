//
//  DeDaoEvernoteShare.mm
//  DeDaoEvernoteShare
//
//  Created by 杨志超 on 2017/9/22.
//  Copyright (c) 2017年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import "CaptainHook/CaptainHook.h"
#import <UIKit/UIKit.h>

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

@class ENSaveToEvernoteActivity;

CHDeclareClass(SubscribeInfoWKViewController);

CHOptimizedMethod0(self, void, SubscribeInfoWKViewController, viewDidLoad) {
    
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *shareImage = [UIImage imageNamed:@"new_nav_share"];
    [shareButton setImage:shareImage forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [shareButton sizeToFit];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    
    [[self navigationItem] setRightBarButtonItem:shareItem];
    
    CHSuper(0, SubscribeInfoWKViewController, viewDidLoad);
}

CHDeclareMethod1(void, SubscribeInfoWKViewController, shareButtonClicked, UIButton *, sender) {
    NSString *articleFilePath = [self articleFilePath];
    if ([articleFilePath length] == 0) return;
    
    ENSaveToEvernoteActivity *saveActivity = [[objc_getClass("ENSaveToEvernoteActivity") alloc] init];
    [saveActivity setNoteTitle:@"article"];
    
    NSString *content = [[NSString alloc] initWithContentsOfFile:articleFilePath encoding:NSUTF8StringEncoding error:nil];
    if ([content length] == 0) return;
    
    NSArray *items = @[content];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:@[saveActivity]];
    
    UIPopoverPresentationController *popover = activity.popoverPresentationController;
    if (popover) {
        popover.sourceView = sender;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:activity animated:YES completion:nil];
}


CHDeclareMethod0(NSString *, SubscribeInfoWKViewController, articleFilePath) {
    NSString *subscribeTitle = [[[self viewModel] articleEntity] subscribe_title];
    if ([subscribeTitle length] == 0) {
        subscribeTitle = @"未知专栏";
    }
    
    NSNumber *articleId = [[[self viewModel] articleEntity] article_id];
    NSString *articleTitle = [[[self viewModel] articleEntity] article_title];
    if ([articleTitle length] == 0) {
        articleTitle = @"未知文章";
    }
    
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    
    NSString *allArticlesDirectory = [@"articles" stringByAppendingPathComponent:subscribeTitle];
    NSString *subscribeDirectoryPath = [documentDirectoryPath stringByAppendingPathComponent:allArticlesDirectory];
    
    BOOL createSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:subscribeDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (!createSuccess) return nil;
    
    NSString *filename = [NSString stringWithFormat:@"%ld-%@.html", (long)[articleId integerValue], articleTitle];
    NSString *articleFilePath = [subscribeDirectoryPath stringByAppendingPathComponent:filename];
    
    return articleFilePath;
}

CHOptimizedMethod2(self, void, SubscribeInfoWKViewController, callBackAction, unsigned int, action, info, NSString *, info) {
    CHSuper2(SubscribeInfoWKViewController, callBackAction, action, info, info);
    
    if (action != 1) return;
    if ([info length] == 0) return;
    
    NSString *filePath = [self articleFilePath];
    if ([filePath length] == 0) return;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [info writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}


CHConstructor {
    @autoreleasepool {
        CHLoadLateClass(SubscribeInfoWKViewController);
        CHHook0(SubscribeInfoWKViewController, viewDidLoad);
        CHHook2(SubscribeInfoWKViewController, callBackAction, info);
    }
}
