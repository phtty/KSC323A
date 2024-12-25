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
	ldx		#led_PM								; 12h模式AM需要灭PM点
	jsr		F_ClrSymbol
	lda		R_Time_Hour							; 改显存函数会改A值，重新取变量
	cmp		#0
	beq		L_Time_0Hour
	bra		L_Start_DisTime_Hour
L_Time12h_PM:
	ldx		#led_PM								; 12h模式PM需要亮PM点
	jsr		F_DisSymbol
	lda		R_Time_Hour							; 改显存函数会改A值，重新取变量
	sec
	sbc		#12
	cmp		#0
	bne		L_Start_DisTime_Hour
L_Time_0Hour:									; 12h模式0点需要变成12点
	lda		#12
	bra		L_Start_DisTime_Hour

L_24hMode_Time:
	ldx		#led_PM								; 24h模式下需要灭PM点
	jsr		F_ClrSymbol
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

F_UnDisplay_Hour:
	lda		#10
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	rts

F_UnDisplay_Min:
	lda		#10
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts




; Sys_Status_Ordinal = 闹钟序号
F_Display_Alarm:									; 调用显示函数显示当前闹钟
	jsr		L_DisAlarm_Min
	jsr		L_DisAlarm_Hour
	rts

L_DisAlarm_Min:
	lda		Sys_Status_Ordinal						; 判断要显示三组闹钟的哪一个
	cmp		#0
	bne		No_Alarm1Min_Display
	lda		R_Alarm1_Min
	sta		R_Alarm_Min
	bra		AlarmMin_Display_Start
No_Alarm1Min_Display:
	cmp		#1
	bne		No_Alarm2Min_Display
	lda		R_Alarm2_Min
	sta		R_Alarm_Min
	bra		AlarmMin_Display_Start
No_Alarm2Min_Display:
	lda		R_Alarm3_Min
	sta		R_Alarm_Min
AlarmMin_Display_Start:
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
	sta		R_Alarm_Hour
	bra		AlarmHour_Display_Start
No_Alarm1Hour_Display:
	cmp		#1
	bne		No_Alarm2Hour_Display
	lda		R_Alarm2_Hour
	sta		R_Alarm_Hour
	bra		AlarmHour_Display_Start
No_Alarm2Hour_Display:
	lda		R_Alarm3_Hour
	sta		R_Alarm_Hour
AlarmHour_Display_Start:
	bbr0	Clock_Flag,L_24hMode_Alarm

	lda		R_Alarm_Hour
	jsr		L_A_DecToHex
	cmp		#12
	bcs		L_Alarm12h_PM
	ldx		#led_PM								; 12h模式AM需要灭PM点
	jsr		F_ClrSymbol
	lda		R_Alarm_Hour						; 改显存函数会改A值，重新取变量
	cmp		#0
	beq		L_Alarm_0Hour
	bra		L_Start_DisAlarm_Hour
L_Alarm12h_PM:
	ldx		#led_PM								; 12h模式PM需要亮PM点
	jsr		F_DisSymbol
	lda		R_Alarm_Hour						; 改显存函数会改A值，重新取变量
	sec
	sbc		#12
	cmp		#0
	bne		L_Start_DisAlarm_Hour
L_Alarm_0Hour:									; 12h模式0点需要变成12点
	lda		#12
	bra		L_Start_DisAlarm_Hour

L_24hMode_Alarm:
	ldx		#led_PM								; 24h模式下需要灭PM点
	jsr		F_ClrSymbol
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
	jsr		L_A_DecToHex						; 所以20固定会显示
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


F_UnDisplay_Year:								; 闪烁时取消显示用的函数
	lda		#10
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts

F_UnDisplay_Month:								; 闪烁时取消显示用的函数
	lda		#10
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	rts

F_UnDisplay_Day:								; 闪烁时取消显示用的函数
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
	ldx		#led_week
	jsr		L_Dis_7Bit_WeekDot
	rts



