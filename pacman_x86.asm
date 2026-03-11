include irvine32.inc
includelib kernel32.lib   ; Required for system calls
includelib user32.lib     ; Required for user interface functions
include macros.inc

.data
	cursorInfo CONSOLE_CURSOR_INFO <>   ; a structre that holds info about the cursor
	;base BYTE 20 DUP("#")
	;Rowsize = ($ - base)
	maze_x_cordinate BYTE 0
	maze_y_cordinate Byte 0
	fluffy byte "=^_^=",0
	sleepyghost byte "(v_v)",0
	freakyghost byte "(o_O)",0
	arsh byte "(@_@)",0
	space byte "     ",0
	lives byte 3
	x_cordinate_array BYTE 840 DUP(?)  ; 413 cordinates in total i think
	;y_cordinate_array BYTE 420 DUP(?)
	cordinate_coin_array byte 220 DUP(0)  ; lets go with hundred for now
	sleepy_steps byte   12, 11, 18, 11, 27, 27, 11, 18, 11, 12               ;"D", "L", "D", "L", "U", "D", "R", "U", "R", "U", 0   
	repopulate_sleepy byte 12, 11, 18, 11, 27, 27, 11, 18, 11, 12

	freaky_steps byte	48, 3, 21, 11, 12, 11, 6, 3, 45										  ; "R". "U". "L". "U".	"R"."D". "R". "D". "L"
	repopulate_freaky byte  48, 3, 21, 11, 12, 11, 6, 3, 45

	arsh_steps byte	10, 10									  ; "R". "U". "L". "U".	"R"."D". "R". "D". "L"
	repopulate_arsh byte  10, 10
	freaky_index  byte 0
	sleepy_index byte 0
	arsh_index byte 0
	user_input  byte ?
	score byte 0
	score_string byte "Your Score: ",0

	x_cordinate_user BYTE 42
	y_cordinate_user BYTE 4
	x_cordinate_sleepyghost byte 64
	y_cordinate_sleepyghost byte 3
	x_cordinate_freakyghost byte 51
	y_cordinate_freakyghost byte 18
	x_cordinate_arsh byte 51
	y_cordinate_arsh byte 22


	x_cordinate_coin byte 0							  
	y_cordinate_coin byte 0
		BYTE ?
	flag BYTE ?  ;tells the validate function who is the caller
	sleepyflag byte ?
	collisionflag byte 0

	starttime dword 0
	currenttime dword 0
	elapsedtime dword 0
	;coin_cordinates_array BYTE 6 dup(?) ; 3 coins for now 

	hconsole dword ?
	bluecolor byte 9 ; blue text black backgrd
	defaultcolor byte 7 ; standard settings
	yellowcolor byte 6
	coincount byte 0
	brightaqua byte 11

