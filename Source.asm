
include irvine32.inc						;to include the Irvine library
include Macros.inc							;to include the Macros library		
includelib winmm.lib
includelib kernel32.lib						;to include the kernel32 library

option casemap:none							;to make the code case sensitive

;---------------------------------------------------PROTOYPES--------------------------------------------------------------;
ExitProcess PROTO, dwExitCode:DWORD			; Prototype for ExitProcess
PlaySound proto, pszSound:ptr byte, hmod:dword, fdwSound:dword
GetConsoleOutputCP PROTO STDCALL            ;Gets the curreny console pages code page
SetConsoleOutputCP PROTO STDCALL :DWORD     ;Sets the console output code page
WriteConsoleA PROTO, a1:DWORD, a2: PTR BYTE, a3: Dword, a4: ptr dword, a5:dword     ;winApi to write on console in different codes
GetStdHandle PROTO STDCALL :DWORD           ;Gets the handle for standard output

;-----------------------------------------------Constants-------------------------------------------------------------------;
CP_UTF8 EQU 65001                              ;Lets you print emojis on the console (UTF8 code page)
MAX_NAME_LENGTH = 10
MAX_PLAYERS = 10
TOTAL_PLAYERS = 11
;-----------------------------------------------------STRUCT----------------------------------------------------------------;
;to store player data for file handling
PLAYER STRUCT
	playerName BYTE 10 DUP(0)
	PlyScore DWORD ?
	playerLevel BYTE ?
PLAYER ENDS
;-----------------------------------------------------MACROS----------------------------------------------------------------;
;-----------------------------------------------------DRAW HEART MACRO -----------------------------------------------------;
;prints count (32-bit) hearts
;avoid sending eax,ebx,edx as arguments

DrawHeart MACRO count:REQ 
    local print                                     ;declare label as local one
    push eax                                        ;save eax
    push ebx                                        ;save ebx

    DrawBox 140,8,30,10,white,lightRed

    mov eax, lightRed+(white shl 4)                      ;set the color to red
    call SetTextColor                               ;set the text color
    
    mGotoxy 155,14
    mWriteSpace 7
    INVOKE GetConsoleOutputCP                       ;get the current console Code page
    mov originalCP,eax                              ;save the cp

    INVOKE SetConsoleOutputCP , CP_UTF8             ;set the CP to UTF8

    INVOKE GetStdHandle, -11                        ;get std handle for output
    mov consoleHandle, eax                          ;save the handle

    xor ebx,ebx                                     ;clear ebx for loop
    mov ebx,count                                   ;mov count in ebx

    mGotoxy 145,14                                  ;fix cords for "LIVES :"
    mWrite "LIVES : "                               ;print "LIVES :"

    mGotoxy 155,14                                  ;fix cords for life 
    
    print:
    INVOKE WriteConsoleA, consoleHandle, offset HeartUTF8, 3, 0, 0      ;print the heart
    INVOKE WriteConsoleA, consoleHandle, offset space, 2, 0, 0          ;print space
    dec ebx
    cmp ebx,0                                                           ;basic loop (not using ecx as writeConsole messes with 
    jne print                                                           ;it and infinite loop runs)

    INVOKE SetConsoleOutputCP  ,originalCP          ;Set the original CP back

    mov eax,white+(black shl 4)                     ;restore text color
    call SetTextColor                               ;set text color

    pop ebx                ;restore ecx 
    pop eax                ;restore eax
    
ENDM
DrawRocket MACRO x:REQ , y:REQ
    local print                                     ;declare label as local one
    push eax                                        ;save eax
    
    mGotoxy x,y

    INVOKE GetConsoleOutputCP                       ;get the current console Code page
    mov originalCP,eax                              ;save the cp

    INVOKE SetConsoleOutputCP , CP_UTF8             ;set the CP to UTF8

    INVOKE GetStdHandle, -11                        ;get std handle for output
    mov consoleHandle, eax                          ;save the handle

                                   ;clear ebx for loop

    INVOKE WriteConsoleA, consoleHandle, offset RocketUTF8, 4, 0, 0      ;print the heart

    INVOKE SetConsoleOutputCP  ,originalCP          ;Set the original CP back
    pop eax                ;restore eax
    
ENDM
;-----------------------------------------------------DRAW HEART MACRO END -------------------------------------------------------;
ResetGame MACRO
    ; Save all registers
    pushad

    ; Reset player score and lives
    mov playerScore, 0
    mov lives, 3

    ; Reset brickActive array (30 bytes, all set to 1)
    mov esi, OFFSET brickActive
    mov ecx, 30
fill_brickActive:
    mov byte ptr [esi], 1
    inc esi
    loop fill_brickActive

    ; Reset brickActive2 array (30 bytes, all set to 2)
    mov esi, OFFSET brickActive2
    mov ecx, 30
fill_brickActive2:
    mov byte ptr [esi], 2
    inc esi
    loop fill_brickActive2

    ; Reset brickActive3 array (30 bytes, custom values)
    mov esi, OFFSET brickActive3
    mov ecx, 22  ; First 22 elements should be 3
fill_brickActive3:
    mov byte ptr [esi], 3
    inc esi
    loop fill_brickActive3

    ; Set the remaining values manually
    mov byte ptr [esi], 5
    inc esi
    mov byte ptr [esi], 3
    inc esi
    mov byte ptr [esi], 3
    inc esi
    mov byte ptr [esi], 4
    inc esi
    mov byte ptr [esi], 3
    inc esi
    mov byte ptr [esi], 3
    inc esi
    mov byte ptr [esi], 3
    inc esi
    mov byte ptr [esi], 4

    ; Restore all registers
    popad
ENDM



;-----------------------------------------------------DRAW BOX--------------------------------------------------------------------;
DrawBox MACRO x:REQ, y:REQ, width:REQ, height:REQ, color:REQ, outlineColor:REQ
    local heightLoop, outlineTopBottom, drawRow

    push eax
    push ecx
    push edx
    push ebx

    ; Set outline color for top and bottom
    mov eax, outlineColor
    shl eax, 4                          ; Multiply by 16 for background
    add eax, outlineColor               ; Add background color
    call SetTextColor

    ; Draw top outline
                      
    mGotoxy x, y                       ; Go to x, y (top row)
    mWriteSpace width+2                    ; Draw top line

    ; Set interior color
    mov eax, color
    shl eax, 4
    add eax, color
    call SetTextColor

    ; Draw interior with outline on the sides
    mov ecx, height                     ; Set height loop counter
    dec ecx                             ; Top and bottom rows are handled separately
    xor ebx, ebx
    mov bl, y
    inc bl                              ; Move to the row below the top outline

heightLoop:
    mGotoxy x, bl                       ; Go to x, y (current row)
    ; Draw left outline
    mov eax, outlineColor
    shl eax, 4
    add eax, outlineColor
    call SetTextColor
    mWrite "  "                          ; Draw left outline character

    ; Draw interior spaces
    mov eax, color
    shl eax, 4
    add eax, color
    call SetTextColor
    mWriteSpace width-2                     ; Draw interior spaces

    ; Draw right outline
    mov eax, outlineColor
    shl eax, 4
    add eax, outlineColor
    call SetTextColor
    mWrite "  "                          ; Draw right outline character

    inc bl                              ; Move to next row
    loop heightLoop                     ; Repeat until height is done

    ; Draw bottom outline
    mov eax, outlineColor
    shl eax, 4
    add eax, outlineColor
    call SetTextColor
    mov bl, y
    add bl, height - 1                  ; Bottom row: y + height - 1
    mGotoxy x, bl                       ; Go to bottom row
    mWriteSpace width                     ; Draw bottom line

    ; Reset the color to default (light gray text on black background)
    mov eax,white+(black shl 4)
    call SetTextColor
    pop ebx
    pop edx
    pop ecx
    pop eax
ENDM
;-----------------------------------------------------DRAW BOX END---------------------------------------------------------;
;-----------------------------------------------------DRAW BRICK MACRO-----------------------------------------------------;
DrawBrick MACRO color:REQ , x:REQ , y:REQ
;all bricks are x-10 and y-2
	push eax								;save eax
	push ebx								;save ebx
	push ecx								;save ecx

	xor eax,eax								;clear eax
	xor ebx,ebx								;clear ebx
	xor ecx,ecx								;clear ecx

	mov al,color							;mov color to eax
	shl eax,4								;mulitply by 16
	add eax,color							;add the base color
	call SetTextColor						;set text color

	mov ebx,x								;mov x to ebx
	mov ecx,y								;mov y to ecx
	mGotoxy bl,cl							;goto x,y
	mWriteSpace 10							;write 10 spaces
	inc ecx									;next line
	mGotoxy bl,cl							;goto next line
	mWriteSpace 10							;write 10 spaces

	mov eax,white+(black shl 4)				;restore text color
	call SetTextColor						;set text color
	pop ecx									;restore ecx
	pop ebx									;restore ebx
	pop eax									;restore eax
ENDM
;-----------------------------------------------------DRAW BRICK MACRO END------------------------------------------------;

;-----------------------------------------------------DELETE BRICK MACRO--------------------------------------------------;
DeleteBrick MACRO x:REQ , y:REQ

	DrawBrick black,x,y

ENDM
;-----------------------------------------------------DELETE BRICK MACRO END--------------------------------------------------;

;-----------------------------------------------------DATA----------------------------------------------------------------;
.data
xCord byte 80								;X coordinate 
yCord byte 0								;Y coordinate

;30 bricks staring x-ycordinates
startXCords byte 81,91,101,111,121,81,91,101,111,121,81,91,101,111,121,81,91,101,111,121,81,91,101,111,121,81,91,101,111,121		;starting x coordinates for bricks
startYCords byte 1,1,1,1,1,3,3,3,3,3,5,5,5,5,5,7,7,7,7,7,9,9,9,9,9,11,11,11,11,11													;starting y coordinates for bricks
endXCords byte 91,101,111,121,131,91,101,111,121,131,91,101,111,121,131,91,101,111,121,131,91,101,111,121,131,91,101,111,121,131	;ending x coordinates for bricks
endYCords byte 3,3,3,3,3,5,5,5,5,5,7,7,7,7,7,9,9,9,9,9,11,11,11,11,11,13,13,13,13,13												;ending y coordinates for bricks
brickColors1 byte blue,red,green,yellow,blue,red,green,yellow,blue,red,green,yellow,blue,red,green,yellow,blue,red,green,yellow,blue,red,green,yellow,blue,red,green,yellow,blue,red
;Brick scores
;Blue = 1 , Red = 2 , Green = 3 , Yellow = 4
brickScores byte 1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4,1,2
brickActive byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1    ; 30 bytes, each initialized to 1

