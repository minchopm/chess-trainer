// A flat C interface over Stockfish's Engine class.
//
// Stockfish 18 is embeddable: Engine exposes set_position/go/stop plus
// callbacks, so nothing here drives it through stdin. A C surface is used
// rather than Swift's C++ interop because the pieces that would cross the
// boundary — std::function, std::string_view, templates on std::variant — are
// exactly the ones interop handles least predictably.
#ifndef SFBRIDGE_H
#define SFBRIDGE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SFEngine SFEngine;

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
} SFInfo;

typedef void (*SFInfoHandler)(void* context, const SFInfo* info);
typedef void (*SFBestMoveHandler)(void* context, const char* bestMove, const char* ponder);

/// Initialise global tables. Safe to call more than once; must precede sf_create.
void sf_global_init(void);

const char* sf_engine_info(void);

SFEngine* sf_create(void);
void sf_destroy(SFEngine* engine);

/// Load both networks from explicit paths. Returns false if either file is
/// missing or unreadable, so the caller can fail cleanly — Stockfish's own
/// verify_networks calls exit() on a missing net, which would take the whole
/// app down rather than surfacing an error.
bool sf_load_networks(SFEngine* engine, const char* bigNetPath, const char* smallNetPath);

void sf_set_option(SFEngine* engine, const char* name, const char* value);
void sf_new_game(SFEngine* engine);

/// Set the position from a FEN. Returns false if the FEN is unusable.
bool sf_set_position(SFEngine* engine, const char* fen);

/// Start searching. Non-blocking; handlers are called from the search thread.
/// Pass 0 for a limit that should not apply. When both are given the search
/// stops at whichever is reached first.
void sf_go(SFEngine* engine,
           int depth,
           int movetimeMs,
           void* context,
           SFInfoHandler onInfo,
           SFBestMoveHandler onBestMove);

void sf_stop(SFEngine* engine);
void sf_wait_for_search(SFEngine* engine);

#ifdef __cplusplus
}
#endif

#endif
