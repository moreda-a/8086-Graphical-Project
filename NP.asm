;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; aTank
;            a Tank game written in x86 assembly language(16 bit)
;
;            by Mohammadreza Daneshvaramoli, 2016
;            computer structure and language 40126
;            Dr.Amir Hossein Jahangir
;            Department of computer engineering
;            Student number 93111139
;
;            Assemble using emu8086
;
;
;
; I tried to keep the code well - documented(hence the large size of this file)
; and I make no claims as to the ultimate efficiency of the algorithms!:)
;
; In terms of program organization, it is split into these main chunks :
;    1. Macros - for coding simple and define something.
;    2. the constants / variables area - basically a "data" area
;    3. main program - call all of procedures that need to run in game
;    4. initialization procedures - executed once per program run, sets up
;                  -screen, etc.
;    5. in game procedures - executed in a loop until program exit
;                  -handles pieces falling, piece generation, scoring, etc.
;    6. other procedures - subroutines invoked via call statements
;                  -see procedures heading below for more information.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; ;
; Macros;
;        powerful tools to design some basic functions.;
; ;
; ;
; ;
; Notes:;
;        -procedures are labels which are reached via copying statements.;
;        -some macros preserve registers, as indicated in the comments;
;        -some macros expect input in registers, as per their comments;
;        -some macros output values in registers, as per their comments;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
;
; move anything to anything
;
; Input:
;     destination as register or memory
;     source as register or memory or immediate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move macro destination, source
push source
pop destination
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; set pixel color
;
;
;INT 10h / AH = 0Ch - change color for a single pixel.
;
; input:
;	AL = pixel color
;	CX = column.
;	DX = row.
;
; Input:
;         col as register / memory
;         row as register / memory
;         (as Byte)color as register / memory / immediate
;
;
;   last code :
;	    mov ax, color
;   	mov cx, col
;   	mov dx, row
;   	mov ah, 0ch
;   	int 10h
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_pixel macro col, row, color
push ax
push cx
push dx

push row
push col
push color
pop ax; mov ax, color
pop cx; mov cx, col
pop dx; mov dx, row

mov ah, 0ch
int 10h

pop dx
pop cx
pop ax
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; set pixel color
;
;
;INT 10h / AH = 0Dh - get color of a single pixel.
;
; input:
;	AL = pixel color
;	CX = column.
; output:
;   AL = pixel color
;
; Input:
;         col as register / memory
;         row as register / memory
; Output:
;         (as Byte)color as register / memory
;
;          use temp in memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_pixel macro col, row, color
push ax
push cx
push dx

push row
push col
pop cx; mov cx, col
pop dx; mov dx, row
mov ah, 0dh
int 10h
mov ah, 0
mov temp, ax

