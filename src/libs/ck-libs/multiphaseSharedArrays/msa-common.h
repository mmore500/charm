// emacs mode line -*- mode: c++; tab-width: 4 -*-
#ifndef MSA_COMMON_H
#define MSA_COMMON_H

enum { MSA_INVALID_PAGE_NO = 0xFFFFFFFF };
enum { MSA_INVALID_PE = -1 };
typedef void* page_ptr_t;

typedef enum {
 Uninit_State = 0,
 Read_Fault = 1,
 Write_Fault = 2,
 Accumulate_Fault = 3
} MSA_Page_Fault_t;

/// Allow MSA_Page_Fault_t's to be pupped:
inline void operator|(PUP::er &p,MSA_Page_Fault_t &f) {
  int i=f; // if packing
  p|i;
  f=(MSA_Page_Fault_t)i; // if unpacking
}

enum { MSA_DEFAULT_ENTRIES_PER_PAGE = 1024 };
// Therefore, size of page == MSA_DEFAULT_ENTRIES_PER_PAGE * sizeof(element type)

// Size of cache on each PE
enum { MSA_DEFAULT_MAX_BYTES = 16*1024*1024 };

typedef enum { MSA_COL_MAJOR=0, MSA_ROW_MAJOR=1 } MSA_Array_Layout_t;

//================================================================

/** This is the interface used to perform the accumulate operation on
    an Entry.  T is the data type.  It may be a primitive one or a
    class.  T must support the default constructor, assignment, +=
    operator if you use accumulate, typecast from int 0, 1, and pup.
*/

template <class T, bool PUP_EVERY_ELEMENT=true >
class DefaultEntry {
public:
    inline void accumulate(T& a, const T& b) { a += b; }
    // identity for initializing at start of accumulate
    inline T getIdentity() { return (T)0; }
    inline bool pupEveryElement(){ return PUP_EVERY_ELEMENT; }
};

template <class T, bool PUP_EVERY_ELEMENT=true >
class ProductEntry {
public:
    inline void accumulate(T& a, const T& b) { a *= b; }
    inline T getIdentity() { return (T)1; }
    inline bool pupEveryElement(){ return PUP_EVERY_ELEMENT; }
};

template <class T, T minVal, bool PUP_EVERY_ELEMENT=true >
class MaxEntry {
public:
    inline void accumulate(T& a, const T& b) { a = (a<b)?b:a; }
    inline T getIdentity() { return minVal; }
    inline bool pupEveryElement(){ return PUP_EVERY_ELEMENT; }
};

//================================================================

#define DEBUG_PRINTS

#endif