.code
	

	main PROC
		
		INVOKE GetStdHandle, STD_OUTPUT_HANDLE   ;Setting the cursor to invisible, fruitless cause when the screen is resized the settings are reset
		mov hconsole, eax
		mov cursorInfo.bVisible, 0
		mov cursorInfo.dwSize, 1
		INVOKE SetConsoleCursorInfo, hconsole, ADDR cursorInfo
		
		;le creation de maze
		call DrawMaze
		; le creation de coins
		call DrawCoins  
		; le creation de sleepyghost
		mov dl, x_cordinate_sleepyghost
		mov dh, y_cordinate_sleepyghost
		call DrawSleepyGhost
		mov dl, x_cordinate_freakyghost
		mov dh, y_cordinate_freakyghost
		call DrawFreakyah_ghost
		mov dl, x_cordinate_arsh
		mov dh, y_cordinate_arsh
		call DrawArsh_ghost
		; le creation de player
		call DrawPlayer
		xor eax, eax
		INVOKE GetTickCount
		mov starttime, eax
		mgotoxy 0 , 3
		mwrite < "TIMER: " >
		GameLoop:	;main gamw loop
			
			INVOKE SetConsoleCursorInfo, hconsole, ADDR cursorInfo
			xor eax, eax
			invoke gettickcount
			sub eax, starttime
			mgotoxy 6, 3
			call writedec
			mov elapsedtime, eax
			cmp elapsedtime, 60000
			ja GameOver
			call CheckCollision
			cmp collisionflag, 1
			je GameOver
			cmp score, 109
			je GameOver
			invoke GetKeyState, VK_CAPITAL
			test al, 1
			jz turncaps
			jmp itsfinebud
			turncaps:
				mov dh, 4
				call gotoxy
				mwrite < "TURN ON CAPSLOCK" >
				jmp ahead
			itsfinebud:
				mov dh, 4
				call gotoxy
				mwrite < "                 " >
			ahead:
			mov dl, 0
			mov dh, 0
			mov flag, 0
			mov sleepyflag, 0
			
			call gotoxy
			mov edx, offset score_string
			call writestring
			xor eax, eax
			mov al, score
			;add al, "0"
			call writedec
			

		;	movzx eax, brightaqua
		;	INVOKE SetConsoleTextAttribute, hconsole, ax
			call MoveSleepyGhost
		;	movzx eax, defaultcolor
		;	INVOKE SetConsoleTextAttribute, hconsole, ax
			mov x_cordinate_sleepyghost, dl
			mov y_cordinate_sleepyghost, dh

			call MoveFreakyGhost
			mov x_cordinate_freakyghost, dl
			mov y_cordinate_freakyghost, dh
			
			call MoveArsh
			mov x_cordinate_arsh, dl
			mov y_cordinate_arsh, dh

			call ReDrawCoins
			mov eax, 3
			call delay
			call ReadKey
			mov user_input, al
			;checking where the user wants to move
			cmp user_input, "X"
			je gameover ;user is a pussy
			cmp user_input, "W"
			je moveup
			cmp user_input, "S"
			je movedown
			cmp user_input, "D"
			je moveright
			cmp user_input, "A"
			je moveleft
			jmp Gameloop ;if wrong input jmp to the top again 
			
			;moving fluffy
			moveup:
				mov flag,1  ;1 = move up
				call ValidateMove
				cmp flag, 0  ; flag 0 means an invalid move
				je Gameloop
				mov dl, x_cordinate_user
				mov dh, y_cordinate_user
				call ErasePreviousImage
				dec y_cordinate_user
				call DrawPlayer
				jmp Gameloop
			movedown:
				mov flag,2  ;2 = move dwn
				call ValidateMove
				cmp flag, 0
				je Gameloop
				mov dl, x_cordinate_user
				mov dh, y_cordinate_user
				call ErasePreviousImage
				inc y_cordinate_user
				call DrawPlayer
				jmp Gameloop
			moveright:
				mov flag,3  ;3 = move right
				call ValidateMove
				cmp flag, 0
				je Gameloop
				mov dl, x_cordinate_user
				mov dh, y_cordinate_user
				call ErasePreviousImage
				inc x_cordinate_user
				call DrawPlayer
				jmp Gameloop
			moveleft:
				mov flag,4  ;4 = move LEFT
				call ValidateMove
				cmp flag, 0
				je Gameloop
				mov dl, x_cordinate_user
				mov dh, y_cordinate_user
				call ErasePreviousImage
				dec x_cordinate_user
				call DrawPlayer
				jmp Gameloop
				
		jmp Gameloop
		call writeint
		gameover:
			;reseting the cursor
			call clrscr
			mov dl, 75
			mov dh, 18
			call gotoxy
			cmp user_input, "X"
			je exittt
			cmp score, 109
			je win
			jmp compcolision
			win:
				mwrite < " YOU COLLECTED ALL THE COINS!! " >
			compcolision:
			cmp collisionflag, 1
			je coll
			jmp pussyassbitch
			coll:
				mwrite < " YOU COLLIDED!" > 
				jmp exittt
			pussyassbitch:
				mwrite < " YOU LOST ON TIME " >
		

		exittt:
			 mgotoxy 70, 20
			 call waitmsg
		exit

	main ENDP

