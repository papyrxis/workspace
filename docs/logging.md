# Shared logging

Workspace uses the native `m-mdy-m/log.c` library through its stable C ABI. The Python adapter lives in `px/logger.py`; it is deliberately thin and does not create a second logging framework.

## Runtime behavior

- Each subsystem uses a stable component name (for example `build`, `config`, `export`, `release`, `verify`).
- Events use the `publishing` layer and include level, component, status and message.
- `M_MDY_M_LOG_LIBRARY` can point to an explicit shared-library path.
- If no compatible ABI-1 shared library is found, the CLI uses a clearly marked stderr fallback so bootstrap commands remain usable.
- `px doctor` reports whether the native logger is available.

## Build and install log.c

Follow the authoritative instructions in [m-mdy-m/log.c](https://github.com/m-mdy-m/log.c). The CI workflow builds the shared library from the tagged release and sets `M_MDY_M_LOG_LIBRARY` for the Workspace test process.

A typical CMake installation is:

~~~sh
cmake -S log.c -B log.c/build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DBUILD_SHARED_LIBS=ON
cmake --build log.c/build --parallel
cmake --install log.c/build
~~~

Then expose the installed library through the platform loader or set `M_MDY_M_LOG_LIBRARY` to its full path. Use `px doctor` to confirm the native path is active.

## Reuse from another Papyrxis repository

Do not copy Workspace's logger or embed repository-specific logger logic. Link/build `m-mdy-m/log.c` as a shared dependency, use its documented stable C ABI, and give every subsystem a component prefix.

The public C API is intentionally small:

~~~c
#include <m-mdy-m/log.h>
#include <string.h>

mmlog_logger_t *logger = NULL;
mmlog_event_t event;
if (mmlog_logger_create(NULL, &logger) == MMLLOG_OK) {
    mmlog_event_init(&event);
    event.level = MMLLOG_LEVEL_INFO;
    event.layer = "publishing";
    event.component = "papers";
    event.status = "built";
    event.message = "PDF build completed";
    event.message_length = strlen(event.message);
    mmlog_logger_write(logger, &event);
    mmlog_logger_destroy(logger);
}
~~~

For Python, Rust, Go, C#, Lua and other foreign runtimes, call the non-variadic `mmlog_logger_write()` record API; never call the C variadic `mmlog_logf()` through FFI. Query `mmlog_abi_version()`, use the public struct initializers, check status codes, and keep strings alive until the synchronous write returns. The current ABI is 1.0.

For Python repositories, `px.logger` is a Workspace-specific adapter; other projects should use a small adapter around the same public ABI rather than depending on the Workspace package. The upstream [C ABI reference](https://github.com/m-mdy-m/log.c/blob/v0.1.0/docs/abi.md) and [language binding guide](https://github.com/m-mdy-m/log.c/blob/v0.1.0/docs/language-bindings.md) define the exact layouts and FFI rules.

For shell compatibility, call `px log --level info --component <component> <message>` when Workspace is installed. Do not use shell `eval` or parse structured YAML to construct logging commands.

## Diagnostics

~~~sh
px doctor
px log --level info --component release "release preparation started"
PX_LOG_LEVEL=debug px list
~~~

The fallback is intended for bootstrap and diagnostics, not as a replacement for the shared native library in production integrations.
