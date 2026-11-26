"""The few things macOS/Linux and Windows do differently: locking a file, swapping one in,
telling whether a process is still running, and starting one that outlives its parent.

Windows has no `fcntl`, and `os.kill(pid, 0)` there doesn't probe a process: signal 0 is
`CTRL_C_EVENT`, and the call succeeds even for a process that has exited.
"""
import os
import subprocess
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

    def _detach_flags():
        return subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP

    def _popen_detached(cmd, **kwargs):
        # Out of the starter's job too, where the job allows it, so closing that doesn't end this.
        try:
            return subprocess.Popen(cmd, creationflags=_detach_flags() | subprocess.CREATE_BREAKAWAY_FROM_JOB, **kwargs)
        except OSError:
            return subprocess.Popen(cmd, creationflags=_detach_flags(), **kwargs)

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

    def _popen_detached(cmd, **kwargs):
        return subprocess.Popen(cmd, start_new_session=True, **kwargs)


def spawn_detached(cmd, log, cwd=None):
    """Start `cmd` in its own process group, with no terminal, writing its output to `log`.
    It keeps running once the caller exits, and isn't stopped with the task that ran the caller:
    once its parent is gone, nothing links it back."""
    with open(log, "w") as out:
        return _popen_detached(cmd, stdin=subprocess.DEVNULL, stdout=out, stderr=subprocess.STDOUT,
                               cwd=cwd, close_fds=True)
