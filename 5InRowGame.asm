;Mohamed Aref Agbaria 314720293
INCLUDE Irvine32.inc
include 5InRowGameData.inc
.data
	myName BYTE "name: Mohamed Aref Agbaria Id: 314720293",13,10,0
	WelcomeMsg BYTE " Welcome to the world of Order & Chaos :",13,10,0
	PlayerWord BYTE" Player ",0
	ReadCoordMsg2 BYTE" Enter row number : ",0
	ReadCoordMsg3 BYTE"Enter column number : ",0
	ErorMsg BYTE"***Eror, try again",13,10,0
	ReadXOMsg BYTE "Choose piece (X or O only) : ",0
	WinMsg BYTE" is the WINNER !!",13,10,0
	DrawMsg BYTE"The game finished in DRAW",13,10,0

	Row DWORD 0
	Column DWORD 0
	DiagonalOffset DWORD 0

	ContinueGame Dword 4
	SequenceLength Dword 5
.code

myMain PROC
	call PreGameStarting
	checkGameStatus:
		cmp eax,ContinueGame
		jne gameFinished
		push offset turn
		push offset Board
		call next_step
	jmp checkGameStatus
	gameFinished:
		call printTheResult 
	call ReadChar
	call exitProcess
myMain ENDP

next_step PROC
BOARDADDRESS = 8
PLAYERTURN = BOARDADDRESS + 4
GAMEFINISHEDINDRAW = 3
BOARDHAVEEMPTYLOC = 1
	push ebp
	mov ebp, esp

	push [ebp+BOARDADDRESS]
	call PrintBoard

	push [ebp+BOARDADDRESS]
	call CheckEMptyLoc

	cmp ebx,BOARDHAVEEMPTYLOC
	jne NoEMptyLoc

	push [ebp+PLAYERTURN]
	call Read_coord

	mov esi, eax ; save eax value place 
	call Read_XO
	mov bx,ax ; save the piece

	push ax ;Piece
	push esi; xy Location
	push [ebp+BOARDADDRESS]; board addres
	call SetXY

	cmp eax,1 ; update player turn 1->2   2->1
	jne skip
	mov esi,[ebp+PLAYERTURN]
	cmp word ptr[esi],1
	je incTurn
	dec word ptr[esi]
	dec word ptr[esi]
	incTurn:
	inc word ptr[esi]

	push [ebp+BOARDADDRESS]; board addres
	call Check4Win

	cmp eax,1
	jne skip
	push [ebp+PLAYERTURN]
	call WhoTheWinner

	jmp skip2
	jmp skip
	NoEMptyLoc:
		mov eax,GAMEFINISHEDINDRAW
		jmp skip2
	skip: ;skip := called if there is no winner and we want to update eax
		mov eax,ContinueGame
	skip2: ;skip2 := called if there is a winner and we donot want to update eax
		mov esp,ebp
		pop ebp
		ret 6
next_step ENDP

printTheResult PROC
	push ebp
	mov ebp, esp

	cmp eax,1
	je Player1Win
	cmp eax,2
	je Player2Win
	jmp Draw
	Player1Win:
		mov edx,offset PlayerWord
		call WriteString
		call WriteDec
		mov edx, offset WinMsg
		call WriteString
		jmp skip
	Player2Win:
		mov edx,offset PlayerWord 
		call WriteString
		call WriteDec
		mov edx, offset WinMsg
		call WriteString
		jmp skip
	Draw:
		mov edx,offset DrawMsg
		call WriteString
	skip:
		mov esp,ebp
		pop ebp
		ret
printTheResult ENDP


WhoTheWinner PROC
; return in eax which player is the winner (1/2)
PLAYERTURN = 8
	push ebp
	mov ebp,esp

	mov esi,[ebp+PLAYERTURN] ; esi store player turn offset
	cmp word ptr[esi],1
	je player2Win
	jmp skip
	player2Win:
		mov eax,2
	skip:
		mov esp,ebp
		pop ebp
		ret 4
WhoTheWinner ENDP

Check4Win Proc
	BOARDADDRESS = 8
	push ebp
	mov ebp,esp
	push [ebp+BOARDADDRESS]
	call Check4WinRows
	push [ebp+BOARDADDRESS]
	call Check4WinColumns
	push [ebp+BOARDADDRESS]
	call Check4WinDiagonal
	cmp eax,1
	jne NoWinner
	push [ebp+BOARDADDRESS]
	call PrintBoard
	jmp skip 

	NoWinner:
		mov eax,ContinueGame
	skip:
		mov esp,ebp
		pop ebp
		ret 4
Check4Win ENDP