;---------------------------variables for level 2---------------------------------------------------;
brickColorslvl1 byte blue , red ,green ,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green
brickColorslvl2 byte lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen
brickActive2 byte 30 DUP (2) ;2 for dark color 1 for light color 0 for broken
brickScores2 byte 1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3
;-----------------------------Variables for level 3---------------------------------------------------;
brickColors3lvl1 byte blue , red ,green ,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , red ,green,blue , magenta ,green,blue , gray ,green,blue , red,gray
brickColors3lvl2 byte lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen,lightBlue,lightRed,lightGreen
brickColors3lvl3 byte white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white,white
brickActive3 byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,5,3,3,4,3,3,3,4
;---------------------------------------------paddle and general game vars--------------------------------------------------------------;
paddle byte "            ",0                      
paddleSize byte 12
paddle1 byte "          ",0                      
paddleSize1 byte 10
paddle2 byte "       ",0                      
paddleSize2 byte 7
inputChar byte "a"
ballChar byte "O"
xCordBall byte 0                            ;X coordinate for ball
yCordBall byte 0                            ;Y coordiante for ball
xDirection sbyte 1
yDirection sbyte -1

temp1 dd 0
temp2 dd 0
temp3 byte 0
playerScore dd 0
xScoreCord byte 140
yScoreCord byte 30
xCordHeart byte 0
yCordHeart byte 0
allActiveBrick byte 1
;--------------------------------------------------For time------------------------------------------------------------------;
timer dword 240000
;-----------------------------Heart Print------------------------------------------------------------------------------------;
originalCP DWORD 0
consoleHandle DWORD 0
HeartUTF8 BYTE 0E2h, 09Dh, 0A4h, 0   ; UTF-8 encoding for , null-terminated
space byte "  ",0
RocketUTF8 BYTE 0F0h, 09Fh, 09Ah, 080h, 0 
rocketX byte 0
rocketY byte 0

;----------------------------GLOBAL VARS-------------------------------------------------------------------------------------;
lives DWORD ?
pName byte 10 DUP (0)
level byte 0
;---------------------------------------For music----------------------------------------------------------------------------;

startSound db "glassBreak.wav", 0
startSound1 db "background.wav", 0
snd_asy equ 00000001h
snd_nowait equ 00002000h
;---------------------------------------Pause game vars---------------------------------------------------------------------;
gamePaused db 0          ; 0: Game is running, 1: Game is paused
pauseMessage db "Game Paused. Press 'p' to resume.", 0

;---------------------------------------FILE HANDLING VARIABLES--------------------------------------------------------------;
;file names
scoreBin byte "score.bin",0
nametxt byte "name.txt",0
lvlBin byte "level.bin",0

;struct of PLAYERS of size 11
;10 are to read from file and 1 is for current player then I sort them and print top 10 to file
playerArray PLAYER TOTAL_PLAYERS DUP (<>)  ; null values before reading
;temp vars for inbetween files
input_buffer byte 120 dup(0)
score_buffer dword 0
levelBuffer byte 0
fileHandle DWORD ?
playersInFile DWORD 0
delimBuffer byte 0
delim db '/', 0

indexArray byte 0,1,2,3,4,5,6,7,8,9,10
tempStore DWORD 0
;print highscore vars
highscoreY byte 20
;--------------------------------------------------intro screen-----------------------------------------------------------------;

                    
 wlcm1 byte                        "__        __     _                                _____      ",0
 wlcm2 byte                        "\ \      / /___ | |  ___  ___   _ __ ___    ___  |_   _|___  ",0
 wlcm3 byte                        " \ \ /\ / // _ \| | / __|/ _ \ | '_ ` _ \  / _ \   | | / _ \ ",0
 wlcm4 byte                        "  \ V  V /|  __/| || (__| (_) || | | | | ||  __/   | || (_) |",0
 wlcm5 byte                        "   \_/\_/  \___||_| \___|\___/ |_| |_| |_| \___|   |_| \___/ ",0
                                                              

 
intro1 byte      " ____         _        _      ____                     _",0               
intro2 byte      "|  _ \       (_)      | |    |  _ \                   | |",0              
intro3 byte      "| |_) | _ __  _   ___ | | __ | |_) | _ __  ___   __ _ | | __ ___  _ __",0 
intro4 byte      "|  _ < | '__|| | / __|| |/ / |  _ < | '__|/ _ \ / _` || |/ // _ \| '__|",0
intro5 byte      "| |_) || |   | || (__ |   <  | |_) || |  |  __/| (_| ||   <|  __/| |",0   
intro6 byte      "|____/ |_|   |_| \___||_|\_\ |____/ |_|   \___| \__,_||_|\_\\___||_|",0   

        

menu1 byte " __  __  _____  _   _  _   _  ",0
menu2 byte "|  \/  || ____|| \ | || | | | ",0
menu3 byte "| |\/| ||  _|  |  \| || | | | ",0
menu4 byte "| |  | || |___ | |\  || |_| | ",0
menu5 byte "|_|  |_||_____||_| \_| \___/  ",0


                
inst1 byte " ___              _                       _    _                    ",0
inst2 byte "|_ _| _ __   ___ | |_  _ __  _   _   ___ | |_ (_)  ___   _ __   ___ ",0
inst3 byte " | | | '_ \ / __|| __|| '__|| | | | / __|| __|| | / _ \ | '_ \ / __|",0
inst4 byte " | | | | | |\__ \| |_ | |   | |_| || (__ | |_ | || (_) || | | |\__ \",0
inst5 byte "|___||_| |_||___/ \__||_|    \__,_| \___| \__||_| \___/ |_| |_||___/",0
                                                                     
    
 hghs1 byte " _   _  _         _      ____                              ",0
 hghs2 byte "| | | |(_)  __ _ | |__  / ___|   ___  ___   _ __  ___  ___ ",0
 hghs3 byte "| |_| || | / _` || '_ \ \___ \  / __|/ _ \ | '__|/ _ \/ __|",0
 hghs4 byte "|  _  || || (_| || | | | ___) || (__| (_) || |  |  __/\__ \",0
 hghs5 byte "|_| |_||_| \__, ||_| |_||____/  \___|\___/ |_|   \___||___/",0
 hghs6 byte "           |___/                                           ",0

             
gmovr1 byte "  ____     _     __  __  _____        ___ __     __ _____  ____  ",0
gmovr2 byte " / ___|   / \   |  \/  || ____|      / _ \\ \   / /| ____||  _ \ ",0
gmovr3 byte "| |  _   / _ \  | |\/| ||  _|       | | | |\ \ / / |  _|  | |_) |",0
gmovr4 byte "| |_| | / ___ \ | |  | || |___      | |_| | \ V /  | |___ |  _ < ",0
gmovr5 byte " \____|/_/   \_\|_|  |_||_____|      \___/   \_/   |_____||_| \_\",0
                                                                  
;-----------------------------------------------------CODE------------------------------------------------------------------;
.code 
;-------------------------------------draw paddle---------------------------------------------------------------------------;
DrawPaddle PROC
    mov eax,yellow + (yellow shl 4)					
    call SetTextColor
    movsx ecx, paddleSize
    mov esi, OFFSET paddle
    mov dl, xCord
    mov dh, yCord
drawLoop:
    call Gotoxy
    lodsb
    call WriteChar
    inc dl
    loop drawLoop
    mov eax, white + (black shl 4)
    call SetTextColor
    ret
DrawPaddle ENDP
;-----------------------------------Using this function to update paddle after movement----------------------------------;
UpdatePaddle PROC
    movzx ecx, paddleSize
    mov dl, xCord
    mov dh, yCord
clearLoop:
    call Gotoxy
    mWrite " "
    inc dl
    loop clearLoop
    ret
UpdatePaddle ENDP
;-----------------------------------Paddle for level 2-------------------------------------;
DrawPaddle1 PROC
    mov eax, yellow + (yellow shl 4)
    call SetTextColor
    movsx ecx, paddleSize1
    mov esi, OFFSET paddle1
    mov dl, xCord
    mov dh, yCord
drawLoop:
    call Gotoxy
    lodsb
    call WriteChar
    inc dl
    loop drawLoop
    mov eax, white + (black shl 4)
    call SetTextColor
    ret
DrawPaddle1 ENDP
;-----------------------------------Using this function to update paddle after movement----------------------------------;
UpdatePaddle1 PROC
    movzx ecx, paddleSize1
    mov dl, xCord
    mov dh, yCord
clearLoop:
    call Gotoxy
    mWrite " "
    inc dl
    loop clearLoop
    ret
UpdatePaddle1 ENDP
;-----------------------------------for level 3---------------------------------------------------;
DrawPaddle2 PROC
    mov eax, yellow + (yellow shl 4)
    call SetTextColor
    movsx ecx, paddleSize2
    mov esi, OFFSET paddle2
    mov dl, xCord
    mov dh, yCord
drawLoop:
    call Gotoxy
    lodsb
    call WriteChar
    inc dl
    loop drawLoop
    mov eax, white + (black shl 4)
    call SetTextColor
    ret
DrawPaddle2 ENDP
;-----------------------------------Using this function to update paddle after movement----------------------------------;
UpdatePaddle2 PROC
    movzx ecx, paddleSize2
    mov dl, xCord
    mov dh, yCord
clearLoop:
    call Gotoxy
    mWrite " "
    inc dl
    loop clearLoop
    ret
UpdatePaddle2 ENDP

;---------------------------------------Draw ball-----------------------------------------------;
DrawBall PROC
    mov eax , lightGreen + (black shl 4)
    call SetTextColor
    mov dl, xCordBall
    mov dh, yCordBall
    call Gotoxy
    mov al, ballChar
    call WriteChar
    mov eax, white + (black shl 4)
    call SetTextColor
    ret
DrawBall ENDP
;-----------------------------------------Procedure to update the ball----------------------------------------------;
ClearBall PROC
    mov dl, xCordBall
    mov dh, yCordBall
    call Gotoxy
    mov al, ' '
    call WriteChar
    ret
ClearBall ENDP
;-----------------------------------------Procedure to update the position of the ball------------------------------;
UpdateBall PROC
;-------------------------------------------Checking lives-----------------------------------------;
 
; Clear the old ball position
    call ClearBall

    ; Update ball position
    mov al, xCordBall         ; Load x-coordinate of the ball
    add al, xDirection        ; Update x-coordinate based on x-direction
    mov xCordBall, al         ; Store updated x-coordinate

    mov al, yCordBall         ; Load y-coordinate of the ball
    add al, yDirection        ; Update y-coordinate based on y-direction
    mov yCordBall, al         ; Store updated y-coordinate

    call checkBrickCollision

    ; ------------------- Missed Paddle Check -------------------;
    mov al, yCordBall         ; AL = y-coordinate of the ball
    mov bl, yCord             ; BL = y-coordinate of the paddle
    cmp al, bl                ; Compare ball's Y with paddle's Y
    jl checkOtherCollisions  ; If the ball is above or at the paddle, skip

    ; Ball skipped the paddle
missedPaddle:
    dec lives                 ; Decrement lives
    cmp lives,0
    je livesFinished
    mov al,xCord
    mov xCordBall, al        ; Reset ball's X-coordinate
    mov yCordBall, 39         ; Reset ball's Y-coordinate
    DrawHeart lives
    
    jmp checkOtherCollisions         ; Skip remaining updates

