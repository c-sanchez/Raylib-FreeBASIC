# Raylib Header Converter for FreeBASIC

This tool is a specialized parser written in FreeBASIC that automatically converts the official **Raylib** C headers into FreeBASIC compatible headers (`.bi` files).

It creates a seamless bridge between the two languages by generating native headers, allowing you to use `raylib`, `raymath`, and `rlgl` directly in your FreeBASIC projects.

## Features

*   **Complete Module Support:** Fully converts the three main modules:
    *   `raylib.h` (Core API)
    *   `raymath.h` (Vector/Matrix math - converts implementations to declarations)
    *   `rlgl.h` (OpenGL abstraction)
*   **Smart Type Mapping:** Automatically maps C types to FreeBASIC equivalents (e.g., `int` $\to$ `long`, `const char*` $\to$ `zstring ptr`).
*   **Struct & Enum Parsing:** Correctly translates C structs and enums into FreeBASIC `Type` and `Enum` blocks.
*   **Syntax Corrections:** Handles naming conflicts automatically (e.g., renaming the C struct `Color` to `RayColor` to avoid conflicts with FreeBASIC's built-in keywords).
*   **Variadic Support:** Handles functions with variable arguments (`...`) properly.

## How it works

The converter scans the original C header files line-by-line but understands the context. It:
1.  Identifies version strings automatically.
2.  Filters out C-specific macros that aren't needed in FB.
3.  Parses function signatures (handling `RLAPI` and `RMAPI`).
4.  Skips inline C implementations (specifically for `raymath.h`) to generate clean `declare` statements.
5.  Adds necessary boilerplate code (like `#inclib "raylib"`, `extern "C"`, and CRT includes).

## Usage

Compile the converter using FreeBASIC, then run it from the command line providing the input C header and the output file path.

```bash
# Syntax
converter.exe <input_file.h> <output_file.bi>

# Examples
converter.exe raylib.h raylib.bi
converter.exe raymath.h raymath.bi
converter.exe rlgl.h rlgl.bi