/*
 *  fmonitr.r -- event, EvGet
 *
 *   This file contains execution monitoring code, used only if EventMon
 *   (event monitoring) or some of its constituent events is defined.
 *   There used to be a separate virtual machine with all events defined,
 *   but the current setup allows specific events to be defined, and the
 *   source is moving towards a setup in which monitoring is unified into
 *   the main virtual machine.
 *
 *   The built-in functions are defined for all MultiThread interpreters.
 *
 *   When EventMon is undefined, most of the "MMxxxx" and "EVxxxx"
 *   entry points are defined as null macros in monitor.h.  See
 *   monitor.h for important definitions.
 */


#ifdef MultiThread
/*
 * event(x, y, C) -- generate an event at the program level.
 */

"event(x, y, C) - create event with event code x and event value y."

function{0,1} event(x,y,ce)
   body {
      struct progstate *dest;

      if (is:null(x)) {
	 x = curpstate->eventcode;
	 if (is:null(y)) y = curpstate->eventval;
	 }
      if (is:null(ce) && is:coexpr(curpstate->parentdesc))
	 ce = curpstate->parentdesc;
      else if (!is:coexpr(ce)) runerr(118,ce);
      dest = BlkLoc(ce)->coexpr.program;
      dest->eventcode = x;
      dest->eventval = y;
      if (mt_activate(&(dest->eventcode),&result,
			 (struct b_coexpr *)BlkLoc(ce)) == A_Cofail) {
         fail;
         }
       return result;
      }
end

/*
 * EvGet(c) - user function for reading event streams.
 * EvGet returns the code of the matched token.  These keywords are also set:
 *    &eventcode     token code
 *    &eventvalue    token value
 */

"EvGet(c,flag) - read through the next event token having a code matched "
" by cset c."

function{0,1} EvGet(cs,flag)
   if !def:cset(cs,fullcs) then
      runerr(104,cs)

   body {
      register int c;
      tended struct descrip dummy;
      struct progstate *p;

      /*
       * Be sure an eventsource is available
       */
      if (!is:coexpr(curpstate->eventsource))
         runerr(118,curpstate->eventsource);

      /*
       * If our event source is a child of ours, assign its event mask.
       */
      p = BlkLoc(curpstate->eventsource)->coexpr.program;
      if (p->parent == curpstate) {
	 if (BlkLoc(p->eventmask) != BlkLoc(cs)) {
	    p->eventmask = cs;

	    /*
	     * Most instrumentation functions depend on a single event.
	     */
	    p->Cplist =
	       ((Testb((word)ToAscii(E_Lcreate), cs)) ? cplist_1 : cplist_0);
	    p->Cpset =
	       ((Testb((word)ToAscii(E_Screate), cs)) ? cpset_1 : cpset_0);
	    p->Cptable =
	       ((Testb((word)ToAscii(E_Tcreate), cs)) ? cptable_1 : cptable_0);

	    /*
	     * A few functions enable more than one event code.
	     */
	    p->EVstralc =
	       (((Testb((word)ToAscii(E_String), cs)) ||
		 (Testb((word)ToAscii(E_StrDeAlc), cs)))
		? EVStrAlc_1 : EVStrAlc_0);

	    /*
	     * interp() is the monster case:
	     * We should replace 30 membership tests with a cset intersection.
	     * Heck, we should redo the event codes so any bit in one
	     * particular word means: "use the instrumented interp".
	     */
	    if (Testb((word)ToAscii(E_Intcall), cs) ||
		Testb((word)ToAscii(E_Stack), cs) ||
		Testb((word)ToAscii(E_Fsusp), cs) ||
		Testb((word)ToAscii(E_Osusp), cs) ||
		Testb((word)ToAscii(E_Bsusp), cs) ||
		Testb((word)ToAscii(E_Ocall), cs) ||
		Testb((word)ToAscii(E_Ofail), cs) ||
		Testb((word)ToAscii(E_Tick), cs) ||
		Testb((word)ToAscii(E_Line), cs) ||
		Testb((word)ToAscii(E_Loc), cs) ||
		Testb((word)ToAscii(E_Opcode), cs) ||
		Testb((word)ToAscii(E_Fcall), cs) ||
		Testb((word)ToAscii(E_Prem), cs) ||
		Testb((word)ToAscii(E_Erem), cs) ||
		Testb((word)ToAscii(E_Intret), cs) ||
		Testb((word)ToAscii(E_Psusp), cs) ||
		Testb((word)ToAscii(E_Ssusp), cs) ||
		Testb((word)ToAscii(E_Pret), cs) ||
		Testb((word)ToAscii(E_Efail), cs) ||
		Testb((word)ToAscii(E_Sresum), cs) ||
		Testb((word)ToAscii(E_Fresum), cs) ||
		Testb((word)ToAscii(E_Oresum), cs) ||
		Testb((word)ToAscii(E_Eresum), cs) ||
		Testb((word)ToAscii(E_Presum), cs) ||
		Testb((word)ToAscii(E_Pfail), cs) ||
		Testb((word)ToAscii(E_Ffail), cs) ||
		Testb((word)ToAscii(E_Frem), cs) ||
		Testb((word)ToAscii(E_Orem), cs) ||
		Testb((word)ToAscii(E_Fret), cs) ||
		Testb((word)ToAscii(E_Oret), cs)
		)
	       p->Interp = interp_1;
	    else
	       p->Interp = interp_0;
	    }
	 }

#ifdef Graphics
      if (Testb((word)ToAscii(E_MXevent), cs) &&
	  is:file(kywd_xwin[XKey_Window])) {
	 wbp _w_ = (wbp)BlkLoc(kywd_xwin[XKey_Window])->file.fd;
	 wsync(_w_);
	 pollctr = pollevent();
	 if (pollctr == -1)
	    fatalerr(141, NULL);
	 if (BlkLoc(_w_->window->listp)->list.size > 0) {
	    c = wgetevent(_w_, &curpstate->eventval, -1);
	    if (c == 0) {
	       StrLen(curpstate->eventcode) = 1;
	       StrLoc(curpstate->eventcode) =
		  (char *)&allchars[FromAscii(E_MXevent) & 0xFF];
	       return curpstate->eventcode;
	       }
	    else if (c == -1)
	       runerr(141);
	    else
	       runerr(143);
	    }
	 }
#endif					/* Graphics */

      /*
       * Loop until we read an event allowed.
       */
      while (1) {
         /*
          * Activate the event source to produce the next event.
          */
	 dummy = cs;
	 if (mt_activate(&dummy, &curpstate->eventcode,
			 (struct b_coexpr *)BlkLoc(curpstate->eventsource)) ==
	     A_Cofail) fail;
	 deref(&curpstate->eventcode, &curpstate->eventcode);
	 if (!is:string(curpstate->eventcode) ||
	     StrLen(curpstate->eventcode) != 1) {
	    /*
	     * this event is out-of-band data; return or reject it
	     * depending on whether flag is null.
	     */
	    if (!is:null(flag))
	       return curpstate->eventcode;
	    else continue;
	    }

#if E_Cofail || E_Coret
	 switch(*StrLoc(curpstate->eventcode)) {
	 case E_Cofail: case E_Coret: {
	    if (BlkLoc(curpstate->eventsource)->coexpr.id == 1) {
	       fail;
	       }
	    }
	    }
#endif					/* E_Cofail || E_Coret */

	 return curpstate->eventcode;
	 }
      }
