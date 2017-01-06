//
//  ViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/5/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController () <MCAdvertiserAssistantDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceBrowserDelegate>

@property (strong, nonatomic) MCPeerID *peer;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;

@end

@implementation ViewController

- (IBAction)findDevicesTapped:(id)sender {
    MCBrowserViewController *browserController = [[MCBrowserViewController alloc] initWithBrowser:self.browser session:self.session];
    browserController.delegate = self;
    [self presentViewController:browserController animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.peer = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc] initWithPeer:self.peer];
    self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"sprocket" discoveryInfo:nil session:self.session];
    self.advertiser.delegate = self;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peer serviceType:@"sprocket"];
    [self.advertiser start];
    
//    NSLog(@"%@", self.session);
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MCAdvertiserAssistantDelegate

- (void)advertiserAssitantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    
}

- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *, NSString *> *)info
{
    NSLog(@"FOUND: %@", peerID);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"LOST: %@", peerID);
}

@end
