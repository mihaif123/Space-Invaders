.386

.model flat,stdcall

includelib msvcrt.lib
extern exit: proc
extern time : proc
extern srand : proc
extern rand : proc
extern printf : proc
public start

.data

format db "%d " , 0
a dd 0 
.code

start:

push 0
call time
add esp ,4
mov a , eax


push a
call srand
add esp , 4


mov ecx , 5
loop_5nr:
pusha
call rand
mov edx , 0
mov ebx , 50
div ebx 
push edx
push offset format
call printf
add esp , 8
popa
loop loop_5nr

	push 0
	call exit
end start