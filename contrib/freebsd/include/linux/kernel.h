#ifndef _LINUX_KERNEL_H
#define _LINUX_KERNEL_H

#include <stddef.h>

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
#endif

#ifndef BIT
#define BIT(nr) (1UL << (nr))
#endif

#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) ((a) > (b) ? (a) : (b))
#endif

#endif