Check4WinDiagonal PROC
	BOARDADDRESS = 8
	push ebp
	mov ebp,esp

	cmp eax,1
	je skip
	mov edi,[ebp+BOARDADDRESS]; edi store board adress
	mov Row,1 ; edx store row number
	mov Column,1
	mov ecx,N
	mov esi,0 ; index to travel on the board
	sub ecx,SequenceLength
	inc ecx  ; now ecx store how many rows to check (from where start the diagonal elements)
	SearchDiagonalOuterLoop:
		push ecx
		mov ecx,N
		mov Column,1
		SearchDiagonalInnerLoop:
			
			mov edx,N
			sub edx,Column
			inc edx
			cmp edx,SequenceLength ; (N-Column+1>=SequenceLength)
			JL LeftSearch

			mov DiagonalOffset,N
			inc DiagonalOffset
			push [ebp+BOARDADDRESS] ; Board Addres
			Call CheckSpecificDiagonal

			LeftSearch:
			mov edx,Column
			cmp edx,SequenceLength ;(Column>=SequenceLength)
			JL PieceNotInDiagonal

			mov DiagonalOffset,N
			dec DiagonalOffset
			push [ebp+BOARDADDRESS] ; Board Addres
			Call CheckSpecificDiagonal

			cmp eax,1
			JE exitLoop

			PieceNotInDiagonal:
			inc esi
			inc Column
			Loop SearchDiagonalInnerLoop
		pop ecx
	loop SearchDiagonalOuterLoop

	jmp skip
	exitLoop:
		pop ecx

	skip:
		mov esp,ebp
		pop ebp
		ret 4
Check4WinDiagonal ENDP

CheckSpecificDiagonal PROC USES esi ecx edi
	BOARDADDRESS = 20
	push ebp
	mov ebp,esp

	mov ecx,SequenceLength
	mov edi,[ebp+BOARDADDRESS]; edi store board adress
	CheckDiagonalLoop:
		cmp [edi+esi],bl
		jne skip
		add esi,DiagonalOffset
	Loop CheckDiagonalLoop
	mov eax,1
	jmp skip

	skip:
		mov esp,ebp
		pop ebp
		ret 4
CheckSpecificDiagonal ENDP


Check4WinColumns PROC
	BOARDADDRESS = 8
	push ebp
	mov ebp,esp
	cmp eax,1
	je skip
	mov edx,0 ;  edx store the length of sequence of same piece
	mov edi,[ebp+BOARDADDRESS]; edi store board adress
	mov eax,0 ; eax store game status
	mov ecx,N; loop iterations number
	mov esi,0 ; index to travel on the board
	OuterLoopCheckColumns:
		push ecx
		mov ecx,N
		InnerLoopCheckColumns:
			cmp [edi+esi],bl ; bl store the last piece that set on the board
			jne DonotCount
			inc edx
			jmp ContinueInnerLoopCheckColumns
			DonotCount:
				cmp edx,0
				jbe ContinueInnerLoopCheckColumns
				cmp edx,SequenceLength 
				jne DecraseSequenceCounter
				jmp ContinueInnerLoopCheckColumns
				DecraseSequenceCounter:
					dec edx
				ContinueInnerLoopCheckColumns:
					add esi,N
		Loop InnerLoopCheckColumns
		cmp edx,SequenceLength 
		jne NoWinner
		mov eax,1
		jmp exitLoop
		NoWinner:
			mov edx,0
			inc edi
			mov esi,0
			pop ecx
		Loop OuterLoopCheckColumns
		exitLoop:
	skip:
	mov esp,ebp
	pop ebp
	ret 4
Check4WinColumns ENDP


Check4WinRows PROC
	BOARDADDRESS = 8
	push ebp
	mov ebp,esp
	mov edx,0 ;  edx store the length of sequence of same piece
	mov edi,[ebp+BOARDADDRESS]; edi store board adress
	mov eax,0 ; eax store game status
	mov ecx,N; loop iterations number
	mov esi,0 ; index to travel on the board
	OuterLoopCheckRows:
		push ecx
		mov ecx,N
		InnerLoopCheckRows:
			cmp [edi+esi],bl ; bl store the last piece that set on the board
			jne DonotCount
			inc edx
			jmp ContinueInnerLoopCheckRows
			DonotCount:
				cmp edx,0
				jbe ContinueInnerLoopCheckRows
				cmp edx,SequenceLength ; to change
				jne DecraseSequenceCounter
				jmp ContinueInnerLoopCheckRows
				DecraseSequenceCounter:
					dec edx
				ContinueInnerLoopCheckRows:
					inc esi
		Loop InnerLoopCheckRows
		cmp edx,SequenceLength
		jne NoWinner
		mov eax,1
		jmp exitLoop
		NoWinner:
			mov edx,0
			pop ecx
		Loop OuterLoopCheckRows
		exitLoop:

	mov esp,ebp
	pop ebp
	ret 4
Check4WinRows ENDP


