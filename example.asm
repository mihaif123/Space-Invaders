.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf :proc
extern time : proc
extern srand : proc
extern rand : proc 
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Space Invaders",0
area_width EQU 640
area_height EQU 480
area DD 0
aux dd 0
proiectil_x dd 0
proiectil_y dd 0
enemy_projectile_x dd 0
enemy_projectile_y dd 0
enemy_shoot_aux dd 0 
shoot_again dd 1
enemy_shoot_again dd 1 
x dd 290
y dd 410
image_height equ 20
image_width equ 20
ctr dd 0
ext_mat_x dd 110
ext_mat_y dd 110
enemy_shot dd 0
ship_shot dd 0
score dd 0
matrix_move_left dd 1
matrix_move_right dd 0
gameover dd 0
clr dd 0
format db "%d  ",0
aux_x dd 0
aux_y dd 0
mat_ctr dd 0
skip_timer dd 0
random_nr dd 0
enemy_shot_aux dd 0


arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include ship.inc
include extraterestru.inc 
include alien2.inc 
include alien3.inc
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ext_mat
ext_mat macro x1,y1,color
local mat1,mat2,ctr_Loop
	pusha
		push y1
		push x1
		mov ecx , 10
		mat1:
		make_alien3_macro area, x1,y1
		add x1 , 40
		dec ecx
		cmp ecx , 0
		jg mat1
		pop x1 
		add y1, 20
		
		mov ecx, 10
		push x1
		mat2:
		make_alien2_macro area, x1,y1
		add x1 , 40
		dec ecx
		cmp ecx , 0
		jg mat2
		pop x1 
		add y1 , 20
		
		
		
		mov ctr , 3
		mat33:
		mov ecx , 10
		push x1
		mat3:
		make_alien1_macro area, x1, y1
		add x1 , 40
		dec ecx
		cmp ecx, 0
		jg mat3
		pop x1
		add y1, 20
		dec ctr 
		cmp ctr , 0
		jg mat33
		
		
		pop y1
		
		
		
	popa


endm

linie_o macro x1,y1,len,color
local loop_linie
pusha
	mov eax , y1
	mov ebx , area_width
	mul ebx
	add eax , x1  ; eax = y* area_width + x 
	shl eax , 2
	add eax , area
	
	mov ecx, len
	
	loop_linie: 
	mov dword ptr [eax + 4* ecx],color

	loop loop_linie

popa
endm

linie_v macro x1,y1,len,color
local loop_linie
pusha
	mov aux , eax
	mov eax , y1
	mov ebx , area_width
	mul ebx
	mov edx , eax
	mov eax , aux
	add edx , x1
	shl edx , 2
	add edx, area
	
	mov ecx , len
	
	push ebx
	mov ebx , color
	loop_linie : 
		mov dword ptr [edx] , ebx 
		add edx , 4 * area_width
	loop loop_linie 
	pop ebx 

popa

endm

ship_shoot macro color
local proiectil 
	pusha
	mov ecx , 3
	push proiectil_x
	proiectil :
		linie_v proiectil_x,proiectil_y,20,color
		inc proiectil_x
	loop proiectil
		pop proiectil_x
	popa

endm

enemy_shoot macro color
	local projectile
	
	pusha
		mov ecx, 3
		push enemy_projectile_x
		projectile:
			linie_v enemy_projectile_x, enemy_projectile_y, 20 ,color
			inc enemy_projectile_x
		loop projectile
			pop enemy_projectile_x
	popa

endm 

get_right_color macro x1,y1

	pusha
	mov eax , y1
	mov ebx , area_width 
	mul ebx
	add eax , x1
	shl eax , 2
	add eax , area
	
	mov edx , dword ptr [eax + 4]
	mov clr , edx
	popa

endm


patrat macro x1,y1,color
local patrat_x
	pusha
		mov ecx , 20
		mov eax , x1
		mov ebx , y1
		patrat_x : 
			push ebx
			linie_v eax, ebx, 20 , color
			dec ecx
			inc eax 
			pop ebx 
		cmp ecx , 0
		jne patrat_x
	popa


endm

jmp jmp_proc

mov_ship_right macro

