#ifndef COMMLIBMANAGER_H
#define COMMLIBMANAGER_H

#include "charm++.h"
#include "cksection.h"
#include "envelope.h"
#include "commlib.h"
#include <math.h>

#define USE_DIRECT 0          //A dummy strategy that directly forwards 
                              //messages without any processing.
#define USE_TREE 1            //Organizes the all to all as a tree
#define USE_MESH 2            //Virtual topology is a mesh here
#define USE_HYPERCUBE 3       //Virtual topology is a hypercube
#define USE_GROUP_BY_PROCESSOR 4 //Groups messages by destination processor 
                                 //(does not work as of now)
#define USE_GRID 5            //Virtual topology is a 3d grid

#define CHARM_MPI 0 
#define MAX_NSTRAT 1024
#define LEARNING_PERIOD 1000 //Number of iterations after which the
                             //learning framework will discover 
                             //the appropriate strategy, not completely 
                             //implemented
#define IS_MULTICAST -1

#define ALPHA 5E-6
#define BETA 3.33E-9

PUPbytes(comID);

#include "commlib.decl.h"

//Dummy message to be sent incase there are no messages to send. 
//Used by only the EachToMany strategy!
class ComlibDummyMsg: public CMessage_ComlibDummyMsg {
    int dummy;
};

/*
//Priority message to call end iteration
class PrioMsg: public CMessage_PrioMsg {
 public:
    int instID;
};
*/

class ComlibMulticastMsg : public CkMcastBaseMsg, 
               public CMessage_ComlibMulticastMsg {
    
  public:
    int size;
    char *usrMsg;        
    CkArrayIndexMax *indices;
};

extern CkGroupID cmgrID;

//An Instance of the communication library.
class ComlibInstanceHandle {
 public:    
    
    int _instid;
    CkGroupID _dmid;
    
    ComlibInstanceHandle();
    ComlibInstanceHandle(int instid, CkGroupID dmid);    
    //    ComlibInstanceHandle(ComlibInstanceHandle &that);
    
    void beginIteration();
    void endIteration();
    
    CkGroupID getComlibManagerID();
};

PUPbytes(ComlibInstanceHandle);

class ComlibManager: public CkDelegateMgr {

    int npes;
    int *pelist;

    //CkArrayID dummyArrayID;
    CkArrayIndexMax dummyArrayIndex;

    //For compatibility and easier use!
    int strategyID; //Identifier of the strategy

    StrategyTable strategyTable[MAX_NSTRAT]; //A table of strategy pointers
    CkQ<Strategy *> ListOfStrategies;
    int nstrats, curStratID, prevStratID;      
    //Number of strategies created by the user.

    //flags
    int receivedTable, flushTable, barrierReached, barrier2Reached;
    int totalMsgCount, totalBytes, nIterations;

    ComlibArrayListener *alistener;
    int prioEndIterationFlag;

    void init(); //initialization function

    //charm_message for multicast for a section of that group
    void multicast(void *charm_msg); //charm_message here.
    void multicast(void *charm_msg, int npes, int *pelist);     

 public:
    ComlibManager();  //Receommended constructor

    //ComlibManager(int strategyID, int eltPerPE=0);
    //ComlibManager(Strategy *strat, int eltPerPE=0);

    ComlibManager::ComlibManager(CkMigrateMessage *m){ }
    //int useDefCtor(void){ return 1; }

    void barrier(void);
    void barrier2(void);
    void resumeFromBarrier2(void);

    //Depricated by the use of array listeners
    //void localElement();
    //void registerElement(int strat);   //Register a chare for an instance
    //void unRegisterElement(int strat); //UnRegister a chare for an instance

    void receiveID(comID id);                        //Depricated
    void receiveID(int npes, int *pelist, comID id); //Depricated
    void receiveTable(StrategyWrapper sw);     //Receive table of strategies.

    void ArraySend(int ep, void *msg, const CkArrayIndexMax &idx, 
                   CkArrayID a);
    void GroupSend(int ep, void *msg, int onpe, CkGroupID gid);
    
    virtual void ArrayBroadcast(int ep,void *m,CkArrayID a);
    virtual void GroupBroadcast(int ep,void *m,CkGroupID g);
    virtual void ArraySectionSend(int ep,void *m,CkArrayID a,CkSectionID &s);

    void beginIteration();     //Notify begining of a bracket 
                               //with strategy identifier
    void endIteration();       //Notify end, endIteration must be called if 
                               //a beginIteration is called. Otherwise 
                               //end of the entry method is assumed to 
                               //be the end of the bracket.

    void setInstance(int id); 
    //void prioEndIteration(PrioMsg *pmsg);

    Strategy *getStrategy(int instid)
        {return strategyTable[instid].strategy;}
    StrategyTable *getStrategyTableEntry(int instid)
        {return &strategyTable[instid];}

    //To create a new strategy, returns handle to the strategy table;
    ComlibInstanceHandle createInstance(Strategy *);  

    void doneCreating();             //Done creating instances

    //Learning functions
    void learnPattern(int totalMessageCount, int totalBytes);
    void switchStrategy(int strat);

    static ComlibMulticastMsg *
        getPackedMulticastMessage(CharmMessageHolder *m);
};

ComlibInstanceHandle  ComlibRegisterStrategy(Strategy *);
ComlibInstanceHandle  ComlibRegisterStrategy(Strategy *, CkArrayID aid);
ComlibInstanceHandle  ComlibRegisterStrategy(Strategy *, CkGroupID gid);

void ComlibDelegateProxy(CProxy *proxy);
#endif