DrawMaze PROC
    INVOKE GetStdHandle, -11
    mov hconsole, eax
    movzx eax, bluecolor
    INVOKE SetConsoleTextAttribute, hconsole, ax
    mov esi, offset x_cordinate_array

    ; setting up middle wall 1 (vertical)
    mov maze_x_cordinate, 50
    mov maze_y_cordinate, 3
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 30
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting up middle wall 2 (vertical)
    mov maze_x_cordinate, 60
    mov maze_y_cordinate, 3
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 10
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting up middle wall 3 (vertical)
    mov maze_x_cordinate, 75
    mov maze_y_cordinate, 3
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 14
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting up middle wall 5 (horizontal)
    mov maze_x_cordinate, 75
    mov maze_y_cordinate, dh
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 20
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting up middle wall 4 (vertical)
    mov maze_x_cordinate, 100
    mov maze_y_cordinate, 3
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 10
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting up wall 6 (horizontal)
    mov maze_x_cordinate, 60
    mov maze_y_cordinate, 20
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 49
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting up wall 7 (horizontal)
    mov maze_x_cordinate, 65
    mov maze_y_cordinate, 25
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 20
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting up wall 8 (vertical)
    mov maze_x_cordinate, 70
    mov maze_y_cordinate, 26
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 11
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting up wall 9 (horizontal)
    mov maze_x_cordinate, 76
    mov maze_y_cordinate, 30
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 34
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting up wall 10 (vertical)
    mov maze_x_cordinate, 90
    mov maze_y_cordinate, 34
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 4
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting upper wall (horizontal)
    mov maze_x_cordinate, 40
    mov maze_y_cordinate, 2
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 70
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting left wall (vertical)
    mov maze_x_cordinate, 40
    mov maze_y_cordinate, 2
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 35
    mov al, 219
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; setting lower wall (horizontal)
    mov maze_x_cordinate, 40
    mov maze_y_cordinate, dh
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    call gotoxy
    mov ecx, 70
    mov al, 219
    mov ebx, 1  ; set for horizontal
    call Wallloop

    ; setting right wall (vertical)
    mov maze_x_cordinate, 109
    mov maze_y_cordinate, 2
    mov dl, maze_x_cordinate
    mov dh, maze_y_cordinate
    mov ecx, 35
    call gotoxy
    xor ebx, ebx  ; set for vertical
    call Wallloop

    ; resetting the cursor
    mov dl, 0
    mov dh, 0
    mov ebx, 0
    call gotoxy

    ; resetting to default color
    movzx eax, defaultcolor
    INVOKE SetConsoleTextAttribute, hconsole, ax

    ret
DrawMaze ENDP


Wallloop PROC
	cmp ebx, 0
   jz draw_vertical
   jmp draw_horizontal
	draw_vertical:
		draw_v_loop:
			cmp dl, 50
			je checkothercord
			jmp nevermind
			checkothercord:
				cmp dh, 18
			je nodraw
			nevermind:
			call writechar
			;mov eax, 50
			;call delay
			mov eax, 219
			mov [esi], dl
			add esi, TYPE BYTE
			mov [esi], dh
			add esi, TYPE BYTE
			nodraw:
		  		inc dh
				call gotoxy
			loop draw_v_loop
		jmp end_wallloop
	draw_horizontal:
   		draw_h_loop:
			call writechar
			;mov eax, 50
			;call delay
			mov eax, 219
			mov [esi], dl
			add esi, TYPE BYTE
			mov [esi], dh
			add esi, TYPE BYTE
			inc dl
			call gotoxy
			loop draw_h_loop
		jmp end_wallloop

end_wallloop:
    ret
