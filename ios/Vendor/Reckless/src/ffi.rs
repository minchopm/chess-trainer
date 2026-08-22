//! A flat C surface over the engine, for embedding in applications.
//!
//! This file exists because the crate exports nothing usable: `lib.rs` declares
//! every module private, so a wrapper crate that merely depends on `reckless`
//! cannot reach the search. It is written to need no other change — a sibling
//! module can see the crate root's private modules, which is exactly what
//! `wasm.rs` already relies on. The whole fork is this file, one `mod` line, and
//! one entry in `[lib] crate-type`.
//!
//! The shape is `bridge/include/reckless.h`, which in turn mirrors the host
//! application's Stockfish bridge. Where the two engines disagree the comments
//! say so.

use std::{
    collections::HashMap,
    ffi::{CStr, CString, c_char, c_int, c_longlong, c_void},
    sync::{
        Arc, Mutex,
        atomic::{AtomicU64, Ordering},
    },
    thread::JoinHandle,
    time::Duration,
};

use crate::{
    board::Board,
    search::Report,
    thread::{SharedContext, Status, StdoutWriter, ThreadData, UciWriter},
    threadpool::ThreadPool,
    time::{Limits, TimeManager},
    types::{Move, Score, is_decisive, is_loss, is_win},
};

/// Matches `sf_go`'s behaviour when asked for neither a depth nor a time.
const DEFAULT_DEPTH: i32 = 12;

#[repr(C)]
pub struct RKInfo {
    pub depth: c_int,
    pub sel_depth: c_int,
    pub multi_pv: c_int,
    pub score_cp: c_int,
    pub score_mate: c_int,
    pub is_mate: bool,
    pub nodes: c_longlong,
    pub time_ms: c_longlong,
    pub pv: *const c_char,
}

pub type RKInfoHandler = Option<unsafe extern "C" fn(*mut c_void, *const RKInfo)>;
pub type RKBestMoveHandler =
    Option<unsafe extern "C" fn(*mut c_void, *const c_char, *const c_char)>;

/// The caller's opaque context and its two handlers, travelling together.
///
/// Sent to the search thread, hence the `Send`: the pointer is the caller's to
/// keep valid, which is the same contract the Stockfish bridge works under.
#[derive(Clone, Copy)]
struct Callbacks {
    context: *mut c_void,
    on_info: RKInfoHandler,
    on_best_move: RKBestMoveHandler,
}

unsafe impl Send for Callbacks {}

/// Turns the engine's UCI `info` lines back into a struct.
///
/// Reckless reports through a `UciWriter` that is handed a formatted line, so a
/// structured callback means parsing what `ThreadData::print_uci_info` just
/// printed. That is a round trip, and it is still the right trade: the
/// alternative is a second copy of the formatting logic living in this file,
/// which would have to be kept in step with upstream's every time the info
/// format changed. Parsing tolerates fields moving and ignores ones it does not
/// know; duplicated formatting would silently disagree.
struct CallbackWriter {
    callbacks: Callbacks,
}

impl UciWriter for CallbackWriter {
    fn write_line(&mut self, line: &str) {
        let Some(on_info) = self.callbacks.on_info else { return };

        let mut info = RKInfo {
            depth: 0,
            sel_depth: 0,
            multi_pv: 1,
            score_cp: 0,
            score_mate: 0,
            is_mate: false,
            nodes: 0,
            time_ms: 0,
            pv: std::ptr::null(),
        };
        let mut pv = String::new();

        let mut tokens = line.split_whitespace();
        while let Some(token) = tokens.next() {
            match token {
                "depth" => info.depth = number(&mut tokens) as c_int,
                "seldepth" => info.sel_depth = number(&mut tokens) as c_int,
                "multipv" => info.multi_pv = number(&mut tokens) as c_int,
                "nodes" => info.nodes = number(&mut tokens) as c_longlong,
                "time" => info.time_ms = number(&mut tokens) as c_longlong,
                "score" => match tokens.next() {
                    // Already normalised to centipawns by `normalize_to_cp`, and
                    // already in moves rather than plies — the same units the
                    // Stockfish bridge hands over.
                    Some("cp") => info.score_cp = number(&mut tokens) as c_int,
                    Some("mate") => {
                        info.is_mate = true;
                        info.score_mate = number(&mut tokens) as c_int;
                    }
                    _ => {}
                },
                // Last field of the line, so this consumes the rest.
                "pv" => pv = tokens.by_ref().collect::<Vec<_>>().join(" "),
                _ => {}
            }
        }

        let pv = CString::new(pv).unwrap_or_default();
        info.pv = pv.as_ptr();
        unsafe { on_info(self.callbacks.context, &info) };
    }
}

