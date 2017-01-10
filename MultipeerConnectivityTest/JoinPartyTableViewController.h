//
//  JoinPartyTableViewController.h
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/9/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface JoinPartyTableViewController : UITableViewController

@property (strong, nonatomic) MCPeerID *peer;
@property (strong, nonatomic) MCSession *session;

@end
