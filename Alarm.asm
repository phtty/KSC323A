F_Alarm_Display:
	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol

	jsr		F_Display_Alarm

	lda		Sys_Status_Ordinal
	bne		No_Alarm1_Display
	ldx		#led_AL1
	jsr		F_DisSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	bra		Alarm_Display_Exit
No_Alarm1_Display:
	cmp		#1
	bne		No_Alarm2_Display
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_DisSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	bra		Alarm_Display_Exit
No_Alarm2_Display:
	cmp		#2
	bne		Alarm_Display_Exit
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_DisSymbol
Alarm_Display_Exit:
	rts



F_Alarm_Set:
	lda		Sys_Status_Ordinal
	bne		No_AL1Switch_Set
	jmp		F_Alarm_SwitchStatue
No_AL1Switch_Set:
	cmp		#1
	bne		No_AL1_HourSet
	jmp		F_AlarmHour_Set
No_AL1_HourSet:
	cmp		#2
	bne		No_AL1_MinSet
	jmp		F_AlarmMin_Set
No_AL1_MinSet:
	cmp		#3
	bne		No_AL2Switch_Set
	jmp		F_Alarm_SwitchStatue
No_AL2Switch_Set:
	cmp		#4
	bne		No_AL2_HourSet
	jmp		F_AlarmHour_Set
No_AL2_HourSet:
	cmp		#5
	bne		No_AL2_MinSet
	jmp		F_AlarmMin_Set
No_AL2_MinSet:
	cmp		#6
	bne		No_AL3Switch_Set
	jmp		F_Alarm_SwitchStatue
No_AL3Switch_Set:
	cmp		#7
	bne		No_AL3_HourSet
	jmp		F_AlarmHour_Set
No_AL3_HourSet:
	jmp		F_AlarmMin_Set
	rts




; 闹钟开关显示
F_Alarm_SwitchStatue:
	pha
	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol
	pla

	jsr		L_A_Div_3							; sys ordinal除以3得到左移的量
	txa
	lda		#1
	jsr		L_A_LeftShift_XBit					; 把1左移相应位计算出当前的闹钟开关的位号
	and		Alarm_Switch						; 和闹钟开关状态相与得出该位号是开还是关

	beq		ALSwitch_DisOff
	lda		#13
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot					; 显示ON

	lda		#14
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot

	bra		ALSwitch_DisNum

ALSwitch_DisOff:
	lda		#16
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot					; 显示OFF

	lda		#16
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot

ALSwitch_DisNum:								; 显示闹钟序号
	lda		#15
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot

	lda		Sys_Status_Ordinal
	bne		AlamNumDis2
	lda		#1
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts
AlamNumDis2:
	cmp		#3
	bne		AlamNumDis3
	lda		#2
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts
AlamNumDis3:
	lda		#3
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts




F_AlarmHour_Set:
	bbs0	Timer_Flag,L_AlarmHour_Set
	rts
L_AlarmHour_Set:
	rmb0	Timer_Flag

	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol

	lda		Sys_Status_Ordinal					; 保存子模式序号
	pha
	clc
	ror											; 将设置模式的序号除以2
	beq		Alarm_Serial_HourOut				; 再减1即可得到显示模式的序号
	sec											; 如果除以2之后为0则不用减
	sbc		#1
Alarm_Serial_HourOut:
	sta		Sys_Status_Ordinal					; 为了调用显示闹钟函数，子模式序号改为闹钟显示模式

	bbs0	Key_Flag,L_AlarmHour_Display		; 有按键时直接常亮
	bbs1	Timer_Flag,L_AlarmHour_Clear
L_AlarmHour_Display:
	jsr		L_DisAlarm_Hour
	jsr		L_DisAlarm_Min
	bra		AlarmHour_Set_Exit
L_AlarmHour_Clear:
	rmb1	Timer_Flag							; 清1S标志
	jsr		F_UnDisplay_Hour
AlarmHour_Set_Exit:
	pla
	sta		Sys_Status_Ordinal					; 将子模式序号恢复为闹钟设置模式版本
	rts




F_AlarmMin_Set:
	bbs0	Timer_Flag,L_AlarmMin_Set
	rts
L_AlarmMin_Set:
	rmb0	Timer_Flag

	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol

	lda		Sys_Status_Ordinal					; 保存子模式序号
	pha
	clc
	ror											; 将设置模式的序号除以4
	clc
	ror
	sta		Sys_Status_Ordinal					; 为了调用显示闹钟函数，子模式序号改为闹钟显示模式

	bbs0	Key_Flag,L_AlarmMin_Display			; 有按键时直接常亮
	bbs1	Timer_Flag,L_AlarmMin_Clear
L_AlarmMin_Display:
	jsr		L_DisAlarm_Hour
	jsr		L_DisAlarm_Min
	bra		AlarmMin_Set_Exit
L_AlarmMin_Clear:
	rmb1	Timer_Flag							; 清1S标志
	jsr		F_UnDisplay_Min
AlarmMin_Set_Exit:
	pla
	sta		Sys_Status_Ordinal					; 将子模式序号恢复为闹钟设置模式版本
	rts




F_Alarm_Handler:
	jsr		L_IS_AlarmTrigger					; 判断闹钟是否触发
	bbr2	Clock_Flag,L_No_Alarm_Process		; 有响闹标志位再进处理
	jsr		L_Alarm_Process
	rts
L_No_Alarm_Process:
	rmb1	PADF0								; PB3 PWM输出控制
	rmb4	PADF0								; PB3配置为IO口
	rmb3	PB_TYPE								; PB3选择NMOS输出1避免漏电
	smb3	PB

	rmb6	Timer_Flag
	rmb7	Timer_Flag
	lda		#0
	sta		AlarmLoud_Counter
	rts

