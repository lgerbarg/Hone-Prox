//
//  LGAppDelegate.m
//  Hone Prox
//
//  Created by Louis Gerbarg on 7/2/13.
//  Copyright (c) 2013 Louis Gerbarg. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "LGHoneProxAppDelegate.h"

#pragma mark Convenience Block methods for sheets

@implementation NSApplication (SheetAdditions)

- (void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger returnCode))block {
  [self beginSheet:sheet
    modalForWindow:window
     modalDelegate:self
    didEndSelector:@selector(my_blockSheetDidEnd:returnCode:contextInfo:)
       contextInfo:(void *)CFBridgingRetain(block)];
}

- (void)my_blockSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  void (^block)(NSInteger returnCode) = CFBridgingRelease(contextInfo);
  block(returnCode);
}

@end

@implementation LGHoneProxAppDelegate {
  NSUserDefaults *_defaultsManager;
  NSURL *_entryActionURL;
  NSURL *_exitActionURL;
  NSString *_uuidString;
  float _sensitivitySliderValue;
  CBCentralManager *_central;
  CBCentralManagerState _centralState;
  CFUUIDRef _closestUUID;
  CFUUIDRef _activeUUID;
  NSInteger _closestUUIDStrength;
  NSInteger _activeUUIDStrength;
  BOOL _inRange;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _defaultsManager = [NSUserDefaults standardUserDefaults];
  [_defaultsManager registerDefaults:@{@"sensitivitySliderValue" : @-85}];
  _entryActionURL = [_defaultsManager URLForKey:@"entryActionURL"];
  _exitActionURL = [_defaultsManager URLForKey:@"exitActionURL"];
  _uuidString = [_defaultsManager stringForKey:@"uuidString"];
  _sensitivitySliderValue = [_defaultsManager floatForKey:@"sensitivitySliderValue"];
  [self updateDisplayedValues];
  
  _closestUUID = nil;
  self.pairingSheetUuidTextField.stringValue = @"00000000-0000-0000-0000-000000000000";
  
  //Start scanning for devices
  _central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
  _centralState = _central.state;
  
  if (_centralState == CBCentralManagerStatePoweredOn) {
    [_central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"1802"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
  }
}

#pragma mark -
#pragma mark CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  _centralState = _central.state;
  
  if (_centralState == CBCentralManagerStatePoweredOn) {
    [_central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"1802"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  CFUUIDRef UUID = peripheral.UUID;
  
  if (UUID != nil) {
    //UUID is not nil;
    
    if (_closestUUID == nil) {
      //No closest measured so far
      _closestUUID = UUID;
      CFRetain(_closestUUID);
      _closestUUIDStrength = RSSI.integerValue;
      self.pairingSheetUuidTextField.stringValue = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, _closestUUID));
    } else if (CFEqual(UUID, _closestUUID)) {
      //It is the closest device, update the strength;
      _closestUUIDStrength = RSSI.integerValue;
    } else {
      //It isn't the closest, check to see if it is stronger
      NSInteger newStrength = RSSI.integerValue;
      if (newStrength > _closestUUIDStrength) {
        //It is stronger, make it the new closest
        CFRelease(_closestUUID);
        _closestUUID = UUID;
        CFRetain(_closestUUID);
        _closestUUIDStrength = newStrength;
        self.pairingSheetUuidTextField.stringValue = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, _closestUUID));
      }
    }
  
    if (_activeUUID && CFEqual(UUID, _activeUUID)) {
      _activeUUIDStrength = RSSI.integerValue;
      if (!_inRange && (_sensitivitySliderValue < _activeUUIDStrength)) {
        _inRange = YES;
        if (_entryActionURL) {
          [[NSWorkspace sharedWorkspace] openURL:_entryActionURL];
        }
      } else if (_inRange && (_sensitivitySliderValue >= _activeUUIDStrength)) {
        _inRange = NO;
        if (_exitActionURL) {
          [[NSWorkspace sharedWorkspace] openURL:_exitActionURL];
        }
      }
      
      [self updateProximityIndicator];
    }
  } else {
    //The device does not have a UUID. We need to force a connect so that Mac OS will create one
    [_central connectPeripheral:peripheral options:nil];
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  //We don't want to actually do anything with the peripheral here
  [_central cancelPeripheralConnection:peripheral];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)entryActionPathControlChanged:(id)sender {
  _entryActionURL = self.entryActionPathControl.URL.fileReferenceURL;
  [self updateSavedValues];
}