pop dx
pop cx
pop ax
move color, temp

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; swap to values.
; push(arg1, arg2)
; pop(arg2, arg1)
;
;
; Input:
;         arg1 as register / memory
;         arg2 as register / memory
; Output:
;         arg1 and arg2 are output.
; Auxiliary:
;         using stack for swap values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
swap macro arg1, arg2
push arg1
push arg2
pop arg1
pop arg2
endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; assign in some language do something like this
; answer = term ? accept : reject
;
; Input:
;         term as register / memory
;         accept as register / memory / immediate
;         reject as register / memory / immediate
; Output:
;         in register / memory in answer
; Auxiliary:
;         using stack to transfer answer
;         and temp1, and temp2 for avoid bit - extend
; Notes:
;        -may change Flag Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_if_else macro answer, term, accept, reject
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; To use local labels use this line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOCAL else_label, end_label
move temp1, accept
move temp2, reject
cmp term, 0
jz else_label
push temp1
jmp end_label
else_label :
push temp2
end_label :
pop answer
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; assign in some language do something like this
; answer = ex1 == ex2 ? accept : reject
;
; Input:
;         ex1 as register / memory / immediate
;         ex2 as register / memory / immediate
;         accept as register / memory / immediate
;         reject as register / memory / immediate
; Output:
;         in register / memory in answer
; Auxiliary:
;         using stack to transfer answer
;         using temp in memory for
; Notes:
;        -may change Flag Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_if_equal macro answer, ex1, ex2, accept, reject
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; To use local labels use this line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOCAL else_label, end_label
push ax
move temp1, accept
move temp2, reject
move temp, ex2
mov ax, ex1
cmp ax, temp
jnz else_label
pop ax
push temp1
jmp end_label
else_label :
pop ax
push temp2
end_label :
pop answer
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; set random number between from and to
; answer = (random() % (to - from)) + from
;
; Input:
;         from as register / memory / immediate
;         to as register / memory / immediate
; Output:
;         in register / memory in answer
; Auxiliary:
;         using stack to transfer answer
;         and using temp in memory
; Notes:
;        -may change Flag Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
random macro answer, from, to
push dx
push bx
push ax
move temp, from
mov bx, to
sub bx, temp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; call generate_random_number_procedure that have bx as input and ax as
; output. and set random value between 0 and N - 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call generate_random_number_procedure
add ax, temp
mov temp, ax
pop ax
pop bx
pop dx
move answer, temp
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;M;;
; set square root of number in answer
; answer = sqrt(number)
;
; Input:
;         answer as register / memory
;         number as register / memory / immediate
; Output:
;         in register / memory in answer
; Auxiliary:
;         using stack to transfer answer
;         and using temp in memory
; Notes:
;        -may change Flag Register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sqrt macro answer, number
push dx
push cx
push bx
push ax
push di

mov di, number
mov ax, 255
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; call isqrt that have di and ax as input and ax as
; output. and set ax the result of sqrt(number)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call isqrt_procedure

mov temp, ax
pop di
pop ax
pop bx
pop cx
pop dx
move answer, temp
endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; ;
; Includes;
; ;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; For using some library and functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
include emu8086.inc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COM programs are required to have their origin at CS : 0100h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
org 100h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; jump over data section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
jmp main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
; DATA
;
; Notes:
;       there are three types of data
;		1 - Constants: some string value that show in start and end of games.
;		2 - Structures: combine type of data that make blocks of data.
;		3 - variables: data that use in program and change they are global
;			variable and use in all part of codes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; ;
; Constants;
; ;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nothing1 dw 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strings that will be displayed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
msg_score db " your score is $"
msg_congrats db " CONGRATULATIONS! $"; congratulations!
msg_scoreHelp db " it's not good try it again $"
msg_entername db "Enter your name: $"; what is your name ? : )
msg_enter_mode db "Enter type of game (0/1/2) $"
msg_enter_vga db "Enter quality of game(0{low}, 1{high}) $"

delay_centiseconds db 20; delay between frames in hundredths of a second
nothing2 dw 0

no_delay dw 0

nameLength equ 15

BLUE equ 1
RED equ 40
YELLOW equ 14
GREEN equ 2
BLACK equ 0

precision dw 100; precision for make fix size float
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; ;
; Structures;
; ;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
max_number_of_points equ 750 + 10
point_struct_length equ 18;(on BYTE x2 not in WORD because memory is BYTE addressable)

point dw max_number_of_points*point_struct_length dup(0)
p_x equ 0
p_y equ 2
p_v equ 4
p_vx equ 6
p_vy equ 8
p_color equ 10
p_col equ 12
p_row equ 14
p_move equ 16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; ;
; Variables;
; ;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; temporary word on memory to save something in some time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
temp dw 0; hold temporary data
temp1 dw 0
temp2 dw 0

address_point dw 0; hold temporary address

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
video_type db 0; 0 for low quality, 1 for high quality

screen_hight dw 0
screen_width dw 0

mname db nameLength, ? , nameLength dup(' ')
; array to store player name(only 15 characters)