Wallloop ENDP




	ValidateMove PROC

		mov ecx, 820
		mov esi, offset x_cordinate_array
		;mov edi, offset y_cordinate_array
		mov dl, x_cordinate_user
		mov dh, y_cordinate_user
		cmp flag, 1
		je validateup
		cmp flag, 2
		je validatedown
		cmp flag, 3
		je validateright
		cmp flag, 4
		je validateleft

		validateup:
				dec dh
				call CompareCordinates
				jmp validated

		validatedown:
				inc dh
				call CompareCordinates
				jmp validated

		validateright:
				inc dl
				call CompareCordinates
				jmp validated

		validateleft:
				dec dl
				call CompareCordinates
				
		validated:
		ret
	ValidateMove ENDP

	CompareCordinates PROC
		mov bl, dl

		checkloop:
			cmp [esi], dl
			je compare_ycordinate
			mov bl, dl
			inc bl
			cmp [esi], bl
			je compare_ycordinate
			inc bl
			cmp [esi], bl
			je compare_ycordinate
			inc bl
			cmp [esi], bl
			je compare_ycordinate
			inc bl
			cmp [esi], bl
			je compare_ycordinate
			jmp dontcompare
			compare_ycordinate:
				add esi, type byte
				cmp dh, [esi]
				je setflag
			dontcompare:
				add esi, type byte
				;add edi, type byte
		loop checkloop
		jmp dontsetflag
		setflag:
			mov flag, 0
		dontsetflag:
			
		ret
	CompareCordinates ENDP
	MoveFreakyGhost PROC
		local temp1:byte
		local temp2 : byte
		top:
			xor eax, eax
			xor ebx, ebx
			mov al, freaky_index
			mov esi, offset freaky_steps
			mov bl, [esi + eax]
			cmp bl, 0
			jle incrementfreakyindex

			mov dl, x_cordinate_freakyghost
			mov dh, y_cordinate_freakyghost
			dec bl
			mov [esi + eax], bl
			cmp al, 0
			je movright
			cmp al, 1
			je movup
			cmp al, 2
			je movleft
			cmp al, 3
			je movup
			cmp al, 4
			je movright
			cmp al, 5
			je movdown
			cmp al, 6
			je movright
			cmp al, 7
			je movdown
			cmp al, 8
			je movleft
			movdown:
			add dh, 1
			mov sleepyflag, 1
			jmp completemove
		movup:
			dec dh
			mov sleepyflag, 2
			jmp completemove
		movleft:
			dec dl
			mov sleepyflag, 4
			jmp completemove
		movright:
			inc dl
			mov sleepyflag, 3
			jmp completemove
		incrementfreakyindex:
			inc freaky_index
			mov al, freaky_index
			cmp al, 9
			jne recursivecall
			mov freaky_index, 0
			mov esi, offset freaky_steps
			mov edi, offset repopulate_freaky
			mov ecx, 9
			repopulate:	
				mov al, [edi]
				mov [esi], al
				add esi, type byte
				add edi, type byte
			loop repopulate
			recursivecall:
				jmp top
	completemove:
			call DrawFreakyah_ghost
			mov temp1, dl
			mov temp2, dh
			mov dl, x_cordinate_freakyghost
			mov dh, y_cordinate_freakyghost
			call ErasePreviousImage
			mov dl, temp1
			mov dh, temp2
		ret


	MoveFreakyGhost ENDP

MoveArsh PROC
    cmp arsh_index, 0
    je movright
    jmp movleft

movright:
    mov dl, x_cordinate_arsh
    inc dl
    cmp dl, 101
    je setflag
    jmp completemove

setflag:
    mov arsh_index, 1
    jmp completemove

movleft:
    mov dl, x_cordinate_arsh
    dec dl
    cmp dl, 52
    je unsetflag
    jmp completemove

unsetflag:
    mov arsh_index, 0

completemove:
    mov x_cordinate_arsh, dl
    mov dh, y_cordinate_arsh
    call DrawArsh_ghost
cmp arsh_index, 1
	je leftremove
	jmp rightremove
	leftremove:
		
		add dl, 5
		call gotoxy
		mwrite<" ">
		sub dl, 5
		jmp over
	rightremove:
		dec dl
		call gotoxy
		mwrite<" " >
		inc dl
	over:
		
    ret
