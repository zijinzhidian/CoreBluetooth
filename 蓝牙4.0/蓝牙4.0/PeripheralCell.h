//
//  PeripheralCell.h
//  蓝牙4.0
//
//  Created by apple on 2018/1/9.
//  Copyright © 2018年 zjbojin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeripheralCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *peripheralName;
@property (weak, nonatomic) IBOutlet UILabel *connectState;
@property (weak, nonatomic) IBOutlet UILabel *RSSI;

@end
