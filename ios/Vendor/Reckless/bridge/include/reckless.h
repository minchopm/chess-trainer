// A flat C interface over Reckless, mirroring Vendor/Stockfish/bridge/include/sfbridge.h.
//
// The implementation is Rust — src/ffi.rs inside the engine crate — because the
// crate exports nothing: every module in src/lib.rs is private, so a separate
// wrapper crate cannot reach the search. The file lives inside the crate for
// that reason and for that reason only.
//
// The shape deliberately follows the Stockfish bridge so RecklessEngine.swift
// can be a near-copy of StockfishEngine.swift. Two differences are unavoidable
// and are called out at the declarations concerned: there is no rk_load_networks
// (the network is compiled in), and rk_engine_info reports a Reckless version.
#ifndef RECKLESS_H
#define RECKLESS_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RKEngine RKEngine;

/// One `info` line from the search.
typedef struct {
    int depth;
    int selDepth;
    int multiPV;      ///< 1-based rank of this line
    int scoreCp;      ///< valid when isMate is false
    int scoreMate;    ///< moves to mate, signed; valid when isMate is true
    bool isMate;
    long long nodes;
    long long timeMs;
    const char* pv;   ///< space-separated UCI moves, valid only during the call
} RKInfo;

typedef void (*RKInfoHandler)(void* context, const RKInfo* info);
typedef void (*RKBestMoveHandler)(void* context, const char* bestMove, const char* ponder);

/// Initialise global tables. Safe to call more than once; must precede rk_create.
///
/// Unlike Stockfish this is not strictly required — rk_create calls it — but it
/// is exposed so the cost (attack tables and the threat index) can be paid at a
/// moment of the caller's choosing rather than on the first search.
void rk_global_init(void);

const char* rk_engine_info(void);

RKEngine* rk_create(void);
void rk_destroy(RKEngine* engine);

/// There is no rk_load_networks.
///
/// Reckless embeds its network in the binary as a `static` — `include_bytes!` of
/// the file named by EVALFILE at build time — so there is no path to hand it and
/// no failure to report. The 63 MB that buys is the dominant cost of the engine;
/// see ios/README.md. rk_create is correspondingly infallible where sf_create
/// must be followed by sf_load_networks.

/// Recognised names: Threads, Hash, MultiPV, MoveOverhead, Minimal.
/// An unknown name is ignored, matching the UCI layer's tolerance.
void rk_set_option(RKEngine* engine, const char* name, const char* value);
void rk_new_game(RKEngine* engine);

/// Set the position from a FEN. Returns false if the FEN is unusable, leaving
/// the previous position in place.
bool rk_set_position(RKEngine* engine, const char* fen);

/// Start searching. Non-blocking; handlers are called from the search thread.
/// Pass 0 for a limit that should not apply. When both are given the search
/// stops at whichever is reached first.
void rk_go(RKEngine* engine,
           int depth,
           int movetimeMs,
           void* context,
           RKInfoHandler onInfo,
           RKBestMoveHandler onBestMove);

void rk_stop(RKEngine* engine);
void rk_wait_for_search(RKEngine* engine);

#ifdef __cplusplus
}
#endif

#endif
