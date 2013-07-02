//
//  LGAppDelegate.h
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

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface LGHoneProxAppDelegate : NSObject <NSApplicationDelegate, NSPathControlDelegate, CBCentralManagerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPathControl *entryActionPathControl;
@property (weak) IBOutlet NSPathControl *exitActionPathControl;
@property (weak) IBOutlet NSTextField *uuidTextField;
@property (weak) IBOutlet NSSlider *sensitivitySlider;
@property (weak) IBOutlet NSImageView *proximityIndicatorImageView;
@property (strong) IBOutlet NSWindow *pairingSheetWindow;
@property (weak) IBOutlet NSTextField *pairingSheetUuidTextField;
- (IBAction)entryActionPathControlChanged:(id)sender;
- (IBAction)exitActionPathControlChanged:(id)sender;

- (IBAction)pairButtonPressed:(id)sender;
- (IBAction)sensititySliderChanged:(id)sender;
- (IBAction)pairingSheetPairButtonPressed:(id)sender;
- (IBAction)pairingSheetCancelButtonPressed:(id)sender;

@end
