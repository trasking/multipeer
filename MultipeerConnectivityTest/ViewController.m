//
//  ViewController.m
//  MultipeerConnectivityTest
//
//  Created by James Trask on 1/5/17.
//  Copyright © 2017 hp. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "HostPartyTableViewController.h"

@interface ViewController () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate>

@property (strong, nonatomic) MCPeerID *peer;
@property (strong, nonatomic) MCPeerID *hostPeer;
@property (strong, nonatomic) MCSession *hostSession;
@property (strong, nonatomic) MCSession *guestSession;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *joinPartyButton;
@property (weak, nonatomic) IBOutlet UIButton *sendPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *hostPartyButton;

@end

@implementation ViewController

NSString *kServiceType = @"sprocket";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupConnectivity];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setHostPartyButtonText];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"HostPartySegue"]) {
        UINavigationController *nav = (UINavigationController *)segue.destinationViewController;
        HostPartyTableViewController *vc = (HostPartyTableViewController *)nav.topViewController;
        vc.peer = self.peer;
        vc.session = self.hostSession;
    }
}

#pragma mark - Button handlers

- (IBAction)sendPhotoTapped:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)joinPartyButtonHandler:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.joinPartyButton.titleLabel.text isEqualToString:@"Join Party"]) {
            [self.advertiser startAdvertisingPeer];
            [self.joinPartyButton setTitle:@"Ready to Party" forState:UIControlStateNormal];
        } else if ([self.joinPartyButton.titleLabel.text isEqualToString:@"Ready to Party"]) {
          [self.advertiser stopAdvertisingPeer];
            [self.joinPartyButton setTitle:@"Join Party" forState:UIControlStateNormal];
        } else {
            [self.guestSession disconnect];
            self.hostPeer = nil;
            [self.joinPartyButton setTitle:@"Join Party" forState:UIControlStateNormal];
            self.sendPhotoButton.hidden = YES;
        }
    });
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
        UIImage *image = [self normalizedImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        NSData *data = UIImagePNGRepresentation(image);
        NSError *error = nil;
        BOOL result = [self.guestSession sendData:data toPeers:@[ self.hostPeer ] withMode:MCSessionSendDataReliable error:&error];
        NSLog(@"SEND %@\nERROR: %@", result ? @"SUCCESS" : @"FAIL", error);
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
    NSLog(@"START RESOURCE: %@", resourceName);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"FINISH RESOURCE: %@\nURL: %@\nERROR: %@", resourceName, localURL, error);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"SESSION PEER:  %@:  %ld", peerID, (long)state);
    [self setHostPartyButtonText];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"INVITATION RECEIVED");
    [self.advertiser stopAdvertisingPeer];
    self.hostPeer = peerID;
    invitationHandler(YES, self.guestSession);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.joinPartyButton setTitle:[NSString stringWithFormat:@"Partying with %@", self.hostPeer.displayName] forState:UIControlStateNormal];
        self.sendPhotoButton.hidden = NO;
    });
}

#pragma mark - Utilities

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (void)setupConnectivity
{
    self.peer = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.hostSession = [[MCSession alloc] initWithPeer:self.peer];
    self.hostSession.delegate = self;
    self.guestSession = [[MCSession alloc] initWithPeer:self.peer];
    self.guestSession.delegate = self;
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peer discoveryInfo:nil serviceType:kServiceType];
    self.advertiser.delegate = self;
}

- (void)setHostPartyButtonText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = @"Host Party";
        if (self.hostSession.connectedPeers.count > 0) {
            text = [NSString stringWithFormat:@"Hosting Party (%lu)", (unsigned long)self.hostSession.connectedPeers.count];
        }
        [self.hostPartyButton setTitle:text forState:UIControlStateNormal];
    });
}

@end
