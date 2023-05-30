#import "VBModule.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <spawn.h>
#import <pthread.h>
#import "../include/NSTask.h"


@implementation VBModule

// Most third-party Control Center modules out there use non-CAML approach because it's easier to get icon images than create CAML
// Choose either CAML and non-CAML portion of the code for your final implementation of the toggle
// IMPORTANT: To prepare your icons and configure the toggle to its fullest, check out CCSupport Wiki: https://github.com/opa334/CCSupport/wiki

#pragma mark - CAML approach

// CAML descriptor of your module (.ca directory)
// Read more about CAML here: https://medium.com/ios-creatix/apple-make-your-caml-format-a-public-api-please-9e10ba126e9d
- (CCUICAPackageDescription *)glyphPackageDescription {
    return [CCUICAPackageDescription descriptionForPackageNamed:@"VBModule" inBundle:[NSBundle bundleForClass:[self class]]];
}

#pragma mark - End CAML approach

#pragma mark - Non-CAML approach


// Icon of your module
- (UIImage *)iconGlyph {
    return [UIImage imageNamed:@"disabled" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

// Optional: Icon of your module, once selected 
- (UIImage *)selectedIconGlyph {
    return [UIImage imageNamed:@"enabled" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

// Selected color of your module
- (UIColor *)selectedColor {
    return [UIColor blackColor];
}

#pragma mark - End Non-CAML approach

// Current state of your module
- (BOOL)isSelected {
    return access("/var/jb/bin/bash", F_OK) != 0;
}

-(UIAlertController *)showProgress:(BOOL)selected{

    NSString *plzwait = @"";
    if(selected) plzwait = @"Hiding";
    else  plzwait = @"Revealing";
    plzwait = [NSString stringWithFormat:@"%@ files...", plzwait];


    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = keyWindow.rootViewController;
    UIAlertController *progressAlert = [UIAlertController alertControllerWithTitle:@"vnodebypass" message:plzwait preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView *progressActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [progressActivity startAnimating];
	[progressActivity setFrame:CGRectMake(0, 0, 70, 60)];
	[progressAlert.view addSubview:progressActivity];
	[rootViewController presentViewController:progressAlert animated:YES completion:nil];
    return progressAlert;
}

-(void)showAlert:(NSString *)title msg:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];

    [alertController addAction:okAction];

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = keyWindow.rootViewController;

    [rootViewController presentViewController:alertController
                                     animated:YES
                                   completion:nil];
}

- (void)setSelected:(BOOL)selected {

    UIAlertController *progressAlert = [self showProgress:selected];

    [progressAlert dismissViewControllerAnimated:YES completion:^{
    // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{

        

    //     dispatch_async(dispatch_get_main_queue(), ^{

            LSApplicationProxy* app = [LSApplicationProxy applicationProxyForIdentifier:@"kr.xsf1re.vnodebypass"];
            NSString *exec = app.bundleExecutable;
            NSString *execPath = [NSString stringWithFormat:@"/var/jb/usr/bin/%@", exec];
            
            

            pid_t pid;
            int status;
            if (selected) {
                const char* args[] = {exec.UTF8String, "-s", NULL};
                posix_spawn(&pid, execPath.UTF8String, NULL, NULL, (char* const*)args, NULL);
                waitpid(pid, &status, 0);
                sleep(1);

                const char* args2[] = {exec.UTF8String, "-h", NULL};
                posix_spawn(&pid, execPath.UTF8String, NULL, NULL, (char* const*)args2, NULL);
                waitpid(pid, &status, 0);
            } else {
                const char* args[] = {exec.UTF8String, "-r", NULL};
                posix_spawn(&pid, execPath.UTF8String, NULL, NULL, (char* const*)args, NULL);
                waitpid(pid, &status, 0);
                sleep(1);

                const char* args2[] = {exec.UTF8String, "-R", NULL};
                posix_spawn(&pid, execPath.UTF8String, NULL, NULL, (char* const*)args2, NULL);
                waitpid(pid, &status, 0);
            }

            [super refreshState];

            if(selected) {
                if(access("/var/jb/bin/bash", F_OK) == 0) {
                    [self showAlert:@"vnodebypass" msg:@"Failed to hide files, please install libkrw/libkernrw or try again in a minute. If the error persists, reboot."];
                } else {
                    [self showAlert:@"vnodebypass" msg:@"Successfully hide files."];
                }
            } else {
                if(access("/var/jb/bin/bash", F_OK) != 0) {
                    [self showAlert:@"vnodebypass" msg:@"Failed to reveal files, try again in a minute. If the error persists, reboot."];
                } else {
                    [self showAlert:@"vnodebypass" msg:@"Successfully revealed files."];
                }
            }
    //     });
    // });
    }];


    // if (selected) {
    //     // Your module turned selected/on, do something
    // } else {
    //     // Your module turned unselected/off, do something
    // }
}

@end