global_velocity dw 0

points_number dw 100

random_mode dw 0


end_game dw 0
win_score dw 0

mouse_x dw 160
mouse_y dw 100

middle_x dw 160
middle_y dw 100

ddx dw 0
ddy dw 0
ddx2 dw 0
ddy2 dw 0
dis dw 0
dis2 dw 0

no_move_point dw 0

mousei dw 0

reserve_color dw 0;

lx dw 0
ly dw 0
ux dw 0
uy dw 0


min_renge dw 3; border distance of map

random_place dw 0; incremented by various events
; such as input, clock polling, etc.
nothing3 dw 0
delay_stopping_point_centiseconds db 0; convenience variable used by the
; delay subroutine
nothing4 dw 0
delay_initial db 0; another convenience variable used by the
; delay subroutine
nothing5 dw 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; Main Program;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; getting the info for set in game
; in fact, this is menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call init_info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialize data by info for example point locations
; and setting random numbers and ...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call init_data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start to showing on graphic mode
; has video_type as type of video mode(Boolean type)
; prepare the screen to start game
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call init_window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; loop of move to reach goals
; call redraw for all points in all cycle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call game_doing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; show congratulations message if the player win
; and end of the codes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call game_finish
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
; Procedures
;
; Notes:
;        -procedures are labels which are reached via call statements, and
;          it is expected that they return properly
;        -some procedures preserve registers, as indicated in the comments
;        -some procedures expect input in registers, as per their comments
;        -some procedures output values in registers, as per their comments
;        -procedure naming convention is as follows :
;            1. their names are in the main program and they do initialization
;               are named "init_xx_yy_zz"
;            2. their names are in the main program and they do in loop of
;               of game, are named "game_xx_yy_zz"
;            3. some of regular procedure that that call indirect are named
;               "xx_yy_zz_procedure", like random and etc.
;            4. their sub - labels(between which jumps occur while inside the
	;               procedure) are named "xx_yy_zz_purpose", etc.
	;          (I chose this naming convention in order to easily jump between
		;          procedure definition and invocations via simple text search, as well
		;          as between sub - labels within a procedure)
	;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; Initialization;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Getting info
;
; getting information of player and set state of playing and type of games
; and send some message in non - graphical mode
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_info proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load offset of enter name message
; and write it on screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call CLEAR_SCREEN
mov dx, offset msg_entername; load offset of enter name message into dx
mov ah, 9; prepare appropriate interrupt
int 21h; output enter name message on screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; store the input in name array
; and get input name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov dx, offset mname
mov ah, 0ah
int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load offset of enter_vga message
; and write it on screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call CLEAR_SCREEN
mov dx, offset msg_enter_vga; load offset of enter name message into dx
mov ah, 9; prepare appropriate interrupt
int 21h; output enter name message on screen

call scan_num
mov video_type, cl
call CLEAR_SCREEN

mov dx, offset msg_enter_mode; load offset of enter name message into dx
mov ah, 9; prepare appropriate interrupt
int 21h; output enter name message on screen

call scan_num
mov random_mode, cx



ret
init_info endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DATA initialization
;
; set number of some global values
; set some random values
; initialize data for start game
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_data proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set screen resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_if_else screen_width, video_type, 640, 320
set_if_else screen_hight, video_type, 480, 200
cmp random_mode, 2
je frak

call srand_procedure
random global_velocity, 100, 255
lea di, point
mov cx, points_number

cmp random_mode, 1
je randomm
while:
call srand_procedure

random[di + p_col], 10, 310; screen_width - 0ah
mov ax, [di + p_col]
mul precision
mov[di + p_x], ax

call srand_procedure
random[di + p_row], 10, 190; screen_hight - 0ah
mov ax, [di + p_row]
mul precision
mov[di + p_y], ax

mov bx, YELLOW
mov[di + p_color], bx
mov bx, global_velocity
mov[di + p_v], bx
mov[di + p_move], 1

