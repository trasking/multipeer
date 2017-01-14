//
//  HostPartyTableViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/9/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "ViewController.h"
#import "HostPartyTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface HostPartyTableViewController () 

@end

@implementation HostPartyTableViewController

NSString *kHostCellReuseIdentifier = @"HostPartyCell";
NSString *kHostServiceType = @"sprocket";
NSUInteger kHostJoinedSection = 0;
NSUInteger kHostAvailableSection = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.availablePeripherals = [NSMutableArray array];
    self.connectedPeripherals = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePeripheralsChanged:) name:kPeripheralsChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.delegate startHosting];
}

- (IBAction)doneButtonTapped:(id)sender {
    [self.delegate stopHosting];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (kHostJoinedSection == section) {
        return self.connectedPeripherals.count;
    } else {
        return self.availablePeripherals.count;
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (kHostJoinedSection == section) {
        return @"Joined";
    } else {
        return @"Available";
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (kHostJoinedSection == section) {
        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.connectedPeripherals.count, 1 == self.connectedPeripherals.count ? @"" : @"s"];
    } else {
        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.availablePeripherals.count, 1 == self.availablePeripherals.count ? @"" : @"s"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHostCellReuseIdentifier forIndexPath:indexPath];
    CBPeripheral *peripheral = nil;
    if (kHostJoinedSection == indexPath.section) {
        peripheral = [self.connectedPeripherals objectAtIndex:indexPath.row];
    } else {
        peripheral = [self.availablePeripherals objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    if (indexPath.section == kHostAvailableSection) {
        CBPeripheral *peripheral = [self.availablePeripherals objectAtIndex:indexPath.row];
        [self.delegate didRequestConnectPeripheral:peripheral];
    }
}

#pragma mark - NSNotificationCenter

- (void)handlePeripheralsChanged:(NSNotification *)notification
{
    self.availablePeripherals = [notification.userInfo objectForKey:@"availablePeripherals"];
    self.connectedPeripherals = [notification.userInfo objectForKey:@"connectedPeripherals"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
