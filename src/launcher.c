/* Original app-only launcher. Does not edit services, firmware or boot settings. */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <limits.h>

/* Escape a filesystem path as a JSON string, including unusual checkout names. */
static int json_string(const char *s, char *out, size_t cap) {
    size_t n = 0;
    if (cap < 3) return -1;
    out[n++] = '"';
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        if (*p < 32 || *p == '"' || *p == '\\') {
            if (n + 6 >= cap) return -1;
            int added = snprintf(out+n, cap-n, "\\u%04x", *p);
            n += (size_t)added;
        } else {
            if (n + 1 >= cap) return -1;
            out[n++] = (char)*p;
        }
    }
    if (n + 2 > cap) return -1;
    out[n++] = '"'; out[n] = 0;
    return 0;
}

#ifndef FIREWATCH_LAUNCHER_UNIT_TEST
int main(void) {
    static const char id[] = "uk.local.minimalhome.native";
    static const char data[] = "/media/developer/.minimalhome-native";
    char main_file[PATH_MAX], escaped[PATH_MAX*6+3], payload[PATH_MAX*6+128];
    ssize_t n = readlink("/proc/self/exe", main_file, sizeof(main_file)-1);
    if (n <= 0 || n >= (ssize_t)sizeof(main_file)-1) {
        fputs("Firewatch Home: unable to locate application directory\n", stderr);
        return 126;
    }
    main_file[n] = 0;
    char *slash = strrchr(main_file, '/');
    if (!slash || (size_t)(slash-main_file)+sizeof("/main.qml") > sizeof(main_file)) return 126;
    strcpy(slash, "/main.qml");
    if (access(main_file, R_OK) || json_string(main_file, escaped, sizeof(escaped))) {
        fputs("Firewatch Home: main.qml is unavailable\n", stderr);
        return 126;
    }
    int len = snprintf(payload, sizeof(payload), "{\"main\":%s,\"appId\":\"%s\",\"params\":{}}", escaped, id);
    if (len < 0 || (size_t)len >= sizeof(payload)) return 126;
    struct stat st;
    if ((mkdir(data, 0700) && errno != EEXIST) || lstat(data, &st) ||
        !S_ISDIR(st.st_mode) || st.st_uid != geteuid()) {
        fputs("Firewatch Home: preference directory unavailable or unexpected ownership\n", stderr);
        return 126;
    }
    if (setenv("QSG_RENDER_LOOP", "threaded", 1) ||
        unsetenv("WEBOS_GL_DISABLE_THREADED_RENDERING")) {
        perror("Firewatch Home renderer environment");
        return 126;
    }
    /* Preserve the tested qml-runner argument contract. No shell or eval. */
    execl("/usr/bin/qml-runner", "qml-runner", "--appid", id, payload, (char *)0);
    perror("Firewatch Home qml-runner");
    return 127;
}
#endif
