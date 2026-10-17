# COAL - Assembly Language Programs

**Name:** Ashhal Maqsood
**Roll No:** 25L-0600
**Program:** BSCS, FAST-NUCES
**Course:** Computer Organization and Assembly Language (COAL)

---

## Description

**Assignment 3 - Text Viewport Manager with Windowed Scrolling and Live Keyword Highlighter**

A 16-bit 8088 assembly program (`.com` format) that builds a bordered text window directly in video memory (segment `0xB800`). The program:

- clears the whole 80x25 screen using `rep stosw`,
- draws a double-line bordered window (rows 3 to 21, columns 8 to 72) with a centered title banner in attribute `0x1E` (yellow on blue),
- streams a multi-line paragraph into the window line by line using `lodsb` / `stosw` (left margin = column + 2),
- scrolls **only the text inside the window** upward (`movsw` to move rows, `stosw` to blank the vacated rows) without touching the border or anything outside the window,
- searches the window for a keyword using `repe cmpsb` and highlights every match by changing **only the attribute bytes** (attribute `0xCE`, blinking yellow on red), leaving the characters unchanged,
- shows the match count in a status bar on row 23, printed by an iterative, stack-based `printNum` subroutine.

### Subroutine rules followed

- Every procedure receives its parameters through the stack.
- Parameters and locals are accessed with BP-relative addressing (`[bp+n]`, `[bp-n]`).
- Temporary counters and accumulators are local variables on the stack (`sub sp, N`).
- All modified registers are saved with `push` and restored with `pop`.
- The callee cleans up the stack with `ret n`.

### Subroutines

| Subroutine | Purpose |
|---|---|
| `clear_screen` | Fills the whole screen with blanks |
| `draw_window` | Draws the double-line border |
| `print_string` | Prints a 0-terminated string at a given row, column and attribute |
| `scroll_window_up` | Scrolls the window interior up by N lines |
| `find_and_highlight` | Finds the keyword on screen and highlights it |
| `printNum` | Prints a number using the stack to reverse the digits |
| `showstatus` | Draws the status bar on row 23 |

---

## Tools Used

- **NASM** - assembler
- **DOSBox** - DOS emulator used to run the program

---

## How to Assemble and Run

Assemble:

```
nasm viewport.asm -f bin -o viewport.com
```

Run in DOSBox:

```
mount c C:\path\to\COAL\Assignment3
c:
viewport.com
```

To change how many lines the window scrolls, edit the `scrollRows` variable in the data section and assemble again. A value of `0` means no scroll.

To change the search word, edit the `keyword` line in the data section.