pusha
	cmp x , 530
		je end_proc1
	patrat x,y, 0000000h
	add x , 20
	mov eax, x
	mov ebx ,y
	make_ship_macro area,eax, ebx 
	
	end_proc1:
popa


endm
mov_ship_left macro
pusha

	cmp x , 50
		je end_proc2
	patrat x,y,0000000h
	sub x , 20
	mov eax ,x
	mov ebx ,y
	make_ship_macro area, eax, ebx 
	end_proc2:
popa

endm

get_color_above proc

	pusha
	mov eax , proiectil_y
	mov ebx , area_width 
	mul ebx
	add eax , proiectil_x
	shl eax , 2
	add eax , area
	
	mov edx , dword ptr [eax- 4*area_width]
	mov aux , edx
	popa
	mov eax , aux 
	ret

get_color_above endp 

get_below_color proc

	pusha
	mov eax , ext_mat_y
	mov ebx , area_width 
	mul ebx
	add eax , ext_mat_x
	shl eax , 2
	add eax , area
	
	mov edx , dword ptr [eax]
	mov clr , edx
	popa	
	ret

get_below_color endp 



get_left_color proc

	pusha
	mov eax , ext_mat_y
	mov ebx , area_width 
	mul ebx
	add eax , ext_mat_x
	shl eax , 2
	add eax , area
	
	mov edx , dword ptr [eax - 4]
	mov clr ,edx
	popa
	ret

get_left_color endp 


check_ext macro

	pusha
		push ext_mat_y
		push ext_mat_x
		mov ebx , proiectil_x
		mov ext_mat_x , ebx
		mov ebx, proiectil_y
		mov ext_mat_y, ebx
		sub ext_mat_x , 9
		call get_below_color
		pop ext_mat_x
		pop ext_mat_y
		
		cmp clr , 0000200h
		je destroy_ext_sideways
		
		cmp clr , 0121212h
		je change_to_brown_sideways
		
		cmp clr , 0181818h
		je change_to_blue_sideways
		
		push eax
		call get_color_above
		mov clr , eax
		pop eax
		cmp clr, 0000200h
		je destroy_ext_front
		
		cmp clr , 0121212h
		je change_to_brown_front
		
		cmp clr , 0181818h
		je change_to_blue_front
		
		
	jmp not_enemy
destroy_ext_sideways:
	cmp enemy_shot, 0
	je do_this1
	jmp not_enemy
do_this1:
	add score , 10
	ship_shoot 0000000h
	sub proiectil_x , 9
	patrat proiectil_x,proiectil_y,0000000h
	mov enemy_shot , 1
jmp not_enemy
destroy_ext_front:
	cmp enemy_shot , 0
		je do_this2
	jmp not_enemy
	do_this2:
	add score , 10
	ship_shoot 0000000h
	sub proiectil_x , 9
	sub proiectil_y , 20
	patrat proiectil_x,proiectil_y,0000000h
	mov enemy_shot , 1
jmp not_enemy

change_to_brown_front:
	cmp enemy_shot , 0
		je do_this3
	do_this3:
	jmp not_enemy
	ship_shoot 0000000h
	sub proiectil_x , 9
	sub proiectil_y , 20
	make_alien1_macro area, proiectil_x,proiectil_y
	mov enemy_shot ,1
jmp not_enemy

change_to_brown_sideways:
	cmp enemy_shot , 0
		je do_this5
	jmp not_enemy
	do_this5:
	ship_shoot 0000000h
	sub proiectil_x , 9
	make_alien1_macro area, proiectil_x,proiectil_y
	mov enemy_shot ,1
jmp not_enemy

change_to_blue_sideways:
	cmp enemy_shot , 0
		je do_this6
	jmp not_enemy
	do_this6:
	ship_shoot 0000000h
	sub proiectil_x , 9
	make_alien2_macro area, proiectil_x,proiectil_y
	mov enemy_shot , 1
jmp not_enemy

change_to_blue_front:
	cmp enemy_shot , 0
	je do_this4
	jmp not_enemy
	do_this4:
	ship_shoot 0000000h
	sub proiectil_x , 9
	sub proiectil_y , 20
	make_alien2_macro area, proiectil_x,proiectil_y
	mov enemy_shot , 1

	not_enemy:
	popa
endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MATRIX_MOVE
mov_matrix macro
	 
	cmp matrix_move_left , 1
		je left_cond
	jmp right_cond
	
	
	left_cond: 
		cmp ext_mat_x, 50
		je left_max
	
	
	mov mat_ctr , 20
	push ext_mat_x
	mat_mov_left:
		
	mov ctr , 5
	push ext_mat_y
	col_loop :
	call get_below_color
	
	cmp clr, 0000200h
	je mov_alien1
	
	cmp clr, 0121212h
	je mov_alien2
	
	cmp clr ,0181818h
	je mov_alien3
	
	jmp jmp_mov
mov_alien1:
	sub ext_mat_x, 20
	make_alien1_macro area ,ext_mat_x, ext_mat_y
	add ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
jmp jmp_mov	

mov_alien2:
	sub ext_mat_x, 20
	make_alien2_macro area ,ext_mat_x, ext_mat_y
	add ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h

jmp jmp_mov 
mov_alien3:
	sub ext_mat_x, 20
	make_alien3_macro area ,ext_mat_x, ext_mat_y
	add ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
	
	
jmp_mov:
	add ext_mat_y, 20
	dec ctr
	cmp ctr , 0
	jg col_loop
	pop ext_mat_y
	add ext_mat_x , 20
dec mat_ctr
cmp mat_ctr, 0
jg mat_mov_left
	pop ext_mat_x
	sub ext_mat_x, 20
	
jmp check_endgame


left_max: 
mov matrix_move_left , 0
mov matrix_move_right , 1
jmp down_cond


right_max:
mov matrix_move_left , 1
mov matrix_move_right , 0
jmp down_cond


right_cond :

mov mat_ctr , 20

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;mat_mov_right



cmp ext_mat_x , 170
jge right_max

push ext_mat_x
add ext_mat_x ,360
mov mat_ctr , 20
mat_mov_right:
push ext_mat_y
mov ctr , 5
col_loop2:

get_right_color ext_mat_x ,ext_mat_y

	cmp clr, 0000200h
	je mov_alien13
	
	cmp clr, 0121212h
	je mov_alien23
	
	cmp clr ,0181818h
	je mov_alien33
	
	jmp jmp_mov3
mov_alien13:
	add ext_mat_x, 20
	make_alien1_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
jmp jmp_mov3	

mov_alien23:
	add ext_mat_x, 20
	make_alien2_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h

jmp jmp_mov3 
mov_alien33:
	add ext_mat_x, 20
	make_alien3_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_x, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
jmp_mov3:
	add ext_mat_y , 20
	
	dec ctr
	cmp ctr, 0
	jg col_loop2
	pop ext_mat_y
	sub ext_mat_x , 20 
	dec mat_ctr
	cmp mat_ctr , 0
	jg mat_mov_right
	pop ext_mat_x
	add ext_mat_x , 20

jmp check_endgame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;down_cond
down_cond:

	push ext_mat_y 
	add ext_mat_y , 80
	
	cmp ext_mat_y , 430
	jge game_over_et_proc


	mov mat_ctr , 5
move_mat_down:
	mov ctr , 20
	push ext_mat_x
	row_loop:

	get_right_color ext_mat_x ,ext_mat_y 
	
	cmp clr, 0000200h
	je mov_alien12
	
	cmp clr, 0121212h
	je mov_alien22
	
	cmp clr ,0181818h
	je mov_alien32
	
	jmp jmp_mov2
mov_alien12:
	add ext_mat_y, 20
	make_alien1_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_y, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
jmp jmp_mov2	

mov_alien22:
	add ext_mat_y, 20
	make_alien2_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_y, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h

jmp jmp_mov2 
mov_alien32:
	add ext_mat_y, 20
	make_alien3_macro area ,ext_mat_x, ext_mat_y
	sub ext_mat_y, 20
	patrat ext_mat_x ,ext_mat_y, 0000000h
jmp_mov2:
	add ext_mat_x , 20
	
dec ctr
cmp ctr , 0
jg row_loop
	pop ext_mat_x
	sub ext_mat_y , 20 
	dec mat_ctr
	cmp mat_ctr , 0
	jg move_mat_down
	
	pop ext_mat_y
	add ext_mat_y, 20