checkOtherCollisions:
    ; ------------------- Collision Checks -------------------
    ; Top and bottom boundary collision
    mov al, yCordBall
    cmp al, 2                 ; Top boundary
    jl bounceY                ; Bounce if above top boundary
    cmp al, 48                ; Bottom boundary
    jg bounceY                ; Bounce if below bottom boundary

    ; Left and right boundary collision
    mov al, xCordBall
    cmp al, 82                ; Left boundary
    jl bounceX                ; Bounce if past left boundary
    cmp al, 127               ; Right boundary
    jg bounceX                ; Bounce if past right boundary

    ; ------------------- Paddle Collision -------------------
    mov al, yCordBall
    add al, 1                 ; Check slightly below ball
    cmp al, yCord             ; Compare with paddle's Y-coordinate
    jne noPaddleCollision     ; Skip if no collision

    mov al, xCordBall
    cmp al, xCord             ; Check if ball is to the left of paddle
    jl noPaddleCollision

    mov al, xCordBall
    sub al, paddleSize        ; Calculate paddle's rightmost position
    cmp al, xCord             ; Check if ball is beyond paddle
    jg noPaddleCollision

    ; Ball hit the paddle
    jmp bounceY

noPaddleCollision:
    ; No collision detected, proceed normally
    jmp endUpdateBall

bounceY:
    ; Invert the Y direction to bounce
    mov al, yDirection
    neg al
    mov yDirection, al
    jmp endUpdateBall

bounceX:
    ; Invert the X direction to bounce
    mov al, xDirection
    neg al
    mov xDirection, al
    jmp endUpdateBall

livesFinished:
call ClearHearts
ret

endUpdateBall:
    ; Draw the new ball position
    call DrawBall
    mov eax, 60

    sub timer,eax
    call Delay
    ret
UpdateBall ENDP
;-------------------------------------------Procedure for update ball level 2 ----------------------------------------------------;
UpdateBalllvl2 PROC
;-------------------------------------------Checking lives-----------------------------------------;
 
; Clear the old ball position
    call ClearBall

    ; Update ball position
    mov al, xCordBall         ; Load x-coordinate of the ball
    add al, xDirection        ; Update x-coordinate based on x-direction
    mov xCordBall, al         ; Store updated x-coordinate

    mov al, yCordBall         ; Load y-coordinate of the ball
    add al, yDirection        ; Update y-coordinate based on y-direction
    mov yCordBall, al         ; Store updated y-coordinate

    call checkBrickCollision2

    ; ------------------- Missed Paddle Check -------------------;
    mov al, yCordBall         ; AL = y-coordinate of the ball
    mov bl, yCord             ; BL = y-coordinate of the paddle
    cmp al, bl                ; Compare ball's Y with paddle's Y
    jl checkOtherCollisions  ; If the ball is above or at the paddle, skip

    ; Ball skipped the paddle
missedPaddle:
    dec lives                 ; Decrement lives
    cmp lives,0
    je livesFinished
    mov al,xCord
    mov xCordBall, al        ; Reset ball's X-coordinate
    mov yCordBall, 39         ; Reset ball's Y-coordinate
    DrawHeart lives
    
    jmp checkOtherCollisions         ; Skip remaining updates

checkOtherCollisions:
    ; ------------------- Collision Checks -------------------
    ; Top and bottom boundary collision
    mov al, yCordBall
    cmp al, 2                 ; Top boundary
    jl bounceY                ; Bounce if above top boundary
    cmp al, 48                ; Bottom boundary
    jg bounceY                ; Bounce if below bottom boundary

    ; Left and right boundary collision
    mov al, xCordBall
    cmp al, 82                ; Left boundary
    jl bounceX                ; Bounce if past left boundary
    cmp al, 127               ; Right boundary
    jg bounceX                ; Bounce if past right boundary

    ; ------------------- Paddle Collision -------------------
    mov al, yCordBall
    add al, 1                 ; Check slightly below ball
    cmp al, yCord             ; Compare with paddle's Y-coordinate
    jne noPaddleCollision     ; Skip if no collision

    mov al, xCordBall
    cmp al, xCord             ; Check if ball is to the left of paddle
    jl noPaddleCollision

    mov al, xCordBall
    sub al, paddleSize1        ; Calculate paddle's rightmost position
    cmp al, xCord             ; Check if ball is beyond paddle
    jg noPaddleCollision

    ; Ball hit the paddle
    jmp bounceY

noPaddleCollision:
    ; No collision detected, proceed normally
    jmp endUpdateBall

bounceY:
    ; Invert the Y direction to bounce
    mov al, yDirection
    neg al
    mov yDirection, al
    jmp endUpdateBall

bounceX:
    ; Invert the X direction to bounce
    mov al, xDirection
    neg al
    mov xDirection, al
    jmp endUpdateBall

livesFinished:
call ClearHearts
ret

endUpdateBall:
    ; Draw the new ball position
    call DrawBall
    mov eax, 70
    sub timer,eax
    call Delay
    ret
UpdateBalllvl2 ENDP
;----------------------------------Update ball for level 3-------------------------------------------;
UpdateBalllvl3 PROC
;-------------------------------------------Checking lives-----------------------------------------;
 
; Clear the old ball position
    call ClearBall

    ; Update ball position
    mov al, xCordBall         ; Load x-coordinate of the ball
    add al, xDirection        ; Update x-coordinate based on x-direction
    mov xCordBall, al         ; Store updated x-coordinate

    mov al, yCordBall         ; Load y-coordinate of the ball
    add al, yDirection        ; Update y-coordinate based on y-direction
    mov yCordBall, al         ; Store updated y-coordinate

    call checkBrickCollision3

    ; ------------------- Missed Paddle Check -------------------;
    mov al, yCordBall         ; AL = y-coordinate of the ball
    mov bl, yCord             ; BL = y-coordinate of the paddle
    cmp al, bl                ; Compare ball's Y with paddle's Y
    jl checkOtherCollisions  ; If the ball is above or at the paddle, skip

    ; Ball skipped the paddle
missedPaddle:
    dec lives                 ; Decrement lives
    cmp lives,0
    je livesFinished
    mov al,xCord
    mov xCordBall, al        ; Reset ball's X-coordinate
    mov yCordBall, 39         ; Reset ball's Y-coordinate
    DrawHeart lives
    
    jmp checkOtherCollisions         ; Skip remaining updates

checkOtherCollisions:
    ; ------------------- Collision Checks -------------------
    ; Top and bottom boundary collision
    mov al, yCordBall
    cmp al, 2                 ; Top boundary
    jl bounceY                ; Bounce if above top boundary
    cmp al, 48                ; Bottom boundary
    jg bounceY                ; Bounce if below bottom boundary

    ; Left and right boundary collision
    mov al, xCordBall
    cmp al, 82                ; Left boundary
    jl bounceX                ; Bounce if past left boundary
    cmp al, 127               ; Right boundary
    jg bounceX                ; Bounce if past right boundary

    ; ------------------- Paddle Collision -------------------
    mov al, yCordBall
    add al, 1                 ; Check slightly below ball
    cmp al, yCord             ; Compare with paddle's Y-coordinate
    jne noPaddleCollision     ; Skip if no collision

    mov al, xCordBall
    cmp al, xCord             ; Check if ball is to the left of paddle
    jl noPaddleCollision

    mov al, xCordBall
    sub al, paddleSize2        ; Calculate paddle's rightmost position
    cmp al, xCord             ; Check if ball is beyond paddle
    jg noPaddleCollision

    ; Ball hit the paddle
    jmp bounceY

noPaddleCollision:
    ; No collision detected, proceed normally
    jmp endUpdateBall

bounceY:
    ; Invert the Y direction to bounce
    mov al, yDirection
    neg al
    mov yDirection, al
    jmp endUpdateBall

bounceX:
    ; Invert the X direction to bounce
    mov al, xDirection
    neg al
    mov xDirection, al
    jmp endUpdateBall

livesFinished:
call ClearHearts
ret

endUpdateBall:
    ; Draw the new ball position
    call DrawBall
    mov eax, 65
    sub timer,eax
    call Delay
    ret
UpdateBalllvl3 ENDP
;-----------------------------------------------Procedure to check brick collision--------------------------------------;

checkBrickCollision PROC
    xor eax,eax
    mov eax,0
    xor ecx,ecx
    mov ecx, 0                    ; Total bricks to process
    xor esi,esi
    mov esi, 0                     ; Start from the first brick
    
brickLoop:
    cmp ecx, 30                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov al, [brickActive + ecx]    ; Check if the brick is active
    cmp al, 0                      ; Brick not active
    je skipNextBrick               ; Skip to the next brick if not active

    ; Check X-coordinate of ball with brick boundaries
    mov al, [startXCords + ecx]    ; Load start X
    cmp xCordBall, al
    jb skipNextBrick               ; No collision on X-axis, skip to next brick

    mov al, [endXCords + ecx]      ; Load end X
    cmp xCordBall, al
    ja skipNextBrick               ; No collision on X-axis, skip to next brick

    ; Check Y-coordinate of ball with brick boundaries
    mov al, [startYCords + ecx]    ; Load start Y
    cmp yCordBall, al
    jl skipNextBrick               ; No collision on Y-axis, skip to next brick

    mov al, [endYCords + ecx]      ; Load end Y
    cmp yCordBall, al
    jg skipNextBrick               ; No collision on Y-axis, skip to next brick

    ; Collision detected
    
    xor eax,eax
    mov al,0
    mov [brickActive + ecx], 0 ; Mark brick as inactive
    movzx eax,[brickScores+ecx]

    add playerScore,eax
    ;call printScoreAndLives

    ; Delete the brick visually
    movzx eax, [startXCords + ecx] ; Get X-coordinate
    movzx ebx, [startYCords + ecx] ; Get Y-coordinate
    
    push ecx

    mov temp1,eax
    mov temp2,ebx

   DeleteBrick temp1, temp2               ; Delete the brick
   INVOKE PlaySound, ADDR startSound, NULL, snd_asy or snd_nowait
    ;INVOKE PlaySound, ADDR startSound1, NULL, snd_asy or snd_nowait
   
  
   pop ecx
    ; Bounce the ball
    mov al, yDirection
    neg al
    mov yDirection, al
    ; Continue to next brick
    jmp incrementIndex

skipNextBrick:
    ; Skip to the next brick

incrementIndex:
    inc ecx                        ; Increment brick index
    jmp brickLoop                  ; Repeat for the next brick

endCheckCollision:
    ret
checkBrickCollision ENDP
;--------------------------------------Brick collison for level 2--------------------------------------------;
checkBrickCollision2 PROC

    xor ecx,ecx
    mov ecx, 0                    ; Total bricks to process
                        ; Start from the first brick

