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
	ldx		#led_d1
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Day_Tens_NoZero					; 日期十位0不显示
	lda		#10
L_Day_Tens_NoZero:
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	rts

L_DisDate_Month:
	lda		R_Date_Month
	jsr		L_A_DecToHex
	pha
	and		#$0f
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	pla
	and		#$f0
	jsr		L_LSR_4Bit
	bne		L_Month_Tens_NoZero					; 月份十位0不显示
	lda		#10
L_Month_Tens_NoZero:
	ldx		#led_d2
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
	ldx		#led_d2
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d3
	jsr		L_Dis_7Bit_DigitDot
	rts

F_UnDisplay_Day:								; 闪烁时取消显示用的函数
	lda		#10
	ldx		#led_d0
	jsr		L_Dis_7Bit_DigitDot
	lda		#10
	ldx		#led_d1
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

	lda		#12									; 显示华氏度F
	ldx		#led_d7
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_TMP
	jsr		F_DisSymbol
	rts

L_Celsius_Degree:
	lda		#11									; 显示摄氏度C
	ldx		#led_d7
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_TMP
	jsr		F_DisSymbol

	rts



F_Display_Humid:
	lda		R_Humidity
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



F_SymbolRegulate:
	lda		Sys_Status_Flag
	bne		?No_ClockDis_Mode
	lda		Sys_Status_Ordinal					; 时钟模式日期显示需要灭PM点
	beq		?No_ClockDis_Mode
	ldx		#led_PM
	jsr		F_ClrSymbol
	ldx		#led_COL1
	jsr		F_ClrSymbol
	ldx		#led_COL2
	jsr		F_ClrSymbol
	rts

?No_ClockDis_Mode:
	cmp		#2
	bne		?No_AlarmDis_Mode
	lda		Sys_Status_Ordinal					; 闹钟模式需要显示对应闹组的点
	beq		?No_Alarm_1ON
	ldx		#led_AL1
	jsr		F_DisSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts
?No_Alarm_1ON:
	cmp		#1
	bne		?No_Alarm_2ON
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_DisSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts
?No_Alarm_2ON:
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_DisSymbol
	rts

?No_AlarmDis_Mode:
	cmp		#3
	bne		?No_ClockSet_Mode
	lda		Sys_Status_Ordinal					; 时钟设置模式日期设置需要灭PM点
	cmp		#3
	bcc		?No_ClockSet_Mode
	ldx		#led_PM
	jsr		F_ClrSymbol
	ldx		#led_COL1
	jsr		F_ClrSymbol
	ldx		#led_COL2
	jsr		F_ClrSymbol
	rts

?No_ClockSet_Mode:
	lda		Sys_Status_Ordinal					; 闹钟设置模式，需要亮对应闹组的点
	cmp		#3
	bcs		?No_Alarm1Set
	ldx		#led_AL1
	jsr		F_DisSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts
?No_Alarm1Set:
	cmp		#6
	bcs		?No_Alarm2Set
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_DisSymbol
	ldx		#led_AL3
	jsr		F_ClrSymbol
	rts
?No_Alarm2Set:
	ldx		#led_AL1
	jsr		F_ClrSymbol
	ldx		#led_AL2
	jsr		F_ClrSymbol
	ldx		#led_AL3
	jsr		F_DisSymbol
	rts




F_AlarmSW_Display:
	lda		Sys_Status_Flag
	cmp		#2
	bne		?No_AlarmSW_AlarmDis
	rts
?No_AlarmSW_AlarmDis:
	cmp		#4
	bne		Alarm1_Switch
	rts											; 在闹钟显示和设置模式下，不控制闹钟组的点显示

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
