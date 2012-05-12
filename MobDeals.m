//
//  MobDeals.m
//  Loot iOS SDK
//
//  Created by Rohen Peterson on 5/4/12.
//  Copyright (c) 2012 CrowdMob, Inc. All rights reserved.
//

#import "MobDeals.h"
#import <QuartzCore/QuartzCore.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <CommonCrypto/CommonDigest.h>

@implementation MobDeals

//Delegate for the UIWebView
@synthesize delegate;
//Instance of the actual UIWebView
@synthesize webView;
//Secret key that must be set for all operations
@synthesize secretKey;
//Permalink that must be set for all operations
@synthesize permalink;
//Environment variable that accepts "PRODUCTION" as a valid production environment flag
@synthesize environment;


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the controller as its own delegate
    [webView setDelegate:self];
    
    //Grab image of the parent view - iOS5
    UIView *parentView = self.presentingViewController.view;
    //iOS4 equivalent
    //UIView *parentView = self.parentViewController.view;
    
    //Set the image parameters based on the parent view's size
    UIGraphicsBeginImageContext(parentView.bounds.size);
    [parentView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //Setup an image view with the parent's image
    UIImage *parentViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Setup the image view from the parent image
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.image = parentViewImage;
    
    //Dim the image
    [imageView setBackgroundColor:[UIColor blackColor]];
    [imageView setAlpha:0.5];
    
    //Insert the image view at the bottom of the image stack
    [self.view insertSubview:imageView atIndex:0];
    
    //Round the edges
    [[webView layer] setCornerRadius:15.0];
    [[webView layer] setMasksToBounds:YES];
    
    //Grab the target URL
    //Production server
    NSURL* url = [NSURL URLWithString:@"https://offerwall.crowdmob.com"];
    
    //Staging server to use if not in a production environment
    if (environment != @"PRODUCTION") {
        url = [NSURL URLWithString:@"http://offerwall.mobstaging.com"];
    }
    
    //Create the URL request and pass it to the UIWebView
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [webView loadRequest:urlRequest];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setDelegate:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

//Use to close the UIWebView from a button within the view
- (IBAction)closeButton:(id)sender
{
    [delegate closeOfferwall:YES];
}


//Runs each time a request is loading
- (BOOL)webView:(UIWebView *)webView2 shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    //If a request is a call from the MobDeals interface, grab the data
    //This acts as a callback when transactions are complete
    if ([[[request URL] absoluteString] hasPrefix:@"mobdeals-html5:"]) {
        
        //Format the string into a JSON object
        NSData *jsonData = [[[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]] dataUsingEncoding:NSUTF8StringEncoding];
        jsonData = [jsonData subdataWithRange:NSMakeRange([@"mobdeals-html5:" length], [jsonData length] - [@"mobdeals-html5:" length])];
        
        //Transform the JSON object into a dictionary
        NSError *error = [[NSError alloc] init];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                
        //Obtain the callback information from the dictionary
        NSString *coins = [data valueForKey:@"coins"];
        NSString *transID = [data valueForKey:@"transaction"];
        NSString *timestamp = [data valueForKey:@"timestamp"];
        NSString *signature = [data valueForKey:@"signature"];
        
        //Verify the transaction based on the md5 hash
        if ([[self md5:[NSString stringWithFormat:@"%@%@%@%@", coins, timestamp, transID, secretKey]] isEqualToString:signature]) {

//********************************************************************************************************
            //If the transaction is valid, credit the user here!
//********************************************************************************************************
        }
        else {

//********************************************************************************************************
            //If the transaction failed, perform notice code here!
//********************************************************************************************************
        }
        
        return NO;
    }
    
    //If the call is not a MobDeals callback, ignore this function
    return YES;
}

//Verify an install with Loot
- (void)verifyInstall
{
    //Set up the message
    NSString *uuidHash = [self getMacAddressHash];
    NSString *message = [NSString stringWithFormat:@"%@%@", permalink, uuidHash];
    NSString *secretHash = [self sha256:message salt:secretKey];
    
    //Set up the call to the core server to report the install
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    
    //Production server
    NSURL* URL = [NSURL URLWithString:@"https://deals.crowdmob.com/loot/verify_install.json"];

    if (environment != @"PRODUCTION") {
        URL = [NSURL URLWithString:@"http://deals.mobstaging.com/loot/verify_install.json"];
    }
    
    //Set the parameters
    NSData *parameters = [[NSString stringWithFormat:@"verify[permalink]=%@&verify[uuid]=%@&verify[secret_hash]=%@", permalink, uuidHash, secretHash] dataUsingEncoding:NSUTF8StringEncoding];
    
    //Set up the remainder of the connection
    [request setHTTPBody:parameters];
    [request setHTTPMethod:@"POST"];
    [request setURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:30];

    //Make an asynchronous connection, post the data
    //Requires iOS5
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *jsonData, NSError *error) {
        
        //Serialize the JSON data
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *statusDisplay = [[UIAlertView alloc]
                                      initWithTitle: @"Installation Status"
                                      message: [data valueForKey:@"install_status"]
                                      delegate: self cancelButtonTitle: @"Ok" 
                                      otherButtonTitles: nil];
        
            [statusDisplay show];
        });
    }];
}

//Returns the mac address hash of the current device
- (NSString *)getMacAddressHash
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;              
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0) 
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0) 
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
                                  macAddress[0], macAddress[1], macAddress[2], 
                                  macAddress[3], macAddress[4], macAddress[5]];
    
    // Release the buffer memory
    free(msgBuffer);
    
    return [self sha256:macAddressString];
}

//MD5 Hash Algorithm, returns a hex-encoded hash value
- (NSString *)md5:(NSString *)input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

//SHA-256 Hash Algorithm, returns a hex-encoded hash value
- (NSString *)sha256:(NSString *)input
{
    const char *cStr = [input UTF8String];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, strlen(cStr), hash);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", hash[i]];
    }
    
    return output;
}

//SHA-256 Hash Algorithm with a salt input, returns a hex-encoded hash value
- (NSString *)sha256:(NSString *)input salt:(NSString *)salt
{
    NSString *message = [NSString stringWithFormat:@"%@,%@", salt, input];
    const char *cStr = [message UTF8String];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, strlen(cStr), hash);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", hash[i]];
    }
    
    return output;
}

@end