brickLoop:
    cmp ecx, 30                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov al, [brickActive2 + ecx]    ; Check if the brick is active
    cmp al, 0                      ; Brick not active
    je skipNextBrick               ; Skip to the next brick if not active

    ; Check X-coordinate of ball with brick boundaries
    mov al, [startXCords + ecx]    ; Load start X
    cmp xCordBall, al
    jb skipNextBrick               ; No collision on X-axis, skip to next brick

    mov al, [endXCords + ecx]      ; Load end X
    cmp xCordBall, al
    ja skipNextBrick               ; No collision on X-axis, skip to next brick

    ; Check Y-coordinate of ball with brick boundaries
    mov al, [startYCords + ecx]    ; Load start Y
    cmp yCordBall, al
    jl skipNextBrick               ; No collision on Y-axis, skip to next brick

    mov al, [endYCords + ecx]      ; Load end Y
    cmp yCordBall, al
    jg skipNextBrick               ; No collision on Y-axis, skip to next brick

    ; Collision detected
    mov al, [brickActive2 + ecx]    ; Load the brick's hit counter
    dec al                         ; Decrease the hit counter
    mov  [brickActive2 + ecx], al ; Update the hit counter

    cmp al, 0                      ; Check if the brick is broken (hit twice)
    je DeletingBrick           ; If not broken, skip the visual update
    ;---------------------------------------------------------
    movzx eax, [startXCords + ecx] ; Get X-coordinate
    movzx ebx, [startYCords + ecx] ; Get Y-coordinate

    mov temp1, eax
    mov temp2, ebx
   
    push ebp
    mov ebp,offset brickColorslvl2
    add ebp,ecx
   
    DrawBrick [ebp],temp1,temp2

    pop ebp
    
    mov al, yDirection
    neg al
    mov yDirection, al

    ; Continue to next brick
    jmp incrementIndex


DeletingBrick:
    
    ; Delete the brick visually
    movzx eax, [startXCords + ecx] ; Get X-coordinate
    movzx ebx, [startYCords + ecx] ; Get Y-coordinate

    mov temp1, eax
    mov temp2, ebx
    push ecx
    DeleteBrick temp1, temp2                ; Delete the brick
    INVOKE PlaySound, ADDR startSound, NULL, snd_asy or snd_nowait
;INVOKE PlaySound, ADDR startSound1, NULL, snd_asy or snd_nowait

    pop ecx
    movzx eax,[brickScores2+ecx]
    add playerScore,eax
    ;call printScoreAndLives
    mov al, yDirection
    neg al
    mov yDirection, al

skipNextBrick:
    ; Skip to the next brick

incrementIndex:
    inc ecx                       ; Increment brick index
    jmp brickLoop                  ; Repeat for the next brick

endCheckCollision:
    ret
checkBrickCollision2 ENDP
;------------------------------------Procedure for collision for level 3-------------------------------------;

checkBrickCollision3 PROC


    mov ecx, 30                    ; Total bricks to process
    mov esi, 0                     ; Start from the first brick

brickLoop:
    cmp esi, ecx                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov al, [brickActive3 + esi]   ; Check if the brick is active
    cmp al, 0                      ; Brick not active
    je skipNextBrick               ; Skip to the next brick if not active

    ; Adjusted X-coordinate comparison
    mov al, [startXCords + esi]    ; Load start X
    sub al, 1                      ; Subtract 1 for buffer
    cmp xCordBall, al
    jb skipNextBrick               ; No collision on X-axis, skip to next brick

    mov al, [endXCords + esi]      ; Load end X
    add al, 1                      ; Add 1 for buffer
    cmp xCordBall, al
    ja skipNextBrick               ; No collision on X-axis, skip to next brick

    ; Adjusted Y-coordinate comparison
    mov al, [startYCords + esi]    ; Load start Y
    sub al, 1                      ; Subtract 1 for buffer
    cmp yCordBall, al
    jl skipNextBrick               ; No collision on Y-axis, skip to next brick

    mov al, [endYCords + esi]      ; Load end Y
    add al, 1                      ; Add 1 for buffer
    cmp yCordBall, al
    jg skipNextBrick               ; No collision on Y-axis, skip to next brick

    ; Determine the direction of the bounce
    mov al, [startYCords + esi]    ; Load start Y
    sub al, 1                      ; Subtract 1 for buffer
    cmp yCordBall, al
    je handleBounceTop             ; Ball hits the top of the brick

    mov al, [endYCords + esi]      ; Load end Y
    add al, 1                      ; Add 1 for buffer
    cmp yCordBall, al
    je handleBounceBottom          ; Ball hits the bottom of the brick

    mov al, [startXCords + esi]    ; Load start X
    sub al, 1                      ; Subtract 1 for buffer
    cmp xCordBall, al
    je handleBounceLeft            ; Ball hits the left side of the brick

    mov al, [endXCords + esi]      ; Load end X
    add al, 1                      ; Add 1 for buffer
    cmp xCordBall, al
    je handleBounceRight           ; Ball hits the right side of the brick

    jmp incrementIndex

; Handle different bounce scenarios
handleBounceTop:
    mov al, yDirection
    neg al                         ; Reverse Y direction
    mov yDirection, al
    sub yCordBall, 1               ; Adjust position
    jmp updateBrickState

handleBounceBottom:
    mov al, yDirection
    neg al                         ; Reverse Y direction
    mov yDirection, al
    add yCordBall, 1               ; Adjust position
    jmp updateBrickState

handleBounceLeft:
    mov al, xDirection
    neg al                         ; Reverse X direction
    mov xDirection, al
    sub xCordBall, 1               ; Adjust position
    jmp updateBrickState

handleBounceRight:
    mov al, xDirection
    neg al                         ; Reverse X direction
    mov xDirection, al
    add xCordBall, 1               ; Adjust position
    jmp updateBrickState

updateBrickState:
    ; Mark the brick as hit temporarily to avoid multiple collisions in the same frame
    mov al, [brickActive3 + esi]
    cmp al, 4
    je skipNextBrick
    cmp al,5
    je deletingRandomBricks
    dec al                         ; Decrease hit counter
    mov [brickActive3 + esi], al   ; Update hit counter

    cmp al, 0
    je DeletingBrick               ; If brick is broken, delete it
    cmp al, 1
    je drawingLightestBrick        ; Draw the lighter version of the brick

    ; Update visuals for normal bricks
    movzx eax, [startXCords + esi] ; Get X-coordinate
    movzx ebx, [startYCords + esi] ; Get Y-coordinate

    mov temp1, eax
    mov temp2, ebx
    push ebp
    mov ebp, offset brickColors3lvl2
    add ebp, esi
    DrawBrick [ebp], temp1, temp2  ; Redraw the brick
    pop ebp

    jmp incrementIndex

deletingRandomBricks:
    mov [brickActive3 + esi], 0    ; Deactivate the current brick
    movzx eax, [startXCords + esi] ; Get X-coordinate
    movzx ebx, [startYCords + esi] ; Get Y-coordinate

    mov temp1, eax
    mov temp2, ebx
    mov ecx, 0                     ; Counter for deleted bricks

    DeleteBrick temp1, temp2       ; Delete the current brick visually

label1:
    cmp ecx, 5                     ; Check if 5 bricks are deleted
    je endCheckCollision           ; Exit if done

    mov eax, 30                    ; Set range [0, 29]
    call RandomRange               ; Call Irvine32's RandomRange
    ; Result is in EAX

    cmp eax, 0
    jl label1                      ; Retry if below range (not likely)
    cmp eax, 29
    jg label1                      ; Retry if above range (not likely)

    mov bl, [brickActive3 + eax]   ; Check brick state
    cmp bl, 0
    je label1                      ; Skip if inactive
    cmp bl, 4
    je label1                      ; Skip if in "bouncing" state

    mov [brickActive3 + eax], 0    ; Mark the brick as inactive
    movzx edx, [startXCords + eax] ; Get X-coordinate
    movzx ebx, [startYCords + eax] ; Get Y-coordinate
    mov temp1, edx
    mov temp2, ebx
    DeleteBrick temp1, temp2       ; Delete brick visually
    inc ecx                        ; Increment deleted count
    jmp label1                     ; Repeat for the next brick


 DeletingBrick:
    ; Update visuals for brick deletion
    movzx eax, [startXCords + esi]
    movzx ebx, [startYCords + esi]

    mov temp1, eax
    mov temp2, ebx
    DeleteBrick temp1, temp2       ; Delete the brick visually
    movzx eax, [brickScores2 + esi]
    add playerScore, eax

    push eax
    push ebx
    push ecx
    push edx
    push esi
    INVOKE PlaySound, ADDR startSound, NULL, snd_asy or snd_nowait
    ;INVOKE PlaySound, ADDR startSound1, NULL, snd_asy or snd_nowait
    
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax


    ; Bounce logic
    jmp incrementIndex
    
drawingLightestBrick:
    ; Update visuals for the lighter brick
    movzx eax, [startXCords + esi]
    movzx ebx, [startYCords + esi]

    mov temp1, eax
    mov temp2, ebx
    push ebp
    mov ebp, offset brickColors3lvl3
    add ebp, esi
    DrawBrick [ebp], temp1, temp2  ; Draw the lighter version of the brick
    pop ebp

    jmp incrementIndex

skipNextBrick:
incrementIndex:
    inc esi                        ; Increment brick index
    jmp brickLoop                  ; Repeat for the next brick

endCheckCollision:
  ret
checkBrickCollision3 ENDP

;------------------------------------Procedure to clear hearts------------------------------------------------;
ClearHearts PROC
   
   ; Set up initial positions
    xor ebx, ebx                ; Clear EBX
    mov ebx, 7              ; Load the number of lives into EBX
    mov xCordHeart, 155                ; Starting X-coordinate for the hearts
    mov yCordHeart, 14                 ; Fixed Y-coordinate for the hearts

ClearHeartLoop:
    cmp ebx, 0                  ; Check if all hearts are cleared
    jle EndClearHearts

    mGotoxy xCordHeart, yCordHeart            ; Move to the current position
    mWrite "  "                 ; Overwrite the heart with spaces
    add xCordHeart, 1                  ; Move X-coordinate to the next heart position
    dec ebx                     ; Decrement the counter
    jmp ClearHeartLoop          ; Repeat until all hearts are cleared

EndClearHearts:
ret
ClearHearts ENDP
;-------------------------------------Procedure to check the the active status of all bricks to end game-------------------------------;
CheckingBrickStatus PROC
    mov ecx, 30                    ; Total number of bricks to check
    mov esi, 0                     ; Start from the first brick
    mov al, 0                      ; Assume all bricks are broken (0)

checkLoop:
    cmp esi, ecx                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov bl, [brickActive + esi]    ; Load the current brick status (either 0 or 1)
    cmp bl, 1                      ; Check if the brick is active (1)
    je brickStillActive            ; If brick is still active, set status to 1

    ; Continue checking the next brick
skipNextBrick:
    inc esi                        ; Move to the next brick
    jmp checkLoop

brickStillActive:
    mov al, 1                      ; Set status to 1 (not all bricks are broken)
    jmp skipNextBrick              ; Skip the rest and continue with next brick

endCheckCollision:
    ; Store the final status in the variable 'allActiveBrick'
    mov [allActiveBrick], al       ; Store final status (0 for all broken, 1 for not all broken)

    ret
