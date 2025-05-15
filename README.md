# Brick Breaker Game 🚀

A classic Brick Breaker game implemented in **MASM assembly language**, utilizing the Irvine32 library for Windows console graphics and input handling.

## Features 🎮

- **Three increasing difficulty levels** 
- **Score tracking** and **high score system** stored in files
- **Lives system** with visual heart indicators
- Pause functionality (press 'p')
- Customizable paddle movement
- Timed gameplay
- Colorful ASCII art and UTF-8 emojis (❤️🚀)

## Setup and Compilation ⚙️

### Prerequisites
1. **MASM (Microsoft Macro Assembler)**
   - Included with Visual Studio
2. **Irvine32 Library** (included in most assembly development environments)
3. **Winmm.lib** (Windows Multimedia Library)

### Compilation Steps
1. Save the source code as `brick_breaker.asm`
2. Assemble with MASM:
   ```bash
   ml /c /coff brick_breaker.asm
   ```
3. Link with Irvine32 and Windows libraries:
   ```bash
   link /SUBSYSTEM:CONSOLE /DEFAULTLIB:irvine32 /DEFAULTLIB:kernel32 /DEFAULTLIB:user32 /DEFAULTLIB:winmm brick_breaker.obj
   ```
4. Run the executable:
   ```bash
   brick_breaker.exe
   ```

## How to Play 🕹️

1. **Movement Controls**:
   - `A` key: Move paddle left
   - `D` key: Move paddle right
   - `P` key: Pause/unpause game
   - `Q` key: Quit to main menu (in certain screens)

2. **Gameplay**:
   - Break all bricks to advance levels
   - Avoid losing all lives
   - Earn points for breaking bricks


## File Structure 📁

```
brick_breaker.asm       # Main source code
irvine32.inc            # Irvine32 library header
Macros.inc              # Custom macros for text output
score.bin               # Stores player scores
name.txt                # Stores player names
level.bin               # Stores player levels
```

## Testing Environment 🖥️

Tested on:
- Windows 10/11
- MASM (Visual Studio 2019/2022)
- Irvine32 Library v1.0
- Visual Studio 2019



Special thanks to **Kip Irvine** for the Irvine32 library! 💖

