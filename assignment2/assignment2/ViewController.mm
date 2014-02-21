//
//  ViewController.m
//  PlayRollingStones
//
//  Created by Eric Larson on 2/5/14.
//  Copyright (c) 2014 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUGraphHelper.h"
#import "SMUFFTHelper.h"


#define kBufferLength 4096

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *frequencyButton;


@end

@implementation ViewController

Novocaine *audioManager;
AudioFileReader *fileReader;
RingBuffer *ringBuffer;
GraphHelper *graphHelper;
float *audioData;

SMUFFTHelper *fftHelper;
float *fftMagnitudeBuffer;
float *fftPhaseBuffer;
float frequency = 16000.0; //starting frequency

float magAwayArray[10];
float magTowardArray[10];
float sumAway = 0;
float sumToward = 0;
float myAverage = 0;


#pragma mark - loading and appear
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    audioManager = [Novocaine audioManager];
    ringBuffer = new RingBuffer(kBufferLength,2);
    
    audioData = (float*)calloc(kBufferLength,sizeof(float));
    
    //setup the fft
    fftHelper = new SMUFFTHelper(kBufferLength,kBufferLength,WindowTypeRect);
    fftMagnitudeBuffer = (float *)calloc(kBufferLength/2,sizeof(float));
    fftPhaseBuffer     = (float *)calloc(kBufferLength/2,sizeof(float));
    
    
    // start animating the graph
    int framesPerSecond = 30;
    int numDataArraysToGraph = 2;
    graphHelper = new GraphHelper(self,
                                  framesPerSecond,
                                  numDataArraysToGraph,
                                  PlotStyleSeparated);//drawing starts immediately after call
    
    graphHelper->SetBounds(-0.9,0.9,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)
    
    
}

// action connected with slider to set frequency value
- (IBAction)sliderValue:(UISlider *)sender {
    frequency = sender.value;
    _frequencyButton.text = [NSString stringWithFormat:@"%.2f kHz",sender.value/1000];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    // still taking in audio with our set frequency
    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(ringBuffer!=nil)
             ringBuffer->AddNewFloatData(data, numFrames);
     }];
    
    
    __block float phase = 0.0;
    __block float samplingRate = audioManager.samplingRate;
    
    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         
         double phaseIncrement = 2*M_PI*frequency/samplingRate;
         double repeatMax = 2*M_PI;
         for (int i=0; i < numFrames; ++i)
         {
             for(int j=0;j<numChannels;j++){
                 data[i*numChannels+j] = 0.8*sin(phase);
                 
             }
             phase += phaseIncrement;
             
             if(phase>repeatMax)
                 phase -= repeatMax;
         }
         
         
     }];
    
}

#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    // stop opengl from running
    graphHelper->tearDownGL();
}

-(void)dealloc{
    graphHelper->tearDownGL();
    
    free(audioData);
    
    free(fftMagnitudeBuffer);
    free(fftPhaseBuffer);
    
    delete fftHelper;
    delete ringBuffer;
    delete graphHelper;
    
    ringBuffer = nil;
    fftHelper  = nil;
    audioManager = nil;
    graphHelper = nil;
    
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    
}

#pragma mark - OpenGL and Update functions
//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    graphHelper->draw(); // draw the graph
}


//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    // calculate index of the freq the slider is at, then open window by 10
    int index = (frequency * kBufferLength/audioManager.samplingRate);
    
    // plot the audio
    ringBuffer->FetchFreshData2(audioData, kBufferLength, 0, 1);
    graphHelper->setGraphData(0,audioData,kBufferLength); // set graph channel
    
    //take the FFT
    fftHelper->forward(0,audioData, fftMagnitudeBuffer, fftPhaseBuffer);
    
    // plot the FFT
    graphHelper->setGraphData(1,&fftMagnitudeBuffer[index-10],(kBufferLength/2)-index,sqrt(kBufferLength)); // set graph channel
    
    graphHelper->update(); // update the graph
    
    
    for (int i=9; i>-1; i--) {
        magAwayArray[i] = fftMagnitudeBuffer[index-i];
        sumAway = sumAway + magAwayArray[i];
    }
    for (int i=0;i<10;i++) {
        magTowardArray[i] = fftMagnitudeBuffer[index+i];
        sumToward = sumToward + magTowardArray[i];
    }
    myAverage = (sumAway/10)/(sumToward/10);
    NSLog(@"My average is %.2f",myAverage);
    
}

#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}

@end