CheckingBrickStatus ENDP
;-------------------------------Checking brick status 2----------------------------------------------------;
CheckingBrickStatus2 PROC
    mov ecx, 30                    ; Total number of bricks to check
    mov esi, 0                     ; Start from the first brick
    mov al, 0                      ; Assume all bricks are broken (0)

checkLoop:
    cmp esi, ecx                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov bl, [brickActive2 + esi]    ; Load the current brick status (either 0 or 1)
    cmp bl, 1                      ; Check if the brick is active (1)
    jge brickStillActive            ; If brick is still active, set status to 1

    ; Continue checking the next brick
skipNextBrick:
    inc esi                        ; Move to the next brick
    jmp checkLoop

brickStillActive:
    mov al, 1                      ; Set status to 1 (not all bricks are broken)
    jmp skipNextBrick              ; Skip the rest and continue with next brick

endCheckCollision:
    ; Store the final status in the variable 'allActiveBrick'
    mov [allActiveBrick], al       ; Store final status (0 for all broken, 1 for not all broken)
   ret
CheckingBrickStatus2 ENDP
;----------------------------------for level 3-----------------------------------------------------;
CheckingBrickStatus3 PROC
    mov ecx, 30                    ; Total number of bricks to check
    mov esi, 0                     ; Start from the first brick
    mov al, 0                      ; Assume all bricks are broken (0)

checkLoop:
    cmp esi, ecx                   ; Check if all bricks are processed
    jge endCheckCollision          ; Exit loop if all bricks are checked

    mov bl, [brickActive3 + esi]    ; Load the current brick status (either 0 or 1)
    cmp bl,4
    je skipNextBrick
    cmp bl, 1                      ; Check if the brick is active (1)
    jge brickStillActive            ; If brick is still active, set status to 1

    ; Continue checking the next brick
skipNextBrick:
    inc esi                        ; Move to the next brick
    jmp checkLoop

brickStillActive:
    mov al, 1                      ; Set status to 1 (not all bricks are broken)
    jmp skipNextBrick              ; Skip the rest and continue with next brick

endCheckCollision:
    ; Store the final status in the variable 'allActiveBrick'
    mov [allActiveBrick], al       ; Store final status (0 for all broken, 1 for not all broken)
   ret
CheckingBrickStatus3 ENDP
;--------------------------------------------Procedure of level 1 ------------------------------------------------------;
Level1 PROC
	call writeTitle								;write the title of the game
	call DrawBoundry							;Draw the boundry for the game
	call DrawLvl1								;Draw the bricks for level 1
	mov xCord,100
    mov yCord,40
    mov xCordBall,100
    mov yCordBall,39
    call DrawPaddle
    call DrawBall
    ;DrawBox 140,8,40,1,cyan
    DrawHeart lives
    call printScoreAndLives
;------------------------------------------Game Loop----------------------------------------------------------;
gameLoop:
    call UpdateBall
    call printScoreAndLives
    call CheckingBrickStatus
    cmp allActiveBrick,0
    je moveNextLevel
    cmp lives,0
    je endingGame
    call ReadKey                      ; Get input character from the user
    mov inputChar,al
    cmp inputChar, "a"                 ; Check if the input is 'a'
    je moveLeft                        ; Jump to moveLeft if 'a' is pressed
    cmp inputChar, "d"                 ; Check if the input is 'd'
    je moveRight                       ; Jump to moveRight if 'd' is pressed
    cmp inputChar, "p"
    je pauseLoop

    jmp gameLoop                       ; Loop back to game logic

;------------------------------------------Paddle Movement-----------------------------------------------------------;


pauseGame:
    mov gamePaused, 1        ; Set gamePaused to 1
    jmp gameLoop             ; Continue to pause logic in game loop

pauseLoop:
    ; Display pause message
    mGotoxy 20, 30
    mov edx, OFFSET pauseMessage
    call WriteString

    ; Wait for 'p' to resume
    call ReadChar
    mov inputChar, al
    cmp inputChar, "p"
    jne pauseLoop            ; Stay in pause loop until 'p' is pressed

    mov gamePaused, 0        ; Resume game
    mGotoxy 10, 20           ; Clear pause message
    jmp gameLoop             ; Return to main game logic
moveLeft:
    cmp xCord, 82                       ; Check if paddle is at left boundary
    jle gameLoop                       ; If yes, don't move further left
    call UpdatePaddle                  ; Clear the paddle at the current position
    sub xCord, 2                        ; Move paddle left by 3 units
    call DrawPaddle                    ; Redraw the paddle at the new position
     
    jmp gameLoop

moveRight:
    xor eax,eax
    mov al, xCord
    add al, paddleSize               ; Calculate paddle's rightmost position
    cmp eax, 130                       ; Check if paddle is at right boundary
    jge gameLoop                       ; If yes, don't move further right
    call UpdatePaddle                  ; Clear the paddle at the current position
    add xCord, 2                        ; Move paddle right by 3 units
    call DrawPaddle                    ; Redraw the paddle at the new position
    
    jmp gameLoop
moveNextLevel:
add level,1
add playerScore,50
call Clrscr
call Level2

endingGame:
call endPage
ret

Level1 ENDP
;----------------------------------------------Procedure level 2--------------------------------------------------;
Level2 PROC
mov xDirection,1
mov yDirection ,-1

	call writeTitle								;write the title of the game
	call DrawBoundry							;Draw the boundry for the game
	call DrawLvl2								;Draw the bricks for level 1
	mov xCord,100
    mov yCord,40
    mov xCordBall,100
    mov yCordBall,39
    call DrawPaddle1
    call DrawBall
    ;DrawBox 140,8,40,1,cyan
    DrawHeart lives
    call printScoreAndLives
;------------------------------------------Game Loop----------------------------------------------------------;
gameLoop:
    ;add lives,1
    call UpdateBalllvl2
    call printScoreAndLives
    call CheckingBrickStatus2
    cmp allActiveBrick,0
    je jmpToLevel3
    cmp lives,0
    je endingGame
    call ReadKey                      ; Get input character from the user
    mov inputChar,al
    cmp inputChar, "a"                 ; Check if the input is 'a'
    je moveLeft                        ; Jump to moveLeft if 'a' is pressed
    cmp inputChar, "d"                 ; Check if the input is 'd'
    je moveRight                       ; Jump to moveRight if 'd' is pressed
    cmp inputChar,"p"
    je pauseLoop
   jmp gameLoop                       ; Loop back to game logic

;------------------------------------------Paddle Movement-----------------------------------------------------------;


pauseGame:
    mov gamePaused, 1        ; Set gamePaused to 1
    jmp gameLoop             ; Continue to pause logic in game loop

pauseLoop:
    ; Display pause message
    mGotoxy 20, 30
    mov edx, OFFSET pauseMessage
    call WriteString

    ; Wait for 'p' to resume
    call ReadChar
    mov inputChar, al
    cmp inputChar, 'p'
    jne pauseLoop            ; Stay in pause loop until 'p' is pressed

    mov gamePaused, 0        ; Resume game
    mGotoxy 10, 20           ; Clear pause message
    jmp gameLoop             ; Return to main game logic

moveLeft:
    cmp xCord, 82                       ; Check if paddle is at left boundary
    jle gameLoop                       ; If yes, don't move further left
    call UpdatePaddle1                  ; Clear the paddle at the current position
    sub xCord, 2                        ; Move paddle left by 3 units
    call DrawPaddle1                    ; Redraw the paddle at the new position
     
    jmp gameLoop

moveRight:
    xor eax,eax
    mov al, xCord
    add al, paddleSize1               ; Calculate paddle's rightmost position
    cmp eax, 130                       ; Check if paddle is at right boundary
    jge gameLoop                       ; If yes, don't move further right
    call UpdatePaddle1                  ; Clear the paddle at the current position
    add xCord, 2                        ; Move paddle right by 3 units
    call DrawPaddle1                    ; Redraw the paddle at the new position
    
    jmp gameLoop

jmpToLevel3:
add level,1
add playerScore,50
call Clrscr
call Level3

endingGame:
call endPage
ret

Level2 ENDP
;----------------------------------------Level 3 procedure-----------------------------------------------;
Level3 PROC
mov xDirection,1
mov yDirection ,-1
	call writeTitle								;write the title of the game
	call DrawBoundry							;Draw the boundry for the game
	call DrawLvl3								;Draw the bricks for level 1
	mov xCord,100
    mov yCord,40
    mov xCordBall,100
    mov yCordBall,39
    call DrawPaddle2
    call DrawBall
    ;DrawBox 140,8,40,1,cyan
    DrawHeart lives
    call printScoreAndLives
    
;------------------------------------------Game Loop----------------------------------------------------------;
gameLoop:
   
    ;add lives,1
    call UpdateBalllvl3
    call printScoreAndLives
    call CheckingBrickStatus3
    cmp allActiveBrick,0
    je endingGame
    cmp lives,0
    je endingGame
    call ReadKey                      ; Get input character from the user
    mov inputChar,al
    cmp inputChar, 'a'                 ; Check if the input is 'a'
    je moveLeft                        ; Jump to moveLeft if 'a' is pressed
    cmp inputChar, 'd'                ; Check if the input is 'd'
    je moveRight                       ; Jump to moveRight if 'd' is pressed
    cmp inputChar,'p'
    je pauseLoop
   jmp gameLoop                       ; Loop back to game logic

;------------------------------------------Paddle Movement-----------------------------------------------------------;

pauseGame:
    mov gamePaused, 1        ; Set gamePaused to 1
    jmp gameLoop             ; Continue to pause logic in game loop

pauseLoop:
    ; Display pause message
    mGotoxy 20, 30
    mov edx, OFFSET pauseMessage
    call WriteString

    ; Wait for 'p' to resume
    call ReadChar
    mov inputChar, al
    cmp inputChar, 'p'
    jne pauseLoop            ; Stay in pause loop until 'p' is pressed

    mov gamePaused, 0        ; Resume game
    mGotoxy 10, 20           ; Clear pause message
    jmp gameLoop             ; Return to main game logic


moveLeft:
    cmp xCord, 82                       ; Check if paddle is at left boundary
    jle gameLoop                       ; If yes, don't move further left
    call UpdatePaddle2                  ; Clear the paddle at the current position
    sub xCord, 2                        ; Move paddle left by 3 units
    call DrawPaddle2                    ; Redraw the paddle at the new position
     
    jmp gameLoop

moveRight:
    xor eax,eax
    mov al, xCord
    add al, paddleSize2               ; Calculate paddle's rightmost position
    cmp eax, 131                       ; Check if paddle is at right boundary
    jge gameLoop                       ; If yes, don't move further right
    call UpdatePaddle2                  ; Clear the paddle at the current position
    add xCord, 2                        ; Move paddle right by 3 units
    call DrawPaddle2                    ; Redraw the paddle at the new position
    jmp gameLoop
endingGame:
call endPage
ret

Level3 ENDP
;----------------------------------------Procedure for time---------------------------------------------------------------------------;


