#ifndef _MULTICAST
#define _MULTICAST

class mCastCookie;

class multicastSetupMsg;
class multicastGrpMsg;
class cookieMsg;
class ReductionMsg;

typedef mCastCookie * mCastCookiePtr;

#include "CkMulticast.decl.h"

class CkMcastBaseMsg {
public:
  unsigned int _gpe, _redNo;
  void *_cookie;
public:
  unsigned int &gpe(void) { return _gpe; }
  unsigned int &redno(void) { return _redNo; }
  void *&cookie(void) { return _cookie; }
};

#define MAXMCASTCHILDREN  2

typedef void (*redClientFn)(CkSectionCookie sid, void *param,int dataSize,void *data);

class CkMulticastMgr: public CkDelegateMgr {
  private:
    CkSectionCookie sid;  // for now
    int idNum;
  public:
    CkMulticastMgr(): idNum(0) {};
    void setSection(CkSectionCookie &id, CkArrayID aid, CkArrayIndexMax *, int n);
    void setSection(CkSectionCookie &id);
    void setSection(CProxySection_ArrayElement *proxy);
    void teardown(CkSectionCookie s);
    void freeup(CkSectionCookie s);
    void init(CkSectionCookie sid);
    void reset(CkSectionCookie sid);
    cookieMsg * setup(multicastSetupMsg *);
    void ArraySend(int ep, void *m, const CkArrayIndexMax &idx, CkArrayID a);
    void ArrayBroadcast(int ep,void *m, CkArrayID a);
    void ArraySectionSend(int ep,void *m, CkArrayID a, CkSectionCookie &s);
    void recvMsg(multicastGrpMsg *m);
    // for reduction
    void setReductionClient(CkSectionCookie sid, redClientFn fn,void *param=NULL);
    void setReductionClient(CProxySection_ArrayElement *, redClientFn fn,void *param=NULL);
    void contribute(int dataSize,void *data,CkReduction::reducerType type, CkSectionCookie &sid);
    void rebuild(CkSectionCookie &);
    // entry
    void recvRedMsg(ReductionMsg *msg);
    void updateRedNo(mCastCookie *, int red);
  public:
    typedef ReductionMsg *(*reducerFn)(int nMsg,ReductionMsg **msgs);
  private:
    enum {MAXREDUCERS=256};
    static reducerFn reducerTable[MAXREDUCERS];
    void releaseFutureReduceMsgs(mCastCookie *entry);
    void releaseBufferedReduceMsgs(mCastCookie *entry);
};


extern void setSectionID(void *msg, CkSectionCookie sid);
extern void CkGetSectionID(CkSectionCookie &id, void *msg);

#endif
