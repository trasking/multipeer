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

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate, CBCentralManagerDelegate, HostPartyTableViewControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *joinPartyButton;
@property (weak, nonatomic) IBOutlet UIButton *sendPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *hostPartyButton;

//@property (strong, nonatomic) MCPeerID *peer;
//@property (strong, nonatomic) MCPeerID *hostPeer;
//@property (strong, nonatomic) MCSession *hostSession;
//@property (strong, nonatomic) MCSession *guestSession;
//@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
//@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
//@property (strong, nonatomic) NSInputStream *input;
//@property (strong, nonatomic) NSOutputStream *output;

@property (strong, nonatomic) NSMutableData *imageDataReceived;
@property (assign, nonatomic) NSUInteger imageSizeExpected;
@property (strong, nonatomic) NSData *imageDataToSend;
@property (assign, nonatomic) NSUInteger imageBytesSent;
@property (strong, nonatomic) NSDate *sendStartTime;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *availablePeripherals;
@property (strong, nonatomic) NSMutableArray<CBPeripheral *> *connectedPeripherals;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableService *service;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic;

@end

@implementation ViewController

NSString * const kPeripheralsChangedNotification = @"kPeripheralsChangedNotification";
NSString * const kServiceType = @"sprocket";
NSString * const kServiceUUID = @"3605946E-9BBB-4366-9369-06B7D4412927";
NSString * const kCharacteristicUUID = @"815DCE0B-2A67-415F-B2A4-10E0221AE541";
NSUInteger const kMaxChunkSize = 1024;

- (void)viewDidLoad {
    [super viewDidLoad];
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
        vc.availablePeripherals = self.availablePeripherals;
        vc.connectedPeripherals = self.connectedPeripherals;
        vc.delegate = self;
    }
}

#pragma mark - Button handlers

- (IBAction)sendPhotoTapped:(id)sender {
    NSString *value = @"DUDE!!";
    [self.peripheralManager updateValue:[value dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
//    
//    
//    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
//    imagePickerController.delegate = self;
//    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)joinPartyButtonHandler:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.joinPartyButton.titleLabel.text isEqualToString:@"Join Party"]) {
            [self startAdvertising];
            [self.joinPartyButton setTitle:@"Ready to Party" forState:UIControlStateNormal];
        } else if ([self.joinPartyButton.titleLabel.text isEqualToString:@"Ready to Party"]) {
            [self.peripheralManager stopAdvertising];
            [self.joinPartyButton setTitle:@"Join Party" forState:UIControlStateNormal];
        } else {
            [self.peripheralManager stopAdvertising];
            [self.joinPartyButton setTitle:@"Join Party" forState:UIControlStateNormal];
            self.sendPhotoButton.hidden = YES;
        }
    });
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"PHOTO: %@", info);
    [self dismissViewControllerAnimated:YES completion:^{
        [self sendImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)setHostPartyButtonText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = @"Host Party";
        if (self.connectedPeripherals.count > 0) {
            text = [NSString stringWithFormat:@"Hosting Party (%lu)", (unsigned long)self.connectedPeripherals.count];
        }
        [self.hostPartyButton setTitle:text forState:UIControlStateNormal];
    });
}

- (BOOL)sendImage:(UIImage *)image
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.progressView.progress = 0.0;
//        self.progressView.hidden = NO;
//    });
//    UIImage *normalizedImage = [self normalizedImage:image];
//    self.imageDataToSend = UIImagePNGRepresentation(normalizedImage);
//    self.imageBytesSent = 0;
//    self.sendStartTime = [NSDate date];
//    NSError *error = nil;
//    self.output = [self.guestSession startStreamWithName:@"Image" toPeer:self.hostPeer error:&error];
//    self.output.delegate = self;
//    [self.output scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    [self.output open];
//    
//    // Adapted from http://stackoverflow.com/questions/4378218/how-do-i-convert-a-24-bit-integer-into-a-3-byte-array
//    NSUInteger value = [self.imageDataToSend length];
//    Byte bytes[4];
//    bytes[0] = value & 0xff;
//    bytes[1] = (value >> 8) & 0xff;
//    bytes[2] = (value >> 16) & 0xff;
//    bytes[3] = (value >> 24) & 0xff;
//    [self.output write:bytes maxLength:4];
    
    return YES;
}

#pragma mark - Bluetooth

- (void)setupBluetooth
{
    self.availablePeripherals = [NSMutableArray array];
    self.connectedPeripherals = [NSMutableArray array];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
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

- (void)startScanning
{
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    [self.centralManager scanForPeripheralsWithServices:@[ serviceUUID ] options:nil];
}

- (void)notifyPeripheralsChanged
{
   [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralsChangedNotification object:self userInfo:@{ @"availablePeripherals": self.availablePeripherals,   @"connectedPeripherals": self.connectedPeripherals }];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"CENTRAL STATE: %ld", central.state);
    if (CBManagerStatePoweredOn == central.state) {
        self.hostPartyButton.enabled = YES;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"DISCOVERED PERIPHERAL: %@\nADVERTISEMENT DATA: %@\nRSSI: %@", peripheral, advertisementData, RSSI);
    if (![self.availablePeripherals containsObject:peripheral]) {
        [self.availablePeripherals addObject:peripheral];
    }
    [self notifyPeripheralsChanged];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"CONNECTED PERIPHERAL: %@", peripheral);
    peripheral.delegate = self;
    [self.availablePeripherals removeObject:peripheral];
    [self.connectedPeripherals addObject:peripheral];
    [self notifyPeripheralsChanged];
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    [peripheral discoverServices:@[ serviceUUID ]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"FAILED TO CONNECT PERIPHERAL: %@\nERROR: %@", peripheral, error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"DISCONNECTED PERIPHERAL: %@\nERROR: %@", peripheral, error);
    [self.connectedPeripherals removeObject:peripheral];
    [self setHostPartyButtonText];
    [self notifyPeripheralsChanged];
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict {}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"PERIPHERAL STATE CHANGE: %ld", (long)peripheral.state);
    if (CBManagerStatePoweredOn == peripheral.state && !self.service) {
        self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kCharacteristicUUID] properties:CBCharacteristicPropertyRead + CBCharacteristicPropertyIndicate value:nil permissions:CBAttributePermissionsReadable];
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kServiceUUID] primary:YES];
        self.service.characteristics = @[ self.characteristic ];
        [self.peripheralManager addService:self.service];
        self.joinPartyButton.enabled = YES;
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

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    NSLog(@"RESTORE STATE: %@", dict);
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"CENTRAL SUBSCRIBED: %@", characteristic);
    self.characteristic = characteristic;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sendPhotoButton.hidden = NO;
    });
}

//- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {}
//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {}
//- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"DISCOVERED SERVICES: %@\nERROR: %@", peripheral.services, error);
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    [peripheral discoverCharacteristics:@[ characteristicUUID ] forService:peripheral.services[0]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    NSLog(@"DISCOVERED CHARACTERISTICS: %@\nERROR: %@", service.characteristics, error);
    [peripheral setNotifyValue:YES forCharacteristic:service.characteristics[0]];
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    [self notifyPeripheralsChanged];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"UPDATE NOTIFICATION: %@\nERROR: %@", characteristic, error);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"UPDATE VALUE: %@\nERROR: %@", characteristic.value, error);
}

#pragma mark - HostPartyTableViewControllerDelegate

- (void)startHosting
{
    [self startScanning];
}

- (void)stopHosting
{
    [self.centralManager stopScan];
}

- (void)didRequestConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager connectPeripheral:peripheral options:nil];
}

@end
