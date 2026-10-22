#ifndef HELIX_LOCK_H
#define HELIX_LOCK_H
/* A mutex for the native adapters' C, shared with the platform's threads (the audio callback, decoding workers): a slim reader/writer lock
 * held exclusively on Windows, whose MSVC has no pthreads, and pthread's mutex elsewhere. Neither is recursive. */
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
typedef SRWLOCK helix_lock_t;
#define HELIX_LOCK_INIT SRWLOCK_INIT
static inline void helix_lock(helix_lock_t *lock) { AcquireSRWLockExclusive(lock); }
static inline void helix_unlock(helix_lock_t *lock) { ReleaseSRWLockExclusive(lock); }
#else
#include <pthread.h>
typedef pthread_mutex_t helix_lock_t;
#define HELIX_LOCK_INIT PTHREAD_MUTEX_INITIALIZER
static inline void helix_lock(helix_lock_t *lock) { pthread_mutex_lock(lock); }
static inline void helix_unlock(helix_lock_t *lock) { pthread_mutex_unlock(lock); }
#endif
#endif
