#pragma once
@import Foundation;
#import "libkfd.h"
#import "fun.h"

/// Uses CVE-2022-46689 to grant the current app read/write access outside the sandbox.
void grant_full_disk_access(u64 kfd, void (^_Nonnull completion)(NSError* _Nullable));
bool patch_installd(u64 kfd);