SetXY PROC
	;return in eax 1 if succesfully set the piece in the place
	BOARDADDRESS = 8
	SETPLACE = BOARDADDRESS + 4
	PIECE = SETPLACE + 4
	SUCCESFULLYSETPIECE = 1
	push ebp
	mov ebp,esp

	mov edi, [ebp+BOARDADDRESS] ;edi store board addres
	mov esi, [ebp+SETPLACE] ;esi store the index (place in the Board) where to set the piece
	mov dx,  [ebp+PIECE] ; dx store the piece we want to set (X/O)
	cmp BYTE PTR[edi+esi],'-'
	je setPiece
	mov edx, offset ErorMsg
	call WriteString
	jmp skip

	setPiece:
		mov [edi+esi],dl
		mov eax,SUCCESFULLYSETPIECE
	skip:
		mov esp,ebp
		pop ebp
		ret 10
SetXY ENDP


Read_XO PROC
	push ebp
	mov ebp,esp

	pieceInput:
		mov eax,0 ; clean eax to get char from user
		mov edx,offset ReadXOMsg
		call WriteString
		call ReadChar
		call WriteChar
		call Crlf
		cmp al,'O'
		je validPiece
		cmp al, 'X'
		je validPiece
		mov edx,offset ErorMsg		
		call WriteString
	jmp pieceInput
	validPiece:
		mov esp,ebp
		pop ebp
		ret
Read_XO ENDP


Read_coord PROC uses ebx edx
	;return in eax the place in the board
	PLAYERTURN = 16
	push ebp
	mov ebp,esp

	rowInput:
		mov eax,0
		mov edx ,offset PlayerWord 
		call WriteString
		mov eax, [ebp+PLAYERTURN] ; eax store player turn offset
		movzx eax,Word ptr[eax]
		call WriteDec
		mov edx ,offset ReadCoordMsg2
		call WriteString
		call ReadInt
		cmp eax,N
		jG badRowInput
		cmp eax,0
		jG checkColumn
		badRowInput:
			mov edx,offset ErorMsg
			call WriteString
	jmp rowInput

	checkColumn:
		dec eax
		mov ebx,N
		mul ebx
		mov ebx,eax ; ebx store row place in the board

		columnInput:
			mov edx ,offset ReadCoordMsg3
			call WriteString
			call ReadInt
			cmp eax,N
			JG badColumnInput
			cmp eax,0
			jG validInput
		badColumnInput:
			mov edx,offset ErorMsg
			call WriteString
	jmp columnInput

	validInput:
		dec eax
		add eax,ebx

		mov esp,ebp
		pop ebp
		ret 4
Read_coord ENDP


CheckEMptyLoc PROC uses ecx edx edi esi 
; return ebx = 1 if the board has empty place otherwise ebx = 0
BOARDADDRESS = 24
THEREISANEMPTYPLACE = 1
	push ebp
	mov ebp, esp

	mov ecx,NN ; ecx store board length
	mov edi,[ebp+BOARDADDRESS] ; edi store board addres
	mov esi,0 ; esi index to travel on the board
	mov ebx,0 ; ebx store the return value
	EmptyPlace:
		mov dl,[edi+esi]
		cmp dl,'-'
		jz YesEmpty
		inc esi
	loop EmptyPlace
	jmp skip
	YesEmpty:
		mov ebx,THEREISANEMPTYPLACE
	skip:
		mov esp,ebp
		pop ebp
		ret 4
CheckEMptyLoc ENDP


PrintBoard PROC USES eax ecx edx edi esi
BOARDADDRESS = 28
	push ebp
	mov ebp, esp

	mov ecx,N ; ecx is edge length
	mov edi,[ebp+BOARDADDRESS] ; edi store board addres
	mov esi,0 ; esi index to travel on the board
	mov edx, 1 ; edx store a number of column and row (1-6) uses for printing
	mov al, ' '
	call WriteChar
	call WriteChar
	
	PrintRowHeader:;print 1  2  3  4 .........
		mov eax, edx
		call WriteDec
		mov al, ' '
		call WriteChar
		inc edx
	loop PrintRowHeader

	call CRLF
	mov edx, 1
	mov ecx,N
	OuterLoopPrintBoard:
		mov eax, edx
		call WriteDec
		mov al, ' '
		call WriteChar
		push ecx
		mov ecx,N
		InnerLoopPrintBoard:
			mov al,[edi+esi]
			call WriteChar
			mov al, ' '
			call WriteChar
			inc esi
		loop InnerLoopPrintBoard
		Call CRLF
		pop ecx
		inc edx
	loop OuterLoopPrintBoard

	mov esp,ebp
	pop ebp
	ret 4
PrintBoard ENDP


PreGameStarting PROC
	push ebp
	mov ebp, esp

	mov edx, offset myName
	call WriteString ; print Name
	mov edx, offset WelcomeMsg
	call WriteString ; print WelcomeMsg
	mov eax,ContinueGame ; set eax to start the game

	mov esp,ebp
	pop ebp
	ret 
PreGameStarting ENDP

END myMain