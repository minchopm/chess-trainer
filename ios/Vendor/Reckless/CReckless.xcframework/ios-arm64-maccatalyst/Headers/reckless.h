// A flat C interface over Reckless, mirroring Vendor/Stockfish/bridge/include/sfbridge.h.
//
// The implementation is Rust — src/ffi.rs inside the engine crate — because the
// crate exports nothing: every module in src/lib.rs is private, so a separate
// wrapper crate cannot reach the search. The file lives inside the crate for
// that reason and for that reason only.
//
// The shape deliberately follows the Stockfish bridge so RecklessEngine.swift
// can be a near-copy of StockfishEngine.swift. One difference is unavoidable and
// is called out at the declaration concerned: rk_load_network is global where
// sf_load_networks is per-engine, because Reckless keeps one network for the
// whole process. And rk_engine_info reports a Reckless version.
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

/// Null before rk_load_network has succeeded: an engine with no network cannot
/// search, and handing one back would only move the failure to the first move it
/// was asked for.
RKEngine* rk_create(void);
void rk_destroy(RKEngine* engine);

/// Read the network from a file. Must succeed before rk_create.
///
/// Reckless used to compile its network in, as `include_bytes!` of the file
/// named by EVALFILE, and this declaration used to say so and explain why there
/// was nothing to load. What that cost was 141 MB of static library per platform
/// slice — the 60 MB network stored twice over, once as data and once inside the
/// bitcode that fat LTO emits — against 235 KB of actual engine. The crate now
/// has an `embedded-network` feature, on by default so that building it alone is
/// unchanged, and this app builds with it off.
///
/// Global rather than per-engine, unlike sf_load_networks, because the network
/// is: every engine in the process searches with the same one. A build that
/// still embeds its network returns true without reading anything, so the call
/// can be made unconditionally.
bool rk_load_network(const char* path);

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