;-----------------------------------------------------MAIN procedure----------------------------------------------------------------;
main PROC
mov eax, white+(black shl 4)				;set text color
call SetTextColor
call Randomize
;INVOKE PlaySound, ADDR startSound1, NULL, snd_asy or snd_nowait

call mainMenu 
mov eax,white+(black shl 4)				;set text color
call SetTextColor

INVOKE ExitProcess, 0						;exit the program
main ENDP
;-----------------------------------------------------PROCEDURES----------------------------------------------------------;

;-----------------------------------------------------MAIN MENU------------------------------------------------------------;
mainMenu PROC

    DrawBox 52,10,100,30,white,yellow
    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor
    mGotoxy 68,12
    mWriteString wlcm1
    mGotoxy 68,13
    mWriteString wlcm2
    mGotoxy 68,14
    mWriteString wlcm3
    mGotoxy 68,15
    mWriteString wlcm4
    mGotoxy 68,16
    mWriteString wlcm5
    mGotoxy 68,18
    mWriteString intro1
    mGotoxy 68,19
    mWriteString intro2
    mGotoxy 68,20
    mWriteString intro3
    mGotoxy 68,21
    mWriteString intro4
    mGotoxy 68,22
    mWriteString intro5
    mGotoxy 68,23
    mWriteString intro6
    mGotoxy 73,30
    mWrite "Enter Player Name (10 letters MAX) : "
    mov edx,offset pName
    mov ecx,10
    call ReadString

    mov eax,white+(black shl 4)				;set text color
    call SetTextColor
    call Clrscr


    skipperOption:
    DrawBox 52,10,100,30,white,yellow
    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor

    mGotoxy 85,12
    mWriteString menu1
    mGotoxy 85,13
    mWriteString menu2
    mGotoxy 85,14
    mWriteString menu3
    mGotoxy 85,15
    mWriteString menu4
    mGotoxy 85,16
    mWriteString menu5

    mGotoxy 140,12
    mWriteString pName

    mGotoxy 95,20
    mWrite "Start Game"
    mGotoxy 94,22
    mWrite "Instructions"
    mGotoxy 95,24
    mWrite "Highscores"
    mGotoxy 98,26
    mWrite "Exit"

    xor ebx,ebx
    mov bl,19
    mov ecx,9

    plop:
    mGotoxy 90,bl
    mov al,186
    call WriteChar
    mGotoxy 110,bl
    mov al,186
    call WriteChar
    inc bl
    loop plop

    mGotoxy 110,bl
    mov al,188
    call WriteChar

    mGotoxy 90,bl
    mov al,200
    call WriteChar
    mov ecx,19
    mov al,205
    plop5:
    call WriteChar
    loop plop5



    mov ecx,3
    mov bl,21
    plop2:
    mGotoxy 90,bl
    mov al,204
    call WriteChar
    mGotoxy 110,bl
    mov al,185
    call WriteChar
    mGotoxy 91,bl
    mov al,205
    push ecx
    mov ecx,19  
    plop3:
    call WriteChar
    loop plop3
    pop ecx
    add bl,2
    loop plop2

    mGotoxy 90,19
    mov al, 201
    call WriteChar
    mov ecx,19
    mov al,205
    plop4:
    call WriteChar
    loop plop4
    mov al, 187
    call WriteChar

    mov rocketX, 91
    mov rocketY, 20
    DrawRocket rocketX, rocketY

    menuLoop:
        call ReadChar             ; Read key input
        cmp al, 'w'              ; Check if the key is 'w' (move up)
        je MoveUp
        cmp al, 's'              ; Check if the key is 's' (move down)
        je MoveDown
        cmp al, 0Dh              ; Check if Enter (Carriage Return, 0Dh) is pressed
        je SelectOption
        jmp menuLoop             ; Repeat the loop if no valid key

    MoveUp:
        cmp rocketY, 20          ; Check if the rocket is already at the top (Start Game)
        je menuLoop              ; Don't move up if rocket is at "Start Game"
        mGotoxy rocketX, rocketY
        mWriteSpace 2
        sub rocketY,2              ; Move the rocket up (decrease Y-coordinate)
        DrawRocket rocketX,rocketY          ; Update rocket's position
        jmp menuLoop

    MoveDown:
        cmp rocketY, 26          ; Check if the rocket is already at the bottom (Exit)
        je menuLoop ; Don't move down if rocket is at "Exit"
        mGotoxy rocketX, rocketY
        mWriteSpace 2
        add rocketY,2              ; Move the rocket down (increase Y-coordinate)
        DrawRocket rocketX,rocketY         
        jmp menuLoop

    SelectOption:
        cmp rocketY, 20          ; Check if the rocket is at "Start Game"
        je StartGame
        cmp rocketY, 22          ; Check if the rocket is at "Instructions"
        je Instructions
        cmp rocketY, 24          ; Check if the rocket is at "Highscores"
        je HighScores
        cmp rocketY, 26          ; Check if the rocket is at "Exit"
        je ExitGame
        jmp menuLoop

    StartGame:
    mov eax,white+(black shl 4)
    call SetTextColor
    call Clrscr
    add level,1
    ResetGame                     ; calls the reset game macro
    call Level1
    jmp mainMenu

    Instructions:   
    DrawBox 52,10,100,30,white,yellow
    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor
    mGotoxy 68,12
    mWriteString inst1
    mGotoxy 68,13
    mWriteString inst2
    mGotoxy 68,14
    mWriteString inst3
    mGotoxy 68,15
    mWriteString inst4
    mGotoxy 68,16
    mWriteString inst5

    mGotoxy 68,20
    mWrite "Press 'a' to move paddle left and 'd' to move right"
    mGotoxy 68,21
    mWrite "Press 'p' to pause the game"
    mGotoxy 68,22
    mWrite "Press 'q' to go back to main menu"

    insLoop:
        call ReadChar             ; Read key input
        cmp al, 'q'              ; Check if the key is 'q' (go back to main menu)
        je skipperOption
       jmp insLoop



    HighScores:
    call printHighscores
    jmp skipperOption

    ExitGame:
    Invoke ExitProcess,0
        ret

    mov eax,white+(black shl 4)				;set text color
    call SetTextColor
    ret 
mainMenu ENDP
;-----------------------------------------------------MAIN MENU ENDP--------------------------------------------------------;

printHighscores PROC
    DrawBox 52,10,100,30,white,yellow
    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor

    mGotoxy 68,12
    mWriteString hghs1
    mGotoxy 68,13
    mWriteString hghs2
    mGotoxy 68,14
    mWriteString hghs3
    mGotoxy 68,15
    mWriteString hghs4
    mGotoxy 68,16
    mWriteString hghs5
    mGotoxy 68,17
    mWriteString hghs6

    mGotoxy 68,18
    mWrite "Player Name"
    mGotoxy 90,18
    mWrite "Score"
    mGotoxy 100,18
    mWrite "Level"

    ;open name file and read all the names
    mov edx, offset nametxt                     ;name file
    call OpenInputFile                          ;open the file
    mov fileHandle, eax                         ;save handle

    mov ecx, lengthof input_buffer       ; Set loop counter to buffer size
    mov edi, OFFSET input_buffer        ; Point to the start of the buffer

    clear_loop:
    mov BYTE PTR [edi], 0     ; Set current byte to 0
    inc edi                    ; Move to the next byte
    loop clear_loop            ; Repeat for all bytes
                                            
    mov edx, offset input_buffer                ;read all the file in buffer
    mov ecx,lengthof input_buffer               ;move amount of words to read (size of buffer)
    mov eax, fileHandle                         ;give the handle of file to read from
    call ReadFromFile                           ;read
                                            
    mov eax, fileHandle                         ;give handle
    call CloseFile                              ;close file were done reading
                                            
    xor ecx, ecx                                ;clear ecx just in case
    mov edx, offset input_buffer                ;mov buffer to edx
    call StrLength                              ;get the length of the string for ecx
    mov ecx, eax                                
                                            
    mov esi, offset input_buffer                
    xor eax, eax                

    ;count number of players in the file mostly 10 but just to avoid access violations  
    mov playersInFile, 0                        ;initialize the counter

    countPlayers:                               
        mov al, [esi]                           ;pretty standard compare loop to check for all '/' as they mark end of a players name
        cmp al, '/'                             
        jne skipPlayerCount                     
        inc playersInFile                       

    skipPlayerCount:
        inc esi                    
        dec ecx                    
        jnz countPlayers       
    
    ;now we have the number of players in the file , store them in the playerArray
    cmp playersInFile, MAX_PLAYERS
    ja warning  						;if more than 10 players in file , this will probably never happen but just in case 

    ;copy the names of the players in the playerArray.playerName

    mov esi, offset input_buffer    ;point to buffer to copy from
    mov edi, offset playerArray     ;point to first element of array
    mov ecx, playersInFile          ;Number of players

    copyPlayerNames:
        mov edx, edi                ;current index of playerArray [struct]
        mov ebx,0                   ;index of players name as we copy it byte by byte
        xor eax,eax				    ;clear eax

    copyNameLoop:
        mov al, [esi]               ;load the current character
        cmp al, '/'                 ;check for '/' delimiter
        je endNameCopy              ;if player name ends move to the next index of players array
        cmp ebx, 9                  ;check for max length of name [not necessary but better be safe]
        ja endNameCopy              ;move to next player if name is too long

        mov (PLAYER PTR [edx]).playerName[ebx], al ;move the character to the playerName if not delimiter
        inc ebx                     ;move to next name byte (player->playerName->next byte)
        inc esi                     ; Move to the next character in the input buffer
        jmp copyNameLoop            ;loop for the entire name

    endNameCopy:
        ; Null-terminate the playerName
        mov (PLAYER PTR [edx]).playerName[ebx], 0 ; Add a null terminator at the end
        inc esi                      ; Skip the delimiter '/'
    
        ; Move to the next PLAYER struct
        add edi, SIZEOF PLAYER
        loop copyPlayerNames         ; Repeat for all players in file

    ;now open the score file and copy all the scores into the playerStruct
    
    ; Open file for reading
    mov edx, OFFSET scoreBin
    call OpenInputFile
    mov fileHandle, eax
    ;Read scores and store in playerArray also checking for delimiter errors
    mov ecx, playersInFile
    mov esi, OFFSET playerArray
    xor ebx, ebx
    readScores:
        push ecx
        mov edx, OFFSET score_buffer
        mov eax, fileHandle
        mov ecx,4
        call ReadFromFile
        mov eax, score_buffer
        mov (PLAYER PTR [esi]).PlyScore, eax
        mov ecx,1
        mov eax, fileHandle
        lea edx,offset delimBuffer
        call ReadFromFile
        xor eax,eax
        mov al,delimBuffer
        cmp al, '/'
        jne DelimiterError
        add esi, SIZEOF PLAYER
        pop ecx
        loop readScores

        mov eax, fileHandle
        call CloseFile

    ; Now open level file and do the same (read->store->check for delim)

    ; Open file for reading
    mov edx, OFFSET lvlBin
    call OpenInputFile
    mov fileHandle, eax
    ;Read scores and store in playerArray also checking for delimiter errors
    mov ecx, playersInFile
    mov esi, OFFSET playerArray
    xor ebx, ebx
    readLevels:
        push ecx
        lea edx,levelBuffer
        mov eax, fileHandle
        mov ecx,1
        call ReadFromFile
        xor eax,eax
        mov al,levelBuffer
        mov (PLAYER PTR [esi]).playerLevel,al
        mov ecx,1
        mov eax, fileHandle
        lea edx,offset delimBuffer
        call ReadFromFile
        xor eax,eax
        mov al,delimBuffer
        cmp al, '/'
        jne DelimiterError
        add esi, SIZEOF PLAYER
        pop ecx
        loop readLevels
    mov eax, fileHandle
    call CloseFile

    ; Now print the highscores
    printTopPlayers:
    mov ecx, MAX_PLAYERS           ; Initialize loop counter
    mov esi, 0					 ; Initialize indexArray index
    mov highscoreY, 20             ; Start Y-coordinate for printing

    printLoop:
    mov ebx, esi     ; Get index from indexArray
    xor eax, eax                   ; Clear eax for multiplication
    mov edi, OFFSET playerArray    ; Base address of playerArray
    mov eax, TYPE PLAYER           ; Size of one PLAYER struct
    mul ebx                        ; Multiply index by size of PLAYER
    add edi, eax                   ; Address of playerArray[indexArray[i]]

    ; Print player name
    mGotoxy 68, highscoreY
    lea edx, (PLAYER PTR [edi]).playerName
    call WriteString

    ; Print player score
    mGotoxy 90, highscoreY
    mov eax, (PLAYER PTR [edi]).PlyScore
    call WriteDec

    ; Print player level
    mGotoxy 100, highscoreY
    movzx eax, (PLAYER PTR [edi]).playerLevel
    call WriteDec

    inc esi                        ; Move to next index in indexArray
    add highscoreY, 2              ; Move to next line

    dec ecx                        ; Decrement counter
    jnz printLoop                  ; Jump back if counter is not zero


    insLoop2:
        call ReadChar             ; Read key input
        cmp al, 'q'              ; Check if the key is 'q' (go back to main menu)
        je returnerer
       jmp insLoop2

    DelimiterError:
    ; Print error message and exit
    mWrite "The was an error with the delimitors ,Please Recheck the files !"
    jmp returnerer

    warning:
    mWrite "Something went wrong, please check the file.There cant be more than 10 players !"
    jmp returnerer


    returnerer:
    ret
