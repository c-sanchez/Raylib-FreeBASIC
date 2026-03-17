# Raylib & Raygui Converter for FreeBASIC

[🇪🇸 Leer versión en Español](#español) | [🇬🇧 Read English version](#english)

---

## 🇬🇧 English

This tool is a specialized parser and build system written in FreeBASIC that automatically converts the official **Raylib** and **Raygui** C headers into FreeBASIC compatible headers (`.bi` files) and compiles the necessary static libraries.

It creates a seamless bridge between the two languages by generating native headers and libraries, allowing you to use `raylib`, `raymath`, `rlgl`, and `raygui` directly in your FreeBASIC projects for both x86 (32-bit) and x64 (64-bit) architectures.

### ✨ Features

*   **Complete Module Support:** Fully converts the four main modules:
    *   `raylib.h` (Core API)
    *   `raymath.h` (Vector/Matrix math)
    *   `rlgl.h` (OpenGL abstraction)
    *   `raygui.h` (Immediate-mode GUI API)
*   **Smart Type Mapping:** Automatically maps C types to FreeBASIC equivalents (e.g., `int` $\to$ `long`, `const char*` $\to$ `zstring ptr`).
*   **Struct & Enum Parsing:** Correctly translates C structs and enums into FreeBASIC `Type` and `Enum` blocks.
*   **Syntax Corrections:** Handles naming conflicts automatically (e.g., renaming the C struct `Color` to `RayColor` to avoid conflicts with FreeBASIC's built-in keywords).
*   **Static Library Compilation:** Automatically compiles header-only C libraries (like Raygui) into ready-to-use `.a` static libraries.

### ⚙️ How it works

The converter scans the original C header files line-by-line but understands the context. It:
1.  Identifies version strings automatically.
2.  Filters out C-specific macros that aren't needed in FB.
3.  Parses function signatures (handling `RLAPI`, `RMAPI` and `RAYGUIAPI`).
4.  Skips inline C implementations (specifically for `raymath.h` and `raygui.h`) to generate clean `Declare` statements.
5.  Adds necessary boilerplate code (like `#inclib`, `extern "C"`, CRT includes, and Windows system dependencies).

### ⚠️ Prerequisites & Requirements

To compile the C implementations (like Raygui) and guarantee compatibility with FreeBASIC's internal linker, you **must** use GCC versions compiled with **MSVCRT** (not UCRT).

1. **MinGW Compilers (WinLibs):**
   * 32-bit: `winlibs-i686-posix-dwarf-gcc-11.5.0-mingw-w64msvcrt-12.0.0-r1`
   * 64-bit: `winlibs-x86_64-posix-seh-gcc-11.5.0-mingw-w64msvcrt-12.0.0-r1`
   * *(Note: GCC 8.5 with MSVCRT is also highly recommended for maximum legacy compatibility).*
2. **Raylib Static Libraries (`libraylib.a`):**
   * Download the official Raylib MinGW releases.
   * Place the 64-bit `libraylib.a` (from `raylib-x.x_win64_mingw-w64`) in the `lib_c\x64` folder.
   * Place the 32-bit `libraylib.a` (from `raylib-x.x_win32_mingw-w64`) in the `lib_c\x86` folder.
3. **Raygui Header (`raygui.h`):**
   * Download the official Raygui release (`raygui-x.x.zip`).
   * Extract `raygui.h` and place it in the `src_c` folder.

### 💻 Environment Setup

To automate the compilation for both architectures and keep the compilers organized, this system expects the following folder structure on your `C:\` drive:

```text
C:\dev\
 ├── cmd\        (Add this folder to your system PATH)
 ├── mingw32\    (Extract 32-bit WinLibs MSVCRT here)
 └── mingw64\    (Extract 64-bit WinLibs MSVCRT here)
```

Inside the `C:\dev\cmd` folder, create the following wrapper `.bat` files to easily call the compilers:

**gcc32.bat** & **ar32.bat**:
```batch
@echo off
setlocal
set PATH=C:\dev\mingw32\bin;%PATH%
gcc.exe %*    :: (Use ar.exe %* for ar32.bat)
endlocal
```
**gcc64.bat** & **ar64.bat**:
```batch
@echo off
setlocal
set PATH=C:\dev\mingw64\bin;%PATH%
gcc.exe %*    :: (Use ar.exe %* for ar64.bat)
endlocal
```

### 🚀 Build Instructions

1. **Get the Headers:** Obtain `raylib.h`, `raymath.h`, `rlgl.h`, and `raygui.h`.
2. **Clean Headers:** Remove comments from the headers. You can do this automatically using the `remove_comments_h.bas` tool located in the `tools` folder.
3. **Place Files:** Put all the clean `.h` files into the `src_c` folder.
4. **Generate FreeBASIC Bindings:** Run `gen-raylib_headers.bat` (located in `_build_scripts`). This will parse the C headers and generate `.bi` files.
5. **Compile Raygui Libraries:** Run `build-raygui_lib.bat` (located in `_build_scripts`). This will compile `raygui.h` into static `libraygui.a` libraries for both x86 and x64 using your GCC setup.

If you followed all steps correctly, you will have a complete, ready-to-use FreeBASIC SDK for both Raylib and Raygui. You can find all the generated files (`.bi` and `.a`) inside the `sdk_freebasic` folder.

### 🛠️ CLI Usage (Converter)

If you want to use the FreeBASIC converter tool manually:

```bash
# Syntax
converter.exe <input_file.h> <output_file.bi>

# Examples
converter.exe raylib.h raylib.bi
converter.exe raygui.h raygui.bi
```

### 🔗 Links
* **WinLibs GCC:** https://winlibs.com/
* **Raylib Releases:** https://github.com/raysan5/raylib/releases
* **Raygui Releases:** https://github.com/raysan5/raygui/releases