//
//  CrowdMob.h
//  Loot iOS SDK
//
//  Created by Rohen Peterson on 5/4/12.
//  Copyright (c) 2012 CrowdMob, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//UIWebView will act as its own delegate
@protocol CrowdMobDelegate <NSObject>
@required

//Allow for the delegate to close the browser via a button
- (void) closeOfferwall:(BOOL) status;

//Runs when a verification succeeds or fails
- (void) verificationStatus:(BOOL) status verificationStatusCode:(NSInteger) statusCode;

//Runs when a MobDeals transaction succeeds or fails
- (void) transactionStatus:(BOOL) status;

@end

@interface CrowdMob : UIViewController<UIWebViewDelegate> {
    IBOutlet UIWebView *webView;
}


//Delegate for the messaging
@property (nonatomic,assign) id <CrowdMobDelegate> delegate;

//Instance of the actual UIWebView
@property (nonatomic,retain) UIWebView *webView;
//Secret key that must be set for all operations
@property (nonatomic,retain) NSString *secretKey;
//Permalink that must be set for all operations
@property (nonatomic,retain) NSString *permalink;
//Environment variable that accepts "PRODUCTION" as a valid production environment flag
@property (nonatomic,retain) NSString *environment;


//Use to close the UIWebView from a button within the view
- (IBAction)closeButton:(id)sender;


//Verify an install with Loot
- (void)verifyInstall;
//Returns the mac address hash of the current device
- (NSString *)getMacAddressHash;
//MD5 Hash Algorithm, returns a hex-encoded hash value
- (NSString *)md5:(NSString *)input;
//SHA-256 Hash Algorithm, returns a hex-encoded hash value
- (NSString *)sha256:(NSString *)input;
//SHA-256 Hash Algorithm with a salt input, returns a hex-encoded hash value
- (NSString *)sha256:(NSString *)input salt:(NSString *)salt;

@end