call game_recall

add di, point_struct_length
loop while
mov reserve_color, GREEN

jmp enddata :
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; random V random Vx random Vy and random locations for all points
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
randomm:
call srand_procedure

random[di + p_col], 10, 310; screen_width - 0ah
mov ax, [di + p_col]
mul precision
mov[di + p_x], ax

call srand_procedure
random[di + p_row], 10, 190; screen_hight - 0ah
mov ax, [di + p_row]
mul precision
mov[di + p_y], ax

mov bx, YELLOW
mov[di + p_color], bx
mov bx, global_velocity
mov[di + p_v], bx
mov[di + p_move], 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; as sin ^ 2 + cos ^ 2 = 1
; we know that vx ^ 2 + vy ^ 2 = v ^ 2
; so we calculate vy from v and vx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call srand_procedure
random[di + p_vx], 0, global_velocity

mov ax, [di + p_vx]
mul ax
mov bx, ax

mov ax, global_velocity
mul ax

sub ax, bx

sqrt[di + p_vy], ax


random ax, 0, 2
add ax, ax
sub ax, 1
imul[di + p_vx]
mov[di + p_vx], ax

random ax, 0, 2
add ax, ax
sub ax, 1
imul[di + p_vy]
mov[di + p_vy], ax

add di, point_struct_length
loop randomm
mov reserve_color, GREEN
jmp enddata

frak :
mov reserve_color, BLUE
enddata :
ret
init_data endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Enter graphics mode and make screen
;
; Input(hide) :
	;         video_type(al) as type of screen
	;
; al == 0: set 13h, 320x200 pixels 8bit color(16:10)
; al == 1: set 2eh, 640x480 pixels 8bit color(4:3)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_window proc
push ax
mov al, video_type
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; setting resolution for various type lower resolution(320x200) on emu
; and high resolution(640x480) on.exe or .com files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_if_else ax, al, 002eh, 0013h
int 10h

cmp random_mode, 2
je eeend
mov ax, 0
int 33h

mov ax, 1
int 33h

eeend :
pop ax
ret
init_window endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; INGAME Procedures;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GAME DOING
;
; super Function of game_drawing that plan time of game drawing
; and plan changing goal and mouse listener
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_doing proc
cmp random_mode, 2
je frak1
mov cx, 0100h
call game_drawing
mov delay_centiseconds, 200
call delay_procedure
call delay_procedure
call delay_procedure
mov delay_centiseconds, 5
while1:
push cx
call game_drawing
call delay_procedure
call game_mouseListener
push ax
mov ax, mousei
mov mousei, 0
sub win_score, ax
pop ax
pop cx
cmp end_game, 1
je pendi
loop while1
jmp pendi
frak1 :
mov cx, 0ffffh
push ax
push bx
mov ax, middle_x
mov bx, middle_y

sub ax, 2
mov lx, ax
add ax, 5
mov ux, ax
sub bx, 2
mov ly, bx
add bx, 5
mov uy, bx


mov ax, middle_x
mov bx, middle_y

dec ax
dec bx

set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE

dec bx
dec bx
inc ax
set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE

dec bx
dec bx
inc ax
set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE
inc bx
set_pixel ax, bx, BLUE

pop bx
pop ax
mov delay_centiseconds, 1
whilee:
push cx
cmp no_delay, 0
jz goi
call delay_procedure
goi :
call game_frak
cmp end_game, 1
je pendi
pop cx
inc cx
loop whilee
pendi :
ret
game_doing endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; loop of game main procedure in the code!!!!!
; this procedure calls in each cycle of game for all of point and change goal
; and check if they are near each other
;
; Notes:
;       this procedure may change CX so save it before calling the procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_frak proc
lea di, point
mov no_move_point, 0
mov[di + p_move], 1
call srand_procedure
random[di + p_col], lx, ux
call srand_procedure
random[di + p_row], ly, uy
mov[di + p_color], BLUE
get_pixel[di + p_col], [di + p_row], [di + p_color]
cmp[di + p_color], BLUE
je pend3

