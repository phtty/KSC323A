;===========================================================
; LCD_RamAddr		.equ	0200H
;===========================================================
F_FillScreen:
	lda		#$ff
	bne		L_FillLcd
F_ClearScreen:
	lda		#0
L_FillLcd:
	sta		$1800
	sta		$1801
	sta		$1804
	sta		$1805
	sta		$1806
	sta		$1807
	sta		$180A
	sta		$180B
	sta		$180C
	sta		$180D
	sta		$1810
	sta		$1811
	sta		$1812
	sta		$1813
	sta		$1816
	sta		$1817
	sta		$1818
	sta		$1819
	sta		$181C
	sta		$181D
	sta		$181E
	sta		$181F
	sta		$1822
	sta		$1823

	rts


;===========================================================
;@brief		显示完整的一个数字
;@para:		A = 0~9
;			X = offset	
;@impact:	P_Temp，P_Temp+1，P_Temp+2，P_Temp+3, X，A
;===========================================================
L_Dis_15Bit_DigitDot:
	stx		P_Temp+2					; 偏移量暂存进P_Temp+2, 腾出X来做变址寻址

	clc
	rol									; 乘以2得到正确的偏移量
	tax
	lda		Table_Digit_15bit,x			; 将显示的数字通过查表找到对应的段码存进A
	sta		P_Temp+1					; 暂存段码值到P_Temp+1、P_Temp
	inx
	lda		Table_Digit_15bit,x
	sta		P_Temp

	lda		#15
	sta		P_Temp+3					; 设置显示段数为15
L_Judge_Dis_15Bit_DigitDot:				; 显示循环的开始
	ldx		P_Temp+2					; 表头偏移量->X
	lda		Lcd_bit,x					; 查表定位目标段的bit位
	sta		P_Temp+4					; bit位->P_Temp+4
	lda		Lcd_byte,x					; 查表定位目标段的显存地址
	tax									; 显存地址偏移->X
	ror		P_Temp						; 循环右移取得目标段是亮或者灭
	ror		P_Temp+1
	bcc		L_CLR_15bit					; 当前段的值若是0则进清点子程序
	lda		LCD_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp+4
	sta		LCD_RamAddr,x
	bra		L_Inc_Dis_Index_Prog_15bit	; 跳转到显示索引增加的子程序。
L_CLR_15bit:	
	lda		LCD_RamAddr,x				; 加载LCD RAM的地址
	ora		P_Temp+4					; 将COM和SEG信息与LCD RAM地址进行逻辑或操作
	eor		P_Temp+4					; 进行异或操作，用于清除对应的段。
	sta		LCD_RamAddr,x				; 将结果写回LCD RAM，清除对应位置。
L_Inc_Dis_Index_Prog_15bit:
	inc		P_Temp+2					; 递增偏移量，处理下一个段
	dec		P_Temp+3					; 递减剩余要显示的段数
	bne		L_Judge_Dis_15Bit_DigitDot	; 剩余段数为0则返回
	rts



; 用于显示星期的七段数显
L_Dis_7Bit_WeekDot:
	stx		P_Temp+1					; 偏移量暂存进P_Temp+1, 腾出X来做变址寻址

	ldx		R_Date_Week					; 取得当前星期数
	lda		Table_Digit_7bit,x			; 将显示的数字通过查表找到对应的段码存进A
	sta		P_Temp						; 暂存段码值到P_Temp

	lda		#7
	sta		P_Temp+2					; 设置显示段数为7
L_Judge_Dis_7Bit_WeekDot:				; 显示循环的开始
	ldx		P_Temp+1					; 取回偏移量作为索引
	lda		Lcd_bit,x					; 查表定位目标段的bit位
	sta		P_Temp+3	
	lda		Lcd_byte,x					; 查表定位目标段的显存地址
	tax
	ror		P_Temp						; 循环右移取得目标段是亮或者灭
	bcc		L_CLR_7bit					; 当前段的值若是0则进清点子程序
	lda		LCD_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp+3
	sta		LCD_RamAddr,x
	bra		L_Inc_Dis_Index_Prog_7bit	; 跳转到显示索引增加的子程序
