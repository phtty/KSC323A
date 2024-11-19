F_Display_Time:									; 调用显示函数显示当前时间
	jsr		L_DisTime_Min
	jsr		L_DisTime_Hour
	rts

L_DisTime_Min:
	lda		R_Time_Min
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	rts	

L_DisTime_Hour:									; 显示小时
	bbr0	Clock_Flag,L_24hMode_Time
	lda		R_Time_Hour
	cmp		#12
	bcs		L_Time12h_PM
	ldx		#lcd_PM								; 12h模式AM需要灭PM点
	jsr		F_ClrSymbol
	lda		R_Time_Hour							; 显示函数会改A值，重新取变量
	cmp		#0
	beq		L_Time_0Hour
	bra		L_Start_DisTime_Hour
L_Time12h_PM:
	ldx		#lcd_PM								; 12h模式PM需要亮PM点
	jsr		F_DisSymbol
	lda		R_Time_Hour							; 显示函数会改A值，重新取变量
	sec
	sbc		#12
	cmp		#0
	bne		L_Start_DisTime_Hour
L_Time_0Hour:									; 12h模式0点需要变成12点
	lda		#12
	bra		L_Start_DisTime_Hour

L_24hMode_Time:
	ldx		#lcd_PM								; 24h模式下需要灭PM点
	jsr		F_ClrSymbol
	lda		R_Time_Hour
L_Start_DisTime_Hour:
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Hour_Tens_NoZero					; 小时模式的十位0不显示
	lda		#$0b
L_Hour_Tens_NoZero:
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	rts 

F_UnDisplay_Hour:
	lda		#11
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	rts

F_UnDisplay_Min:
	lda		#11
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	rts



; 显示日期函数
F_Display_Date:
	jsr		L_DisDate_Day
	jsr		L_DisDate_Month
	rts

L_DisDate_Day:
	lda		R_Date_Day
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Day_Tens_NoZero					; 日期十位0不显示
	lda		#$0b
L_Day_Tens_NoZero:
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	rts

L_DisDate_Month:
	lda		R_Date_Month
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Month_Tens_NoZero					; 月份十位0不显示
	lda		#$0b
L_Month_Tens_NoZero:
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	rts

L_DisDate_Year:
	lda		#00									; 20xx年的开头20是固定的
	jsr		L_A_DecToHex							; 所以20固定会显示
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	lda		#02
	jsr		L_A_DecToHex
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot

	lda		R_Date_Year							; 显示当前的年份
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	rts


F_UnDisplay_Year:								; 闪烁时取消显示用的函数
	lda		#11
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	rts

F_UnDisplay_Month:								; 闪烁时取消显示用的函数
	lda		#11
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	rts

F_UnDisplay_Day:								; 闪烁时取消显示用的函数
	lda		#11
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#11
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	rts



F_DisDate_Week:
	jsr		L_GetWeek
	ldx		#lcd_week
	jsr		L_Dis_7Bit_WeekDot
	rts

F_Display_Week:
	bbr1	Sys_Status_Flag,No_4DMode_Week
	rts
No_4DMode_Week:
	jsr		L_GetWeek
	ldx		#lcd_week
	jsr		L_Dis_7Bit_WeekDot
	rts




F_SymbolRegulate:
	bbs0	Sys_Status_Flag,RTMode_Symbol
	bbs1	Sys_Status_Flag,4DMode_Symbol
	bbs2	Sys_Status_Flag,TMMode_Symbol
	bbs3	Sys_Status_Flag,TSMode_Symbol
	bbs4	Sys_Status_Flag,TSMode_Symbol
	bbs5	Sys_Status_Flag,YSMode_Symbol
	bbs6	Sys_Status_Flag,MSMode_Symbol
	bbs7	Sys_Status_Flag,DSMode_Symbol
	rts

RTMode_Symbol:
	ldx		#lcd_Y
	jsr		F_ClrSymbol
	ldx		#lcd_DM
	jsr		F_ClrSymbol
	rts

4DMode_Symbol:
	ldx		#lcd_D
	jsr		F_DisSymbol
	ldx		#lcd_COL
	jsr		F_ClrSymbol
	ldx		#lcd_DM
	jsr		F_ClrSymbol
	ldx		#lcd_Y
	jsr		F_ClrSymbol
	ldx		#lcd_PM
	jsr		F_ClrSymbol
	rts

TMMode_Symbol:
	ldx		#lcd_COL
	jsr		F_ClrSymbol
	ldx		#lcd_PM
	jsr		F_ClrSymbol
	rts

TSMode_Symbol:

	rts

YSMode_Symbol:
	ldx		#lcd_Y
	jsr		F_DisSymbol
	ldx		#lcd_COL
	jsr		F_ClrSymbol
	ldx		#lcd_PM
	jsr		F_ClrSymbol
	rts

MSMode_Symbol:
	ldx		#lcd_DM
	jsr		F_DisSymbol
	ldx		#lcd_Y
	jsr		F_ClrSymbol
L_No_4D_Day_MS:
	rts

DSMode_Symbol:
	ldx		#lcd_DM
	jsr		F_DisSymbol
	rts


; 判断是否为周三、周六、周天，这三天4D全天显示
L_4D_Day_Judge:
	jsr		L_GetWeek
	cmp		#00
	bne		No_Sunday
	smb3	Random_Flag
	rts
No_Sunday:
	cmp		#03
	bne		No_Wednesday
	smb3	Random_Flag
	rts
No_Wednesday:
	cmp		#06
	bne		No_Saturday
	smb3	Random_Flag
	rts
No_Saturday:
	rmb3	Random_Flag
	rts


L_4D_Day_Display:
	bbs1	Sys_Status_Flag,L_No_4D_Day			; 如果在4D模式则由4D模式接管4D亮灭
	jsr		L_4D_Day_Judge						; 判断是否为4D日
	bbs3	Random_Flag,L_4D_Day
	ldx		#lcd_D
	jsr		F_ClrSymbol
	bra		L_No_4D_Day
L_4D_Day:
	ldx		#lcd_D
	jsr		F_DisSymbol
L_No_4D_Day:
	rts




L_LSR_4Bit:
	clc
	ror
	ror
	ror
	ror
	rts


;================================================
;十进制转十六进制
L_A_DecToHex:
	sta		P_Temp								; 将十进制输入保存到 P_Temp
	lda		#0									; 初始化高位寄存器
	sta		P_Temp+1							; 高位清零
	sta		P_Temp+2							; 低位清零

L_DecToHex_Loop:
	lda		P_Temp								; 读取当前十进制值
	cmp		#10
	bcc		L_DecToHex_End						; 如果小于16，则跳到结束

	sec											; 启用借位
	sbc		#10									; 减去16
	sta		P_Temp								; 更新十进制值
	inc		P_Temp+1							; 高位+1，累加十六进制的十位

	bra		L_DecToHex_Loop						; 重复循环

L_DecToHex_End:
	lda		P_Temp								; 最后剩余的值是低位
	sta		P_Temp+2							; 存入低位

	lda		P_Temp+1							; 将高位放入A寄存器准备结果组合
	clc
	rol
	rol
	rol
	rol											; 左移4次，完成乘16
	clc
	adc		P_Temp+2							; 加上低位值

	rts
