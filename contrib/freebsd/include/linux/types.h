#ifndef _LINUX_TYPES_H
#define _LINUX_TYPES_H

#include <stdint.h>

#if !defined(__u8) && !defined(__u16) && !defined(__u32) && !defined(__u64) && \
	!defined(__s8) && !defined(__s16) && !defined(__s32) && !defined(__s64)

#ifndef __u8
typedef uint8_t __u8;
#endif
#ifndef __u16
typedef uint16_t __u16;
#endif
#ifndef __u32
typedef uint32_t __u32;
#endif
#ifndef __u64
typedef uint64_t __u64;
#endif

#ifndef __s8
typedef int8_t __s8;
#endif
#ifndef __s16
typedef int16_t __s16;
#endif
#ifndef __s32
typedef int32_t __s32;
#endif
#ifndef __s64
typedef int64_t __s64;
#endif

#ifndef __le16
typedef __u16 __le16;
#endif
#ifndef __le32
typedef __u32 __le32;
#endif
#ifndef __le64
typedef __u64 __le64;
#endif

#ifndef __be16
typedef __u16 __be16;
#endif
#ifndef __be32
typedef __u32 __be32;
#endif
#ifndef __be64
typedef __u64 __be64;
#endif

#ifndef __sum16
typedef __u16 __sum16;
#endif
#ifndef __wsum
typedef __u32 __wsum;
#endif

#ifndef __aligned_u64
typedef __u64 __aligned_u64 __attribute__((aligned(8)));
#endif

#endif

#endif