end

/*
 * Prototypes.
 */

void mmrefresh		(void);

#define evforget()


char typech[MaxType+1];	/* output character for each type */

int noMTevents;			/* don't produce events in EVAsgn */

#ifdef HaveProfil
union { 			/* clock ticker -- keep in sync w/ interp.r */
   unsigned short s[16];	/* four counters */
   unsigned long l[8];		/* two longs are easier to check */
} ticker;
unsigned long oldtick;		/* previous sum of the two longs */
#endif					/* HaveProfil */

#if UNIX
/*
 * Global state used by EVTick()
 */
word oldsum = 0;
#endif					/* UNIX */


static char scopechars[] = "+:^-";

/*
 * Special event function for E_Assign & E_Deref;
 * allocates out of monitor's heap.
 */
void EVVariable(dptr dx, int eventcode)
{
   int i;
   dptr procname;
   struct progstate *parent = curpstate->parent;
   struct region *rp = curpstate->stringregion;

   if (dx == glbl_argp) {
      /*
       * we are dereferencing a result, glbl_argp is not the procedure.
       * is this a stable state to leave the TP in?
       */
      actparent(eventcode);
      return;
      }

#if COMPILER
   procname = &(PFDebug(*pfp)->proc->pname);
#else					/* COMPILER */
   procname = &((&BlkLoc(*glbl_argp)->proc)->pname);
#endif					/* COMPILER */
   /*
    * call get_name, allocating out of the monitor if necessary.
    */
   curpstate->stringregion = parent->stringregion;
   parent->stringregion = rp;
   noMTevents++;
   i = get_name(dx,&(parent->eventval));

   if (i == GlobalName) {
      if (reserve(Strings, StrLen(parent->eventval) + 1) == NULL) {
	 fprintf(stderr, "failed to reserve %d bytes for global\n",
		 StrLen(parent->eventval)+1);
	 syserr("monitoring out-of-memory error");
	 }
      StrLoc(parent->eventval) =
	 alcstr(StrLoc(parent->eventval), StrLen(parent->eventval));
      alcstr("+",1);
      StrLen(parent->eventval)++;
      }
   else if ((i == StaticName) || (i == LocalName) || (i == ParamName)) {
      if (!reserve(Strings, StrLen(parent->eventval) + StrLen(*procname) + 1)) {
	 fprintf(stderr,"failed to reserve %d bytes for %d, %d+%d\n",
		StrLen(parent->eventval)+StrLen(*procname)+1, i,
		 StrLen(parent->eventval), StrLen(*procname));
	 syserr("monitoring out-of-memory error");
	 }
      StrLoc(parent->eventval) =
	 alcstr(StrLoc(parent->eventval), StrLen(parent->eventval));
      alcstr(scopechars+i,1);
      alcstr(StrLoc(*procname), StrLen(*procname));
      StrLen(parent->eventval) += StrLen(*procname) + 1;
      }
   else if (i == Error) {
      noMTevents--;
      syserr("get_name failed in EVVariable");
      return; /* should be more violent than this */
      }

   parent->stringregion = curpstate->stringregion;
   curpstate->stringregion = rp;
   noMTevents--;
   actparent(eventcode);
}


