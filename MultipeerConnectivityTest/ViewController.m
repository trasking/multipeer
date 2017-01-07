//
//  ViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/5/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController () <MCAdvertiserAssistantDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceBrowserDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate>

@property (strong, nonatomic) MCPeerID *peer;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.peer = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc] initWithPeer:self.peer];
    self.session.delegate = self;
    self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"sprocket" discoveryInfo:nil session:self.session];
    self.advertiser.delegate = self;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peer serviceType:@"sprocket"];
    [self.advertiser start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handlers

- (IBAction)sendPhotoTapped:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)findDevicesTapped:(id)sender {
    MCBrowserViewController *browserController = [[MCBrowserViewController alloc] initWithBrowser:self.browser session:self.session];
    browserController.delegate = self;
    [self presentViewController:browserController animated:YES completion:nil];
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"PHOTO: %@", info);
    [self dismissViewControllerAnimated:YES completion:^{
//        UIImagePickerControllerReferenceURL
        NSData *data = UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerOriginalImage]);
        NSError *error = nil;
        BOOL result = [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
        NSLog(@"SEND %@", result ? @"SUCCESS" : @"FAIL");
        NSLog(@"SEND ERROR: %@", error);
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithData:data];
        self.imageView.image = image;
        NSLog(@"IMAGE RECEIVED: %@", image);
    });
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"SESSION PEER:  %@:  %ld", peerID, (long)state);
}

@end
