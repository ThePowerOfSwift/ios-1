//
//  MotionViewController.m
//  MotionDemoSMU
//
//  Created by Eric Larson on 2/19/14.
//  Copyright (c) 2014 Eric Larson. All rights reserved.
//

#import "MotionViewController.h"
#import "APLGraphView.h"
#import <CoreMotion/CoreMotion.h>

@interface MotionViewController ()
@property (weak, nonatomic) IBOutlet UISlider *stepCountSlider;
@property (weak, nonatomic) IBOutlet APLGraphView *graphView;

@property (strong,nonatomic) CMStepCounter *cmStepCounter;
@property (strong,nonatomic) NSNumber *dailyStepGoal;
@property (weak, nonatomic) IBOutlet UILabel *labelForSteps;
@property (strong,nonatomic) CMMotionActivityManager *cmActivityManager;
@property (weak, nonatomic) IBOutlet UILabel *labelIsRunning;
@property (strong,nonatomic) CMMotionManager *cmDeviceMotionManager;

@end

@implementation MotionViewController

-(CMMotionManager*)cmDeviceMotionManager{
    if(!_cmDeviceMotionManager){
        _cmDeviceMotionManager = [[CMMotionManager alloc] init];
        
        if(![_cmDeviceMotionManager isDeviceMotionAvailable]){
            _cmDeviceMotionManager = nil;
        }
    }
    return _cmDeviceMotionManager;
    
}

-(CMMotionActivityManager*)cmActivityManager{
    if(!_cmActivityManager){
        if([CMMotionActivityManager isActivityAvailable])
            _cmActivityManager = [[CMMotionActivityManager alloc]init];
    }
    return _cmActivityManager;
}

-(CMStepCounter*)cmStepCounter{
    if(!_cmStepCounter){
        if([CMStepCounter isStepCountingAvailable]){
            _cmStepCounter = [[CMStepCounter alloc ] init];
        }
    }
    return _cmStepCounter;
}


-(NSNumber*)dailyStepGoal{
    if(!_dailyStepGoal){
        _dailyStepGoal = @(100);
    }
    return _dailyStepGoal;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.stepCountSlider.maximumValue = [self.dailyStepGoal floatValue];
    
    [self.cmStepCounter startStepCountingUpdatesToQueue:[NSOperationQueue mainQueue]
                                               updateOn:1
        withHandler:^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error) {
            if(!error){
                self.stepCountSlider.value = numberOfSteps;
                self.labelForSteps.text = [NSString stringWithFormat:@"Steps: %ld",(long)numberOfSteps];
            }
        }];
    
    [self.cmActivityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue]
            withHandler:^(CMMotionActivity *activity) {
                self.labelIsRunning.text = [NSString stringWithFormat:@"Running: %d",activity.running];
            }];
    [self startMotionUpdates];
}

-(void) startMotionUpdates{
    if(self.cmDeviceMotionManager){
        NSOperationQueue *myQueue = [[NSOperationQueue alloc] init];
        myQueue.maxConcurrentOperationCount = 1;
        [self.cmDeviceMotionManager setDeviceMotionUpdateInterval:1.0/100.0];
        [self.cmDeviceMotionManager
         startDeviceMotionUpdatesToQueue:myQueue
            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                
                float dotProduct =
                motion.gravity.x*motion.userAcceleration.x +
                motion.gravity.y*motion.userAcceleration.y +
                motion.gravity.z*motion.userAcceleration.z;
                
                dotProduct /= motion.gravity.x*motion.gravity.x +
                motion.gravity.y*motion.gravity.y +
                motion.gravity.z*motion.gravity.z;
                
                if(abs(dotProduct) > 0.8){
                    dispatch_async(dispatch_get_main_queue(),^{
                        [self.graphView addX:motion.userAcceleration.x
                                           y:motion.userAcceleration.y
                                           z:motion.userAcceleration.z];
                    });
                }
            }];
    }
}


















@end