mov[di + p_color], BLUE

call game_check_near
cmp[di + p_move], 1
je pend3
call game_in_bound
push ax
push bx
mov ax, lx
sub ax, 1
set_if_equal lx, lx, [di + p_col], ax, lx
mov ax, ly
sub ax, 1
set_if_equal ly, ly, [di + p_row], ax, ly
mov ax, ux
sub ax, 1
mov bx, ux
add bx, 1
set_if_equal ux, ax, [di + p_col], bx, ux
mov ax, uy
sub ax, 1
mov bx, uy
add bx, 1
set_if_equal uy, ax, [di + p_row], bx, uy
pop bx
pop ax
pend3 :
ret
game_frak endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; loop of game main procedure in the code!!!!!
; this procedure calls in each cycle of game for all of point and change goal
; and check if they are near each other
;
; Notes:
;       this procedure may change CX so save it before calling the procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_drawing proc
lea di, point
mov cx, points_number
while2 :
push cx
call game_in_bound
cmp[di + p_move], 0
jz p2
call game_check_near
cmp[di + p_move], 0
jz p2
call game_redraw_point
jmp ep2
p2 :
set_pixel[di + p_col], [di + p_row], [di + p_color]
ep2 :
	add di, point_struct_length
	pop cx
	cmp end_game, 1

	mov ax, [di + p_col]
	call print_num

	mov ax, -1
	call print_num

	mov ax, [di + p_row]
	call print_num
	je pend
	loop while2
	pend :
ret
game_drawing endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   check if point are fixed with other point
;
; Input:
;        di as address of point that we want redraw that.
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_in_bound proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check if near cell was colored then make cell green and stop it
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push ax
mov ax, min_renge
cmp[di + p_col], ax
jb stopi

cmp[di + p_row], ax
jb stopi

mov ax, screen_width
sub ax, min_renge
cmp[di + p_col], ax
ja stopi

cmp[di + p_row], 197
ja stopi

mov ax, no_move_point
cmp ax, points_number
je stopi


jmp eendi

stopi :
mov end_game, 1

eendi :
	pop ax
	ret
	game_in_bound endp

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   check if point are fixed with other point
;
; Input:
;        di as address of point that we want redraw that.
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_check_near proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check if near cell was colored then make cell green and stop it
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push si
push bx
mov si, [di + p_row]
mov bx, [di + p_col]

inc bx
get_pixel bx, si, ax
cmp ax, BLACK
jne estop

dec bx
inc si
get_pixel bx, si, ax
cmp ax, BLACK
jne estop

dec si
dec bx
get_pixel bx, si, ax
cmp ax, BLACK
jne estop

dec si
inc bx
get_pixel bx, si, ax
cmp ax, BLACK
jne estop

jmp aeend
estop :
move[di + p_color], reserve_color
mov[di + p_move], 0
set_pixel[di + p_col], [di + p_row], [di + p_color]
inc win_score
inc no_move_point
aeend :
pop bx
pop si
ret
game_check_near endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; clear last point and draw new point
; this procedure calls in each cycle of game for all of points
;
; Input:
;        di as address of point that we want redraw that.
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_redraw_point proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check if color was red set it yellow or if it wasnot red set it black
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_pixel[di + p_col], [di + p_row], [di + p_color]
set_if_equal[di + p_color], [di + p_color], RED, YELLOW, BLACK
set_pixel[di + p_col], [di + p_row], [di + p_color]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; change to new coordinate for point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call new_coor_procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check if color was black set it yellow or if it wasnot black set it red
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_pixel[di + p_col], [di + p_row], [di + p_color]
set_if_equal[di + p_color], [di + p_color], BLACK, YELLOW, RED
set_pixel[di + p_col], [di + p_row], [di + p_color]
ret
game_redraw_point endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; finish game message
;
; show some message and show you're score on screen
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_finish proc; show the congratulations message
mov ch, 6; set the mode of screen first
mov cl, 7; set the mode of screen first
mov ah, 1; set the mode of screen first
int 10h

