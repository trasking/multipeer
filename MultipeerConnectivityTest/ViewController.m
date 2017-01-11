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

@interface ViewController () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, NSStreamDelegate>

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
@property (strong, nonatomic) NSInputStream *input;
@property (strong, nonatomic) NSOutputStream *output;
@property (strong, nonatomic) NSMutableData *imageData;
@property (assign, nonatomic) NSUInteger imageSize;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation ViewController

NSString * const kSessionChangedNotification = @"kSessionChangedNotification";

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
        [self sendImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
//        
//        UIImage *image = [self normalizedImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
//        NSData *data = UIImagePNGRepresentation(image);
//        NSError *error = nil;
//        BOOL result = [self.guestSession sendData:data toPeers:@[ self.hostPeer ] withMode:MCSessionSendDataReliable error:&error];
//        NSLog(@"SEND %@\nERROR: %@", result ? @"SUCCESS" : @"FAIL", error);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = 0.0;
        self.progressView.hidden = NO;
    });
    NSLog(@"RECEIVED STREAM: %@", streamName);
    self.imageData = [NSMutableData data];
    self.imageSize = -1;
    self.input = stream;
    [self.input setDelegate:self];
    [self.input scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.input open];
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"SESSION PEER:  %@:  %ld", peerID, (long)state);
    [[NSNotificationCenter defaultCenter] postNotificationName:kSessionChangedNotification object:nil];
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

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
//    NSLog(@"STREAM: %@  EVENT: %lu", aStream, (unsigned long)eventCode);
    if (NSStreamEventHasBytesAvailable == eventCode) {
        uint8_t buffer[1024];
        NSInteger length = 0;
        length = [(NSInputStream *)aStream read:buffer maxLength:1024];
        if (length) {
            
            if (-1 == self.imageSize) {
                // Adapted from http://stackoverflow.com/questions/4378218/how-do-i-convert-a-24-bit-integer-into-a-3-byte-array
                self.imageSize = ((int)buffer[3]) << 24;
                self.imageSize |= ((int)buffer[2]) << 16;
                self.imageSize |= ((int)buffer[1]) << 8;
                self.imageSize |= buffer[0];
                for (int idx = 4; idx < length; idx++) {
                    buffer[idx - 4] = buffer[idx];
                }
                length -= 4;
            }
            [self.imageData appendBytes:(const void *)buffer length:length];
        } else {
            NSLog(@"ZERO LENGTH!");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = (float)[self.imageData length] / (float)self.imageSize;
            self.progressView.progress = progress;
            NSLog(@"PROGRESS: %.2f", progress);
        });
//        NSLog(@"READ %ld  TOTAL %ld  MAX %ld", (long)length, [self.imageData length], self.imageSize);
    } else if (NSStreamEventEndEncountered == eventCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.hidden = YES;
            UIImage *image = [UIImage imageWithData:self.imageData];
            self.imageView.image = image;
            NSLog(@"IMAGE RECEIVED: %@", image);
            self.imageData = nil;
            [self.input close];
            [self.input removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        });
    }
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

- (BOOL)sendImage:(UIImage *)image
{
    UIImage *normalizedImage = [self normalizedImage:image];
    NSData *data = UIImagePNGRepresentation(normalizedImage);
    NSError *error = nil;
    self.output = [self.guestSession startStreamWithName:@"Image" toPeer:self.hostPeer error:&error];
    self.output.delegate = self;
    [self.output scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output open];
    
    // Adapted from http://stackoverflow.com/questions/4378218/how-do-i-convert-a-24-bit-integer-into-a-3-byte-array
    NSUInteger value = [data length];
    Byte bytes[4];
    bytes[0] = value & 0xff;
    bytes[1] = (value >> 8) & 0xff;
    bytes[2] = (value >> 16) & 0xff;
    bytes[3] = (value >> 24) & 0xff;
    [self.output write:bytes maxLength:4];
    
    [self.output write:[data bytes] maxLength:[data length]];
    NSLog(@"OUTPUT WRITTEN");
    [self.output close];
    [self.output removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    return YES;
}

@end
