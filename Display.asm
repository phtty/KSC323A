F_Display_Time:									; 调用显示函数显示当前时间
	jsr		L_DisTime_Min
	jsr		L_DisTime_Hour
	rts

L_DisTime_Min:
	lda		R_Time_Min
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	rts	

L_DisTime_Hour:									; 显示小时
	bbr0	Clock_Flag,L_24hMode_Time
	lda		R_Time_Hour
	cmp		#12
	bcs		L_Time12h_PM
	jsr		F_ClrPM								; 12h模式AM需要灭PM点
	lda		R_Time_Hour							; 改显存函数会改A值，重新取变量
	cmp		#0
	beq		L_Time_0Hour
	bra		L_Start_DisTime_Hour
L_Time12h_PM:
	jsr		F_DisPM								; 12h模式PM需要亮PM点
	lda		R_Time_Hour							; 改显存函数会改A值，重新取变量
	sec
	sbc		#12
	cmp		#0
	bne		L_Start_DisTime_Hour
L_Time_0Hour:									; 12h模式0点需要变成12点
	lda		#12
	bra		L_Start_DisTime_Hour

L_24hMode_Time:
	jsr		F_ClrPM								; 24h模式下需要灭PM点
	lda		R_Time_Hour
L_Start_DisTime_Hour:
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Hour_Tens_NoZero					; 小时模式的十位0不显示
	lda		#$0a
L_Hour_Tens_NoZero:
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	rts 




; Sys_Status_Ordinal = 闹钟序号
F_Display_Alarm:								; 调用显示函数显示当前闹钟
	jsr		L_DisAlarm_Min
	jsr		L_DisAlarm_Hour
	rts

L_DisAlarm_Min:
	lda		Sys_Status_Ordinal					; 判断要显示三组闹钟的哪一个
	bne		No_Alarm1Min_Display
	lda		R_Alarm1_Min
	bra		AlarmMin_Display_Start
No_Alarm1Min_Display:
	cmp		#1
	bne		No_Alarm2Min_Display
	lda		R_Alarm2_Min
	bra		AlarmMin_Display_Start
No_Alarm2Min_Display:
	lda		R_Alarm3_Min
AlarmMin_Display_Start:
	sta		R_Alarm_Min
	lda		R_Alarm_Min

	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	rts	

L_DisAlarm_Hour:								; 显示闹钟小时
	lda		Sys_Status_Ordinal					; 判断要显示三组闹钟的哪一个
	cmp		#0
	bne		No_Alarm1Hour_Display
	lda		R_Alarm1_Hour
	bra		AlarmHour_Display_Start
No_Alarm1Hour_Display:
	cmp		#1
	bne		No_Alarm2Hour_Display
	lda		R_Alarm2_Hour
	bra		AlarmHour_Display_Start
No_Alarm2Hour_Display:
	lda		R_Alarm3_Hour
AlarmHour_Display_Start:
	sta		R_Alarm_Hour
	bbr0	Clock_Flag,L_24hMode_Alarm

	lda		R_Alarm_Hour
	cmp		#12
	bcs		L_Alarm12h_PM
	jsr		F_ClrPM								; 12h模式AM需要灭PM点
	lda		R_Alarm_Hour						; 改显存函数会改A值，重新取变量
	cmp		#0
	beq		L_Alarm_0Hour
	bra		L_Start_DisAlarm_Hour
L_Alarm12h_PM:
	jsr		F_DisPM								; 12h模式PM需要亮PM点
	lda		R_Alarm_Hour						; 改显存函数会改A值，重新取变量
	sec
	sbc		#12
	cmp		#0
	bne		L_Start_DisAlarm_Hour
L_Alarm_0Hour:									; 12h模式0点需要变成12点
	lda		#12
	bra		L_Start_DisAlarm_Hour

L_24hMode_Alarm:
	jsr		F_ClrPM								; 24h模式下需要灭PM点
	lda		R_Alarm_Hour
