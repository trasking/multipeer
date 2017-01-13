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
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, NSStreamDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

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
@property (strong, nonatomic) NSMutableData *imageDataReceived;
@property (assign, nonatomic) NSUInteger imageSizeExpected;
@property (strong, nonatomic) NSData *imageDataToSend;
@property (assign, nonatomic) NSUInteger imageBytesSent;
@property (strong, nonatomic) NSDate *sendStartTime;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableService *service;

@end

@implementation ViewController

NSString * const kSessionChangedNotification = @"kSessionChangedNotification";
NSString * const kServiceType = @"sprocket";
NSString * const kServiceUUID = @"3605946E-9BBB-4366-9369-06B7D4412927";
NSString * const kCharacteristicUUID = @"815DCE0B-2A67-415F-B2A4-10E0221AE541";
NSUInteger const kMaxChunkSize = 1024;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupConnectivity];
    [self setupBluetooth];
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
            [self startAdvertising];
            // MPC [self.advertiser startAdvertisingPeer];
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
    self.imageDataReceived = [NSMutableData data];
    self.imageSizeExpected = -1;
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
            
            if (-1 == self.imageSizeExpected) {
                // Adapted from http://stackoverflow.com/questions/4378218/how-do-i-convert-a-24-bit-integer-into-a-3-byte-array
                self.imageSizeExpected = ((int)buffer[3]) << 24;
                self.imageSizeExpected |= ((int)buffer[2]) << 16;
                self.imageSizeExpected |= ((int)buffer[1]) << 8;
                self.imageSizeExpected |= buffer[0];
                for (int idx = 4; idx < length; idx++) {
                    buffer[idx - 4] = buffer[idx];
                }
                length -= 4;
            }
            [self.imageDataReceived appendBytes:(const void *)buffer length:length];
        } else {
            NSLog(@"ZERO LENGTH!");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = (float)[self.imageDataReceived length] / (float)self.imageSizeExpected;
            self.progressView.progress = progress;
            NSLog(@"PROGRESS: %.2f", progress);
        });
    } else if (NSStreamEventHasSpaceAvailable == eventCode) {
        NSUInteger bytesRemaining = [self.imageDataToSend length] - self.imageBytesSent;
        NSUInteger chunk = bytesRemaining > kMaxChunkSize ? kMaxChunkSize : bytesRemaining;
        [self.output write:[self.imageDataToSend bytes] + self.imageBytesSent maxLength:chunk];
        self.imageBytesSent += chunk;
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = (float)self.imageBytesSent / (float)[self.imageDataToSend length];
            self.progressView.progress = progress;
            NSTimeInterval elapsedTime = [self.sendStartTime timeIntervalSinceNow];
            NSLog(@"%.2f byte/sec", (float)self.imageBytesSent / (float)elapsedTime * -1);
            if (self.imageBytesSent >= [self.imageDataToSend length]) {
                self.progressView.hidden = YES;
                [self.output close];
                [self.output removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            }
        });
    } else if (NSStreamEventEndEncountered == eventCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.hidden = YES;
            UIImage *image = [UIImage imageWithData:self.imageDataReceived];
            self.imageView.image = image;
            self.imageDataReceived = nil;
            [self.input close];
            [self.input removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        });
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"PERIPHERAL STATE CHANGE: %ld", (long)peripheral.state);
    if (CBManagerStatePoweredOn == peripheral.state && !self.service) {
        CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kCharacteristicUUID] properties:CBCharacteristicPropertyRead + CBCharacteristicPropertyIndicate value:nil permissions:CBAttributePermissionsReadable];
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kServiceUUID] primary:YES];
        self.service.characteristics = @[ characteristic ];
        [self.peripheralManager addService:self.service];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error
{
    NSLog(@"SERVICE ADDED: %@\nERROR: %@", service, error);
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error
{
    NSLog(@"STARTED ADVERTISING: %@", error);
}


//- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {}
//- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {}

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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = 0.0;
        self.progressView.hidden = NO;
    });
    UIImage *normalizedImage = [self normalizedImage:image];
    self.imageDataToSend = UIImagePNGRepresentation(normalizedImage);
    self.imageBytesSent = 0;
    self.sendStartTime = [NSDate date];
    NSError *error = nil;
    self.output = [self.guestSession startStreamWithName:@"Image" toPeer:self.hostPeer error:&error];
    self.output.delegate = self;
    [self.output scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output open];
    
    // Adapted from http://stackoverflow.com/questions/4378218/how-do-i-convert-a-24-bit-integer-into-a-3-byte-array
    NSUInteger value = [self.imageDataToSend length];
    Byte bytes[4];
    bytes[0] = value & 0xff;
    bytes[1] = (value >> 8) & 0xff;
    bytes[2] = (value >> 16) & 0xff;
    bytes[3] = (value >> 24) & 0xff;
    [self.output write:bytes maxLength:4];
    
    return YES;
}

#pragma mark - Bluetooth

- (void)setupBluetooth
{
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
}

- (void)startAdvertising
{
    NSDictionary *advertisingData = @{
        CBAdvertisementDataLocalNameKey: @"Sprocket",
        CBAdvertisementDataServiceUUIDsKey: @[ self.service.UUID ]
    };
    [self.peripheralManager startAdvertising:advertisingData];
}



@end