mov dx, offset msg_congrats; load the offset of message in dx register
mov ah, 9; set the appropriate interrupt
int 21h; show the message

xor bx, bx; prepare to add $ at the end of player name
mov bl, mname[1]; prepare to add $ at the end of player name
mov mname[bx + 2], '$'
mov dx, offset mname + 2; load the $ terminated player name in dx register to display it
int 21h; show the player name

mov dx, offset msg_score
mov ah, 9
int 21h

mov ax, win_score
call print_num


mov dx, offset msg_scoreHelp
mov ah, 9
int 21h

ret
game_finish endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; check if mouse click
;
; change all speeds if clicked
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_mouseListener proc; listen to mouse events

push ax
push bx
push cx
push dx
push di
mov ax, 3; set the appropriate interrupt
int 33h; get the mouse event
cmp bx, 1; if the left button is pressed
jnz endmouse; if not the listen until the left button is pressed

mov mousei, 1
shr cx, 1
mov mouse_x, cx
mov mouse_y, dx
lea di, point
mov cx, points_number
while3 :
push cx
cmp[di + p_move], 0
jz p3
call game_recall
p3 :
add di, point_struct_length
pop cx
loop while3

endmouse :
pop di
pop dx
pop cx
pop bx
pop ax
ret
game_mouseListener endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; re call V_x and V_y of a point
; calculate v_x, v_y
;
; Input:
;      di as a point
;      mouse_x, mouse_y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
game_recall proc

push ax
push bx
push cx
push dx
push di
mov dx, 0
mov ax, mouse_x
sub ax, [di + p_col]
mov ddx, ax
imul ax
mov ddx2, ax

mov dx, 0
mov ax, mouse_y
sub ax, [di + p_row]
mov ddy, ax
imul ax
mov ddy2, ax

add ax, ddx2
mov dis2, ax

sqrt dis, dis2

mov dx, 0
mov ax, ddx
cmp ax, 7fffh
ja ppx
mul[di + p_v]
div dis
mov[di + p_vx], ax
jmp nnx
ppx :
neg ax
mul[di + p_v]
div dis
neg ax
mov[di + p_vx], ax

nnx :
mov dx, 0
mov ax, ddy
cmp ax, 7fffh
ja ppy
mul[di + p_v]
div dis
mov[di + p_vy], ax
jmp nny
ppy :
neg ax
mul[di + p_v]
div dis
neg ax
mov[di + p_vy], ax


