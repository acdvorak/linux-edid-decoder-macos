#ifndef _LINUX_CONST_H
#define _LINUX_CONST_H

#ifndef _AC
#define _AC(X, Y)	(X##Y)
#endif

#ifndef _AT
#define _AT(T, X)	((T)(X))
#endif

#ifndef _UL
#define _UL(x)		(_AC(x, UL))
#endif

#ifndef _ULL
#define _ULL(x)		(_AC(x, ULL))
#endif

#ifndef _BITUL
#define _BITUL(x)	(_UL(1) << (x))
#endif

#ifndef _BITULL
#define _BITULL(x)	(_ULL(1) << (x))
#endif

#endif