L_Start_DisAlarm_Hour:
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_AlarmHour_Tens_NoZero				; 小时模式的十位0不显示
	lda		#$0a
L_AlarmHour_Tens_NoZero:
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
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
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Day_Tens_NoZero					; 日期十位0不显示
	lda		#10
L_Day_Tens_NoZero:
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	rts

L_DisDate_Month:
	lda		R_Date_Month
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Month_Tens_NoZero					; 月份十位0不显示
	lda		#10
L_Month_Tens_NoZero:
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	rts

L_DisDate_Year:
	lda		#00									; 20xx年的开头20是固定的
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	lda		#02
	jsr		L_A_DecToHex
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot

	lda		R_Date_Year							; 显示当前的年份
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	rts




F_UnDisplay_D0_1:								; 闪烁时取消显示用的函数
	lda		#10
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	rts


F_UnDisplay_D2_3:								; 闪烁时取消显示用的函数
	lda		#10
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts




F_Display_Week:
	jsr		L_GetWeek
	sta		R_Date_Week

	rmb2	Calendar_Flag
	ldx		#led_week1
	jsr		L_Dis_7Bit_WeekDot
	smb2	Calendar_Flag
	lda		R_Date_Week
	ldx		#led_week2
	jsr		L_Dis_7Bit_WeekDot
	rts



; 显示温度函数
F_Display_Temper:
	ldx		#led_minus
	jsr		F_ClrSymbol							; 清负号显示
	lda		#0
	jsr		L_Dis_2Bit_DigitDot					; 清温度百位显示
	lda		#10
	ldx		#led_d7
	jsr		L_Dis_7Bit_DigitDot					; 清理温度单位显示

	bbr4	RFC_Flag,Dis_CDegree
	jmp		Display_FahrenheitDegree
Dis_CDegree:
	jmp		Display_CelsiusDegree


Display_CelsiusDegree:
	lda		R_Temperature
	jsr		L_A_DecToHex
	sta		P_Temp+7
	and		#$0f
	ldx		#led_d6
	jsr		L_Dis_7Bit_DigitDot
	lda		P_Temp+7
	and		#$f0
	beq		Degree_NoTens						; 高4位为0，则d5不显示
	jsr		L_LSR_4Bit
	ldx		#led_d5
	jsr		L_Dis_7Bit_DigitDot
	bra		Dis_CelSymbol
Degree_NoTens:
	lda		#10
	ldx		#led_d5
	jsr		L_Dis_7Bit_DigitDot
	bbr2	RFC_Flag,NoMinusTemper				; 温度是个位负数时，d5显示负号

	ldx		#led_d5+6
	jsr		F_DisSymbol
	bra		NoMinusTemper

Dis_CelSymbol:
	bbr2	RFC_Flag,NoMinusTemper				; 温度为十位负数时，d4显示负号
	ldx		#led_minus
	jsr		F_DisSymbol

NoMinusTemper:
	lda		#0									; 显示摄氏度C
	ldx		#led_d7
	jsr		L_Dis_7Bit_WordDot
	rts


Display_FahrenheitDegree:
	jsr		F_C2F
	lda		R_Temperature_F
	jsr		L_A_DecToHex
	
	pha
	txa
	jsr		L_Dis_2Bit_DigitDot
	pla
	pha
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d5
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$0f
	ldx		#led_d6
	jsr		L_Dis_7Bit_DigitDot
	lda		#1									; 显示华氏度C
	ldx		#led_d7
	jsr		L_Dis_7Bit_WordDot
	rts





; 显示湿度函数
F_Display_Humid:
	lda		R_Humidity
	beq		DisHumid_MinusTemper				; 温度为负时，不显示湿度
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d9
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d8
	jsr		L_Dis_7Bit_DigitDot
	rts
DisHumid_MinusTemper:
	lda		#9
	ldx		#led_d8
	jsr		L_Dis_7Bit_WordDot
	lda		#9
	ldx		#led_d9
	jsr		L_Dis_7Bit_WordDot
	rts