L_CLR_7bit:
	lda		LCD_RamAddr,x				; 加载LCD RAM的地址
	ora		P_Temp+3					; 先将指定bit用或操作置1
	eor		P_Temp+3					; 然后异或操作翻转置0
	sta		LCD_RamAddr,x				; 将结果写回LCD RAM，清除对应位置
L_Inc_Dis_Index_Prog_7bit:
	inc		P_Temp+1					; 递增偏移量，处理下一个段
	dec		P_Temp+2					; 递减剩余要显示的段数
	bne		L_Judge_Dis_7Bit_WeekDot	; 剩余段数为0则返回
	rts




; 显示动画帧
; a==当前数字  x==位选  Frame_Counter帧计数
F_Dis_Animation_Frame:
	sta		P_Temp						; 当前数字暂存
	txa									; 位选x入栈
	pha
	lda		P_Temp						; 取出当前数字
	jsr		L_Frame_TableTrans_Down
	pla
	tax									; 位选x出栈
	jsr		L_Dis_15Bit_Frame
	rts




; 计算向下计数动画帧
; a == 当前数字 || Frame_Counter帧计数
L_Frame_TableTrans_Down:
	clc
	rol
	tax
	sta		P_Temp						; 暂存当前数字
	lda		Table_Digit_15bit,x
	sta		Table_Digit_LByte
	inx
	lda		Table_Digit_15bit,x
	sta		Table_Digit_HByte

	lda		P_Temp						; 判断是否是0->9
	bne		L_Target_NoOverflow_Down
	lda		#18
	tax
	bra		L_Target_get_Down
L_Target_NoOverflow_Down:
	dex									; 目标数字的索引==当前数字索引-3
	dex
	dex
L_Target_get_Down:
	lda		Table_Digit_15bit,x
	sta		Target_Digit_LByte
	inx
	lda		Table_Digit_15bit,x
	sta		Target_Digit_HByte

	lda		Frame_Counter
	clc
	adc		#1
	jsr		L_Multiple_3				; n == (FC+1)*3
	sta		P_Temp

	sec
	sbc		#1							; m == n-1
	sta		P_Temp+1

	lda		Frame_Counter
	clc
	rol									; q == FC*2
	sta		P_Temp+2
	
L_TableTrans_Loop1_Down:
	clc
	rol		Table_Digit_LByte
	rol		Table_Digit_HByte
	dec		P_Temp
	lda		P_Temp
	bne		L_TableTrans_Loop1_Down

L_TableTrans_Loop2_Down:
	rol		Target_Digit_LByte
	rol		Target_Digit_HByte
	dec		P_Temp+1
	lda		P_Temp+1
	bne		L_TableTrans_Loop2_Down

	lda		P_Temp+2
	tax
	lda		Table_Digit_15bit_Mask_Down,x
	sta		P_Temp+4					; masklow
	inx
	lda		Table_Digit_15bit_Mask_Down,x
	sta		P_Temp+5					; maskhigh

	lda		Target_Digit_LByte
	and		P_Temp+4
	sta		Target_Digit_LByte
	lda		Target_Digit_HByte
	and		P_Temp+5
	sta		Target_Digit_HByte

	lda		P_Temp+4
	eor		#$ff
	sta		P_Temp+4
	lda		P_Temp+5
	eor		#$ff
	sta		P_Temp+5

	lda		Table_Digit_LByte
	and		P_Temp+4
	sta		Table_Digit_LByte
	lda		Table_Digit_HByte
	and		P_Temp+5
	sta		Table_Digit_HByte

	lda		Table_Digit_LByte
	ora		Target_Digit_LByte
	sta		Table_Digit_LByte
	lda		Table_Digit_HByte
	ora		Target_Digit_HByte
	sta		Table_Digit_HByte

	rts