- (IBAction)exitActionPathControlChanged:(id)sender {
  _exitActionURL = self.exitActionPathControl.URL.fileReferenceURL;
  [self updateSavedValues];
}

- (IBAction)pairButtonPressed:(id)sender {
  [NSApp beginSheet:self.pairingSheetWindow
     modalForWindow:self.window
  completionHandler:^(NSInteger returnCode){
    [self.pairingSheetWindow orderOut:self];
    if (returnCode == 0) {
      //Technically this could be racing a strenght update, but handling that greatly complicates example code
      _uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, _closestUUID));
      [self updateDisplayedValues];
      [self updateSavedValues];
    }
  }];
  
}

- (IBAction)sensititySliderChanged:(id)sender {
  _sensitivitySliderValue = self.sensitivitySlider.floatValue;
  
  [self updateProximityIndicator];
  [self updateSavedValues];
}

- (IBAction)pairingSheetPairButtonPressed:(id)sender {
  [NSApp endSheet:self.pairingSheetWindow returnCode:0];
}

- (IBAction)pairingSheetCancelButtonPressed:(id)sender {
  [NSApp endSheet:self.pairingSheetWindow returnCode:-1];
}

#pragma mark -
#pragma mark NSPathControlDelegate methods

- (NSDragOperation)pathControl:(NSPathControl *)pathControl validateDrop:(id <NSDraggingInfo>)info {
  NSDragOperation retval;
  
  NSURL *URL = [NSURL URLFromPasteboard:[info draggingPasteboard]];
  if (URL != nil) {
    retval = NSDragOperationCopy;
  } else {
    retval = NSDragOperationNone;
  }
  
  return retval;
}

-(BOOL)pathControl:(NSPathControl *)pathControl acceptDrop:(id <NSDraggingInfo>)info {
  BOOL result = NO;
  
  NSURL *URL = [NSURL URLFromPasteboard:[info draggingPasteboard]];
  if (URL != nil) {
    pathControl.URL = URL;
    result = YES;

    //Just reset them both
    
    _entryActionURL = self.entryActionPathControl.URL.fileReferenceURL;
    _exitActionURL = self.exitActionPathControl.URL.fileReferenceURL;
    
    [self updateSavedValues];
  }
  
  return result;
}

- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
  openPanel.resolvesAliases = YES;
  openPanel.canChooseDirectories = NO;
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseFiles = YES;
}

#pragma mark -
#pragma mark Utility methods

- (void)updateProximityIndicator {
  if (_sensitivitySliderValue < _closestUUIDStrength) {
    self.proximityIndicatorImageView.image = [NSImage imageNamed:@"green-large"];
  } else {
    self.proximityIndicatorImageView.image = [NSImage imageNamed:@"black-large"];
  }
}

- (void)updateDisplayedValues {
    if (_entryActionURL) {
        self.entryActionPathControl.URL = _entryActionURL.filePathURL;
    } else {
        self.entryActionPathControl.URL = nil;
    }
    
    if (_exitActionURL) {
        self.exitActionPathControl.URL = _exitActionURL.filePathURL;
    } else {
        self.exitActionPathControl.URL = nil;
    }
    
    if (_uuidString) {
        if (_activeUUID) {
            CFRelease(_activeUUID);
        }
        self.uuidTextField.stringValue = _uuidString;
        _activeUUID = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)(_uuidString));
    } else {
        self.uuidTextField.stringValue = @"00000000-0000-0000-0000-000000000000";
    }
    
    self.sensitivitySlider.floatValue = _sensitivitySliderValue;
    [self updateProximityIndicator];
}

- (void) updateSavedValues {
  [_defaultsManager setURL:_entryActionURL forKey:@"entryActionURL"];
  [_defaultsManager setURL:_exitActionURL forKey:@"exitActionURL"];
  [_defaultsManager setObject:_uuidString forKey:@"uuidString"];
  [_defaultsManager setFloat:_sensitivitySliderValue forKey:@"sensitivitySliderValue"];

  [_defaultsManager synchronize];
}

@end