; 显示温度函数
F_Display_Temper:
	lda		R_Temperature
	bbr4	RFC_Flag,Juge_DegreeMode_Over
	jsr		F_C2F
	txa
	sta		R_Temperature_F
Juge_DegreeMode_Over:
	jsr		L_A_DecToHex						; 转化为16进制
	pha
	and		#$0f
	ldx		#led_d6
	jsr		L_Dis_7Bit_DigitDot
	pla
	pha
	and		#$f0
	jsr		L_LSR_4Bit
	ldx		#led_d5
	jsr		L_Dis_7Bit_DigitDot

	pla
	bbr4	RFC_Flag,L_Celsius_Degree
	lda		R_Temperature_F
	ldx		#led_d4
	jsr		L_Dis_2Bit_DigitDot

	lda		#1									; 显示华氏度F
	ldx		#led_d7
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_TMP
	jsr		F_DisSymbol
	rts

L_Celsius_Degree:
	lda		#0									; 显示摄氏度C
	ldx		#led_d7
	jsr		L_Dis_7Bit_WordDot

	ldx		#led_TMP
	jsr		F_DisSymbol

	rts


; 显示湿度函数
F_Display_Humid:
	lda		R_Humidity
	beq		?Minus_Temper						; 温度为负时，没有湿度
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
?Minus_Temper:
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

	bbr2	RFC_Flag,No_Minus_Temper
	ldx		#led_minus
	jsr		F_DisSymbol
	rts
No_Minus_Temper:
	ldx		#led_minus
	jsr		F_ClrSymbol
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
	ldx		#led_AL1
	jsr		F_DisSymbol
	rts
Group2_Bright:
	ldx		#led_AL2
	jsr		F_DisSymbol
	rts
Group3_Bright:
	ldx		#led_AL1
	jsr		F_DisSymbol
	rts
	
L_ALM_Dot_Clr:
	rmb1	Symbol_Flag							; ALM点1S标志
	bbs0	Triggered_AlarmGroup,Group1_Extinguish
	bbs1	Triggered_AlarmGroup,Group2_Extinguish
	bbs2	Triggered_AlarmGroup,Group3_Extinguish
Group1_Extinguish:
	ldx		#led_AL1
	jsr		F_ClrSymbol
	rts
Group2_Extinguish:
	ldx		#led_AL2
	jsr		F_ClrSymbol
	rts
Group3_Extinguish:
	ldx		#led_AL1
	jsr		F_ClrSymbol
	rts



; 非闹钟显示状态下，显示开启的闹钟
F_AlarmSW_Display:
	bbs3	Clock_Flag,F_AlarmSW_Exit			; 贪睡时，被闪点子程序接管
	lda		Sys_Status_Flag
	cmp		#2
	bne		Alarm1_Switch						; 在闹钟显示模式下，不控制闹钟组的点显示
F_AlarmSW_Exit:
	rts

Alarm1_Switch:
	lda		Alarm_Switch
	and		#001B
	beq		Alarm1_Switch_Off
	ldx		#led_AL1
	jsr		F_DisSymbol
	bra		Alarm2_Switch
Alarm1_Switch_Off:
	ldx		#led_AL1
	jsr		F_ClrSymbol

Alarm2_Switch:
	lda		Alarm_Switch
	and		#010B
	beq		Alarm2_Switch_Off
	ldx		#led_AL2
	jsr		F_DisSymbol
	bra		Alarm3_Switch
Alarm2_Switch_Off:
	ldx		#led_AL2
	jsr		F_ClrSymbol

Alarm3_Switch:
	lda		Alarm_Switch
	and		#100B
	beq		Alarm3_Switch_Off
	ldx		#led_AL3
	jsr		F_DisSymbol
	rts
Alarm3_Switch_Off:
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts



F_RD_DP_Display:
	bbs6	Key_Flag,RD_DP_Dis				; 没有轮显/时显互相切换标志则直接退出
	rts
RD_DP_Dis:
	bbs7	Key_Flag,RD_DP_Dis_Juge			; 等待1S标志到来，增加计数
	pla
	pla
	rts
RD_DP_Dis_Juge:
	rmb7	Key_Flag
	inc		Counter_DP
	lda		Counter_DP
	cmp		#5
	beq		RD_DP_Dis_Over					; 计满5s前一直显示DP

	jsr		L_Dis_dp_2
	
	pla										; 等待1S标志到来，增加计数
	pla
	rts
RD_DP_Dis_Over:
	lda		#0
	sta		Counter_DP
	rmb6	Key_Flag
	rts



F_CD_DP_Display:
	bbs6	Key_Flag,CD_DP_Dis				; 没有轮显/时显互相切换标志则直接退出
	rts
CD_DP_Dis:
	bbs7	Key_Flag,CD_DP_Dis_Juge			; 等待1S标志到来，增加计数
	pla
	pla
	rts
CD_DP_Dis_Juge:
	rmb7	Key_Flag
	inc		Counter_DP
	lda		Counter_DP
	cmp		#5
	beq		DP_Dis_Over						; 计满5s前一直显示DP

	jsr		L_Dis_dp_1

	pla										; 等待1S标志到来，增加计数
	pla
	rts
DP_Dis_Over:
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



F_C2F:
	lda		R_Temperature
	sta		P_Temp							; 初始化一些变量

	lda		#0
	sta		P_Temp+1

	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1
	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1
	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1


	lda		P_Temp
	clc
	adc		R_Temperature					; 加上它自身完成乘9
	sta		P_Temp
	lda		P_Temp+1
	adc		#0
	sta		P_Temp+1

	ldx		#0								; 使用X寄存器来计数商
?Div_By_5_Loop:
	lda		P_Temp+1
	bne		?Div_By_5_Loop_Start			; 有高8位的时候，直接减
	lda		P_Temp							; 无高8位时，再判断低8位的情况
	cmp		#5
	bcc		?Loop_Over
?Div_By_5_Loop_Start:
	lda		P_Temp
	sec
	sbc		#5
	sta		P_Temp
	lda		P_Temp+1
	sbc		#0
	sta		P_Temp+1
	inx
	bra		?Div_By_5_Loop
?Loop_Over:
	stx		P_Temp							; 算出除以5的值
	bbs2	RFC_Flag,Minus_Temper
	txa
	clc
	adc		#32								; 正温度时，直接加上32即为华氏度结果
	sta		R_Temperature_F
	rts

Minus_Temper:								; 处理负温度的情况
	lda		#32
	sec
	sbc		P_Temp							; 负数温度则是32-计算值
	sta		R_Temperature_F
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
	ldx		#0
	lda		#0									; 初始化高位寄存器
	sta		P_Temp+1							; 高位清零
	sta		P_Temp+2							; 低位清零

L_DecToHex_Loop:
	lda		P_Temp								; 读取当前十进制值
	cmp		#10
	bcc		L_DecToHex_End						; 如果小于10，则跳到结束

	sec											; 启用借位
	sbc		#10									; 减去10
	sta		P_Temp								; 更新十进制值
	inc		P_Temp+1							; 高位+1，累加十六进制的十位

	bra		L_DecToHex_Loop						; 重复循环

L_DecToHex_End:
	lda		P_Temp								; 最后剩余的值是低位
	sta		P_Temp+2							; 存入低位

	lda		P_Temp+1							; 将高位放入A寄存器准备结果组合
	cmp		#10
	bcc		No_3Positions
	sec
	sbc		#10
	sta		P_Temp+1
	inx
No_3Positions:
	clc
	rol
	rol
	rol
	rol											; 左移4次，完成乘16
	clc
	adc		P_Temp+2							; 加上低位值

	rts
