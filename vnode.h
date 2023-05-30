#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

const char *vnodeMemPath;
NSString *procursusPath;
NSArray *hidePathList;

void saveVnode();
void hideVnode();
void revertVnode();
void recoveryVnode();
void checkFile();
