//
//  ViewController.m
//  蓝牙4.0
//
//  Created by apple on 2018/1/9.
//  Copyright © 2018年 zjbojin. All rights reserved.
//

#import "ViewController.h"
#import "PeripheralCell.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>

static NSString *const kPeripheralCellID = @"peripheralCellID";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate,CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

//中心管理对象
@property(nonatomic,strong)CBCentralManager *centralManager;

//蓝牙的状态
@property(nonatomic,assign)CBManagerState bluetoothState;

//扫描到的外设数组
@property(nonatomic,strong)NSMutableArray *peripheralsArray;

//已连接的外设
@property(nonatomic,strong)CBPeripheral *connectedPeripheral;

//写数据的特征
@property(nonatomic,strong)CBCharacteristic *writeToCharacteristic;

//开启定时器读取RSSI
@property(nonatomic,strong)NSTimer *timerForRSSI;

@end

@implementation ViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*option参数
     
     1.CBCentralManagerOptionShowPowerAlertKey--->key值是NSNumber(Boolean),默认为NO,当蓝牙处于关闭状态(CBManagerStatePoweredOff)时是否显示Alert提示框(经测试无效,无法弹出提示框,并且iOS10后点击"好"不会跳转设置,所以最好自定义提示框)
     
     2.CBCentralManagerOptionRestoreIdentifierKey--->UUID字符串,当central管理对象被实例化时分配的UUID,这个UUID相当重要,当central被修复时要相同(用来蓝牙的恢复连接的,在后台的长连接中可能会用到,非后台模式写该键-值会报错)
     
     */
    
    //queue为nil则在主线程中进行
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey : @YES, CBCentralManagerOptionRestoreIdentifierKey:@"indentifier"}];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PeripheralCell" bundle:nil] forCellReuseIdentifier:kPeripheralCellID];
    self.tableView.rowHeight = 50;
 
    self.peripheralsArray = [[NSMutableArray alloc] init];
    
}

#pragma mark - Actions
//开始扫描外设
- (IBAction)startScanPerpheral:(id)sender {
    
    if (self.bluetoothState == CBManagerStatePoweredOn) {
        //扫描前先停止扫描
        [self.centralManager stopScan];
        
        /*option中的参数
         1.CBCentralManagerScanOptionAllowDuplicatesKey--->key值是NSNumber(Boolean),默认为NO表示不会重复扫描已经发现的设备,如需要不断获取最新的信号强度RSSI就需要设置成YES(即为YES时每次都会接受到来自peripherals的广播数据包,对电池寿命有影响)
         
         2.CBCentralManagerScanOptionSolicitedServiceUUIDsKey--->key值是数组(存储CBUUID),只扫描数组里面的serviceUUID
         
        */
        
        //第一个参数CBUUID数组,用于搜索特定标示的设备,过滤掉其他设备
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        
        [SVProgressHUD showWithStatus:@"正在扫描..."];
    }
    
}

//停车扫描
- (IBAction)stopScanPeripheral:(id)sender {
    
    if (self.bluetoothState == CBManagerStatePoweredOn) {
        [self.centralManager stopScan];
        [SVProgressHUD dismiss];
    }
    
}

//开始连接设备
- (void)startConnectPeripheral:(CBPeripheral *)peripheral {
    /*options参数:(当有多个App同时请求通知时,离前台最近的一个App才会显示。若开启了蓝牙后台模式就不会有提示)
    1.CBConnectPeripheralOptionNotifyOnConnectionKey--->key值是NSNumber(Boolean),默认为NO,在程序被挂起时,连接成功时是否显示Alert提示框
    
    2.CBConnectPeripheralOptionNotifyOnDisconnectionKey--->key值是NSNumber(Boolean),默认为NO,在程序被挂起时,断开连接时是否显示Alert提示框
    
    3.CBConnectPeripheralOptionNotifyOnNotificationKey--->key值是NSNumber(Boolean),默认NO,在程序被挂起时,是否显示所有的提醒消息(即连接成功、断开连接、接受到外设的数据时都会显示提示框)
    */
     
    [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnNotificationKey:@YES}];
    
    [SVProgressHUD showWithStatus:@"正在连接..."];
    
}

//断开连接
- (IBAction)disconnect:(id)sender {
    
    [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    [self.tableView reloadData];
    
}

//写数据
- (IBAction)writeData:(id)sender {
    
    /*写数据(UUID一般由硬件端给的,此处用于测试)
     
     1.CBCharacteristicWriteWithResponse--->写数据后调用didWriteValueForCharacteristic代理方法判断是否写成功;回馈的数据会调用didUpdateValueForCharacteristic代理方法,可以在该代理方法中获取到回馈信息
     
     2.CBCharacteristicWriteWithoutResponse--->无回馈信息,中心只管写,不处理是否写成功
     
     */
    
    [self.connectedPeripheral writeValue:[self hexString:@"哈哈"] forCharacteristic:self.writeToCharacteristic type:CBCharacteristicWriteWithoutResponse];
    
}



-(NSData *)hexString:(NSString *)hexString {
    int j=0;
    Byte bytes[20];
    ///3ds key的Byte 数组， 128位
    for(int i=0; i<[hexString length]; i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        NSLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:20];
    
    return newData;
}

- (void)startRSSITimer {
    
    self.timerForRSSI = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(readRSSI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timerForRSSI forMode:NSRunLoopCommonModes];
    
}

- (void)readRSSI {
    
    [self.connectedPeripheral readRSSI];
    [self.tableView reloadData];
}


#pragma mark - CBCentralManagerDelegate
//当初始化CBCentralManager对象、蓝牙状态改变时调用
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@"未知的状态");
            break;
            
        case CBManagerStateResetting:
            NSLog(@"重置状态");
            break;
            
        case CBManagerStateUnsupported:
            NSLog(@"不支持蓝牙");
            break;
            
        case CBManagerStateUnauthorized:
            NSLog(@"未授权的状态");
            break;
            
        case CBManagerStatePoweredOff:
            NSLog(@"蓝牙关闭的状态");
            break;
            
        case CBManagerStatePoweredOn:
            NSLog(@"蓝牙开启的状态");
            break;
    }
    
    self.bluetoothState = central.state;
    
}


