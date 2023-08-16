//
//  utils.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#include <stdio.h>
int ResSet16(void);
int removeSMSCache(void);
uint64_t createFolderAndRedirect(uint64_t vnode);
uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data);