MoveArsh ENDP


	MoveSleepyGhost PROC
		local temp1:byte 
		local temp2:byte 
	
		top:
		xor eax, eax
		xor ebx, ebx
		mov al, sleepy_index
		mov esi, offset sleepy_steps
		mov bl, [esi + eax]
		cmp bl, 0
		jle incrementsleepyindex

		mov dl, x_cordinate_sleepyghost
		mov dh, y_cordinate_sleepyghost
		dec bl
		mov [esi + eax], bl
		cmp al, 0
		je movedown
		cmp  al, 1
		je moveleft
		cmp al, 2
		je movedown
		cmp al, 3
		je moveleft
		cmp al, 4
		je moveup
		cmp al, 5
		je movedown
		cmp al, 6
		je moveright
		cmp al, 7
		je moveup
		cmp al, 8
		je moveright
		cmp al, 9
		je moveup
		movedown:
			add dh, 1
			mov sleepyflag, 1
			jmp completemove
		moveup:
			dec dh
			mov sleepyflag, 2
			jmp completemove
		moveleft:
			dec dl
			mov sleepyflag, 4
			jmp completemove
		moveright:
			inc dl
			mov sleepyflag, 3
			jmp completemove
		incrementsleepyindex:
			inc sleepy_index
			mov al, sleepy_index
			cmp al, 10
			jne recursivecall
			mov sleepy_index, 0
			mov ecx, 10
			mov edi, offset repopulate_sleepy
			mov esi, offset sleepy_steps
			repopulate_array:
				mov al, [edi]
				mov [esi], al
				add esi, type byte
				add edi, type byte
			loop repopulate_array
			recursivecall:
				jmp top
	completemove:
			call DrawSleepyGhost
			mov temp1, dl
			mov temp2, dh
			mov dl, x_cordinate_sleepyghost
			mov dh, y_cordinate_sleepyghost
			call ErasePreviousImage
			mov dl, temp1
			mov dh, temp2
	
		ret
	MoveSleepyGhost ENDP

	DrawPlayer PROC
		mov dl, x_cordinate_user
		mov dh, y_cordinate_user
		mov esi, offset cordinate_coin_array
		mov ecx, 109 ; placeholder, i will add an index counter later
		mov al, -1
		call CheckCleavage
		call gotoxy
		mov edx, offset fluffy
		call writestring
		;reseting the cursor
		mov dl, 0
		mov dh, 0
		call gotoxy
		
	ret
	DrawPlayer ENDP

	DrawArsh_ghost PROC
		local temp3: byte
		local temp4:byte
		call gotoxy
		mov eax, 5
		call Delay
		mov temp3, dl
		mov temp4, dh
		mov edx, offset arsh
		call writestring

		mov dl, temp3
		mov dh, temp4
		ret
	DrawArsh_ghost ENDP

	CheckCleavage PROC
	
		pointloop:
			cmp [esi], dl
			je cmp_y
			mov bl, dl
			cmp [esi], bl
			je cmp_y
			inc bl
			cmp [esi], bl
			je cmp_y
			inc bl
			cmp [esi], bl
			je cmp_y
			inc bl
			cmp [esi], bl
			je cmp_y
			inc bl
			cmp [esi], bl
			je cmp_y
			jmp nextcoin
			cmp_y:
				cmp [esi + 1], dh
				jne nextcoin
				add score, 1
				MWRITE < "KIA HOGAYA??" >
				mov [esi], al    ;marking as collected
				mov [esi + 1], al ; marking as collected
			nextcoin:
				add esi, 2
		loop pointloop
		ret
	CheckCleavage ENDP
			
	DrawSleepyGhost PROC

		local temp3: byte
		local temp4:byte
		call gotoxy
		mov eax, 5
		call Delay
		mov temp3, dl
		mov temp4, dh

		mov edx, offset sleepyghost
		call writestring
		mov dl, temp3
		mov dh, temp4
		
		ret
	DrawSleepyGhost ENDP

CheckCollision PROC
    mov dl, x_cordinate_user
    mov dh, y_cordinate_user

    ; Check collision with Sleepy Ghost
    mov bl, x_cordinate_sleepyghost
	cmp bl, dl
	je check_y
	cmp bl,dl
	jge checkendingcord
	jmp check_freaky
	checkendingcord:
		add dl, 4
		cmp bl, dl
		jle check_y
	sub dl, 4
	add bl, 4
	cmp bl,dl
	jge checkendingcord2
	jmp check_freaky
	checkendingcord2:
		add dl, 4
		cmp bl, dl
		jle check_y
		jmp check_freaky
	check_y:
		cmp dh, y_cordinate_sleepyghost
		je user_collided
		
