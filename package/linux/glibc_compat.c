/* Link-time shim so binaries built on a new glibc (2.44, CachyOS) run on glibc >= 2.34.
   Link with -Wl,--wrap=<sym> for every symbol below; each __wrap_ calls the old symbol version. */
#include <stdarg.h>
#include <stdio.h>
#include <wchar.h>
#define OLD(ret, name, ver, args) extern ret old_##name args; __asm__(".symver old_" #name "," #name "@" ver);
OLD(double, sinh, "GLIBC_2.2.5", (double))
OLD(float, atan2f, "GLIBC_2.2.5", (float, float))
OLD(float, sqrtf, "GLIBC_2.2.5", (float))
OLD(float, log10f, "GLIBC_2.2.5", (float))
OLD(float, acosf, "GLIBC_2.2.5", (float))
OLD(float, asinf, "GLIBC_2.2.5", (float))
OLD(double, fmod, "GLIBC_2.2.5", (double, double))
OLD(float, fmodf, "GLIBC_2.2.5", (float, float))
OLD(long, strtol, "GLIBC_2.2.5", (const char *, char **, int))
OLD(unsigned long, strtoul, "GLIBC_2.2.5", (const char *, char **, int))
OLD(long long, strtoll, "GLIBC_2.2.5", (const char *, char **, int))
OLD(unsigned long long, strtoull, "GLIBC_2.2.5", (const char *, char **, int))
OLD(long, wcstol, "GLIBC_2.2.5", (const wchar_t *, wchar_t **, int))
OLD(int, __isoc99_vsscanf, "GLIBC_2.7", (const char *, const char *, va_list))
OLD(int, __isoc99_vfscanf, "GLIBC_2.7", (FILE *, const char *, va_list))

double __wrap_sinh(double x) { return old_sinh(x); }
float __wrap_atan2f(float y, float x) { return old_atan2f(y, x); }
float __wrap_sqrtf(float x) { return old_sqrtf(x); }
float __wrap_log10f(float x) { return old_log10f(x); }
float __wrap_acosf(float x) { return old_acosf(x); }
float __wrap_asinf(float x) { return old_asinf(x); }
double __wrap_fmod(double x, double y) { return old_fmod(x, y); }
float __wrap_fmodf(float x, float y) { return old_fmodf(x, y); }
/* C23 variants differ only in accepting "0b" binary prefixes: not used by MAME or SDL here */
long __wrap___isoc23_strtol(const char *s, char **e, int b) { return old_strtol(s, e, b); }
unsigned long __wrap___isoc23_strtoul(const char *s, char **e, int b) { return old_strtoul(s, e, b); }
long long __wrap___isoc23_strtoll(const char *s, char **e, int b) { return old_strtoll(s, e, b); }
unsigned long long __wrap___isoc23_strtoull(const char *s, char **e, int b) { return old_strtoull(s, e, b); }
long __wrap___isoc23_wcstol(const wchar_t *s, wchar_t **e, int b) { return old_wcstol(s, e, b); }
int __wrap___isoc23_vsscanf(const char *s, const char *f, va_list ap) { return old___isoc99_vsscanf(s, f, ap); }
int __wrap___isoc23_sscanf(const char *s, const char *f, ...) { va_list ap; va_start(ap, f); int r = old___isoc99_vsscanf(s, f, ap); va_end(ap); return r; }
int __wrap___isoc23_fscanf(FILE *fp, const char *f, ...) { va_list ap; va_start(ap, f); int r = old___isoc99_vfscanf(fp, f, ap); va_end(ap); return r; }
