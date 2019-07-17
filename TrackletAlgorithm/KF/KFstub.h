#ifndef __KFstub__
#define __KFstub__

/**
 * This defines Stubs for the Kalman Filter maths HLS code.
 * N.B. It therefore can't use the Settings class or any external libraries! Nor can it be a C++ class.
 * 
 * Author: Ian Tomalin
 */

// Must use AP_UINT(1) instead of bool, due to bug in HLS IP export.

#include "ap_int.h"
#include "ap_fixed.h"

#ifdef CMSSW_GIT_HASH
#include "L1Trigger/TrackFindingTMTT/interface/HLS/HLSutilities.h"
#else
#include "HLSutilities.h"
#endif

#ifndef __SYNTHESIS__
#include <iostream>
#endif

///=== Hard-wired configuration parameters.
///=== WARNING: Since this code must be used in Vivado HLS, it can't use the Settings class.
///=== Therefore all constants are hard-wired here, so may break if you change the configuration parameters.

#ifdef CMSSW_GIT_HASH
namespace TMTT {

namespace KalmanHLS {
#endif

///=== Numbers of bits hard-wired, since same code also used within Vivado HLS, where access to Settings class not possible.

namespace KFstubN {
  // Format of Stub taken from KF stubs.vhd, with #bits specified in L1TF config.vhd, aside from following ...
  // r : KF measures it with respect to beam-line instead of critical radius, so uses 1 extra bit.
  // z : KF uses same multipler as for r, whereas HT uses multiplier factor 2 smaller than r.
  //     By using type TZ, the additional factor 2 is applied when when KFstub is created.

enum {BR = 12+1, BZ = 14, BPHI=14, BR1 = BR - 1, BZ1 = BZ + 1, // For stub coords.
      BEV   = 3,        // Allows up to 8 events to be interleaved inside KF
      NEV   = (1 << BEV),
      BTRK  = 5,        // Allows up to 32 tracks cand IDs (compare TM*(320MHz/40MHz)/(5 stubs) = 29) from HT per KF worker per event.
      NTRK  = (1 << BTRK),
      BLAY  = 3,        // Allows up to 7+1 KF layer IDs (where +1 is for invalid layer)
      NLAY  = (1 << BLAY),
      BID   = 3,        // Stub ID in layer. [pow(2,BID) - 1]  must be >= MaxStubsPerLayPerTrack, 
      NID   = (1 << BID),
      BSEC  = 4,        // Allows up to 2*16 eta sectors, where factor 2 comes from zSign.
      BSEC1 = BSEC + 1, // To allow same number of sectors in raw stub format, where no zSign used.
      BM    = 6, BC = 6};  // Allow 64*64 HT array. 

typedef AP_UFIXED(BR,BR)    TR;
typedef AP_FIXED(BR1,BR1)   TR1;
typedef AP_FIXED(BZ,BZ1)    TZ;  // Lowest integer bit has value zero.
typedef AP_FIXED(BPHI,BPHI) TPHI;
typedef AP_UINT(BEV)        TEV;
typedef AP_UINT(BTRK)       TTRK;
typedef AP_UINT(BLAY)       TLAY;
typedef AP_UINT(BID)        TID;
typedef AP_UINT(BSEC)       TSEC;
typedef AP_UINT(BSEC1)      TSEC1;
typedef AP_INT(BM)          TM;
typedef AP_INT(BC)          TC;
};

//--- Class containing stub coords used by KF maths block.

class KFstubC {
public:

  KFstubC(const KFstubN::TR& r_, const KFstubN::TZ& z_, const KFstubN::TPHI& phi_, const AP_UINT(1)& valid_) : 
    r(r_), z(z_), phiS(phi_), valid(valid_) {}

  KFstubC() : KFstubC(0,0,0,false) {}

public:

  KFstubN::TR     r;  // Note this is r, not rT, so is unsigned.
  KFstubN::TZ     z;  // This is (rMult/zMult) larger than digitised z used by HT, so needs one more integer bit.
  KFstubN::TPHI   phiS;

  AP_UINT(1)      valid; // Used by external code to indicate if input data is valid.

#ifndef __SYNTHESIS__
public:
  void print(const char* text) const {
  if (valid) std::cout<<text<<std::dec<<" r="<<r<<" phiS="<<phiS<<" z="<<float(z)/2.<<std::endl; // z/2 allows comparison with VHDL
  }
#endif
};

//--- Class containing stub address

class KFstubA {
public:

