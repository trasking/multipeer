//
//  HostPartyTableViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/9/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "HostPartyTableViewController.h"
#import "ViewController.h"

@interface HostPartyTableViewController () <MCNearbyServiceBrowserDelegate>

@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) NSMutableArray<MCPeerID *> *availablePeers;

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
    
    self.availablePeers = [NSMutableArray array];
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peer serviceType:kHostServiceType];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

- (IBAction)doneButtonTapped:(id)sender {
    [self.browser stopBrowsingForPeers];
    [self dismissViewControllerAnimated:YES completion:nil];
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
        return self.availablePeers.count;
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
        return [NSString stringWithFormat:@"%lu device%@", (unsigned long)self.availablePeers.count, 1 == self.availablePeers.count ? @"" : @"s"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHostCellReuseIdentifier forIndexPath:indexPath];
    MCPeerID *peer = nil;
    if (kHostJoinedSection == indexPath.section) {
        peer = [self.session.connectedPeers objectAtIndex:indexPath.row];
    } else {
        peer = [self.availablePeers objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = peer.displayName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    if (indexPath.section == kHostAvailableSection) {
        MCPeerID *peer = [self.availablePeers objectAtIndex:indexPath.row];
        NSLog(@"INVITE PEER: %@", peer.displayName);
        [self.browser invitePeer:peer toSession:self.session withContext:nil timeout:10];
        [self.availablePeers removeObject:peer];
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

@end
