"""ctypes adapter for the stable m-mdy-m/log.c C ABI (ABI major 1)."""
from __future__ import annotations

import ctypes
import ctypes.util
import os
import sys
from typing import Any

TRACE, DEBUG, INFO, WARN, ERROR, FATAL = range(6)
_LEVELS = {"trace": TRACE, "debug": DEBUG, "info": INFO, "warn": WARN, "warning": WARN, "error": ERROR, "fatal": FATAL}


class _Config(ctypes.Structure):
    _fields_ = [
        ("struct_size", ctypes.c_uint32), ("min_level", ctypes.c_uint32),
        ("color_mode", ctypes.c_uint32), ("output", ctypes.c_uint32),
        ("format_flags", ctypes.c_uint32), ("max_message_bytes", ctypes.c_uint32),
    ]


class _Event(ctypes.Structure):
    _fields_ = [
        ("struct_size", ctypes.c_uint32), ("level", ctypes.c_int32),
        ("timestamp_unix_ns", ctypes.c_uint64), ("duration_ns", ctypes.c_uint64),
        ("line", ctypes.c_uint32), ("reserved", ctypes.c_uint32),
        ("layer", ctypes.c_char_p), ("component", ctypes.c_char_p),
        ("file", ctypes.c_char_p), ("function", ctypes.c_char_p),
        ("request_id", ctypes.c_char_p), ("trace_id", ctypes.c_char_p),
        ("status", ctypes.c_char_p), ("message", ctypes.c_char_p),
        ("message_length", ctypes.c_size_t),
    ]


class WorkspaceLogger:
    """Native structured logger with a plain stderr fallback for bootstrap use."""

    def __init__(self, component: str = "workspace") -> None:
        self.component = component
        self._lib: Any = None
        self._logger = ctypes.c_void_p()
        self._load()

    def _load(self) -> None:
        candidates: list[str] = []
        explicit = os.environ.get("M_MDY_M_LOG_LIBRARY")
        if explicit:
            candidates.append(explicit)
        discovered = ctypes.util.find_library("m-mdy-m-log") or ctypes.util.find_library("mmlog")
        if discovered:
            candidates.append(discovered)
        candidates.extend(["libm-mdy-m-log.so", "libm-mdy-m-log.dylib", "m-mdy-m-log.dll", "mmlog.dll"])
        for candidate in candidates:
            try:
                self._lib = ctypes.CDLL(candidate)
                break
            except OSError:
                continue
        if self._lib is None:
            return
        lib = self._lib
        lib.mmlog_abi_version.restype = ctypes.c_uint32
        if (lib.mmlog_abi_version() >> 16) != 1:
            self._lib = None
            return
        lib.mmlog_logger_config_init.argtypes = [ctypes.POINTER(_Config)]
        lib.mmlog_logger_config_init.restype = ctypes.c_int32
        lib.mmlog_logger_create.argtypes = [ctypes.POINTER(_Config), ctypes.POINTER(ctypes.c_void_p)]
        lib.mmlog_logger_create.restype = ctypes.c_int32
        lib.mmlog_event_init.argtypes = [ctypes.POINTER(_Event)]
        lib.mmlog_event_init.restype = ctypes.c_int32
        lib.mmlog_logger_write.argtypes = [ctypes.c_void_p, ctypes.POINTER(_Event)]
        lib.mmlog_logger_write.restype = ctypes.c_int32
        lib.mmlog_logger_destroy.argtypes = [ctypes.c_void_p]
        lib.mmlog_logger_destroy.restype = None
        config = _Config()
        if lib.mmlog_logger_config_init(ctypes.byref(config)) != 0:
            self._lib = None
            return
        config.min_level = _LEVELS.get(os.environ.get("PX_LOG_LEVEL", "info").lower(), INFO)
        config.format_flags = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 8)
        if lib.mmlog_logger_create(ctypes.byref(config), ctypes.byref(self._logger)) != 0:
            self._lib = None

    @property
    def native(self) -> bool:
        return self._lib is not None and bool(self._logger)

    def log(self, level: str, message: str, *, status: str = "") -> None:
        numeric = _LEVELS.get(level.lower(), INFO)
        encoded = message.encode("utf-8", errors="replace")
        if self.native:
            event = _Event()
            if self._lib.mmlog_event_init(ctypes.byref(event)) == 0:
                layer = b"publishing"
                component = self.component.encode("utf-8", errors="replace")
                state = status.encode("utf-8", errors="replace") if status else None
                event.level = numeric
                event.layer = layer
                event.component = component
                event.status = state
                event.message = encoded
                event.message_length = len(encoded)
                if self._lib.mmlog_logger_write(self._logger, ctypes.byref(event)) == 0:
                    return
        self._fallback(level, message, status)

    def _fallback(self, level: str, message: str, status: str) -> None:
        suffix = f" status={status}" if status else ""
        safe = message.replace("\r", "\\r").replace("\n", "\\n")
        print(f"{level.upper()} layer=publishing component={self.component}{suffix} | {safe}", file=sys.stderr)

    def close(self) -> None:
        if self.native:
            self._lib.mmlog_logger_destroy(self._logger)
            self._logger = ctypes.c_void_p()


_loggers: dict[str, WorkspaceLogger] = {}


def get_logger(component: str = "workspace") -> WorkspaceLogger:
    if component not in _loggers:
        _loggers[component] = WorkspaceLogger(component)
    return _loggers[component]


def log(level: str, message: str, *, component: str = "workspace", status: str = "") -> None:
    get_logger(component).log(level, message, status=status)


def native_logger_available() -> bool:
    return get_logger().native


def close_all() -> None:
    """Flush and destroy every logger instance created by this process."""
    for instance in _loggers.values():
        instance.close()
    _loggers.clear()