; x==位选
L_Dis_15Bit_Frame:
	stx		P_Temp+1					; 偏移量暂存进P_Temp+2, 腾出X来做变址寻址

	lda		#15
	sta		P_Temp+2					; 设置显示段数为15
L_Judge_Dis_15Bit_Frame:				; 显示循环的开始
	ldx		P_Temp+1					; 表头偏移量->X
	lda		Lcd_bit,x					; 查表定位目标段的bit位
	sta		P_Temp+3					; bit位->P_Temp+4
	lda		Lcd_byte,x					; 查表定位目标段的显存地址
	tax									; 显存地址偏移->X
	ror		Table_Digit_HByte			; 循环右移取得目标段是亮或者灭
	ror		Table_Digit_LByte
	bcc		L_CLR_15bit_Frame			; 当前段的值若是0则进清点子程序
	lda		LCD_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp+3
	sta		LCD_RamAddr,x
	bra		L_Inc_Index_Prog_Frame		; 跳转到显示索引增加的子程序。
L_CLR_15bit_Frame:	
	lda		LCD_RamAddr,x				; 加载LCD RAM的地址
	ora		P_Temp+3					; 将COM和SEG信息与LCD RAM地址进行逻辑或操作
	eor		P_Temp+3					; 进行异或操作，用于清除对应的段。
	sta		LCD_RamAddr,x				; 将结果写回LCD RAM，清除对应位置。
L_Inc_Index_Prog_Frame:
	inc		P_Temp+1					; 递增偏移量，处理下一个段
	dec		P_Temp+2					; 递减剩余要显示的段数
	bne		L_Judge_Dis_15Bit_Frame		; 剩余段数为0则返回
	rts


; a==a*3
L_Multiple_3:
	sta		P_Temp
	clc
	rol
	clc
	adc		P_Temp
	rts

;-----------------------------------------
;@brief:	单独的画点、清点函数,一般用于MS显示
;@para:		X = offset
;@impact:	A, X, P_Temp
;-----------------------------------------
F_DisSymbol:
	jsr		F_DisSymbol_Com
	sta		LCD_RamAddr,x				; 画点
	rts

F_ClrSymbol:
	jsr		F_DisSymbol_Com				; 清点
	eor		P_Temp
	sta		LCD_RamAddr,x
	rts

F_DisSymbol_Com:
	lda		Lcd_bit,x					; 查表得知目标段的bit位
	sta		P_Temp
	lda		Lcd_byte,x					; 查表得知目标段的地址
	tax
	lda		LCD_RamAddr,x				; 将目标段的显存的特定bit位置1来打亮
	ora		P_Temp
	rts


;============================================================

Table_Digit_15bit:
	.word	$7b6f	; 0
	.word	$4924	; 1
	.word	$73e7	; 2
	.word	$79e7	; 3
	.word	$49ed	; 4
	.word	$79cf	; 5
	.word	$7bcf	; 6
	.word	$4927	; 7
	.word	$7bef	; 8
	.word	$79ef	; 9
	.word	$7b6f	; 0
	.word	$0000	; undisplay
	.word	$5bed	; H
	.word	$13c0	; r

Table_Digit_15bit_Mask_Up:
	.word	$0000	; frame 0
	.word	$7000	; frame 1
	.word	$7e00	; frame 2
	.word	$7fc0	; frame 3
	.word	$7ff8	; frame 4
	.word	$7fff	; frame 5

Table_Digit_15bit_Mask_Down:
	.word	$0000	; frame 0
	.word	$0007	; frame 1
	.word	$003f	; frame 2
	.word	$01ff	; frame 3
	.word	$0fff	; frame 4
	.word	$7fff	; frame 5

Table_Digit_7bit:
	.byte	$01		; SUN
	.byte	$02		; MON
	.byte	$04		; TUE
	.byte	$08		; WED
	.byte	$10		; THU
	.byte	$20		; FRI
	.byte	$40		; SAT
	.byte	$00		; undisplay