//
//  ViewController.m
//  Superwall-UIKit-ObjC
//
//  Created by Nest 22, Inc. on 11/1/22.
//

#import "SSAWelcomeViewController.h"

// categories
#import "UIViewController+SSAAdditions.h"

// constants
#import "SSAConstants.h"

// view controllers
#import "SSAHomeViewController.h"

// frameworks
@import SuperwallKit;

@interface SSAWelcomeViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIView *textFieldBackgroundView;
@property (nonatomic, strong) IBOutlet UITextField *textField;

@end

@implementation SSAWelcomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  if ([Superwall sharedInstance].isLoggedIn) {
    [self presentHomeViewController];
  }

  // Configure view.
  self.textFieldBackgroundView.layer.cornerRadius = CGRectGetHeight(self.textFieldBackgroundView.bounds) / 2.0;

  // Configure navigation controller.
  UINavigationBar.appearance.titleTextAttributes = SSAConstants.navigationBarTitleTextAttributes;
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
}

#pragma mark - Actions

- (IBAction)login:(id)sender {
  // Store the user's name.
  NSString *name = self.textField.text;

  id userAttributeFirstName = name ? : [NSNull null];
  [[Superwall sharedInstance] setUserAttributes:@{ @"firstName" : userAttributeFirstName }];

  // Perform a demo login to the account.
  [[Superwall sharedInstance] identifyWithUserId:@"abc"];
  [self presentHomeViewController];
}

#pragma mark - Private

- (void)presentHomeViewController {
  UIViewController *viewController = [SSAHomeViewController ssa_storyboardViewController];
  [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

@end
