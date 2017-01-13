//
//  HostPartyTableViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/9/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "HostPartyTableViewController.h"
#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface HostPartyTableViewController () <MCNearbyServiceBrowserDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) NSMutableArray<MCPeerID *> *availablePeers;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *availablePeripherals;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *connectedPeripherals;

@end

@implementation HostPartyTableViewController

NSString *kHostCellReuseIdentifier = @"HostPartyCell";
NSString *kHostServiceType = @"sprocket";
NSUInteger kHostJoinedSection = 0;
NSUInteger kHostAvailableSection = 1;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionChanged:) name:kSessionChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupBluetooth];
    
// MPC
//    self.availablePeers = [NSMutableArray array];
//    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peer serviceType:kHostServiceType];
//    self.browser.delegate = self;
//    [self.browser startBrowsingForPeers];
}

- (IBAction)doneButtonTapped:(id)sender {
    [self.centralManager stopScan];
// MPC
//    [self.browser stopBrowsingForPeers];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (kHostJoinedSection == section) {
        return self.session.connectedPeers.count;
    } else {
        return self.availablePeripherals.count;
// MPC
//        return self.availablePeers.count;
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
        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.session.connectedPeers.count, 1 == self.session.connectedPeers.count ? @"" : @"s"];
    } else {
        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.availablePeripherals.count, 1 == self.availablePeripherals.count ? @"" : @"s"];
// MPC
//        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.availablePeers.count, 1 == self.availablePeers.count ? @"" : @"s"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHostCellReuseIdentifier forIndexPath:indexPath];
    CBPeripheral *peripheral = [self.availablePeripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    if (indexPath.section == kHostAvailableSection) {
        CBPeripheral *peripheral = [self.availablePeripherals objectAtIndex:indexPath.row];
        [self.connectedPeripherals addObject:peripheral];
        [self.availablePeripherals removeObject:peripheral];
        [self.centralManager connectPeripheral:peripheral options:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - MCNearbyServiceBrowserDelegate

- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    [self.availablePeers addObject:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [self.availablePeers removeObject:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - NSNotificationCenter

- (void)handleSessionChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"CENTRAL STATE: %ld", central.state);
    if (CBManagerStatePoweredOn == central.state) {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:@"3605946E-9BBB-4366-9369-06B7D4412927"];
        [self.centralManager scanForPeripheralsWithServices:@[ serviceUUID ] options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"DISCOVERED PERIPHERAL: %@\nADVERTISEMENT DATA: %@\nRSSI: %@", peripheral, advertisementData, RSSI);
    [self.availablePeripherals addObject:peripheral];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"CONNECTED PERIPHERAL: %@", peripheral);
    peripheral.delegate = self;
    CBUUID *serviceUUID = [CBUUID UUIDWithString:@"3605946E-9BBB-4366-9369-06B7D4412927"];
    [peripheral discoverServices:@[ serviceUUID ]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"FAILED TO CONNECT PERIPHERAL: %@\nERROR: %@", peripheral, error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"DISCONNECTED PERIPHERAL: %@\nERROR: %@", peripheral, error);
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict {}

#pragma mark - Bluetooth

- (void)setupBluetooth
{
    self.availablePeripherals = [NSMutableArray array];
    self.connectedPeripherals = [NSMutableArray array];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"DISCOVERED SERVICES: %@\nERROR: %@", peripheral.services, error);
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"815DCE0B-2A67-415F-B2A4-10E0221AE541"];
    [peripheral discoverCharacteristics:@[ characteristicUUID ] forService:peripheral.services[0]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    NSLog(@"DISCOVERED CHARACTERISTICS: %@\nERROR: %@", service.characteristics, error);
}

@end