F_SymbolRegulate:								; 显示常亮点
	ldx		#led_TMP
	jsr		F_DisSymbol
	ldx		#led_Per1
	jsr		F_DisSymbol
	ldx		#led_Per2
	jsr		F_DisSymbol

	jsr		L_ALMDot_Blink
	jsr		F_AlarmSW_Display
	rts


; 贪睡时闪ALM点
L_ALMDot_Blink:
	bbr3	Clock_Flag,L_SymbolDis_Exit			; 如果非贪睡状态，则不进此子程序
	bbs0	Symbol_Flag,L_SymbolDis
L_SymbolDis_Exit:
	rts
L_SymbolDis:
	rmb0	Symbol_Flag							; ALM点半S标志
	bbs1	Symbol_Flag,L_ALM_Dot_Clr
L_ALM_Dot_Dis:
	bbs0	Triggered_AlarmGroup,Group1_Bright
	bbs1	Triggered_AlarmGroup,Group2_Bright
	bbs2	Triggered_AlarmGroup,Group3_Bright
Group1_Bright:
	jsr		F_DisAL1
	rts
Group2_Bright:
	jsr		F_DisAL2
	rts
Group3_Bright:
	jsr		F_DisAL3
	rts
	
L_ALM_Dot_Clr:
	rmb1	Symbol_Flag							; ALM点1S标志
	bbs0	Triggered_AlarmGroup,Group1_Extinguish
	bbs1	Triggered_AlarmGroup,Group2_Extinguish
	bbs2	Triggered_AlarmGroup,Group3_Extinguish
Group1_Extinguish:
	jsr		F_ClrAL1
	rts
Group2_Extinguish:
	jsr		F_ClrAL2
	rts
Group3_Extinguish:
	jsr		F_ClrAL3
	rts



; 非闹钟显示状态下，显示开启的闹钟
F_AlarmSW_Display:
	bbs3	Clock_Flag,F_AlarmSW_Exit			; 贪睡时，被闪点子程序接管
	lda		Sys_Status_Flag
	cmp		#0010B
	bne		Alarm1_Switch						; 在闹钟显示模式下，不控制闹钟组的点显示
F_AlarmSW_Exit:
	rts

Alarm1_Switch:
	lda		Alarm_Switch
	and		#001B
	beq		Alarm1_Switch_Off
	jsr		F_DisAL1
	bra		Alarm2_Switch
Alarm1_Switch_Off:
	jsr		F_ClrAL1

Alarm2_Switch:
	lda		Alarm_Switch
	and		#010B
	beq		Alarm2_Switch_Off
	jsr		F_DisAL2
	bra		Alarm3_Switch
Alarm2_Switch_Off:
	jsr		F_ClrAL2

Alarm3_Switch:
	lda		Alarm_Switch
	and		#100B
	beq		Alarm3_Switch_Off
	jsr		F_DisAL3
	rts
Alarm3_Switch_Off:
	jsr		F_ClrAL3
	rts




F_DP_Display:
	bbs6	Key_Flag,DP_Display				; 没有DP显示标志则显示时钟
	rts
DP_Display:
	jsr		F_ClrCol						; DP显示需要灭秒点和PM点
	jsr		F_ClrPM
	bbs7	Key_Flag,DP_Display_Juge		; 在DP显示里，如果没1S则不继续显示时钟，直接退出
	pla
	pla
	rts
DP_Display_Juge:
	rmb7	Key_Flag
	inc		Counter_DP
	lda		Counter_DP
	cmp		#6
	beq		DP_Display_Over					; 计满5s前一直显示DP

	bbs2	Key_Flag,DP_RDMode
	jsr		L_Dis_dp_1						; 固显DP-1
	bra		DP_Mode_Return
DP_RDMode:
	jsr		L_Dis_dp_2						; 轮显DP-2