check_endgame:

add x , 20
	get_right_color x , y
	cmp clr , 0000200h
	je game_over_et_proc
	
	cmp clr , 0121212h
	je game_over_et_proc
	
	cmp clr , 0181818h
	je game_over_et_proc
	
	sub x , 40
	get_right_color x , y
	cmp clr , 0000200h
	je game_over_et_proc
	
	cmp clr , 0121212h
	je game_over_et_proc
	
	cmp clr , 0181818h
	je game_over_et_proc
	
	add x,20 
	sub y,20 
	get_right_color x , y
	cmp clr , 0000200h
	je game_over_et_proc
	
	cmp clr , 0121212h
	je game_over_et_proc
	
	cmp clr , 0181818h
	je game_over_et_proc

	add y , 20
	jmp jmp_macro

game_over_et_proc:
add y, 20
mov gameover , 1

jmp_macro:

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAKE_SHIP
make_ship proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var1_0
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_ship endp

; simple macro to call the procedure easier
make_ship_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_ship
	add esp, 12
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END_MAKE_SHIP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAKE_ALIEN1
make_alien1 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_0
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_alien1 endp

; simple macro to call the procedure easier
make_alien1_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_alien1
	add esp, 12
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END_MAKE_ALIEN1


make_alien2 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_1
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_alien2 endp

; simple macro to call the procedure easier
make_alien2_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_alien2
	add esp, 12
endm


make_alien3 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_2
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_alien3 endp

; simple macro to call the procedure easier
make_alien3_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_alien3
	add esp, 12
endm


get_random_nr macro
	
	pusha
	
		call rand
		mov edx, 0
		mov ebx , 10
		div ebx
		mov random_nr , edx
	popa

endm

check_ship macro
	
	add enemy_projectile_y , 20
	sub enemy_projectile_x , 9
	
	get_right_color enemy_projectile_x, enemy_projectile_y
	
	cmp clr , 0000100h
	je game_over_et_macro
	
	push ext_mat_y
	push ext_mat_x
	push ebx
		mov ebx , enemy_projectile_y
		mov ext_mat_y , ebx
		
		mov ebx , enemy_projectile_x
		mov ext_mat_x , ebx
	pop ebx
	
	call get_below_color 
	pop ext_mat_x
	pop ext_mat_y
	cmp clr , 0000100h
	je game_over_et_macro
	
	
	push ext_mat_x
	push ext_mat_y 
	push ebx
		mov ebx , enemy_projectile_y
		mov ext_mat_y , ebx
		
		mov ebx , enemy_projectile_x
		mov ext_mat_x , ebx
	pop ebx
	add ext_mat_x, 10
	
	call get_below_color
	pop ext_mat_y
	pop ext_mat_x
	cmp clr, 0000100h
	je game_over_et_macro
	

	
	jmp skip_macro
	
	game_over_et_macro:
		mov ship_shot , 1
		mov gameover ,1 
	skip_macro:
	sub enemy_projectile_y , 20
	add enemy_projectile_x , 9
endm 


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	cmp gameover , 1
		je game_over_et
	
	jmp not_game_over
	game_over_et:
		make_text_macro 'G', area, 255, 30
		make_text_macro 'A', area, 265, 30
		make_text_macro 'M', area, 275, 30
		make_text_macro 'E', area, 285, 30
		make_text_macro ' ', area, 295, 30
		make_text_macro 'O', area, 305, 30
		make_text_macro 'V', area, 315, 30
		make_text_macro 'E', area, 325, 30
		make_text_macro 'R', area, 335, 30
	jmp final_draw
	
	not_game_over:
	mov eax, [ebp+arg1]
	cmp eax, 2
	jz evt_timer 
	
	cmp eax , 3
	jz evt_keyboard
	
	cmp eax , 1
	je evt_click
	
	
	
	;nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0000000h
	push area
	call memset
	add esp, 12
	make_ship_macro area, x, y 
	ext_mat ext_mat_x, ext_mat_y , 0A52A2Ah
	

	call time
	add esp , 4
	push eax
	call srand
	add esp , 4
	jmp evt_timer 
evt_click:

evt_timer:
	linie_o 50,50,500,000FF00h
	linie_v 50,50,400,000FF00h
	linie_o 50,450,500,000FF00h
	linie_v 550,50,400,000FF00h
	

	
	
	
	cmp skip_timer , 5
	je mov_mat_et
	jmp not_mov_mat_et
mov_mat_et:
	mov_matrix
	mov skip_timer , 0
	
	jmp mat_moved

not_mov_mat_et:
	inc skip_timer
mat_moved:

cmp enemy_shoot_again, 0
je enemy_doesnt_shoot
	get_random_nr
	

	
	push ebx
		mov ebx , ext_mat_y 
		mov enemy_projectile_y , ebx
		mov ebx , ext_mat_x
		mov enemy_projectile_x , ebx
	pop ebx
	
	add enemy_projectile_y , 80
	push eax
		mov eax , 40
		mul random_nr
		add enemy_projectile_x, eax
	pop eax
	
	get_right_color enemy_projectile_x , enemy_projectile_y
	cmp clr , 0000200h
	je enemy_shoots
	jmp enemy_doesnt_shoot
	
	enemy_shoots:
		mov enemy_shoot_again , 0 
		add enemy_projectile_y , 20
		add enemy_projectile_x , 9
		enemy_shoot 0FF0000h
	enemy_doesnt_shoot:
	cmp enemy_projectile_y , 430
	jl enemy_projectile_mm
	je enemy_shoot_again_et
	
	shoot_conds:
	cmp proiectil_y , 50
	jg proiectil_mm
	je shoot_again_et

jmp afisare_litere


enemy_projectile_mm:

	check_ship
	
	cmp ship_shot , 1
	je game_over_et

	mov enemy_shoot_again , 0
	enemy_shoot 0000000h
	add enemy_projectile_y , 20 
	enemy_shoot 0FF0000h

jmp shoot_conds
proiectil_mm:

	check_ext

	cmp enemy_shot , 1
		jne enemy_not_shot
	mov shoot_again , 1
	jmp afisare_litere
	 
enemy_not_shot:
	mov shoot_again , 0
	ship_shoot 0000000h
	sub proiectil_y ,20
	ship_shoot 0FFFFFEh

	
	
jmp afisare_litere 

enemy_shoot_again_et:
	enemy_shoot 0000000h
	mov enemy_shoot_again , 1
jmp shoot_conds

shoot_again_et:
	ship_shoot 0000000h
	mov shoot_again , 1


evt_keyboard :
	mov eax , [ebp + arg2]
	cmp eax , 39
	je mov_ship_right_et
	cmp eax , 37
	je mov_ship_left_et
	cmp eax , 32
	je ship_shoot_et
	
jmp afisare_litere

mov_ship_right_et:
mov_ship_right


jmp afisare_litere

mov_ship_left_et:
mov_ship_left


jmp afisare_litere

ship_shoot_et:

cmp shoot_again , 0
	je afisare_litere
mov enemy_shot , 0
mov eax , x
mov proiectil_x , eax
add proiectil_x , 9

mov eax , y
mov proiectil_y , eax
sub proiectil_y , 20

ship_shoot 0FFFFFEh

	
afisare_litere:

	make_text_macro 'S', area, 10, 10
	make_text_macro 'C', area, 20, 10
	make_text_macro 'O', area, 30, 10
	make_text_macro 'R', area, 40, 10
	make_text_macro 'E', area, 50, 10
	make_text_macro ' ', area, 60, 10
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 90, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 80, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 10
	
	;scriem un mesaj
	make_text_macro 'F', area, 460, 460
	make_text_macro 'E', area, 470, 460
	make_text_macro 'L', area, 480, 460
	make_text_macro 'D', area, 490, 460
	make_text_macro 'I', area, 500, 460
	make_text_macro 'O', area, 510, 460
	make_text_macro 'R', area, 520, 460
	make_text_macro 'E', area, 530, 460
	make_text_macro 'A', area, 540, 460
	make_text_macro 'N', area, 550, 460
	
	make_text_macro 'M', area, 570, 460
	make_text_macro 'I', area, 580, 460
	make_text_macro 'H', area, 590, 460
	make_text_macro 'A', area, 600, 460
	make_text_macro 'I', area, 610, 460

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp



jmp_proc:

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start