printHighscores ENDP

calHighscores PROC uses eax ebx ecx edx esi edi
;open files and read data
;open name file and read all the names
mov edx, offset nametxt                     ;name file
call OpenInputFile                          ;open the file
mov fileHandle, eax                         ;save handle
                                            
mov edx, offset input_buffer                ;read all the file in buffer
mov ecx,lengthof input_buffer               ;move amount of words to read (size of buffer)
mov eax, fileHandle                         ;give the handle of file to read from
call ReadFromFile                           ;read
                                            
mov eax, fileHandle                         ;give handle
call CloseFile                              ;close file were done reading
                                            
xor ecx, ecx                                ;clear ecx just in case
mov edx, offset input_buffer                ;mov buffer to edx
call StrLength                              ;get the length of the string for ecx
mov ecx, eax                                
                                            
mov esi, offset input_buffer                
xor eax, eax                

;count number of players in the file mostly 10 but just to avoid access violations  

mov playersInFile, 0                        ;initialize the counter

countPlayers:                               
    mov al, [esi]                           ;pretty standard compare loop to check for all '/' as they mark end of a players name
    cmp al, '/'                             
    jne skipPlayerCount                     
    inc playersInFile                       

skipPlayerCount:
    inc esi                    
    dec ecx                    
    jnz countPlayers       
    
;now we have the number of players in the file , store them in the playerArray
cmp playersInFile, MAX_PLAYERS
jg warning  						;if more than 10 players in file , this will probably never happen but just in case 

;copy the names of the players in the playerArray.playerName

mov esi, offset input_buffer    ;point to buffer to copy from
mov edi, offset playerArray     ;point to first element of array
mov ecx, playersInFile          ;Number of players

copyPlayerNames:
    mov edx, edi                ;current index of playerArray [struct]
    mov ebx,0                   ;index of players name as we copy it byte by byte
    xor eax,eax				    ;clear eax

copyNameLoop:
    mov al, [esi]               ;load the current character
    cmp al, '/'                 ;check for '/' delimiter
    je endNameCopy              ;if player name ends move to the next index of players array
    cmp ebx, 9                  ;check for max length of name [not necessary but better be safe]
    ja endNameCopy              ;move to next player if name is too long

    mov (PLAYER PTR [edx]).playerName[ebx], al ;move the character to the playerName if not delimiter
    inc ebx                     ;move to next name byte (player->playerName->next byte)
    inc esi                     ; Move to the next character in the input buffer
    jmp copyNameLoop            ;loop for the entire name

endNameCopy:
    ; Null-terminate the playerName
    mov (PLAYER PTR [edx]).playerName[ebx], 0 ; Add a null terminator at the end
    inc esi                      ; Skip the delimiter '/'
    
    ; Move to the next PLAYER struct
    add edi, SIZEOF PLAYER
    loop copyPlayerNames         ; Repeat for all players in file

;now move current player to the last index of the array

; Calculate the address of the 11th player (index 10) in playerArray

lea edi,playerArray[ MAX_PLAYERS * TYPE PLAYER ]

; Copy the current player's name
mov edx, OFFSET pName               ; Address of currentPlayerName
call StrLength                      ; Get the length of the current player's name
mov ecx, eax                        ; Store the length in ecx
xor ebx,ebx 					    ; Clear ebx for indexing the playername array

copyCurrentPlayerName:
    mov al, [edx]                    ; Load the current character from currentName
    mov (PLAYER PTR [edi]).playerName[ebx], al ; Copy to playerName field
    inc edx                          ; Increment source pointer
    inc ebx                          ; Increment destination pointer
    loop copyCurrentPlayerName       ; Repeat for up to 10 characters
    ;null terminate the name
    mov (PLAYER PTR [edi]).playerName[ebx], 0 ; Add a null terminator at the end

;now open the score file and copy all the scores into the playerStruct
; Open file for reading
    mov edx, OFFSET scoreBin
    call OpenInputFile
    mov fileHandle, eax
;Read scores and store in playerArray also checking for delimiter errors
    mov ecx, playersInFile
    mov esi, OFFSET playerArray
    xor ebx, ebx
    readScores:
        push ecx
        mov edx, OFFSET score_buffer
        mov eax, fileHandle
        mov ecx,4
        call ReadFromFile
        mov eax, score_buffer
        mov (PLAYER PTR [esi]).PlyScore, eax
        mov ecx,1
        mov eax, fileHandle
        lea edx,offset delimBuffer
        call ReadFromFile
        xor eax,eax
        mov al,delimBuffer
        cmp al, '/'
        jne DelimiterError
        add esi, SIZEOF PLAYER
        pop ecx
        loop readScores

mov eax, fileHandle
call CloseFile

; Now open level file and do the same (read->store->check for delim)

; Open file for reading
    mov edx, OFFSET lvlBin
    call OpenInputFile
    mov fileHandle, eax
;Read scores and store in playerArray also checking for delimiter errors
    mov ecx, playersInFile
    mov esi, OFFSET playerArray
    xor ebx, ebx
    readLevels:
        push ecx
        lea edx,levelBuffer
        mov eax, fileHandle
        mov ecx,1
        call ReadFromFile
        xor eax,eax
        mov al,levelBuffer
        mov (PLAYER PTR [esi]).playerLevel,al
        mov ecx,1
        mov eax, fileHandle
        lea edx,offset delimBuffer
        call ReadFromFile
        xor eax,eax
        mov al,delimBuffer
        cmp al, '/'
        jne DelimiterError
        add esi, SIZEOF PLAYER
        pop ecx
        loop readLevels
mov eax, fileHandle
call CloseFile

; move the current level and score into the 11th array element!
; Calculate the address of the 11th player (index 10) in playerArray

    lea edi,playerArray[ MAX_PLAYERS * TYPE PLAYER ]
    xor eax,eax
    mov eax,playerScore
    mov (PLAYER PTR [edi]).PlyScore,eax
    xor eax,eax
    mov al,level
    mov (PLAYER PTR [edi]).playerLevel,al

;Now we sort the array of players but instead of sorting and moving the elements of the array itself we sort a parallel array 
; So that we can avoid copying struct elements which is tedious.

; Sort the player array using the parallel index array

sortPlayerArray:
    mov ecx, TOTAL_PLAYERS         ; Number of players to sort (11 total)
    dec ecx                        ; Outer loop for n-1 iterations

outerLoop:
    push ecx                       ; Save outer loop counter
    mov esi, OFFSET indexArray     ; Pointer to start of indexArray
    mov ecx, TOTAL_PLAYERS         ; Inner loop for n-1 iterations
    dec ecx                        ; (n-1-i iterations)

innerLoop:
    mov edi, OFFSET playerArray     ; Base address of playerArray

    ; Load indexArray[i] into ebx
    movzx ebx, BYTE PTR [esi]       ; Load indexArray[i] into ebx
    xor eax, eax                    ; Clear eax for multiplication
    mov eax, TYPE PLAYER            ; Size of one PLAYER struct
    mul ebx                         ; Multiply index by size of PLAYER
    add eax, edi                    ; Address of playerArray[indexArray[i]]
    mov ebx, (PLAYER PTR [eax]).PlyScore ; Load PlyScore[indexArray[i]] into ebx
    mov tempStore, ebx              ; Store PlyScore[indexArray[i]] in tempStore

    ; Load indexArray[i+1] into ebx
    movzx ebx, BYTE PTR [esi + 1]   ; Load indexArray[i+1] into ebx
    xor eax, eax                    ; Clear eax for multiplication
    mov eax, TYPE PLAYER            ; Size of one PLAYER struct
    mul ebx                         ; Multiply index by size of PLAYER
    add eax, edi                    ; Address of playerArray[indexArray[i+1]]
    mov edx, (PLAYER PTR [eax]).PlyScore ; Load PlyScore[indexArray[i+1]] into edx

    ; Compare scores
    mov ebx,tempStore
    cmp ebx, edx                            ; Compare PlyScore[indexArray[i]] and PlyScore[indexArray[i+1]]
    jge noSwap                              ; No swap if current score >= next score

    ; Swap indexArray[i] and indexArray[i+1]
    mov al, BYTE PTR [esi]                  ; Load indexArray[i] into al
    mov dl, BYTE PTR [esi + 1]              ; Load indexArray[i+1] into dl
    mov BYTE PTR [esi], dl                  ; indexArray[i] = indexArray[i+1]
    mov BYTE PTR [esi + 1], al              ; indexArray[i+1] = indexArray[i]

noSwap:
    inc esi                                 ; Move to next index in indexArray
    loop innerLoop                          ; Repeat inner loop

    pop ecx                                 ; Restore outer loop counter
    loop outerLoop                          ; Repeat outer loop