nny :
pop di
pop dx
pop cx
pop bx
pop ax
ret
game_recall endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;
; ;
; Auxiliary Procedures;
; ;
; ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; this procedure uses to debug and don't make any thing
;
; Input:
;       save all register then check anything
;
;   see output by int21 or see in debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test_procedure proc
push ax
push bx
push cx
push dx
push si
mov ax, [di + p_col]
mov bx, [di + p_row]
mov cx, [di + p_vx]
mov dx, [di + p_vy]
mov si, [di + p_color]
pop si
pop dx
pop cx
pop bx
pop ax
ret
test_procedure endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; move one cycle on the game and calculate new x, y for point
;
; Input:
;        di as address of point that we want redraw that.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_coor_procedure proc
push ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; calculate p_x and p_col for point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, [di + p_x]
add ax, [di + p_vx]
mov[di + p_x], ax
mov dx, 0
div precision
mov[di + p_col], ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; calculate p_y and p_row for point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, [di + p_y]
add ax, [di + p_vy]
mov[di + p_y], ax
mov dx, 0
div precision
mov[di + p_row], ax
pop ax
ret
new_coor_procedure endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;P;;
;
; Generate a random number between 0 and N - 1 inclusive
;
; Input:
;        bx - N
; Output:
;        ax - random number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
generate_random_number_procedure proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; advance random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, [random_place]
add ax, 31
mov[random_place], ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; divide by N and return remainder
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov dx, 0
div bx; divide by N
mov ax, dx; save remainder in ax
;xor ah, ah
ret
generate_random_number_procedure endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;P;;
;
; calculate Square Root of number in word by Newton - Raphson / Leibniz iteration
; algorithm in o(logn)
;
; Input:
;         di as value for calculate square root
; Output:
;         ax as Square root Integer
;
; Notes:
;         This Binary Algorithm returns no precision.In order to return
;         an answer with precision you should pass the number with twice
;         the expected precision of the result..
;      (i.e.)
;      24 returns 4
;      2400         49
;      240000      489
;
; Max:   Dword max parameter(4, 294, 967, 295) yields word max of 65535.
; in other words, if ax == 255 number can be 65535
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isqrt_procedure proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; loop on each 2 ^ i value that greater or lesser than result
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start_loop:
mov bx, ax
xor dx, dx
mov ax, di
div bx
add ax, bx
shr ax, 1
mov cx, ax
sub cx, bx
cmp cx, 2
ja start_loop
ret
isqrt_procedure endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;P;;
;
; Generate a random number(load from mili seconds in time)
; SLOW!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
srand_procedure proc
push bx
push dx
push cx
push ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read current system time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xor bl, bl
mov ah, 2Ch
int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; advance random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, [random_place]
add ax, dx
mov[random_place], ax

pop ax
pop cx
pop dx
pop bx

ret
srand_procedure endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;P;;
;
; making a delay
; and
; Generate a random number(load from milliseconds in time)
; use for showing frame by frame
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay_procedure proc
push bx
push cx
push dx
push ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read current system time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xor bl, bl
mov ah, 2Ch
int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; advance random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, [random_place]
add ax, dx
mov[random_place], ax

mov ah, 2Ch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; store second
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov[delay_initial], dh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; calculate stopping point, and do not adjust if the stopping point is in
; the next second
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
add dl, [delay_centiseconds]
cmp dl, 100
jb delay_second_adjustment_done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stopping point will cross into next second, so adjust
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub dl, 100
mov bl, 1

delay_second_adjustment_done:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; save stopping point in centiseconds
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov[delay_stopping_point_centiseconds], dl

read_time_again :
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; call if mouse activate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; call game_mouseListener
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read system time again
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if we have to stop within the same second, ensure we're still within the
; same second
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
test bl, bl; will we stop within the same second ?
je must_be_within_same_second

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; second will change, so we keep polling if we're still within
; the same second as when we started
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cmp dh, [delay_initial]
je read_time_again

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if we're more than one second later than the second read when we entered
; the delay procedure, we have to stop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push dx
sub dh, [delay_initial]
cmp dh, 2
pop dx
jae done_delay

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; we're exactly one second after the initial second (when we entered the 
; delay procedure, which is where we expect the stopping point; therefore,
; we need to check if we've reached the stopping point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
jmp check_stopping_point_reached

must_be_within_same_second :
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; since we expect to stop within the same second, if current second is not
; what we already saved in delay_initial, then we're done
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cmp dh, [delay_initial]
jne done_delay

check_stopping_point_reached :
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; keep reading system time if the current centisecond is below our stopping
; point in centiseconds
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cmp dl, [delay_stopping_point_centiseconds]
jb read_time_again

done_delay :
pop ax
pop dx
pop cx
pop bx

ret
delay_procedure endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEFINE_SCAN_NUM
DEFINE_PRINT_STRING
DEFINE_PRINT_NUM
DEFINE_PRINT_NUM_UNS; required for print_num.
DEFINE_PTHIS
DEFINE_CLEAR_SCREEN

end