check_freaky:
    ; Check collision with Freaky Ghost
    cmp dl, x_cordinate_freakyghost
    jne check_arsh
    cmp dh, y_cordinate_freakyghost
    je user_collided

check_arsh:
    ; Check collision with Arsh Ghost
    cmp dl, x_cordinate_arsh
    jne no_collision
    cmp dh, y_cordinate_arsh
    je user_collided

no_collision:
    ret

user_collided:
    mov collisionflag, 1
    ;dec lives
    ret
CheckCollision ENDP




	DrawFreakyah_ghost PROC
			local temp3: byte
		local temp4:byte
		call gotoxy
		mov eax, 5
		call Delay
		mov temp3, dl
		mov temp4, dh
		mov edx, offset freakyghost
		call writestring
		mov dl, temp3
		mov dh, temp4
		ret
		
	DrawFreakyah_ghost ENDP
ReDrawCoins PROC
	mov esi, offset cordinate_coin_array
	movzx eax, yellowcolor
	INVOKE SetConsoleTextAttribute, hconsole, ax
    mov ecx, 109
    mov esi, offset cordinate_coin_array
	loops:
		mov dl, [esi]
		cmp dl, -1
		je nextcoin          
		mov dh, [esi + 1]
		call gotoxy
		mov al, "O"
		call writechar
		nextcoin:
			add esi, 2
	loop loops
	movzx eax, defaultcolor
	INVOKE SetConsoleTextAttribute, hconsole, ax
    ret
ReDrawCoins ENDP
	

DrawCoins PROC
		mov esi, offset cordinate_coin_array
		movzx eax, yellowcolor
		INVOKE SetConsoleTextAttribute, hconsole, ax
		;setting up middle coin 1
		mov x_cordinate_coin, 45
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin

		call gotoxy
		mov ecx, 12
		mov al, "."
		xor ebx, ebx
		call Coinloop
		add ebx, 1

		;setting up middle coin 2
		
		mov x_cordinate_coin, 55
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 12
		xor ebx, ebx
		call Coinloop
		add ebx, 1
		;setting up middle coin 3

		mov x_cordinate_coin, 65
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 6
		xor ebx, ebx
		call Coinloop
		add ebx, 1

		mov x_cordinate_coin, 70
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 5
		xor ebx, ebx
		call Coinloop
		add ebx, 1

		mov x_cordinate_coin, 70
		mov y_cordinate_coin, 18
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 5
		call Coinloop

		mov x_cordinate_coin, 101
		mov y_cordinate_coin, 15
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 2
		xor ebx, ebx
		call Coinloop
		add ebx, 1

		mov x_cordinate_coin, 77
		mov y_cordinate_coin, 15
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 4
		call Coinloop

		mov x_cordinate_coin, 77
		mov y_cordinate_coin, 12
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 4
		call Coinloop

		mov x_cordinate_coin, 77
		mov y_cordinate_coin, 9
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 4
		call Coinloop

		mov x_cordinate_coin, 77
		mov y_cordinate_coin, 6
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 4
		call Coinloop

		mov x_cordinate_coin, 77
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 4
		call Coinloop

		mov x_cordinate_coin, 106
		mov y_cordinate_coin, 3
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 6
		xor ebx, ebx
		call Coinloop
		add ebx, 1


		mov x_cordinate_coin, 65
		mov y_cordinate_coin, 23
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 8
		call Coinloop

		mov x_cordinate_coin, 71
		mov y_cordinate_coin, 26
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 7
		call Coinloop

		mov x_cordinate_coin, 71
		mov y_cordinate_coin, 29
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 7
		call Coinloop

		mov x_cordinate_coin, 71
		mov y_cordinate_coin, 32
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 7
		call Coinloop

		mov x_cordinate_coin, 71
		mov y_cordinate_coin, 35
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 7
		call Coinloop

		mov x_cordinate_coin, 65
		mov y_cordinate_coin, 24
		mov dl, x_cordinate_coin
		mov dh, y_cordinate_coin
		call gotoxy
		mov ecx, 5
		xor ebx, ebx
		call Coinloop

		movzx eax, defaultcolor
		INVOKE SetConsoleTextAttribute, hconsole, ax
		ret
		
	DrawCoins ENDP

