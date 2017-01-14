//
//  HostPartyTableViewController.h
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/9/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol HostPartyTableViewControllerDelegate;

@interface HostPartyTableViewController : UITableViewController

@property (weak, nonatomic) id<HostPartyTableViewControllerDelegate>delegate;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *availablePeripherals;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *connectedPeripherals;

@end

@protocol HostPartyTableViewControllerDelegate <NSObject>

@required

- (void)startHosting;
- (void)stopHosting;
- (void)didRequestConnectPeripheral:(CBPeripheral *)peripheral;

@end