  KFstubA(const KFstubN::TEV& event_, const KFstubN::TTRK& trk_, const KFstubN::TLAY& lay_, const KFstubN::TID& id_) :
    eventID(event_), trackID(trk_), layerID(lay_), stubID(id_) {} 

  KFstubA() : KFstubA(0,0,0,0) {}

  public:

  KFstubN::TEV    eventID;
  KFstubN::TTRK   trackID;
  KFstubN::TLAY   layerID;
  KFstubN::TID    stubID;
};

//--- Full stub class created by InputLinkFormatter.

class KFstub {
public:

  KFstub(const KFstubN::TR& r_, const KFstubN::TZ& z_, const KFstubN::TPHI& phi_, 
	 const KFstubN::TEV& event_, const KFstubN::TTRK& trk_, const KFstubN::TLAY& lay_, 
	 const KFstubN::TID& id_, 
	 const KFstubN::TSEC& sec_, const AP_UINT(1)& zs_, const KFstubN::TM& mb_, const KFstubN::TC& cb_,
	 const AP_UINT(1)& final_, const AP_UINT(1)& valid_) :
         coord(r_, z_, phi_, valid_), addr(event_, trk_, lay_, id_),
	 etaSectID(sec_), etaSectZsign(zs_), mBin_ht(mb_), cBin_ht(cb_), finalStubInTrk(final_) {}

  KFstub() : KFstub(0,0,0,0,0,0,0,0,0,0,0,0,false) {}

  void getCoords(KFstubC& coord_) const {coord_ = coord;}
  void getAddr  (KFstubA& addr_) const {addr_ = addr;}

  KFstubC coord;
  KFstubA addr;

  KFstubN::TSEC  etaSectID;       // ID increases the further sector is from theta = 90 degrees.
  AP_UINT(1)     etaSectZsign;    // True if eta sector in -ve z half of Tracker.
  KFstubN::TM    mBin_ht;     // HT cell location
  KFstubN::TC    cBin_ht;
  AP_UINT(1)     finalStubInTrk;

#ifndef __SYNTHESIS__
public:
  void print(const char* text) const {
  if (coord.valid) std::cout<<text<<std::dec<<" r="<<coord.r<<" phiS="<<coord.phiS<<" z="<<float(coord.z)<<" evt="<<addr.eventID<<" trk="<<addr.trackID<<" lay="<<addr.layerID<<" stub="<<addr.stubID<<"  sec="<<etaSectID<<" sign="<<etaSectZsign<<" m="<<mBin_ht<<" c="<<cBin_ht<<" final="<<finalStubInTrk<<std::endl;
  }
#endif
};

//--- Reduced stub class that is stored in RAM.

class KFstubR {
public:

  KFstubR(const KFstubN::TR& r_, const KFstubN::TZ& z_, const KFstubN::TPHI& phi_, 
	 const KFstubN::TSEC& sec_, const AP_UINT(1)& zs_, const KFstubN::TM& mb_, const KFstubN::TC& cb_,
	 const AP_UINT(1)& final_, const AP_UINT(1)& valid_) :
         coord(r_, z_, phi_, valid_), 
	 etaSectID(sec_), etaSectZsign(zs_), mBin_ht(mb_), cBin_ht(cb_), finalStubInTrk(final_) {}

  KFstubR() : KFstubR(0,0,0,0,0,0,0,0,false) {}

  KFstubR(const KFstub& s) : coord(s.coord), etaSectID(s.etaSectID), etaSectZsign(s.etaSectZsign), mBin_ht(s.mBin_ht), cBin_ht(s.cBin_ht), finalStubInTrk(s.finalStubInTrk) {}

  void getCoords(KFstubC& coord_) const {coord_ = coord;}

  KFstubC coord;

  KFstubN::TSEC  etaSectID;       // ID increases the further sector is from theta = 90 degrees.
  AP_UINT(1)     etaSectZsign;    // True if eta sector in -ve z half of Tracker.
  KFstubN::TM    mBin_ht;     // HT cell location
  KFstubN::TC    cBin_ht;
  AP_UINT(1)     finalStubInTrk;

#ifndef __SYNTHESIS__
public:
  void print(const char* text) const {
  if (coord.valid) std::cout<<text<<std::dec<<" r="<<coord.r<<" phiS="<<coord.phiS<<" z="<<float(coord.z)<<"  sec="<<etaSectID<<" sign="<<etaSectZsign<<" m="<<mBin_ht<<" c="<<cBin_ht<<" final="<<finalStubInTrk<<std::endl;
  }
#endif
};

#ifdef CMSSW_GIT_HASH
}

}
#endif

#endif