struct Inner {
    threads: ThreadPool,
    board: Board,
    multi_pv: usize,
    move_overhead: u64,
    report: Report,
}

pub struct RKEngine {
    /// The position and the thread pool. Held under a lock so that a caller who
    /// ignores the one-search-at-a-time rule blocks rather than races.
    inner: Mutex<Inner>,
    /// Reachable without the lock, which is what makes `rk_stop` able to
    /// interrupt a search rather than queue behind it.
    shared: Arc<SharedContext>,
    search: Mutex<Option<JoinHandle<()>>>,
    /// Bumped per search so a deadline thread that wakes late cannot stop the
    /// search after the one it was armed for.
    generation: AtomicU64,
}

/// A handle pointer sent to the search thread.
///
/// Safe under the same contract as the rest of the surface: `rk_destroy` stops
/// and joins before freeing, so the reference cannot outlive the engine.
struct EnginePtr(*const RKEngine);
unsafe impl Send for EnginePtr {}

/// Initialise the global tables. Safe to call more than once — and it has to be,
/// because `rk_create` calls it too and a caller following `sf_global_init`'s
/// example will call it first.
///
/// The guard is not decoration. `lookup::initialize` builds a cuckoo table by
/// insertion, evicting whatever occupies a slot and re-inserting that. On an
/// empty table it terminates when an eviction yields the empty entry; on a table
/// that is already full it never yields one, and the loop runs forever. Upstream
/// never notices — `run()` calls it once at startup — but nothing in the
/// function says so, and calling it twice hangs the process on a spinning thread
/// with no diagnostic at all.
#[unsafe(no_mangle)]
pub extern "C" fn rk_global_init() {
    static ONCE: std::sync::Once = std::sync::Once::new();
    ONCE.call_once(|| {
        crate::lookup::initialize();
        crate::nnue::initialize();
    });
}

/// The upstream commit this tree was taken from.
///
/// Hard-coded rather than read from `ENGINE_VERSION`, which `build/build.rs`
/// builds by running `git rev-parse` in the manifest directory. A vendored copy
/// has no repository of its own, so that command answers with the *host*
/// project's HEAD and the engine would report a version belonging to something
/// else entirely.
const UPSTREAM_COMMIT: &str = "789de891";