DP_Mode_Return:
	pla										; 等待1S标志到来，增加计数
	pla
	rts
DP_Display_Over:
	lda		#0
	sta		Counter_DP
	rmb6	Key_Flag
	rts


L_Dis_dp_1:
	ldx		#led_d0
	lda		#5
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d1
	lda		#6
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d2
	lda		#9
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d3
	lda		#1
	jsr		L_Dis_7Bit_DigitDot
	rts


L_Dis_dp_2:
	ldx		#led_d0
	lda		#5
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d1
	lda		#6
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d2
	lda		#9
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d3
	lda		#2
	jsr		L_Dis_7Bit_DigitDot
	rts


L_Dis_xxHr:
	ldx		#led_d3
	lda		#8
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_d2
	lda		#7
	jsr		L_Dis_7Bit_WordDot

	bbr0	Clock_Flag,L_24hMode_Set
	ldx		#led_d1
	lda		#2
	jsr		L_Dis_7Bit_DigitDot
	ldx		#led_d0
	lda		#1
	jsr		L_Dis_7Bit_DigitDot
	rts
L_24hMode_Set:
	ldx		#led_d1
	lda		#4
	jsr		L_Dis_7Bit_DigitDot
	ldx		#led_d0
	lda		#2
	jsr		L_Dis_7Bit_DigitDot
	rts



; 亮秒点
F_DisCol:
	ldx		#led_COL1
	jsr		F_DisSymbol
	ldx		#led_COL2
	jsr		F_DisSymbol
	rts

; 灭秒点
F_ClrCol:
	ldx		#led_COL1
	jsr		F_ClrSymbol
	ldx		#led_COL2
	jsr		F_ClrSymbol
	rts

; 亮PM点
F_DisPM:
	ldx		#led_PM
	jsr		F_DisSymbol
	rts

; 灭PM点
F_ClrPM:
	ldx		#led_PM
	jsr		F_ClrSymbol
	rts

; 亮AL1点
F_DisAL1:
	ldx		#led_AL1
	jsr		F_DisSymbol
	rts

; 灭AL1点
F_ClrAL1:
	ldx		#led_AL1
	jsr		F_ClrSymbol
	rts

; 亮AL2点
F_DisAL2:
	ldx		#led_AL2
	jsr		F_DisSymbol
	rts

; 灭AL2点
F_ClrAL2:
	ldx		#led_AL2
	jsr		F_ClrSymbol
	rts

; 亮AL3点
F_DisAL3:
	ldx		#led_AL3
	jsr		F_DisSymbol
	rts

; 灭AL3点
F_ClrAL3:
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts



L_LSR_4Bit:
	clc
	ror
	ror
	ror
	ror
	rts



; 将256以内的数以十进制存储在十六进制格式中
; A==转换的数，X==百位
L_A_DecToHex:
	sta		P_Temp								; 将十进制输入保存到P_Temp
	ldx		#0
	lda		#0
	sta		P_Temp+1							; 十位清零
	sta		P_Temp+2							; 个位清零

L_DecToHex_Loop:
	lda		P_Temp
	cmp		#10
	bcc		L_DecToHex_End						; 如果小于10，则不用转换

	sec
	sbc		#10									; 减去10
	sta		P_Temp								; 更新十进制值
	inc		P_Temp+1							; 十位+1，累加十六进制的十位
	bra		L_DecToHex_Loop						; 重复循环

L_DecToHex_End:
	lda		P_Temp								; 最后剩余的值是个位
	sta		P_Temp+2							; 存入个位

Juge_3Positions:
	lda		P_Temp+1							; 将十位放入A寄存器组合
	cmp		#10
	bcc		No_3Positions						; 判断是否有百位
	sec
	sbc		#10
	sta		P_Temp+1
	inx
	bra		Juge_3Positions
No_3Positions:
	clc
	rol
	rol
	rol
	rol											; 左移4次，完成乘16
	clc
	adc		P_Temp+2							; 加上个位值

	rts
