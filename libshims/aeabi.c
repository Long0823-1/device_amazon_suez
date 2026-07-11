/*
 * Shim providing the ARM EABI division-by-zero helpers.
 *
 * audio.primary.mt8173.so (built against an old bionic that exported these
 * from libc.so) fails to dlopen on LineageOS 18.1 with:
 *   "cannot locate symbol '__aeabi_idiv0'"
 * because current bionic no longer exposes them as public symbols.
 * Re-implement them here per RTABI 4.3.2: return the value passed in.
 */

int __aeabi_idiv0(int return_value) {
    return return_value;
}

long long __aeabi_ldiv0(long long return_value) {
    return return_value;
}
