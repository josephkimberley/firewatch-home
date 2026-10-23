/* Own-process environment only. No daemon, system configuration or boot edits. */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

int main(void) {
    static const char id[] = "uk.local.minimalhome.native";
    static const char payload[] = "{\"main\":\"/media/developer/apps/usr/palm/applications/uk.local.minimalhome.native/main.qml\",\"appId\":\"uk.local.minimalhome.native\",\"params\":{}}";
    static const char data[] = "/media/developer/.minimalhome-native";
    struct stat st;
    if ((mkdir(data, 0700) && errno != EEXIST) || lstat(data, &st) ||
        !S_ISDIR(st.st_mode) || st.st_uid != geteuid()) {
        fputs("Minimal Home data directory is unavailable or has unexpected ownership\n", stderr);
        return 126;
    }
    if (setenv("QSG_RENDER_LOOP", "threaded", 1) ||
        unsetenv("WEBOS_GL_DISABLE_THREADED_RENDERING")) {
        perror("Minimal Home renderer environment");
        return 126;
    }
    execl("/usr/bin/qml-runner", "qml-runner", "--appid", id, payload, (char *)0);
    perror("Minimal Home qml-runner");
    return 127;
}
