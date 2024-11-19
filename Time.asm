F_Time_Run:
	bbs2	Timer_Flag,L_TimeRun_Add			; 有增S标志才进处理
	rts
L_TimeRun_Add:
	rmb2	Timer_Flag							; 清增S标志

	inc		R_Time_Sec
	lda		R_Time_Sec
	cmp		#60
	bcc		L_Time_SecRun_Exit					; 未发生分钟进位
	lda		#0
	sta		R_Time_Sec
	inc		R_Time_Min
	lda		R_Time_Min
	cmp		#60
	bcc		L_Time_SecRun_Exit					; 未发生小时进位
	lda		#0
	sta		R_Time_Min
	inc		R_Time_Hour
	lda		R_Time_Hour
	cmp		#24
	bcc		L_Time_SecRun_Exit					; 未发生天进位
	lda		#0
	sta		R_Time_Hour
	jsr		F_Calendar_Add
L_Time_SecRun_Exit:
	rts


F_DisTime_Run:
	bbs0	Timer_Flag,L_TimeDot_Out
	rts
L_TimeDot_Out:
	rmb0	Timer_Flag
	bbs1	Timer_Flag,L_Dot_Clear
	ldx		#lcd_COL							; 没1S亮点
	jsr		F_DisSymbol
	jsr		F_Display_Time
	bbr1	Calendar_Flag,No_Date_Add			; 如有增日期，则调用显示星期函数
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
	rts											; 半S触发时没1S标志不走时，直接返回
L_Dot_Clear:
	rmb1	Timer_Flag							; 清1S标志
	ldx		#lcd_COL							; 1S触发后必定进灭点，同时走时
	jsr		F_ClrSymbol
	jsr		F_Display_Time
	bbr1	Calendar_Flag,No_Date_Add			; 如有增日期，则显示更新后的星期
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
No_Date_Add:
	rts





F_DisTimeMode_Set:
	bbs0	Timer_Flag,L_TimeMode_BlinkStart
	rts
L_TimeMode_BlinkStart:
	rmb0	Timer_Flag
	bbs1	Timer_Flag,L_TimeMode_BlinkClear
	bbs0	Clock_Flag,L_TimeMode12h			; 判断12h还是24h模式
	lda		#2
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#4
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	bra		L_DisTimeMode_Hr
L_TimeMode12h:
	lda		#1
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#2
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
L_DisTimeMode_Hr:
	lda		#$0c
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	lda		#$0d
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot
	bbr1	Calendar_Flag,No_Date_Add			; 如有增日期，则调用显示星期函数
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
	rts											; 半S触发时没1S标志不走时，直接返回
L_TimeMode_BlinkClear:
	rmb1	Timer_Flag							; 清1S标志
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
	bbr1	Calendar_Flag,L_TimeMode_NoDateAdd	; 如有增日期，则显示更新后的星期
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
L_TimeMode_NoDateAdd:
	rts





F_DisHour_Set:
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Hour	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Hour				; 没有半S标志时不闪烁
	rts
L_Blink_Hour:
	rmb0	Timer_Flag							; 清半S标志
	bbr1	Calendar_Flag,L_No_Date_Add_HS
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
L_No_Date_Add_HS:
	bbs1	Timer_Flag,L_Hour_Clear
L_KeyTrigger_NoBlink_Hour:
	jsr		L_DisTime_Hour						; 半S亮
	jsr		L_DisTime_Min
	ldx		#lcd_COL
	jsr		F_DisSymbol
	rts
L_Hour_Clear:
	rmb1	Timer_Flag
	jsr		F_UnDisplay_Hour					; 1S灭
	ldx		#lcd_COL
	jsr		F_ClrSymbol
	rts


F_DisMin_Set:
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Min	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Min				; 没有半S标志时不闪烁
	rts
L_Blink_Min:
	rmb0	Timer_Flag							; 清半S标志
	bbr1	Calendar_Flag,L_No_Date_Add_MS
	rmb1	Calendar_Flag
	jsr		F_DisDate_Week
L_No_Date_Add_MS:
	bbs1	Timer_Flag,L_Min_Clear
L_KeyTrigger_NoBlink_Min:
	jsr		L_DisTime_Min						; 半S亮
	jsr		L_DisTime_Hour
	ldx		#lcd_COL
	jsr		F_DisSymbol
	rts
L_Min_Clear:
	rmb1	Timer_Flag
	jsr		F_UnDisplay_Min						; 1S灭
	ldx		#lcd_COL
	jsr		F_ClrSymbol
	rts
