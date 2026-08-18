#include "include/sfbridge.h"

#include <atomic>
#include <cstdio>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "bitboard.h"
#include "engine.h"
#include "misc.h"
#include "position.h"
#include "search.h"
#include "tune.h"
#include "uci.h"

using namespace Stockfish;

namespace {
std::once_flag g_initOnce;
}

struct SFEngine {
    Engine engine;
    void* context = nullptr;
    SFInfoHandler onInfo = nullptr;
    SFBestMoveHandler onBestMove = nullptr;
    std::string currentFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
};

void sf_global_init(void) {
    std::call_once(g_initOnce, [] {
        Bitboards::init();
        Position::init();
    });
}

const char* sf_engine_info(void) {
    static std::string info = engine_info();
    return info.c_str();
}

SFEngine* sf_create(void) {
    sf_global_init();
    auto* handle = new SFEngine();

    handle->engine.set_on_update_full([handle](const Engine::InfoFull& info) {
        if (!handle->onInfo) return;

        SFInfo out{};
        out.depth = info.depth;
        out.selDepth = info.selDepth;
        out.multiPV = static_cast<int>(info.multiPV);
        out.nodes = static_cast<long long>(info.nodes);
        out.timeMs = static_cast<long long>(info.timeMs);

        // Score is a variant. Mate is reported in moves, matching UCI; the
        // internal-units case is already normalised to centipawns by the time
        // it reaches here.
        if (info.score.is<Score::Mate>()) {
            const auto mate = info.score.get<Score::Mate>();
            out.isMate = true;
            out.scoreMate = (mate.plies > 0 ? (mate.plies + 1) : mate.plies) / 2;
        } else if (info.score.is<Score::Tablebase>()) {
            const auto tb = info.score.get<Score::Tablebase>();
            out.isMate = false;
            out.scoreCp = tb.win ? 20000 - tb.plies : -20000 - tb.plies;
        } else {
            out.isMate = false;
            out.scoreCp = info.score.get<Score::InternalUnits>().value;
        }

        const std::string pv(info.pv);
        out.pv = pv.c_str();
        handle->onInfo(handle->context, &out);
    });

    handle->engine.set_on_bestmove([handle](std::string_view best, std::string_view ponder) {
        if (!handle->onBestMove) return;
        const std::string bestMove(best);
        const std::string ponderMove(ponder);
        handle->onBestMove(handle->context, bestMove.c_str(), ponderMove.c_str());
    });

    // Every one of Stockfish's five listeners must be set, not just the ones
    // whose output we want. They are std::functions it calls unconditionally,
    // and an unset one throws std::bad_function_call from the search thread —
    // which ends the process with no diagnostic. The position that triggers
    // this is any terminal one: with no legal moves the search reports through
    // onUpdateNoMoves rather than the usual path.
    handle->engine.set_on_update_no_moves([](const Engine::InfoShort&) {});
    handle->engine.set_on_iter([](const Engine::InfoIter&) {});
    handle->engine.set_on_verify_networks([](std::string_view) {});

    Tune::init(handle->engine.get_options());
    return handle;
}

void sf_destroy(SFEngine* engine) {
    if (!engine) return;
    engine->engine.stop();
    engine->engine.wait_for_search_finished();
    delete engine;
}

bool sf_load_networks(SFEngine* engine, const char* bigNetPath, const char* smallNetPath) {
    if (!engine || !bigNetPath || !smallNetPath) return false;

    // Check readability first. Stockfish reacts to a missing net by calling
    // exit(), which in an app means a crash with no explanation.
    for (const char* path : {bigNetPath, smallNetPath}) {
        std::FILE* file = std::fopen(path, "rb");
        if (!file) return false;
        std::fclose(file);
    }

    // Set the options rather than calling load_*_network directly.
    //
    // Each option's callback does the loading, and — the part that matters —
    // Engine::go later calls verify_networks(), which compares the loaded file
    // against options["EvalFile"]. Loading by path without updating the option
    // leaves those disagreeing, and verify answers a disagreement by calling
    // exit(): the app vanishes with no error at the first search.
    sf_set_option(engine, "EvalFile", bigNetPath);
    sf_set_option(engine, "EvalFileSmall", smallNetPath);
    return true;
}

void sf_set_option(SFEngine* engine, const char* name, const char* value) {
    if (!engine || !name || !value) return;

    // OptionsMap only exposes a const subscript, so options are set the same way
    // the UCI layer does it — by handing setoption the token stream it expects.
    // Changing an option mid-search is undefined, hence the wait.
    engine->engine.wait_for_search_finished();
    std::istringstream stream(std::string("name ") + name + " value " + value);
    engine->engine.get_options().setoption(stream);
}

void sf_new_game(SFEngine* engine) {
    if (!engine) return;
    engine->engine.search_clear();
}

bool sf_set_position(SFEngine* engine, const char* fen) {
    if (!engine || !fen) return false;
    engine->currentFEN = fen;
    engine->engine.set_position(engine->currentFEN, {});
    return true;
}

void sf_go(SFEngine* engine,
           int depth,
           int movetimeMs,
           void* context,
           SFInfoHandler onInfo,
           SFBestMoveHandler onBestMove) {
    if (!engine) return;

    engine->context = context;
    engine->onInfo = onInfo;
    engine->onBestMove = onBestMove;

    Search::LimitsType limits;
    limits.startTime = now();
    if (depth > 0) limits.depth = depth;
    if (movetimeMs > 0) limits.movetime = movetimeMs;
    if (depth <= 0 && movetimeMs <= 0) limits.depth = 12;

    engine->engine.go(limits);
}

void sf_stop(SFEngine* engine) {
    if (engine) engine->engine.stop();
}

void sf_wait_for_search(SFEngine* engine) {
    if (engine) engine->engine.wait_for_search_finished();
}
