#define STR_WITH_LEN(str) (str), (sizeof(str) - 1) 

// Like assert(), but executed even in NDEBUG mode
#undef CHECK_CONDITION
#define CHECK_CONDITION(cond)                                            \
do {                                                                     \
  if (!(cond)) {                                                         \
    ::tcmalloc::Log(::tcmalloc::kCrash, __FILE__, __LINE__, #cond);      \
  }                                                                      \
} while (0)

// Our own version of assert() so we can avoid hanging by trying to do
// all kinds of goofy printing while holding the malloc lock.
#ifndef NDEBUG
#define ASSERT(cond) CHECK_CONDITION(cond)
#else
#define ASSERT(cond) ((void) 0)
#endif




#define handler_error(msg) \
    do { perror(msg); exit(EXIT_FAILURE); } while (0)

int error_wrap ( int retval, const char *func_name) {
    if (retval < 0) {
        fprintf(stderr, "%s returned %d (errno: %d) (%s)\n", func_name, retval, errno, strerr(errno));

        abort();
    }
    return retval;
}


error_wrap(socket(PF_INET, SOCK_STREAM, 0), "socket");
