#ifndef _CK_H_
#define _CK_H_

#include <string.h>
#include <stdlib.h>

#define NDEBUG
#include <assert.h>

#include "charm.h"

#include "envelope.h"
#include "init.h"
#include "qd.h"
#include "register.h"
#include "stats.h"
#include "ckfutures.h"
#include "ckarray.h"
#include "ckstream.h"

class VidBlock {
    enum VidState {FILLED, UNFILLED};
    VidState state;
    PtrQ *msgQ;
    CkChareID actualID;
  public:
    VidBlock() { state = UNFILLED; msgQ = new PtrQ(); }
    void send(envelope *env) {
      if(state==UNFILLED) {
        msgQ->enq((void *)env);
      } else {
        env->setSrcPe(CkMyPe());
        env->setMsgtype(ForChareMsg);
        env->setObjPtr(actualID.objPtr);
        CldEnqueue(actualID.onPE, env, _infoIdx);
        CpvAccess(_qd)->create();
      }
    }
    void fill(int onPE, void *oPtr) {
      state = FILLED;
      actualID.onPE = onPE;
      actualID.objPtr = oPtr;
      envelope *env;
      while(env=(envelope*)msgQ->deq()) {
        env->setSrcPe(CkMyPe());
        env->setMsgtype(ForChareMsg);
        env->setObjPtr(actualID.objPtr);
        CldEnqueue(actualID.onPE, env, _infoIdx);
        CpvAccess(_qd)->create();
      }
      delete msgQ; msgQ=0;
    }
};

extern void _processHandler(void *);
extern void _infoFn(void *msg, CldPackFn *pfn, int *len,
                    int *queueing, int *priobits, UInt **prioptr);
extern void _packFn(void **msg);
extern void _unpackFn(void **msg);
extern void _createGroupMember(int groupID, int eIdx, void *env);
extern void _createGroup(int groupID, envelope *env, int retEp, 
                         CkChareID *retChare);

/***********************/
/* generated by charmc */
/***********************/

extern void CkRegisterMainModule(void);

#endif
