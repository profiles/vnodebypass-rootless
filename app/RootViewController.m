#import "RootViewController.h"
#import <spawn.h>

@interface RootViewController ()
@end

@implementation RootViewController

- (void)loadView {
  [super loadView];

  self.view.backgroundColor = UIColor.blackColor;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(0, 50, UIScreen.mainScreen.bounds.size.width, 100)];
  _titleLabel.text = @"vnodebypass";
  _titleLabel.textAlignment = NSTextAlignmentCenter;
  _titleLabel.textColor = UIColor.whiteColor;
  _titleLabel.font = [UIFont systemFontOfSize:40];
  [self.view addSubview:_titleLabel];

  _subtitleLabel = [[UILabel alloc]
      initWithFrame:CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 100)];
  _subtitleLabel.text = @"USE IT AT YOUR OWN RISK!";
  _subtitleLabel.textAlignment = NSTextAlignmentCenter;
  _subtitleLabel.textColor = UIColor.whiteColor;
  _subtitleLabel.font = [UIFont systemFontOfSize:20];
  [self.view addSubview:_subtitleLabel];

  _button = [UIButton buttonWithType:UIButtonTypeSystem];
  _button.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width / 2 - 30,
                             UIScreen.mainScreen.bounds.size.height / 2 - 25, 60, 50);
  [_button setTitle:access("/var/jb/bin/bash", F_OK) == 0 ? @"Enable" : @"Disable"
           forState:UIControlStateNormal];
  [_button addTarget:self
                action:@selector(buttonPressed:)
      forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_button];
}

-(void)waitUntilDone:(pid_t)pid{
  siginfo_t info;
  while (waitid(P_PID, pid, &info, WEXITED | WSTOPPED | WCONTINUED) == -1) {
    if (errno != EINTR) {
      break;
    }
  }

  if (info.si_code == CLD_EXITED) {
    // int exit_status = info.si_status;
  } else if (info.si_code == CLD_KILLED) {
    // int signal_number = info.si_status;
  }
}

- (void)buttonPressed:(UIButton *)sender {
  BOOL disabled = access("/var/jb/bin/bash", F_OK) == 0;
  
  NSString *launchPath = [NSString stringWithFormat:@"/var/jb/usr/bin/%@", NSProcessInfo.processInfo.processName];

  pid_t pid;

  if(disabled) {
    const char* args[] = {NSProcessInfo.processInfo.processName.UTF8String, "-s", NULL};
    posix_spawn(&pid, [launchPath UTF8String], NULL, NULL, (char* const*)args, NULL);
    [self waitUntilDone:pid];

    const char* args2[] = {NSProcessInfo.processInfo.processName.UTF8String, "-h", NULL};
    posix_spawn(&pid, [launchPath UTF8String], NULL, NULL, (char* const*)args2, NULL);
    [self waitUntilDone:pid];
  } else {
    const char* args[] = {NSProcessInfo.processInfo.processName.UTF8String, "-r", NULL};
    posix_spawn(&pid, [launchPath UTF8String], NULL, NULL, (char* const*)args, NULL);
    [self waitUntilDone:pid];

    const char* args2[] = {NSProcessInfo.processInfo.processName.UTF8String, "-R", NULL};
    posix_spawn(&pid, [launchPath UTF8String], NULL, NULL, (char* const*)args2, NULL);
    [self waitUntilDone:pid];
  }

  NSString *title = access("/var/jb/bin/bash", F_OK) == 0 ? @"Enable" : @"Disable";
  NSString *successTitle = (access("/var/jb/bin/bash", F_OK) == 0) == disabled ? @"Failed" : @"Success";
  [_button setTitle:successTitle forState:UIControlStateNormal];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    sleep(1);
    dispatch_async(dispatch_get_main_queue(), ^{
      [_button setTitle:title forState:UIControlStateNormal];
    });
  });
}

@end
