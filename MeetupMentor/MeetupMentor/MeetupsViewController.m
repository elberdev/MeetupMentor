//
//  MeetupsViewController.m
//  MeetupMentor
//
//  Created by Daniel Distant on 10/31/15.
//  Copyright © 2015 Elber Carneiro. All rights reserved.
//

#import "MeetupsViewController.h"

#import "MeetupManager.h"
#import "MeetupDataObject.h"
#import "MeetupDetailViewController.h"

#import <CoreLocation/CoreLocation.h>


@interface MeetupsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UITextField* textField;

@property (nonatomic) NSMutableArray<MeetupDataObject*>* meetupResultsArray;

@property (nonatomic) CLLocationManager* locationManager;
@property (nonatomic) CLLocation* currentLocation;
@property (weak, nonatomic) IBOutlet UIImageView *crumpledImageView;


@end

@implementation MeetupsViewController

- (void)viewDidLoad

{
    [super viewDidLoad];
    
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.textField.delegate = self;
    
    self.textField.layer.borderColor = [UIColor colorWithRed:225/255.0 green:57/255.0 blue:66/255.0 alpha:1].CGColor;
    self.textField.layer.borderWidth = 2.0;
    self.textField.layer.cornerRadius = 10.0;

    
}

#pragma mark CoreLocation

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations

{
    self.currentLocation = locations.lastObject;
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    UIAlertView* errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"There was a problem in updating your location"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
    
    [errorAlertView show];
    
    
}




#pragma mark TableViewDataSource Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section

{
    
    return self.meetupResultsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MeetupCell" forIndexPath:indexPath];
    
    
    cell.textLabel.text = self.meetupResultsArray[indexPath.row].meetupGroupName;
    cell.layer.backgroundColor = [UIColor clearColor].CGColor;
    cell.backgroundColor = [UIColor clearColor];
    
    
    return cell;
    
}

#pragma mark TableViewDelegate Method


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath

{
    
    MeetupDetailViewController* detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MeetupDetailViewController"];
    
    detailViewController.meetupDataObject = self.meetupResultsArray[indexPath.row];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    
    
}
#pragma mark TextFieldDelegate Method

-(BOOL)textFieldShouldReturn:(UITextField *)textField

{
    
    [textField endEditing:YES];
    
    NSString* formattedString = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    [MeetupManager fetchMeetupsForParameters:@{@"text" : formattedString,
                                               @"lat" : [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.latitude],
                                               @"lon" : [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.longitude]
                                                }
                         withCompletionBlock:^(id response, NSError *error) {
        
        
        
        self.meetupResultsArray = [[NSMutableArray alloc]init];
        
        for(NSDictionary* result in response){
            
            
            MeetupDataObject* dataObject = [[MeetupDataObject alloc]init];
            dataObject.meetupGroupName = result[@"name"];
            NSAttributedString* descriptionWithHTMLStripping = [[NSAttributedString alloc] initWithData:[result[@"description"] dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
            
            dataObject.meetupGroupDescription = [descriptionWithHTMLStripping string];
            dataObject.meetupImageURL = result[@"group_photo"][@"photo_link"];

            
            [self.meetupResultsArray addObject:dataObject];
            
        }
        
        [self.tableView reloadData];
    }];
    
    
    return YES;
}


@end
