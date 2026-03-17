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

---

## 🇪🇸 Español

Esta herramienta es un analizador sintáctico (parser) y sistema de compilación escrito en FreeBASIC que convierte automáticamente las cabeceras oficiales en C de **Raylib** y **Raygui** en cabeceras compatibles con FreeBASIC (archivos `.bi`) y compila las librerías estáticas necesarias.

Crea un puente perfecto entre ambos lenguajes al generar cabeceras y bibliotecas nativas, permitiéndote usar `raylib`, `raymath`, `rlgl` y `raygui` directamente en tus proyectos de FreeBASIC, tanto para arquitecturas x86 (32-bit) como x64 (64-bit).

### ✨ Características

*   **Soporte Completo de Módulos:** Convierte totalmente los cuatro módulos principales:
    *   `raylib.h` (API Principal)
    *   `raymath.h` (Matemáticas de vectores/matrices)
    *   `rlgl.h` (Abstracción de OpenGL)
    *   `raygui.h` (API de GUI en modo inmediato)
*   **Mapeo Inteligente de Tipos:** Asigna automáticamente tipos de C a sus equivalentes en FreeBASIC (ej. `int` $\to$ `long`, `const char*` $\to$ `zstring ptr`).
*   **Análisis de Structs y Enums:** Traduce correctamente los structs y enums de C en bloques `Type` y `Enum` de FreeBASIC.
*   **Correcciones de Sintaxis:** Maneja conflictos de nombres automáticamente (ej. renombrar el struct `Color` de C a `RayColor` para evitar conflictos con las palabras reservadas de FreeBASIC).
*   **Compilación de Librerías Estáticas:** Compila automáticamente librerías C "header-only" (como Raygui) en librerías estáticas `.a` listas para usar.

### ⚙️ Cómo funciona

El convertidor escanea los archivos de cabecera en C originales línea por línea, comprendiendo su contexto para:
1.  Identificar versiones automáticamente.
2.  Filtrar macros específicas de C que no son necesarias en FB.
3.  Analizar firmas de funciones (manejando `RLAPI`, `RMAPI` y `RAYGUIAPI`).
4.  Omitir implementaciones de C en línea (específicamente en `raymath.h` y `raygui.h`) para generar declaraciones `Declare` limpias.
5.  Añadir código base necesario (como `#inclib`, `extern "C"`, dependencias CRT y dependencias del sistema Windows).

### ⚠️ Requisitos y Prerrequisitos

Para compilar las implementaciones en C (como Raygui) y garantizar la compatibilidad con el enlazador (linker) interno de FreeBASIC, **debes** usar versiones de GCC compiladas con **MSVCRT** (no UCRT).

1. **Compiladores MinGW (WinLibs):**
   * 32-bit: `winlibs-i686-posix-dwarf-gcc-11.5.0-mingw-w64msvcrt-12.0.0-r1`
   * 64-bit: `winlibs-x86_64-posix-seh-gcc-11.5.0-mingw-w64msvcrt-12.0.0-r1`
   * *(Nota: GCC 8.5 con MSVCRT también es muy recomendado para máxima compatibilidad).*
2. **Librerías Estáticas de Raylib (`libraylib.a`):**
   * Descarga las *releases* oficiales de Raylib para MinGW.
   * Coloca el `libraylib.a` de 64-bit (de `raylib-x.x_win64_mingw-w64`) en la carpeta `lib_c\x64`.
   * Coloca el `libraylib.a` de 32-bit (de `raylib-x.x_win32_mingw-w64`) en la carpeta `lib_c\x86`.
3. **Cabecera de Raygui (`raygui.h`):**
   * Descarga la *release* oficial de Raygui (`raygui-x.x.zip`).
   * Extrae `raygui.h` y colócalo en la carpeta `src_c`.

### 💻 Configuración del Entorno

Para automatizar la compilación en ambas arquitecturas y mantener los compiladores organizados en tu equipo, este sistema espera la siguiente estructura de carpetas en tu disco `C:\`:

```text
C:\dev\
 ├── cmd\        (Agrega esta carpeta al PATH del sistema)
 ├── mingw32\    (Extrae aquí el WinLibs MSVCRT de 32-bit)
 └── mingw64\    (Extrae aquí el WinLibs MSVCRT de 64-bit)
```

Dentro de la carpeta `C:\dev\cmd`, crea los siguientes archivos `.bat` para llamar fácilmente a los compiladores:

**gcc32.bat** y **ar32.bat**:
```batch
@echo off
setlocal
set PATH=C:\dev\mingw32\bin;%PATH%
gcc.exe %*    :: (Usa ar.exe %* para ar32.bat)
endlocal
```
**gcc64.bat** y **ar64.bat**:
```batch
@echo off
setlocal
set PATH=C:\dev\mingw64\bin;%PATH%
gcc.exe %*    :: (Usa ar.exe %* para ar64.bat)
endlocal
```

### 🚀 Instrucciones Paso a Paso

1. **Obtener las Cabeceras:** Consigue los archivos `raylib.h`, `raymath.h`, `rlgl.h` y `raygui.h`.
2. **Limpiar Cabeceras:** Elimina los comentarios de los archivos `.h`. Puedes hacerlo automáticamente usando la herramienta `remove_comments_h.bas` de la carpeta `tools`.
3. **Colocar Archivos:** Coloca todas las cabeceras `.h` limpias en la carpeta `src_c`.
4. **Generar Cabeceras para FreeBASIC:** Ejecuta `gen-raylib_headers.bat` (en la carpeta `_build_scripts`). Esto analizará las cabeceras de C y generará los archivos `.bi`.
5. **Compilar Librerías de Raygui:** Ejecuta `build-raygui_lib.bat` (en la carpeta `_build_scripts`). Esto compilará `raygui.h` en librerías estáticas (`libraygui.a`) tanto para x86 como para x64.

Si hiciste todo correctamente, tendrás un SDK de FreeBASIC completo y listo para usar, tanto para x64 como para x86. Puedes ver los archivos generados (`.bi` y `.a`) en la carpeta `sdk_freebasic`.

### 🛠️ Uso manual del CLI (Convertidor)

Si deseas utilizar la herramienta de conversión de FreeBASIC manualmente:

```bash
# Sintaxis
converter.exe <archivo_entrada.h> <archivo_salida.bi>

# Ejemplos
converter.exe raylib.h raylib.bi
converter.exe raygui.h raygui.bi
```

### 🔗 Enlaces
* **WinLibs GCC:** https://winlibs.com/
* **Raylib Releases:** https://github.com/raysan5/raylib/releases
* **Raygui Releases:** https://github.com/raysan5/raygui/releases