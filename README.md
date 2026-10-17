# COAL - Computer Organization and Assembly Language

**Name:** Ashhal Maqsood
**Roll No:** 25L-0600
**Program:** BSCS, FAST-NUCES

---

## About This Repository

This repository contains all my COAL (Assembly Language) work. Every assignment is in its own folder, and each folder holds the `.asm` source files, a README for that assignment, and output screenshots.

## Assignments

| Folder | Description |
|---|---|
| [Assignment3](Assignment3/) | Text viewport manager: bordered window in video memory, windowed scrolling, live keyword highlighter and a status bar |

New assignments are added as separate folders with regular commits.

---

## Short Description of the Programs

**Assignment 3 - Text Viewport Manager** (`Assignment3/viewport.asm`)

A 16-bit 8088 program (`.com` format) that writes directly to video memory (segment `0xB800`). It clears the screen, draws a double-line window with a centered title, streams a multi-line paragraph into it with `lodsb` / `stosw`, scrolls only the text inside the window with `movsw` / `stosw` (the border is never touched), finds a keyword with `repe cmpsb` and highlights every match by changing only the attribute bytes, and prints the match count on row 23 with an iterative, stack-based `printNum`.

All subroutines take their parameters on the stack, use BP-relative addressing, keep counters as local variables, save and restore the registers they modify, and clean up with `ret n`.

---

## Tools Used

- **NASM** - assembler
- **DOSBox** - DOS emulator used to run the programs

---

## How to Assemble and Run

Assemble any program (replace the file name):

```
nasm filename.asm -f bin -o filename.com
```

Run in DOSBox:

```
mount c C:\path\to\COAL
c:
cd Assignment3
filename.com
```

For example, for Assignment 3:

```
nasm Assignment3/viewport.asm -f bin -o Assignment3/viewport.com
```