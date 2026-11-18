// JNI over the flat C bridge to Stockfish (ios/Vendor/Stockfish/bridge), so
// the Android app drives the engine exactly as the iOS app does.
//
// Search callbacks arrive on Stockfish's own search thread. That thread is
// attached to the VM the first time it calls back and detached when it exits
// (a thread that dies attached aborts the process).
#include <jni.h>
#include <pthread.h>
#include <string>

#include "sfbridge.h"

namespace {

JavaVM* g_vm = nullptr;
pthread_key_t g_detachKey;
pthread_once_t g_detachOnce = PTHREAD_ONCE_INIT;

void detachThread(void*) {
    if (g_vm) g_vm->DetachCurrentThread();
}

void makeDetachKey() { pthread_key_create(&g_detachKey, detachThread); }

JNIEnv* attachedEnv() {
    JNIEnv* env = nullptr;
    if (g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK) return env;
    if (g_vm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK) return nullptr;
    pthread_once(&g_detachOnce, makeDetachKey);
    pthread_setspecific(g_detachKey, env);
    return env;
}

// One per engine: the listener of the search under way.
struct Session {
    SFEngine* engine = nullptr;
    jobject listener = nullptr;   // global ref, replaced at every go
    jmethodID onInfo = nullptr;
    jmethodID onBestMove = nullptr;
};

void handleInfo(void* context, const SFInfo* info) {
    auto* session = static_cast<Session*>(context);
    JNIEnv* env = attachedEnv();
    if (!env || !session->listener) return;
    jstring pv = env->NewStringUTF(info->pv ? info->pv : "");
    env->CallVoidMethod(session->listener, session->onInfo,
                        static_cast<jint>(info->depth), static_cast<jint>(info->selDepth),
                        static_cast<jint>(info->multiPV), static_cast<jint>(info->scoreCp),
                        static_cast<jint>(info->scoreMate), static_cast<jboolean>(info->isMate),
                        static_cast<jlong>(info->nodes), static_cast<jlong>(info->timeMs), pv);
    env->DeleteLocalRef(pv);
    if (env->ExceptionCheck()) env->ExceptionClear();
}

void handleBestMove(void* context, const char* bestMove, const char* ponder) {
    auto* session = static_cast<Session*>(context);
    JNIEnv* env = attachedEnv();
    if (!env || !session->listener) return;
    jstring best = env->NewStringUTF(bestMove ? bestMove : "");
    jstring pond = env->NewStringUTF(ponder ? ponder : "");
    env->CallVoidMethod(session->listener, session->onBestMove, best, pond);
    env->DeleteLocalRef(best);
    env->DeleteLocalRef(pond);
    if (env->ExceptionCheck()) env->ExceptionClear();
}

std::string text(JNIEnv* env, jstring value) {
    if (!value) return {};
    const char* chars = env->GetStringUTFChars(value, nullptr);
    std::string out(chars ? chars : "");
    if (chars) env->ReleaseStringUTFChars(value, chars);
    return out;
}

Session* session(jlong handle) { return reinterpret_cast<Session*>(handle); }

}  // namespace

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    g_vm = vm;
    return JNI_VERSION_1_6;
}

#define SF(name) Java_com_artesoft_brasspawn_engine_StockfishNative_##name

JNIEXPORT jstring JNICALL SF(engineInfo)(JNIEnv* env, jobject) {
    return env->NewStringUTF(sf_engine_info());
}

JNIEXPORT jlong JNICALL SF(create)(JNIEnv*, jobject) {
    auto* s = new Session();
    s->engine = sf_create();
    return reinterpret_cast<jlong>(s);
}

JNIEXPORT void JNICALL SF(destroy)(JNIEnv* env, jobject, jlong handle) {
    auto* s = session(handle);
    if (!s) return;
    sf_destroy(s->engine);
    if (s->listener) env->DeleteGlobalRef(s->listener);
    delete s;
}

JNIEXPORT jboolean JNICALL SF(loadNetworks)(JNIEnv* env, jobject, jlong handle, jstring big, jstring small) {
    return sf_load_networks(session(handle)->engine, text(env, big).c_str(), text(env, small).c_str());
}

JNIEXPORT void JNICALL SF(setOption)(JNIEnv* env, jobject, jlong handle, jstring name, jstring value) {
    sf_set_option(session(handle)->engine, text(env, name).c_str(), text(env, value).c_str());
}

JNIEXPORT void JNICALL SF(newGame)(JNIEnv*, jobject, jlong handle) {
    sf_new_game(session(handle)->engine);
}

JNIEXPORT jboolean JNICALL SF(setPosition)(JNIEnv* env, jobject, jlong handle, jstring fen) {
    return sf_set_position(session(handle)->engine, text(env, fen).c_str());
}

// The previous search must have finished (the Kotlin side waits for its best
// move, or stops it and waits) before the listener is replaced.
JNIEXPORT void JNICALL SF(go)(JNIEnv* env, jobject, jlong handle, jint depth, jint movetimeMs, jobject listener) {
    auto* s = session(handle);
    sf_wait_for_search(s->engine);
    if (s->listener) env->DeleteGlobalRef(s->listener);
    s->listener = env->NewGlobalRef(listener);
    jclass type = env->GetObjectClass(listener);
    s->onInfo = env->GetMethodID(type, "onInfo", "(IIIIIZJJLjava/lang/String;)V");
    s->onBestMove = env->GetMethodID(type, "onBestMove", "(Ljava/lang/String;Ljava/lang/String;)V");
    sf_go(s->engine, depth, movetimeMs, s, handleInfo, handleBestMove);
}

JNIEXPORT void JNICALL SF(stop)(JNIEnv*, jobject, jlong handle) { sf_stop(session(handle)->engine); }

JNIEXPORT void JNICALL SF(waitForSearch)(JNIEnv*, jobject, jlong handle) {
    sf_wait_for_search(session(handle)->engine);
}

}  // extern "C"
