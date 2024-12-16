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



; 时钟显示模式
F_Clock_Display:
	bbs0	Sys_Status_Ordinal,L_DisDate_Mode
	jsr		F_Time_Display
	rts
L_DisDate_Mode:
	jsr		F_Date_Display
	rts



; 时间显示
F_Time_Display:
	bbs0	Timer_Flag,L_TimeDot_Out
	rts
L_TimeDot_Out:
	rmb0	Timer_Flag
	jsr		F_Display_Time

	bbs1	Timer_Flag,L_Dot_Clear
	ldx		#led_COL1							; 没1S标志亮点
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol
	rts											; 半S触发时没1S标志不走时，直接返回
L_Dot_Clear:
	rmb1	Timer_Flag							; 清1S标志
	ldx		#led_COL1							; 有1S标志灭点
	jsr		F_ClrSymbol
	ldx		#led_COL2
	jsr		F_ClrSymbol
	rts



; 轮流显示
F_Rotate_Display:
	bbs0	Timer_Flag,Rotate_Start
	rts
Rotate_Start:
	inc		CC0
	lda		CC0
	cmp		#11
	bcs		L_Rotate_DateMode
	jsr		F_Time_Display
	rts
L_Rotate_DateMode:
	cmp		#16
	bcs		L_Rotate_TimeMode
	rmb0	Timer_Flag
	jsr		F_Date_Display
	rts
L_Rotate_TimeMode:
	lda		#0
	sta		CC0
	rts




F_Clock_Set:
	lda		Sys_Status_Ordinal
	bne		No_TMSwitch_Display
	jmp		F_Display_Time						; 12/24h模式切换
No_TMSwitch_Display:
	cmp		#1
	bne		No_HourSet_Display
	jmp		F_DisHour_Set
No_HourSet_Display:
	cmp		#2
	bne		No_MinSet_Display
	jmp		F_DisMin_Set
No_MinSet_Display:
	cmp		#3
	bne		No_YearSet_Display
	jmp		F_DisYear_Set
No_YearSet_Display:
	cmp		#4
	bne		No_MonthSet_Display
	jmp		F_DisMonth_Set
No_MonthSet_Display:
	jmp		F_DisDay_Set

	rts




F_DisHour_Set:
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Hour	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Hour				; 没有半S标志时不闪烁
	rts
L_Blink_Hour:
	rmb0	Timer_Flag							; 清半S标志

	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol

	bbs1	Timer_Flag,L_Hour_Clear
L_KeyTrigger_NoBlink_Hour:
	jsr		L_DisTime_Hour						; 半S亮
	jsr		L_DisTime_Min
	rts
L_Hour_Clear:
	rmb1	Timer_Flag
	jsr		F_UnDisplay_Hour					; 1S灭
	rts


F_DisMin_Set:
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Min	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Min				; 没有半S标志时不闪烁
	rts
L_Blink_Min:
	rmb0	Timer_Flag							; 清半S标志

	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol

	bbs1	Timer_Flag,L_Min_Clear
L_KeyTrigger_NoBlink_Min:
	jsr		L_DisTime_Min						; 半S亮
	jsr		L_DisTime_Hour
	rts
L_Min_Clear:
	rmb1	Timer_Flag
	jsr		F_UnDisplay_Min						; 1S灭
	rts