/**
 扫描到一个外设时调用

 @param central 中心管理对象
 @param peripheral 扫描到的外设
 @param advertisementData 广播数据
 @param RSSI 蓝牙信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //判断扫描到的外设是否已经存在,若存在则替换
    BOOL isExit = NO;
    for (int i = 0; i < self.peripheralsArray.count; i++) {
        CBPeripheral *p = self.peripheralsArray[i];
        if ([peripheral isEqual:p]) {
            [self.peripheralsArray replaceObjectAtIndex:i withObject:peripheral];
            [self.tableView reloadData];
            isExit = YES;
        }
    }
    
    //若不存在则添加到列表中
    if (!isExit) {
        [self.peripheralsArray addObject:peripheral];
        [self.tableView reloadData];
    }
    
}

//连接外设成功时回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [SVProgressHUD dismiss];
    [self.tableView reloadData];
    
    //赋值
    self.connectedPeripheral = peripheral;
    //连接成功后扫描服务
    peripheral.delegate = self;
    //可以扫描部分或全部服务,nil即代表扫描全部服务
    [peripheral discoverServices:nil];
    //读取RSSI
    [self startRSSITimer];
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    if (!error) {
        NSLog(@"RSSI--->%@",RSSI);
    } else {
        NSLog(@"读取RSSI错误:%@",error);
    }
}

//连接外设失败时回调
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [SVProgressHUD showErrorWithStatus:@"连接失败"];
    [SVProgressHUD dismissWithDelay:1];
    
}

//扫描到外设的服务时回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (!error) {
        
        //遍历所有的服务
        for (CBService *service in peripheral.services) {
//            NSLog(@"%@",service);
//            NSLog(@"%@",service.UUID.UUIDString);
            //扫描服务的特征
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
    }
}

//扫描到服务的特征时回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (!error) {
        
        //循环遍历服务的所有特征
        for (CBCharacteristic *characteristic in service.characteristics) {
//            NSLog(@"%@",characteristic);
//            NSLog(@"%@",characteristic.UUID.UUIDString);
            
            if ([characteristic.UUID.UUIDString isEqualToString:@"8667556C-9A37-4C91-84ED-54EE27D90049"]) {
                
                self.writeToCharacteristic = characteristic;
                
            }
            
            //读数据(UUID一般由硬件端给的,此处读取电池电量用于测试)
            if ([characteristic.UUID.UUIDString isEqualToString:@"2A19"]) {
     
                //直接读取
                [peripheral readValueForCharacteristic:characteristic];
                
            }
            //AF0BADB1-5B99-43CD-917A-A77BC549E3CC
            if ([characteristic.UUID.UUIDString isEqualToString:@"8667556C-9A37-4C91-84ED-54EE27D90049"]) {
        
                //订阅(监听通知),订阅成功该特征后,在特征的值改变时,外设会通知中心,每次值改变就会调用didUpdateValueForCharacteristic代理
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
            }
        }
    }
}

//收到读请求时调用,只要调用readValueForCharacteristic方法后就会回调(不管是read和notify,获取数据都是从这个方法中读取)
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!error) {
        //数据为hex值
        NSLog(@"接受到的数据:%@",characteristic.value);
       
    } else {
        
        NSLog(@"接受数据失败:%@",error);
        
    }
    
    //写数据后在此处得到回馈的数据
    
}

//收到写请求并请求方式为CBCharacteristicWriteWithResponse时调用
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!error) {
        NSLog(@"写入数据成功");
    } else {
        NSLog(@"写入数据失败:%@",error);
    }
    
}


//中心读取订阅状态(通知状态isNotifying改变、订阅setNotifyValue、取消订阅都会调用该方法)
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (characteristic.isNotifying) {
        NSLog(@"正在通知状态");
    } else {
        NSLog(@"未在通知状态");
        //可以取消订阅
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
    }

}

/**
 当一个连接的外设断开时调用

 @param central 中心管理者
 @param peripheral 断开连接的外设
 @param error 错误信息
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  
    NSLog(@"连接已断开:%@",error);
    [self.tableView reloadData];
    //关闭定时器
    if (self.timerForRSSI) {
        [self.timerForRSSI invalidate];
        self.timerForRSSI = nil;
    }
    
}

//在进程于后台被杀掉时，重连之后会首先调用此方法，可以获取蓝牙恢复时的各种状态
- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSLog(@"%@",central);
    NSLog(@"蓝牙恢复连接");
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.peripheralsArray.count;

    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PeripheralCell *cell = [tableView dequeueReusableCellWithIdentifier:kPeripheralCellID forIndexPath:indexPath];
    
    CBPeripheral *peripheral = self.peripheralsArray[indexPath.row];
    //外设名字
    cell.peripheralName.text = peripheral.name;
    //连接状态
    if (peripheral.state == CBPeripheralStateConnected) {
        cell.connectState.text = @"已连接";
    } else {
        cell.connectState.text = @"未连接";
    }
    
    return cell;
    
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self startConnectPeripheral:self.peripheralsArray[indexPath.row]];
    
}

@end