Coinloop PROC
    cmp ebx, 0
    jz draw_vertical
    jmp draw_horizontal

draw_vertical:
    draw_v_loop:
        mov al, "O"
        call writechar
        mov [esi], dl
        add esi, TYPE BYTE
        mov [esi], dh
        add esi, TYPE BYTE
        add dh, 3
        call gotoxy
        loop draw_v_loop
    jmp end_wallloop

draw_horizontal:
    draw_h_loop:
        mov al, "O"
		call writeChar
        mov [esi], dl
        add esi, TYPE BYTE
        mov [esi], dh
        add esi, TYPE BYTE
        add dl, 6
        call gotoxy
        loop draw_h_loop
    jmp end_wallloop

end_wallloop:
    ret
Coinloop ENDP



	ErasePreviousImage PROC
		local temp:byte
		mov temp, 0
		mov bl, flag
		cmp bl, 0
		jne eraseprevious
		mov bl, sleepyflag
		cmp bl, 0
		jne settemp
		settemp:
			mov temp, 1
		eraseprevious:
			cmp bl, 4
			je removeleft
			cmp bl, 3
			je removeright
			jmp simpleremove

		removeleft:
			add dl, 4
			call gotoxy
			mov al, " "
			call writechar
			jmp resetcursor
		removeright:
			call gotoxy
			mov al, " "
			call writechar
			jmp resetcursor
		simpleremove:
			call gotoxy
			mov edx, offset space
			call writestring
		mov bl, temp
		cmp bl, 1
		je checkcoincleavage
		jmp resetcursor
		checkcoincleavage:
			mov esi, offset cordinate_coin_array
			mov ecx, 30
			cleavageloop:
				cmp [esi], dl
				je cmp_y
				mov bl, dl
				cmp [esi], bl
				je cmp_y
				inc bl
				cmp [esi], bl
				je cmp_y
				inc bl
				cmp [esi], bl
				je cmp_y
				inc bl
				cmp [esi], bl
				je cmp_y
				jmp nextcoin
				cmp_y:
					cmp [esi + 1], dh
					je redrawcleavage
				nextcoin:
					add esi, 2
		loop cleavageloop
		jmp resetcursor
			redrawcleavage:
				mov al, "."
				call writechar
		resetcursor:
		;reseting the cursor
		mov dl, 0
		mov dh, 0
		
		call gotoxy
	ret
	ErasePreviousImage ENDP
	ResetGame PROC
    ; Reset player's coordinates
    mov x_cordinate_user, 42
    mov y_cordinate_user, 4

    ; Reset sleepy ghost's coordinates and index
    mov x_cordinate_sleepyghost, 64
    mov y_cordinate_sleepyghost, 3
    mov sleepy_index, 0

    ; Reset freaky ghost's coordinates and index
    mov x_cordinate_freakyghost, 51
    mov y_cordinate_freakyghost, 18
    mov freaky_index, 0

    ; Reset arsh ghost's coordinates and index
    mov x_cordinate_arsh, 51
    mov y_cordinate_arsh, 22
    mov arsh_index, 0

    ; Reset step arrays to their original values
    lea esi, repopulate_sleepy
    lea edi, sleepy_steps
    mov ecx, 10         ; Number of steps
    rep movsb           ; Copy repopulate_sleepy into sleepy_steps

    lea esi, repopulate_freaky
    lea edi, freaky_steps
    mov ecx, 9          ; Number of steps
    rep movsb           ; Copy repopulate_freaky into freaky_steps

    lea esi, repopulate_arsh
    lea edi, arsh_steps
    mov ecx, 2          ; Number of steps
    rep movsb           ; Copy repopulate_arsh into arsh_steps

    ; Reset score
    mov score, 0

    ; Reset coins' positions in cordinate_coin_array (optional if coins are regenerated)
    lea edi, cordinate_coin_array
    mov ecx, 220         ; Total number of coin positions
    xor eax, eax         ; Fill with zeros
    rep stosb

    ret
ResetGame ENDP






end main
