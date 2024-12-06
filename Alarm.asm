F_DisAlarm_Set:
	bbs0	Timer_Flag,L_Blink_Alarm			; 没有半S标志时不闪烁
	rts
L_Blink_Alarm:
	rmb0	Timer_Flag							; 清半S标志
	bbr1	Calendar_Flag,L_No_Date_Add_AS		; 如有增日期，则调用显示日期函数
	rmb1	Calendar_Flag
	jsr		F_Display_Date
L_No_Date_Add_AS:
	bbs1	Timer_Flag,L_Alarm_Clear
	jsr		F_Display_Alarm						; 半S亮
	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol
	rts
L_Alarm_Clear:
	rmb1	Timer_Flag
	lda		PA
	and		#$C0
	bne		L_Blink_Alarm						; 有按键时不闪烁
	jsr		F_UnDisplay_Hour					; 1S灭
	jsr		F_UnDisplay_Min						; 1S灭
	ldx		#led_COL1
	jsr		F_ClrSymbol
	ldx		#led_COL2
	jsr		F_ClrSymbol
	jsr		F_Display_Time
	rts



F_Alarm_Handler:
	jsr		L_IS_AlarmTrigger					; 判断闹钟是否触发
	bbr2	Clock_Flag,L_No_Alarm_Process		; 有响闹标志位再进处理
	jsr		L_Alarm_Process
	rts
L_No_Alarm_Process:
	rmb0	TMRC
	rmb7	TMRC
	rmb1	PADF0								; 设置PP为CMOS输出
	smb3	PB_TYPE
	rmb3	PB
	rmb6	Timer_Flag
	rmb7	Timer_Flag
	lda		#0
	sta		AlarmLoud_Counter
	rts

L_IS_AlarmTrigger:
	bbr1	Clock_Flag,L_CloseLoud				; 没有开启闹钟拨键不会进响闹模式
	bbs3	Clock_Flag,L_Snooze
	lda		R_Time_Hour							; 没有贪睡的情况下
	cmp		R_Alarm_Hour						; 闹钟设定值和当前时间不匹配不会进响闹模式
	bne		L_CloseLoud
	lda		R_Time_Min
	cmp		R_Alarm_Min
	bne		L_CloseLoud
	bbs2	Clock_Flag,L_Alarm_NoStop
	lda		R_Time_Sec
	cmp		#00
	bne		L_CloseLoud
L_Start_Loud_Juge:
	lda		R_Alarm_Hour						; 在贪睡启动前，必定先触发设定闹钟
	sta		R_Snooze_Hour						; 此时同步设定闹钟时间至贪睡闹钟
	lda		R_Alarm_Min							; 之后贪睡触发时只需要在自己的基础上加5min
	sta		R_Snooze_Min
	bra		L_AlarmTrigger
L_Snooze:
	lda		R_Time_Hour							; 有贪睡的情况下
	cmp		R_Snooze_Hour						; 贪睡闹钟设定值和当前时间不匹配不会进响闹模式
	bne		L_Snooze_CloseLoud
	lda		R_Time_Min
	cmp		R_Snooze_Min
	bne		L_Snooze_CloseLoud
	bbs2	Clock_Flag,L_Alarm_NoStop
	lda		R_Time_Sec
	cmp		#00
	bne		L_Snooze_CloseLoud
L_AlarmTrigger:
	smb7	Timer_Flag
	smb0	TMRC
	smb2	Clock_Flag							; 开启响闹模式和蜂鸣器计时TIM0
	smb1	RFC_Flag							; 禁用RFC采样
L_Alarm_NoStop:
	bbs5	Clock_Flag,L_AlarmTrigger_Exit
	smb5	Clock_Flag							; 保存响闹模式的值,区分响闹结束状态和未响闹状态
L_AlarmTrigger_Exit:
	rts
L_Snooze_CloseLoud:
	bbr5	Clock_Flag,L_CloseLoud				; last==1 && now==0
	rmb5	Clock_Flag							; 响闹结束状态同步响闹模式的保存值
	bbr6	Clock_Flag,L_NoSnooze_CloseLoud		; 没有贪睡按键触发&&贪睡模式&&响闹结束状态才会自然结束贪睡模式
	rmb6	Clock_Flag							; 清贪睡按键触发
	bra		L_CloseLoud
L_NoSnooze_CloseLoud:							; 结束贪睡模式并关闭响闹
	rmb3	Clock_Flag
	rmb6	Clock_Flag
L_CloseLoud:
	rmb2	Clock_Flag							; 关闭响闹模式
	rmb1	RFC_Flag							; 取消禁用RFC采样
	rmb5	Clock_Flag
	rmb7	TMRC
	rmb1	PADF0
	smb3	PB_TYPE
	rmb3	PB
	rmb6	Timer_Flag
	rmb7	Timer_Flag
	rmb0	TMRC
	rts


L_Alarm_Process:
	bbs7	Timer_Flag,L_BeepStart				; 每S进一次
	rts
L_BeepStart:
	rmb7	Timer_Flag
	inc		AlarmLoud_Counter					; 响铃1次加1响铃计数
	lda		#2									; 0-10S响闹的序列为2，1声
	sta		Beep_Serial
	rmb4	Clock_Flag							; 0-30S为序列响铃
	lda		AlarmLoud_Counter
	cmp		#10
	bcc		L_Alarm_Exit
	lda		#4									; 10-20S响闹的序列为4，2声
	sta		Beep_Serial
	lda		AlarmLoud_Counter
	cmp		#20
	bcc		L_Alarm_Exit
	lda		#8									; 20-30S响闹的序列为8，4声
	sta		Beep_Serial
	lda		AlarmLoud_Counter
	cmp		#30
	bcc		L_Alarm_Exit
	smb4	Clock_Flag							; 30S以上使用持续响铃

L_Alarm_Exit:
	rts
