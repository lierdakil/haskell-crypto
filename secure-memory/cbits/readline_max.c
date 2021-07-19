// SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
//
// SPDX-License-Identifier: MPL-2.0

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wchar.h>


/* Read a newline-terminated string into `buf`
 * from `fin` respecting the locale encoding.
 *
 * If the text that the user enters before ending the line does not fit
 * into the buffer, the extra characters will be silently discarded
 * (similar to what `readpassphrase` does on BSD).
 *
 * Now, here is a plot twist: this function (hopefully) works correctly
 * with any character encoding and treats multi-byte characters correctly.
 * It _guarantees_ that the last character will not be broken apart if
 * it does not fit completely – instead it will discard the entire codepoint.
 *
 * Another plot twist is that the text that the user enters
 * will be represented in their locale encoding, in other words,
 * pressing the same sequence of buttons on the keyboard on different
 * systems might result in different byte sequences.
 * This is extremely tricky and, no, ignoring the locale when reading
 * the user’s input will make things even worse. If it is desired
 * that the resulting byte sequences are independent of the system locale,
 * then it is a good idea to decode the bytes that this function returns
 * using the system locale encoding and then re-encode them as UTF-8.
 * Would be cool to do it right here, but this is C :).
 * (Note that this means that the resulting byte strings can _still_
 * turn out different if the user’s input fits into the buffer on one
 * system, but does not fit on another, so allocate generously.)
 *
 * The resulting string is not null-terminated.
 *
 * Returns the size (in bytes) of the string read or a negative
 * number if an error occurred.
 *
 * -1 = there was an error when reading (see fgetwc).
 * -2 = something is off with the locale (see wctomb). This is actually impossible.
 * In either case, `errno` will contain information on the actual error.
 *
 * A noteworthy case is when this function returns -1 and errno == EILSEQ,
 * which means that the user’s terminal is sending bytes that are invalid
 * in their configured system locale encoding, so their setup is messed up
 * and there is absolutely no way for us to interpret their input. Too bad.
 */
int readline_max(FILE* fin, char *buf, int buf_size) {
  char *p = (char*)buf;
  int  no_more_space = 0;

  errno = 0;

  wint_t wc;
  char encoded[MB_CUR_MAX];
  while ((wc = fgetwc(fin)) != WEOF) {
    // Read a unicode codepoint and see if it is a line terminator
    // (note: we only accept these two, not what Unicode defines)
    if (wc == L'\n' || wc == L'\r') {
        break;
    } else if (no_more_space) {
      // we have decided that we are discarding the rest
      continue;
    } else {
      // Now we encode the codepoint back into bytes.
      // XXX: wchar_t is messed up on Windows, no idea if this
      // actually works there. All I know is POSIX says it has to :/.
      int size = wctomb(encoded, (wchar_t)wc);
      if (size < 0) {
        return -2;
      }
      if (p + size <= buf + buf_size) {
        // it still fits!
        memcpy(p, encoded, size);
        p += size;
      } else {
        // discard the remainder
        no_more_space = 1;
      }
    }
  }

  if (errno != 0) {
    return -1;
  } else {
    return p - buf;
  }
}


///
// The functions below are simple wrappers that convert
// from the OS-specific handle/fd that we can get from Haskell
// to FILE*.

#if defined(mingw32_HOST_OS) /* windows */

#include <io.h>

int readline_max_windows(HANDLE hin, char *buf, int buf_size) {
  int fd = _open_osfhandle((intptr_t)fin, _O_RDONLY);
  FILE* fin = _fdopen(fd, "rt");
  setvbuf(fin, 0, _IONBF, 0);
  return readline_max(fin, buf, buf_size);
}

#else /* not windows => unix */

int readline_max_unix(int fd, char *buf, int buf_size) {
  FILE* fin = fdopen(fd, "rt");
  setvbuf(fin, 0, _IONBF, 0);
  return readline_max(fin, buf, buf_size);
}

#endif