L_IS_AlarmTrigger:
	lda		Alarm_Switch
	bne		Alarm_Juge_Start					; 没有任何闹钟开启则不会继续
	rmb1	Clock_Flag
	rts
Alarm_Juge_Start:
	bbs3	Clock_Flag,L_Snooze

	jsr		Is_Alarm_Trigger					; 判断三组闹钟触发(只判断时、分)
	bbr1	Clock_Flag,L_CloseLoud				; 有闹钟触发标志位才会继续判断，否则直接关响闹并结束
	bbs2	Clock_Flag,L_Alarm_NoStop			; 如此时仍在响闹，则直接进入响闹持续部分
	lda		R_Time_Sec							
	cmp		#00
	bne		L_CloseLoud							; 若秒不符合，则不会开启响闹
L_Start_Loud_Juge:
	lda		R_Alarm_Hour						; 触发闹钟时，同步触发的那组闹钟至贪睡闹钟
	sta		R_Snooze_Hour						; 之后贪睡触发时只需要在贪睡闹钟的基础上加5min
	lda		R_Alarm_Min
	sta		R_Snooze_Min
	bra		L_AlarmTrigger
L_Snooze:
	lda		R_Time_Hour							; 有贪睡的情况下,用贪睡闹钟和当前时钟匹配
	cmp		R_Snooze_Hour						; 贪睡闹钟和当前时间不匹配不会进响闹模式
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
	rmb1	Clock_Flag							; 关闭闹钟触发标志
	rmb2	Clock_Flag							; 关闭响闹模式
	rmb1	RFC_Flag							; 取消禁用RFC采样
	rmb5	Clock_Flag

	rmb1	PADF0								; PB3 PWM输出控制
	rmb4	PADF0								; PB3配置为IO口
	rmb3	PB_TYPE								; PB3选择NMOS输出1避免漏电
	smb3	PB

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
	cmp		#11
	bcc		L_Alarm_Exit
	lda		#4									; 10-20S响闹的序列为4，2声
	sta		Beep_Serial
	lda		AlarmLoud_Counter
	cmp		#21
	bcc		L_Alarm_Exit
	lda		#8									; 20-30S响闹的序列为8，4声
	sta		Beep_Serial
	lda		AlarmLoud_Counter
	cmp		#31
	bcc		L_Alarm_Exit
	smb4	Clock_Flag							; 30S以上使用持续响铃

L_Alarm_Exit:
	rts


; 任意一组闹钟设定值的时、分符合当前时间，就设置闹钟触发标志位,并同步至触发闹钟
Is_Alarm_Trigger:
	rmb1	Clock_Flag							; 清空闹钟触发

	lda		R_Time_Hour
	cmp		R_Alarm1_Hour
	beq		L_Alarm1_HourMatch
L_Alarm1_NoMatch:
	lda		R_Time_Hour
	cmp		R_Alarm2_Hour
	beq		L_Alarm2_HourMatch
L_Alarm2_NoMatch:
	lda		R_Time_Hour
	cmp		R_Alarm3_Hour
	beq		L_Alarm3_HourMatch
	rmb1	Clock_Flag							; 闹钟3也不匹配，设定闹钟未触发
	rts

L_Alarm1_HourMatch:
	lda		R_Time_Min
	cmp		R_Alarm1_Min
	beq		L_Alarm1_MinMatch
	bra		L_Alarm1_NoMatch					; 闹钟1不匹配，判断闹钟2

L_Alarm2_HourMatch:
	lda		R_Time_Min
	cmp		R_Alarm2_Min
	beq		L_Alarm2_MinMatch
	bra		L_Alarm2_NoMatch					; 闹钟2不匹配，判断闹钟2

L_Alarm3_HourMatch:
	lda		R_Time_Min
	cmp		R_Alarm3_Min
	beq		L_Alarm3_MinMatch
	rmb1	Clock_Flag							; 闹钟3也不匹配，设定闹钟未触发
	rts

L_Alarm1_MinMatch:
	smb1	Clock_Flag							; 同时满足小时和分钟的匹配，才有闹钟触发
	lda		R_Alarm1_Hour						; 将符合条件的闹钟的时、分同步至触发闹钟,方便后续的判断逻辑
	sta		R_Alarm_Hour
	lda		R_Alarm1_Min
	sta		R_Alarm_Min
	rts

L_Alarm2_MinMatch:
	smb1	Clock_Flag							; 同时满足小时和分钟的匹配，才有闹钟触发
	lda		R_Alarm2_Hour						; 将符合条件的闹钟的时、分同步至触发闹钟,方便后续的判断逻辑
	sta		R_Alarm_Hour
	lda		R_Alarm2_Min
	sta		R_Alarm_Min
	rts

L_Alarm3_MinMatch:
	smb1	Clock_Flag							; 同时满足小时和分钟的匹配，才有闹钟触发
	lda		R_Alarm3_Hour						; 将符合条件的闹钟的时、分同步至触发闹钟,方便后续的判断逻辑
	sta		R_Alarm_Hour
	lda		R_Alarm3_Min
	sta		R_Alarm_Min
	rts



; X存商，A为余数
L_A_Div_3:
	ldx		#0
L_A_Div_3_Start:
	cmp		#3
	bcc		L_A_Div_3_Over
	sec
	sbc		#3
	inx
	bra		L_A_Div_3_Start
L_A_Div_3_Over:
	rts


; 将A左移X位
L_A_LeftShift_XBit:
	sta		P_Temp
Shift_Start:
	txa
	beq		Shift_End
	lda		P_Temp
	clc
	rol		P_Temp
	dex
	bra		Shift_Start
Shift_End:
	lda		P_Temp
	rts