;Now write the top 10 players to a file
mov edx,offset nametxt
call CreateOutputFile
mov fileHandle,eax


mov ecx,MAX_PLAYERS
mov esi, OFFSET indexArray

WriteNameToFile:
    push ecx
    movzx ebx, BYTE PTR [esi]      ; Get index from indexArray
    xor eax, eax                   ; Clear eax for multiplication
    mov edi, OFFSET playerArray    ; Base address of playerArray
    mov eax, TYPE PLAYER           ; Size of one PLAYER struct
    mul ebx                        ; Multiply index by size of PLAYER
    add edi, eax                   ; Address of playerArray[indexArray[i]]
    ; Write player name to file
    lea edx, (PLAYER PTR [edi]).playerName
    call StrLength
    mov ecx, eax
    lea edx, (PLAYER PTR [edi]).playerName
    mov eax, fileHandle
    call WriteToFile
    mov edx, OFFSET delim
    mov ecx, 1
    mov eax, fileHandle
    call WriteToFile
    pop ecx
    inc esi                        ; Move to next index in indexArray
    loop WriteNameToFile

mov eax,fileHandle
call CloseFile

;Now write the scores to file
mov edx,offset scoreBin
call CreateOutputFile
mov fileHandle,eax

mov ecx,MAX_PLAYERS
mov esi, OFFSET indexArray

WriteScoreToFile:
    push ecx
    movzx ebx, BYTE PTR [esi]      ; Get index from indexArray
    xor eax, eax                   ; Clear eax for multiplication
    mov edi, OFFSET playerArray    ; Base address of playerArray
    mov eax, TYPE PLAYER           ; Size of one PLAYER struct
    mul ebx                        ; Multiply index by size of PLAYER
    add edi, eax                   ; Address of playerArray[indexArray[i]]
    ; Write player score to file
    lea edx, (PLAYER PTR [edi]).PlyScore
    mov ecx,4
    mov eax, fileHandle
    call WriteToFile
    mov edx, OFFSET delim
    mov ecx, 1
    mov eax, fileHandle
    call WriteToFile
    pop ecx
    inc esi                        ; Move to next index in indexArray
    loop WriteScoreToFile

mov eax,fileHandle
call CloseFile

;Now write the levels to file
mov edx,offset lvlBin
call CreateOutputFile
mov fileHandle,eax

mov ecx,MAX_PLAYERS
mov esi, OFFSET indexArray

WriteLevelToFile:
    push ecx
    movzx ebx, BYTE PTR [esi]      ; Get index from indexArray
    xor eax, eax                   ; Clear eax for multiplication
    mov edi, OFFSET playerArray    ; Base address of playerArray
    mov eax, TYPE PLAYER           ; Size of one PLAYER struct
    mul ebx                        ; Multiply index by size of PLAYER
    add edi, eax                   ; Address of playerArray[indexArray[i]]
    ; Write player level to file
    lea edx, (PLAYER PTR [edi]).playerLevel
    mov ecx,1
    mov eax, fileHandle
    call WriteToFile
    mov edx, OFFSET delim
    mov ecx, 1
    mov eax, fileHandle
    call WriteToFile
    pop ecx
    inc esi                        ; Move to next index in indexArray
    loop WriteLevelToFile

mov eax,fileHandle
call CloseFile
jmp done
    
DelimiterError:
    ; Print error message and exit
    mWrite "The was an error with the delimitors ,Please Recheck the files !"
    jmp done

warning:
    mWrite "Something went wrong, please check the file.There cant be more than 10 players !"
    jmp done

done:
ret
calHighscores ENDP

;-----------------------------------------------------DRAW BOUNDRY--------------------------------------------------------;
DrawBoundry PROC
;upper boundry (50x for bricks and 2 for boundry)

    mov xCord,80
    mov yCord,0

	mGotoxy xCord,yCord								;start of console
	push eax								;save eax
	mov eax,white+(white shl 4)				;white on white
	call SetTextColor						;set text color
	mWriteSpace 52							;write 52 spaces

	;left boundry
	add yCord,1								;next line
	mGotoxy xCord,yCord						;next line
	push ecx 								;save ecx
	mov ecx,50
	leftBoundry:							;loop for left boundry
	mWriteSpace 1							;write 1 space
	add yCord,1								;next line
	mGotoxy xCord,yCord						;goto next line
	loop leftBoundry						;loop for left boundry

	;lower boundry							
	mGotoxy xCord,yCord						;next line
	mWriteSpace 52							;write 52 spaces

	;right boundry
	add xCord,51							;move to right boundry
	mGotoxy xCord,yCord						;goto right boundry
	xor ecx,ecx								;clear ecx
	mov ecx,51								;30 times
	rightBoundry:							;loop for right boundry
	mWriteSpace 1							;write 1 space
	sub yCord,1								;next line
	mGotoxy xCord,yCord						;goto next line
	loop rightBoundry						;loop for right boundry

	;Restore text color
	mov eax,white+(black shl 4)				;restore text color
	call SetTextColor						;set text color
	pop ecx									;restore ecx
	pop eax 								;restore eax
	ret
DrawBoundry ENDP
;-----------------------------------------------------END DRAW BOUNDRY-----------------------------------------------------;

;-----------------------------------------------------WRITE TITLE----------------------------------------------------------;

writeTitle PROC					
	push eax								;save eax
    
    DrawBox 25,8,35,13,white,lightGreen
	mov eax,lightRed+(white shl 4)			    ;set text color
	call SetTextColor
	mGotoxy 30,10							;goto x=30, y=10
	mWrite "Brick Breaker !"				;brick breaker	
	mGotoxy 30,12
	mWrite "John, Zoha, Urooj"
	mGotoxy 30,14
	mWrite "23k0069,i232555,23k0071"

	pop eax									;pop eax
	ret
writeTitle ENDP
;----------------------------------------------------- END WRITE TITLE-----------------------------------------------------;

;-----------------------------------------------------DRAW LVL 1-----------------------------------------------------------;
DrawLvl1 PROC USES eax ebx ecx edx esi edi ebp

	mov esi,offset startXCords				;mov startXCords to esi
	mov edi,offset startYCords				;mov startYCords to edi
	mov edx,offset brickActive				;mov brickStatus to edx
	mov ebp,offset brickColors1				;mov brickColors to ebp

	mov ecx,30								;30 bricks
	xor eax,eax								;clear eax
	xor ebx,ebx								;clear ebx

	DrawBricks:
	cmp ecx,0								;check if all bricks are drawn
	je done									;if all bricks are drawn

	mov al,[edx]							;check Status
	cmp al,1								;check if brick is visible
	jl skip 
	DrawBrick [ebp],[esi],[edi]					;draw brick
	skip:
	inc esi									;next x
	inc edi									;next y
	inc ebp									;next color
	inc edx									;next status
	dec ecx									;next brick
	jmp DrawBricks							;next brick

	done:
	ret
DrawLvl1 ENDP
;----------------------------------Draw level 2--------------------------------------------------------;
DrawLvl2 PROC USES eax ebx ecx edx esi edi ebp

	mov esi,offset startXCords				;mov startXCords to esi
	mov edi,offset startYCords				;mov startYCords to edi
	mov edx,offset brickActive2				;mov brickStatus to edx
	mov ebp,offset brickColorslvl1				;mov brickColors to ebp

	mov ecx,30								;30 bricks
	xor eax,eax								;clear eax
	xor ebx,ebx								;clear ebx

	DrawBricks:
	cmp ecx,0								;check if all bricks are drawn
	je done									;if all bricks are drawn

	mov al,[edx]							;check Status
	cmp al,1								;check if brick is visible
	jl skip 
	DrawBrick [ebp],[esi],[edi]					;draw brick
	skip:
	inc esi									;next x
	inc edi									;next y
	inc ebp									;next color
	inc edx									;next status
	dec ecx									;next brick
	jmp DrawBricks							;next brick

	done:
	ret
DrawLvl2 ENDP
;----------------------------------------------------Draw level 3--------------------------------------------;
DrawLvl3 PROC USES eax ebx ecx edx esi edi ebp

	mov esi,offset startXCords				;mov startXCords to esi
	mov edi,offset startYCords				;mov startYCords to edi
	mov edx,offset brickActive3				;mov brickStatus to edx
	mov ebp,offset brickColors3lvl1				;mov brickColors to ebp

	mov ecx,30								;30 bricks
	xor eax,eax								;clear eax
	xor ebx,ebx								;clear ebx

	DrawBricks:
	cmp ecx,0								;check if all bricks are drawn
	je done									;if all bricks are drawn

	mov al,[edx]							;check Status
	cmp al,1								;check if brick is visible
	jl skip 
	DrawBrick [ebp],[esi],[edi]					;draw brick
	skip:
	inc esi									;next x
	inc edi									;next y
	inc ebp									;next color
	inc edx									;next status
	dec ecx									;next brick
	jmp DrawBricks							;next brick

	done:
	ret
DrawLvl3 ENDP
;----------------------------------------------------- Print lives and score-----------------------------------------------------;
printScoreAndLives PROC

    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor

    mGotoxy 145,10                  ;players name
    mWrite"PLAYER :  "
    mWriteString pName

    mGotoxy 145,12                  ;Score
    mWrite "SCORE : "
    mov eax,playerScore
    call WriteDec
    mGotoxy 145,13                  
    mWrite "Timer : "
    mov eax,timer
    xor ecx,ecx
    xor edx,edx
    mov ecx,1000
    div ecx
    call WriteDec
    mGotoxy 145,15
    mWrite "Level : "
    movzx eax,level
    call WriteDec

    mov eax,white+(black shl 4)				;set text color
    call SetTextColor
ret
    
printScoreAndLives ENDP
endPage PROC

    call Clrscr
    DrawBox 52,10,100,30,white,yellow
    mov eax,lightRed+(white shl 4)				;set text color
    call SetTextColor

    mGotoxy 68,12
    mWriteString gmovr1
    mGotoxy 68,13
    mWriteString gmovr2
    mGotoxy 68,14
    mWriteString gmovr3
    mGotoxy 68,15
    mWriteString gmovr4
    mGotoxy 68,16
    mWriteString gmovr5

    mGotoxy 68,20
    mWrite "Player Name: "
    mWriteString pName
    mGotoxy 68,21
    mWrite "Score: "
    mov eax,playerScore
    call WriteDec
    mGotoxy 68,22
    mWrite "Level: "
    movzx eax,level
    call WriteDec

    mGotoxy 68,24
    mWrite "Press 'q' to go back to main menu"

    call calHighscores

    insLoop:
        call ReadChar             ; Read key input
        cmp al, 'q'              ; Check if the key is 'q' (go back to main menu)
        je skipperOption
       jmp insLoop

    skipperOption:
    mov eax,white+(black shl 4)				;set text color
    call SetTextColor
    call Clrscr
    call mainMenu

    ret
endPage ENDP
;-------------------------------------------------------END OF CODE-------------------------------------------------------;
END main
;----------------------------------------------------------END-----------------------------------------------------------;

