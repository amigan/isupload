//
//  Imageshack.h
//  Imageshack
//
//  Created by Dan Ponte on 9/1/09.
//  Copyright (c) 2009 __MyCompanyName__, All Rights Reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import <Automator/AMAction.h>
#import <OSAKit/OSAKit.h>

@interface ISUpload : AMBundleAction 
{
	BOOL gimglink;
	NSURL *imglink;
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