#[unsafe(no_mangle)]
pub extern "C" fn rk_engine_info() -> *const c_char {
    static INFO: std::sync::OnceLock<CString> = std::sync::OnceLock::new();
    INFO.get_or_init(|| {
        let version = env!("CARGO_PKG_VERSION");
        CString::new(format!("Reckless {version}-{UPSTREAM_COMMIT}")).unwrap_or_default()
    })
    .as_ptr()
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_create() -> *mut RKEngine {
    rk_global_init();

    let shared = Arc::new(SharedContext::default());
    let threads = ThreadPool::new(shared.clone());

    Box::into_raw(Box::new(RKEngine {
        inner: Mutex::new(Inner {
            threads,
            board: Board::starting_position(),
            multi_pv: 1,
            move_overhead: 0,
            report: Report::Full,
        }),
        shared,
        search: Mutex::new(None),
        generation: AtomicU64::new(0),
    }))
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_destroy(engine: *mut RKEngine) {
    if engine.is_null() {
        return;
    }
    rk_stop(engine);
    rk_wait_for_search(engine);
    drop(unsafe { Box::from_raw(engine) });
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_set_option(
    engine: *mut RKEngine, name: *const c_char, value: *const c_char,
) {
    let Some(engine) = (unsafe { engine.as_ref() }) else { return };
    let (Some(name), Some(value)) = (to_str(name), to_str(value)) else { return };

    let mut inner = lock(&engine.inner);
    match name {
        // Both of these rebuild per-thread state, so they must not land while a
        // search is reading it. The lock is what guarantees that.
        "Threads" => {
            let count = value.parse().unwrap_or(1);
            inner.threads.set_count(count);
        }
        "Hash" => {
            let megabytes = value.parse().unwrap_or(16);
            let threads = inner.threads.len();
            engine.shared.tt.resize(threads, megabytes);
        }
        "MultiPV" => inner.multi_pv = value.parse().unwrap_or(1).max(1),
        "MoveOverhead" => inner.move_overhead = value.parse().unwrap_or(0),
        "Minimal" => inner.report = if value == "true" { Report::Minimal } else { Report::Full },
        _ => {}
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_new_game(engine: *mut RKEngine) {
    let Some(engine) = (unsafe { engine.as_ref() }) else { return };
    let mut inner = lock(&engine.inner);

    // Mirrors uci.rs's `ucinewgame`: clearing the pool alone leaves the shared
    // correction history carrying the last game's biases into this one.
    inner.threads.clear();
    let threads = inner.threads.len();
    engine.shared.tt.clear(threads);
    for corrhist in engine.shared.history.all() {
        corrhist.pawn.clear();
        corrhist.non_pawn[crate::types::Color::White].clear();
        corrhist.non_pawn[crate::types::Color::Black].clear();
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_set_position(engine: *mut RKEngine, fen: *const c_char) -> bool {
    let Some(engine) = (unsafe { engine.as_ref() }) else { return false };
    let Some(fen) = to_str(fen) else { return false };

    // `wasm.rs` answers an unparseable FEN with the starting position. Here it is
    // an error instead: silently searching a different position than the one the
    // caller asked about is the harder bug to find, and `sf_set_position` returns
    // a bool for the same reason.
    let Ok(board) = Board::from_fen(fen) else { return false };

    lock(&engine.inner).board = board;
    true
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_go(
    engine: *mut RKEngine, depth: c_int, movetime_ms: c_int, context: *mut c_void,
    on_info: RKInfoHandler, on_best_move: RKBestMoveHandler,
) {
    if engine.is_null() {
        return;
    }
    // A previous search must be finished before its thread handle is replaced,
    // or the handle is dropped and the thread detached with the callback context
    // still live.
    rk_wait_for_search(engine);

    let callbacks = Callbacks { context, on_info, on_best_move };
    let pointer = EnginePtr(engine);

    let handle = std::thread::Builder::new()
        .name("reckless-search".to_owned())
        .spawn(move || {
            let pointer = pointer;
            run_search(unsafe { &*pointer.0 }, depth, movetime_ms, callbacks);
        });

    if let Ok(handle) = handle {
        *lock(&unsafe { &*engine }.search) = Some(handle);
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_stop(engine: *mut RKEngine) {
    let Some(engine) = (unsafe { engine.as_ref() }) else { return };
    engine.shared.status.set(Status::STOPPED);
}

#[unsafe(no_mangle)]
pub extern "C" fn rk_wait_for_search(engine: *mut RKEngine) {
    let Some(engine) = (unsafe { engine.as_ref() }) else { return };
    let handle = lock(&engine.search).take();
    if let Some(handle) = handle {
        let _ = handle.join();
    }
}

fn run_search(engine: &RKEngine, depth: c_int, movetime_ms: c_int, callbacks: Callbacks) {
    let generation = engine.generation.fetch_add(1, Ordering::AcqRel) + 1;

    let mut guard = lock(&engine.inner);
    let inner = &mut *guard;

    // Reckless's `Limits` is one enum, so it cannot say "this deep, but no longer
    // than this" — which is exactly the pair `sf_go` documents and the pair the
    // app passes. A depth-limited search plus a deadline that stops it gives the
    // same meaning. When only a time is given, the engine's own time management
    // is better than an external deadline, so `Limits::Time` is used instead.
    let limits = match (depth > 0, movetime_ms > 0) {
        (true, _) => Limits::Depth(depth),
        (false, true) => Limits::Time(movetime_ms as u64),
        (false, false) => Limits::Depth(DEFAULT_DEPTH),
    };
    let deadline = (depth > 0 && movetime_ms > 0).then_some(movetime_ms as u64);

    if let Some(deadline) = deadline {
        let shared = engine.shared.clone();
        let ptr = EnginePtr(engine);
        let _ = std::thread::Builder::new().name("reckless-deadline".to_owned()).spawn(move || {
            let ptr = ptr;
            std::thread::sleep(Duration::from_millis(deadline));
            // Only stop the search this deadline was armed for. Without the
            // check, a deadline that wakes after its own search finished would
            // cut the *next* one short at whatever depth it had reached.
            if unsafe { &*ptr.0 }.generation.load(Ordering::Acquire) == generation {
                shared.status.set(Status::STOPPED);
            }
        });
    }

    // Only thread 0 reports, so only thread 0 needs the writer. Installed here
    // rather than at creation because `set_count` and `clear` rebuild the thread
    // data and would drop it.
    inner.threads[0].writer = Box::new(CallbackWriter { callbacks });

    let time_manager =
        TimeManager::new(limits, inner.board.fullmove_number(), inner.move_overhead);
    inner.threads.execute_searches(
        time_manager,
        inner.report,
        inner.multi_pv,
        &inner.board,
        &engine.shared,
    );

    inner.threads[0].writer = Box::new(StdoutWriter);

    let Some(on_best_move) = callbacks.on_best_move else { return };

    let best = best_move(&inner.threads, &inner.board);
    let best = CString::new(best).unwrap_or_default();
    let ponder = CString::default();
    // Dropped only after the call returns, so both pointers are valid for its
    // duration — the same lifetime `sf_go`'s handler gets.
    unsafe { on_best_move(callbacks.context, best.as_ptr(), ponder.as_ptr()) };
}

/// The move to play, chosen the way `uci.rs::go` chooses it.
///
/// Not simply thread 0's first root move: with more than one thread the engine
/// votes, weighting each thread's answer by how deep it got and how much better
/// than the worst it scored. `wasm.rs` skips this and takes thread 0, which is
/// right only at one thread. Kept faithful to upstream so that raising Threads
/// does not quietly change which move comes back.
fn best_move(threads: &ThreadPool, board: &Board) -> String {
    if threads[0].root_moves.is_empty() {
        return "(none)".to_owned();
    }

    let min_score = threads.iter().map(|v| v.root_moves[0].score).min().unwrap();
    let vote_value = |td: &ThreadData| (td.root_moves[0].score - min_score + 10) * td.completed_depth;

    let mut votes: HashMap<&Move, i32> = HashMap::new();
    for result in threads.iter() {
        *votes.entry(&result.root_moves[0].mv).or_default() += vote_value(result);
    }

    let mut best = 0;

    if !matches!(threads[best].time_manager.limits(), Limits::Depth(_)) && threads[0].multi_pv == 1 {
        for current in 1..threads.len() {
            let is_better_candidate = || -> bool {
                let best = &threads[best];
                let current = &threads[current];

                if is_win(best.root_moves[0].score) {
                    return current.root_moves[0].score > best.root_moves[0].score;
                }

                if current.root_moves[0].score != -Score::INFINITE
                    && best.root_moves[0].score != -Score::INFINITE
                    && is_loss(best.root_moves[0].score)
                {
                    return current.root_moves[0].score < best.root_moves[0].score;
                }

                if current.root_moves[0].score != -Score::INFINITE
                    && is_decisive(current.root_moves[0].score)
                {
                    return true;
                }

                let best_vote = votes[&best.root_moves[0].mv];
                let current_vote = votes[&current.root_moves[0].mv];

                !is_loss(current.root_moves[0].score)
                    && (current_vote > best_vote
                        || (current_vote == best_vote && vote_value(current) > vote_value(best)))
            };

            if is_better_candidate() {
                best = current;
            }
        }
    }

    threads[best].root_moves[0].mv.to_uci(board)
}

fn number(tokens: &mut std::str::SplitWhitespace<'_>) -> i64 {
    tokens.next().and_then(|v| v.parse::<i64>().ok()).unwrap_or(0)
}

fn to_str<'a>(pointer: *const c_char) -> Option<&'a str> {
    if pointer.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(pointer) }.to_str().ok()
}

/// A poisoned lock means a previous search panicked. The engine is no worse off
/// for carrying on, and a panic here would cross the FFI boundary into Swift.
fn lock<T>(mutex: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
}
