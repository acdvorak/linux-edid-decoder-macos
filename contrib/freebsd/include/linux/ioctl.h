#ifndef _LINUX_IOCTL_H
#define _LINUX_IOCTL_H

#include <sys/ioctl.h>

#ifndef _IOC
#define _IOC(dir, type, nr, size)	_IOC_NEWTYPE(dir, type, nr, size)
#endif

#ifndef _IOC_DIR
#define _IOC_DIR(nr)		(((nr) >> 29) & 0x7)
#endif

#ifndef _IOC_TYPE
#define _IOC_TYPE(nr)		(((nr) >> 8) & 0xFF)
#endif

#ifndef _IOC_NR
#define _IOC_NR(nr)		((nr) & 0xFF)
#endif

#ifndef _IOC_SIZE
#define _IOC_SIZE(nr)		(((nr) >> 16) & 0x1FFF)
#endif

#ifndef _IOC_NONE
#define _IOC_NONE		0U
#endif

#ifndef _IOC_WRITE
#define _IOC_WRITE		1U
#endif

#ifndef _IOC_READ
#define _IOC_READ		2U
#endif

#endif
