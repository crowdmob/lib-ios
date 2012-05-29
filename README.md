# CrowdMob iOS Integration Documentation for MobDeals and Loot

## Available Services
### MobDeals
MobDeals is an in-app service (also accessible via web) that allows the sale of virtual goods combined with a real-world good, such as a gift card.  Once the customer completes the transaction, the customer is immediately credited with the purchased virtual good in the application.

### Loot (Documentation Forthcoming - check out the comments in our files!)
Loot is an incentivized install service. Installs of a particular application through Loot are recorded on the CrowdMob servers. The drop-in files allow for a publisher to send a hashed mac address to the CrowdMob servers, allowing for confirmation of the source of the installs.

## Sample Integration Application
To see a full sample integration of the MobDeals Offerwall and Loot, check out our [sample integration app on GitHub](https://github.com/crowdmob/ios-sample-integration).

## General File Structure
The CrowdMob drop-in files offer the ability to verify an install (for Loot) and open a UIWebView and perform a package purchase (for MobDeals). A delegate is used to obtain the result of each of these processes (failure, success, and status code on success for Loot).

## Implementation
### MobDeals Offerwall
The MobDeals Offerwall requires 3 elements:
1. Launching the Offerwall
2. Closing the Offerwall
3. Listen for a transaction result

#### General Setup
Two files are absolutely required for utilizing CrowdMob's service, no matter the implementation. These are as follows:
* CrowdMob.h
* CrowdMob.m

However, for a complete functionality without any additional modification, the following files should also be included:
* MobDeals.storyboard
* cancel_button.png
* <pre>cancel_button@2x.png</pre>

Without these files and additional modification, you will not have a working implementation. These files are used for the layout of the modal view controller that launches the UIWebView for the Offerwall and add a graphic for the close button on the UIWebView. These can all be created or modified as needed to produce the interface that fits your application best as long as they are correctly connected to the CrowdMob.h and Crowdmob.h files.


In your view controller that will launch the Offerwall, you must import CrowdMob.h in your .h and .m files.
```objective-c
#import "CrowdMob.h"
```

You must also make sure your application requires or checks for an Internet connection. The MobDeals Offerwall interface will not work without an Internet connection.

#### .h File
You must subclass your view controller to use the CrowdMob delegate and declare the Offerwall as a CrowdMob class instance.
```objective-c
@interface ViewController : UIViewController&lt;CrowdMobDelegate, UITextFieldDelegate>
{
    CrowdMob *offerwall;
}
```

You must also implement the delegate functions to close the Offerwall and obtain the result of a transaction.
```objective-c
//Delegate method from the modal view controller's required protocol that closes the UIWebView
- (void) closeOfferwall:(BOOL) status;

//Delegate method that runs when a MobDeals transaction succeeds or fails, along with transaction information on success
- (void) transactionStatus:(BOOL) status;
```

#### .m File
##### Launching the Offerwall
The Offerwall operates through a UIWebView. To launch the UIWebView, you must 1) instantiate the CrowdMob class with the appropriate storyboard, 2) provide your secret key, 3) set the working environment ("PRODUCTION" or "STAGING"), 4) set the class as its own delegate, and 5) launch the modal view controller that controls the UIWebView.
```objective-c
//Instantiate a modal view which includes a UIWebView to handle the purchase
offerwall = [[UIStoryboard storyboardWithName:@"MobDeals" bundle:nil] instantiateInitialViewController];

//Set the secret key
offerwall.secretKey = [secretKey text];

//Set the environment - use "PRODUCTION" for production environment and "STAGING" for a staging environment
offerwall.environment = @"STAGING";

//Set this controller as the delegate
offerwall.delegate = self;

//Launch the modal view controller, which includes the UIWebView
[self presentModalViewController:offerwall animated:YES];
```

##### Closing the Offerwall
When the close button is pressed within the Offerwall, a delegate method is called. You may implement closing the offerwall in whatever manner you wish, but we suggest the following method.
```objective-c
//Delegate method from the modal view controller's required protocol that closes the UIWebView
- (void) closeOfferwall:(BOOL) status
{
    if (status) {
        //Dismiss the modal view
        [self dismissModalViewControllerAnimated:YES];
        
        //Take care of the leftover modal view elements
        offerwall.webView = nil;
        offerwall = nil;
        
        //Clear the cache - not recommended for production application use, but great for testing
        //[[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
}
```

##### Listening for a Transaction Result
When a user attempts a transaction, a delegate method is called upon success or failure, returning the status of the transaction. If the transaction succeeds, the amount of virtual currency, the transaction ID, and the timestamp are accessible within this delegate function. You may call the relevant functions that credit the user within this method. The suggested implementation is below.
```objective-c
//Delegate method that runs when a MobDeals transaction succeeds or fails, along with transaction information on success
- (void) transactionStatus:(BOOL)status currencyAmount:(NSInteger)amount transactionId:(NSString *)transactionId timestamp:(NSString *)timestamp
{
    NSString *statusMessage = [NSString alloc];
    
    if (status) {
        //Your crediting operations
    }
    else {
        //Your alert operations for a transaction failure
    }
}
```

#### Production and Staging Environments
Remember to set the CrowdMob instance object's environment to the appropriate environment for your testing and production purposes. Use "PRODUCTION" for production environment. Use "STAGING" for a staging environment. This must be done before launching the Offerwall.
```objective-c
offerwall.environment = @"STAGING";
```

## Question/Comments
We're developer centric! If you encounter any issues, have questions, or have suggestions or other comments, please don't hesitate to contact us at developers@crowdmob.com. We are available at most hours and will answer your questions as soon as possible.
