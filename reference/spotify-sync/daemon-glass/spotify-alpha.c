/* Spotify/CEF background alpha compatibility helper.
 * Derived from fixpointer/libcef-transparency-linux (MIT, copyright 2025 fixpointer).
 * See accompanying LICENSE. The launcher gates this helper on both ELF build IDs.
 * Only process memory is changed; installed executables remain untouched.
 */
#define _GNU_SOURCE
#include <link.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

static int write_code(unsigned char *p, const unsigned char *bytes, size_t n) {
    uintptr_t page = (uintptr_t)p & ~(uintptr_t)4095;
    size_t len = (((uintptr_t)p + n + 4095) & ~(uintptr_t)4095) - page;
    if (mprotect((void *)page, len, PROT_READ | PROT_WRITE)) return 0;
    memcpy(p, bytes, n);
    return mprotect((void *)page, len, PROT_READ | PROT_EXEC) == 0;
}

static int executable_range(const char *path, unsigned char **begin, unsigned char **end) {
    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) return 0;
    char line[4096], name[3072], perms[8];
    unsigned long start, stop;
    int found = 0;
    while (fgets(line, sizeof line, f)) {
        name[0] = 0;
        if (sscanf(line, "%lx-%lx %7s %*s %*s %*s %3071[^\n]", &start, &stop, perms, name) != 4) continue;
        if (strchr(perms, 'x') && !strcmp(path, name)) {
            *begin = (unsigned char *)start; *end = (unsigned char *)stop; found = 1; break;
        }
    }
    fclose(f);
    return found;
}

unsigned int la_version(unsigned int version) {
    (void)version;
    char exe[3072];
    ssize_t n = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (n < 0) return LAV_CURRENT;
    exe[n] = 0;
    if (strcmp(exe, "/opt/spotify/spotify")) return LAV_CURRENT;
    unsigned char *start, *end;
    if (!executable_range(exe, &start, &end)) return LAV_CURRENT;
    int count = 0;
    const unsigned char transparent[4] = {0};
    for (unsigned char *p = start + 8; p + 4 <= end; ++p) {
        if (memcmp(p, "\x12\x12\x12\xff", 4)) continue;
        /* mov imm32 into a register, or mov imm32 into a small struct offset. */
        int reg = (p[-1] & 0xf8) == 0xb8;
        int mem = p[-6] == 0xc7 && (p[-5] & 0xf8) == 0x80 &&
                  (p[-3] & 0xf0) == 0 && p[-2] == 0 && p[-1] == 0;
        if ((reg || mem) && write_code(p, transparent, sizeof transparent)) ++count;
    }
    fprintf(stderr, "[spotify-glass] transparent CEF background: %d color sites\n", count);
    return LAV_CURRENT;
}

unsigned int la_objopen(struct link_map *map, Lmid_t lmid, uintptr_t *cookie) {
    (void)lmid; (void)cookie;
    const char *name = strrchr(map->l_name, '/');
    if (!name || strcmp(name + 1, "libcef.so")) return 0;
    unsigned char *start, *end;
    if (!executable_range(map->l_name, &start, &end)) return 0;
    /* Exact validated instruction sequence for the pinned CEF build, unique in .text. */
    static const unsigned char pattern[] = {
        0x41,0x8b,0x46,0x18,0x85,0xc0,0x74,0x0a,0x83,0xf8,0x02,0x74,0x0f,
        0x45,0x31,0xe4,0xeb,0x0d,0x41,0x83,0x3e,0x04,0x41,0x0f,0x94,0xc4,
        0xeb,0x03,0x41,0xb4,0x01
    };
    unsigned char *match = NULL;
    int count = 0;
    for (unsigned char *p = start; p + sizeof pattern <= end; ++p) {
        if (!memcmp(p, pattern, sizeof pattern)) { match = p; ++count; }
    }
    if (count != 1) { fprintf(stderr, "[spotify-glass] incompatible CEF; native alpha disabled\n"); return 0; }
    unsigned char replacement[sizeof pattern];
    memset(replacement, 0x90, sizeof replacement);
    replacement[0] = 0x41; replacement[1] = 0xb4; replacement[2] = 0x01;
    if (write_code(match, replacement, sizeof replacement))
        fprintf(stderr, "[spotify-glass] native X11 alpha enabled\n");
    return 0;
}
