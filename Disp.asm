;===========================================================
; LCD_RamAddr		.equ	0200H
;===========================================================
F_FillScreen:
	lda		#$ff
	bne		L_FillLed
F_ClearScreen:
	lda		#0
L_FillLed:
	sta		$1824
	sta		$1825
	sta		$1826
	sta		$1828
	sta		$1829
	sta		$182a
	sta		$182b
	sta		$182c
	sta		$182d
	sta		$182e
	sta		$182f
	sta		$1830

	rts


;===========================================================
;@brief		显示完整的一个数字
;@para:		A = 0~9
;			X = offset	
;@impact:	P_Temp，P_Temp+1，P_Temp+2，P_Temp+3, X，A
;===========================================================
L_Dis_7Bit_DigitDot:
	stx		P_Temp+1					; 偏移量暂存进P_Temp+2, 腾出X来做变址寻址

	clc
	rol									; 乘以2得到正确的偏移量
	tax
	lda		Table_Digit_7bit,x			; 将显示的数字通过查表找到对应的段码存进A
	sta		P_Temp						; 暂存段码值到P_Temp

	lda		#7
	sta		P_Temp+2					; 设置显示段数为7
L_Judge_Dis_7Bit_DigitDot:				; 显示循环的开始
	ldx		P_Temp+1					; 表头偏移量->X
	lda		Led_bit,x					; 查表定位目标段的bit位
	sta		P_Temp+3					; bit位->P_Temp+3
	lda		Led_byte,x					; 查表定位目标段的显存地址
	tax									; 显存地址偏移->X
	ror		P_Temp						; 循环右移取得目标段是亮或者灭
	bcc		L_CLR_7bit					; 当前段的值若是0则进清点子程序
	lda		LED_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp+3					; 将COM和SEG信息与LED RAM地址进行逻辑或操作
	
	sta		LED_RamAddr,x
	bra		L_Inc_Dis_Index_Prog_7bit	; 跳转到显示索引增加的子程序。
L_CLR_7bit:	
	lda		LED_RamAddr,x				; 加载LED RAM的地址
	ora		P_Temp+3					; 先置1确定状态再异或翻转成0
	eor		P_Temp+3
	sta		LED_RamAddr,x				; 将结果写回LED RAM，清除对应位置。
L_Inc_Dis_Index_Prog_7bit:
	inc		P_Temp+1					; 递增偏移量，处理下一个段
	dec		P_Temp+2					; 递减剩余要显示的段数
	bne		L_Judge_Dis_7Bit_DigitDot	; 剩余段数为0则返回
	rts


F_DisPlay_Frame:
	jsr		F_COM0_SEL
	rmb7	PD							; LE拉低锁存5020当前数据
	lda		#0
	jsr		L_Send_Buffer
	rmb7	PD							; LE拉低锁存5020当前数据
	lda		#1
	jsr		L_Send_Buffer
	rmb7	PD							; LE拉低锁存5020当前数据
	lda		#2
	jsr		L_Send_Buffer

	rmb7	PD							; LE拉低锁存5020当前数据
	rts


; a==当前COM数
L_Send_Buffer:
	clc									; 乘以4作偏移
	rol
	rol
	tax
	lda		LED_RamAddr,x				; 32个Seg的状态依次送进P_Temp
	sta		P_Temp
	dex
	lda		LED_RamAddr,x
	sta		P_Temp+1
	dex
	lda		LED_RamAddr,x
	sta		P_Temp+2
	dex
	lda		LED_RamAddr,x
	sta		P_Temp+3
	dex

	lda		#32
	sta		P_Temp+4
L_Sending_Loop:
	ror		P_Temp+3					; 循环右移后，检测C位
	ror		P_Temp+2
	ror		P_Temp+1
	ror		P_Temp
	bcc		L_Send_0
	smb5	PD							; 如果是1，则输出高
	bra		L_Juge_32Times
L_Send_0:
	rmb5	PD							; 0则输出低
L_CLK_:
	rmb6	PD							; CLK产生一次上升沿使得5020开始位移
	nop									; 延时三个指令周期确保IO口翻转完成
	nop
	nop
	smb6	PD
	dec		P_Temp+4
	bne		L_Sending_Loop

	smb7	PD							; 32bit发送完成，开始显示
	rts



;-----------------------------------------
;@brief:	单独的画点、清点函数,一般用于MS显示
;@para:		X = offset
;@impact:	A, X, P_Temp
;-----------------------------------------
F_DisSymbol:
	jsr		F_DisSymbol_Com
	sta		LED_RamAddr,x				; 画点
	rts

F_ClrSymbol:
	jsr		F_DisSymbol_Com				; 清点
	eor		P_Temp
	sta		LED_RamAddr,x
	rts

F_DisSymbol_Com:
	lda		Led_bit,x					; 查表得知目标段的bit位
	sta		P_Temp
	lda		Led_byte,x					; 查表得知目标段的地址
	tax
	lda		LED_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp
	rts



F_COM0_SEL:
	smb1	PC
	rmb2	PC
	rmb3	PC
	rts

F_COM1_SEL:
	rmb1	PC
	smb2	PC
	rmb3	PC
	rts

F_COM2_SEL:
	rmb1	PC
	rmb2	PC
	smb3	PC
	rts


;============================================================
Table_Digit_7bit:
	.byte	$3f	; 0
	.byte	$06	; 1
	.byte	$5b	; 2
	.byte	$4f	; 3
	.byte	$66	; 4
	.byte	$6d	; 5
	.byte	$7d	; 6
	.byte	$07	; 7
	.byte	$7f	; 8
	.byte	$6f	; 9
	.byte	$00	; undisplay

Table_Week_7bit:
	.byte	$01		; SUN
	.byte	$02		; MON
	.byte	$04		; TUE
	.byte	$08		; WED
	.byte	$10		; THU
	.byte	$20		; FRI
	.byte	$40		; SAT
	.byte	$00		; undisplay