/*
 *  EVInit() - initialization.
 */

void EVInit()
   {
   int i;

   /*
    * Initialize the typech array, which is used if either file-based
    * or MT-based event monitoring is enabled.
    */

   for (i = 0; i <= MaxType; i++)
      typech[i] = '?';	/* initialize with error character */

#ifdef LargeInts
   typech[T_Lrgint]  = E_Lrgint;	/* long integer */
#endif					/* LargeInts */

   typech[T_Real]    = E_Real;		/* real number */
   typech[T_Cset]    = E_Cset;		/* cset */
   typech[T_File]    = E_File;		/* file block */
   typech[T_Record]  = E_Record;	/* record block */
   typech[T_Tvsubs]  = E_Tvsubs;	/* substring trapped variable */
   typech[T_External]= E_External;	/* external block */
   typech[T_List]    = E_List;		/* list header block */
   typech[T_Lelem]   = E_Lelem;		/* list element block */
   typech[T_Table]   = E_Table;		/* table header block */
   typech[T_Telem]   = E_Telem;		/* table element block */
   typech[T_Tvtbl]   = E_Tvtbl;		/* table elem trapped variable*/
   typech[T_Set]     = E_Set;		/* set header block */
   typech[T_Selem]   = E_Selem;		/* set element block */
   typech[T_Slots]   = E_Slots;		/* set/table hash slots */
   typech[T_Coexpr]  = E_Coexpr;	/* co-expression block (static) */
   typech[T_Refresh] = E_Refresh;	/* co-expression refresh block */


   /*
    * codes used elsewhere but not shown here:
    *    in the static region: E_Alien = alien (malloc block)
    *    in the static region: E_Free = free
    *    in the string region: E_String = string
    */

#if UNIX
   /*
    * Call profil(2) to enable program counter profiling.  We use the smallest
    *  allowable scale factor in order to minimize the number of counters;
    *  we assume that the text of iconx does not exceed 256K and so we use
    *  four bins.  One of these four bins will be incremented every system
    *  clock tick (typically 4 to 20 ms).
    *
    *  Take your local profil(2) man page with a grain of salt.  All the systems
    *  we tested really maintain 16-bit counters despite what the man pages say.
    *  Some also say that a scale factor of two maps everything to one counter;
    *  that is believed to be a no-longer-correct statement dating from the days
    *  when the maximum program size was 64K.
    *
    *  The reference to EVInit below just obtains an arbitrary address within
    *  the text segment.
    */
#ifdef HaveProfil
   profil(ticker.s, sizeof(ticker.s), (int) EVInit & ~0x3FFFF, 2);
#endif					/* HaveProfil*/
#endif					/* UNIX */
   }

/*
 * mmrefresh() - redraw screen, initially or after garbage collection.
 */

void mmrefresh()
   {
   char *p;
   word n;

   /*
    * If the monitor is asking for E_EndCollect events, then it
    * can handle these memory allocation "redraw" events.
    */
  if (!is:null(curpstate->eventmask) &&
       Testb((word)ToAscii(E_EndCollect), curpstate->eventmask)) {
      for (p = blkbase; p < blkfree; p += n) {
	 n = BlkSize(p);
#if E_Lrgint || E_Real || E_Cset || E_File || E_Record || E_Tvsubs || E_External || E_List || E_Lelem || E_Table || E_Telem || E_Tvtbl || E_Set || E_Selem || E_Slots || E_Coexpr || E_Refresh
	 RealEVVal(n, typech[(int)BlkType(p)]);	/* block region */
#endif					/* instrument allocation events */
	 }
      EVVal(DiffPtrs(strfree, strbase), E_String);	/* string region */
      }
   }


void EVStrAlc_0(word n) { ; }

void EVStrAlc_1(word n)
{
   if (n < 0) {
      EVVal(-n, E_StrDeAlc);
      }
   else {
      EVVal(n, E_String);
      }
}


#else					/* MultiThread */
static char xjunk;			/* avoid empty module */
#endif					/* MultiThread */
