#ifndef RT_H    /* only include once */
#define RT_H 1

/*
 * Include files.
 */

#include "../h/define.h"
#include "../h/config.h"
#include "../h/sys.h"
#include "../h/typedefs.h"
#include "../h/cstructs.h"
#include "../h/proto.h"
#include "../h/cpuconf.h"
#include "../h/monitor.h"
#include "../h/rmacros.h"
#include "../h/rstructs.h"

#ifdef Graphics
   #include "../h/graphics.h"
#endif                                  /* Graphics */

#ifdef Audio
   #include "../h/audio.h"
#endif                                  /* Audio */

#ifdef PosixFns
#include "../h/posix.h"
#endif                                  /* PosixFns */

#if COMPILER
#ifdef NT
/* 
 * Declare flock (which is defined in fxposix.ri, just before it is used).
 * It's needed here because rtt splits fxposix.ri into several C files 
 * when producing code for iconc, which separates the definition from its use.
 */
int flock(int fd, int operation);
#endif                                  /* NT */
#endif                                  /* COMPILER */


#ifdef Messaging
#include "../h/messagin.h"
#endif                                  /* Messaging */

#include "../h/rexterns.h"
#include "../h/rproto.h"

#ifdef _UCRT    /* Building on Windows using the Universal C Runtime */
#include <io.h>
#include "../h/filepat.h"
#endif                                  /* _UCRT */


#endif                                  /* RT_DOT_H */
