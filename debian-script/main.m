#import <Foundation/Foundation.h>
#import <NSTask.h>
#include <stdio.h>

int main(int argc, char *argv[], char *envp[]) {
  @autoreleasepool {
    NSTask *task = [NSTask new];
    task.launchPath = @"/var/jb/usr/bin/uicache";

    BOOL isRemoving = [NSProcessInfo.processInfo.processName containsString:@"prerm"];
    BOOL isUpgrading = strstr(argv[1], "upgrade");

    if (isRemoving || isUpgrading) {
      NSArray *fileList =
          [[NSString stringWithContentsOfFile:@"/var/jb/var/lib/dpkg/info/kr.xsf1re.vnodebypass.list"
                                     encoding:NSUTF8StringEncoding
                                        error:nil] componentsSeparatedByString:@"\n"];
      NSInteger appPathIndex =
          [fileList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj hasSuffix:@".app"];
          }];
      if (appPathIndex != NSNotFound) {
        task.arguments = @[ @"-u", fileList[appPathIndex] ];
        [task launch];
        [task waitUntilExit];
      } else {
        printf("Could not find vnodebypass.app, skipping uicache\n");
      }
      if (isRemoving) return 0;
    }

    NSString *randomName = [[NSUUID UUID].UUIDString componentsSeparatedByString:@"-"].firstObject;

    NSMutableDictionary *appInfo = [NSMutableDictionary
        dictionaryWithContentsOfFile:@"/var/jb/Applications/vnodebypass.app/Info.plist"];
    appInfo[@"CFBundleExecutable"] = randomName;
    [appInfo writeToFile:@"/var/jb/Applications/vnodebypass.app/Info.plist" atomically:YES];

    NSMutableDictionary *moduleInfo = [NSMutableDictionary
        dictionaryWithContentsOfFile:@"/var/jb/Library/ControlCenter/Bundles/VBModule.bundle/Info.plist"];
    moduleInfo[@"CFBundleExecutable"] = randomName;
    [moduleInfo writeToFile:@"/var/jb/Library/ControlCenter/Bundles/VBModule.bundle/Info.plist" atomically:YES];

    NSArray *renames = @[
      @[ @"/var/jb/usr/bin/vnodebypass", @"/var/jb/usr/bin/%@" ],
      @[ @"/var/jb/Applications/vnodebypass.app/vnodebypass", @"/var/jb/Applications/vnodebypass.app/%@" ],
      @[ @"/var/jb/Applications/vnodebypass.app", @"/var/jb/Applications/%@.app" ],
      @[ @"/var/jb/usr/share/vnodebypass", @"/var/jb/usr/share/%@" ],
      @[ @"/var/jb/Library/ControlCenter/Bundles/VBModule.bundle/VBModule", @"/var/jb/Library/ControlCenter/Bundles/VBModule.bundle/%@" ],
      @[ @"/var/jb/Library/ControlCenter/Bundles/VBModule.bundle", @"/var/jb/Library/ControlCenter/Bundles/%@.bundle" ]
    ];

    for (NSArray *rename in renames) {
      NSString *oldPath = rename[0];
      NSString *newPath = [NSString stringWithFormat:rename[1], randomName];
      NSError *error;
      [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
      if (error) {
        printf("Failed to rename %s: %s\n", oldPath.UTF8String,
               error.localizedDescription.UTF8String);
        return 1;
      }
    }

    NSString *dpkgInfo =
        [NSString stringWithContentsOfFile:@"/var/jb/var/lib/dpkg/info/kr.xsf1re.vnodebypass.list"
                                  encoding:NSUTF8StringEncoding
                                     error:nil];
    dpkgInfo = [dpkgInfo stringByReplacingOccurrencesOfString:@"vnodebypass" withString:randomName];
    dpkgInfo = [dpkgInfo stringByReplacingOccurrencesOfString:@"VBModule" withString:randomName];
    [dpkgInfo writeToFile:@"/var/jb/var/lib/dpkg/info/kr.xsf1re.vnodebypass.list"
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:nil];

    task.arguments = @[ @"-p", [NSString stringWithFormat:@"/var/jb/Applications/%@.app", randomName] ];
    [task launch];
    [task waitUntilExit];
    return 0;
  }
}
