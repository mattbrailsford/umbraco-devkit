"""The few things macOS/Linux and Windows do differently: locking a file, swapping one in, and
telling whether a process is still running.

Windows has no `fcntl`, and `os.kill(pid, 0)` there doesn't probe a process: signal 0 is
`CTRL_C_EVENT`, and the call succeeds even for a process that has exited.
"""
import os
import sys
import time

if sys.platform == "win32":
    import ctypes
    import msvcrt
    from ctypes import wintypes

    _PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    _STILL_ACTIVE = 259

    _kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    _kernel32.OpenProcess.restype = wintypes.HANDLE
    _kernel32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    _kernel32.GetExitCodeProcess.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
    _kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)

    def lock(f):
        """Hold an exclusive lock on open file `f` until `unlock`, waiting for any other holder."""
        f.seek(0)
        while True:
            try:
                msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
                return
            except OSError:
                time.sleep(0.02)

    def unlock(f):
        f.seek(0)
        msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)

    def replace(src, dst):
        """os.replace, retried briefly: on Windows it fails while another process has `dst` open."""
        for _ in range(100):
            try:
                return os.replace(src, dst)
            except PermissionError:
                time.sleep(0.02)
        os.replace(src, dst)

    def pid_running(pid):
        handle = _kernel32.OpenProcess(_PROCESS_QUERY_LIMITED_INFORMATION, False, int(pid))
        if not handle:
            return False
        try:
            code = wintypes.DWORD()
            return bool(_kernel32.GetExitCodeProcess(handle, ctypes.byref(code))) and code.value == _STILL_ACTIVE
        finally:
            _kernel32.CloseHandle(handle)

else:
    import fcntl

    def lock(f):
        """Hold an exclusive lock on open file `f` until `unlock`, waiting for any other holder."""
        fcntl.flock(f, fcntl.LOCK_EX)

    def unlock(f):
        fcntl.flock(f, fcntl.LOCK_UN)

    replace = os.replace

    def pid_running(pid):
        try:
            os.kill(int(pid), 0)
            return True
        except OSError:
            return False
