F_Calendar_Add:									; 走日期
	smb1	Calendar_Flag
	jsr		F_Is_Leap_Year
	ldx		R_Date_Month						; 月份数作为索引，查表
	dex
	bbs0	Calendar_Flag,L_Leap_Year			; 如果是闰年，查闰年月份天数表
	lda		L_Table_Month_Common,x				; 否则查平年月份天数表
	bra		L_Day_Juge
L_Leap_Year:
	lda		L_Table_Month_Leap,x
L_Day_Juge:
	cmp		R_Date_Day
	bne		L_Day_Add			
	lda		#1
	sta		R_Date_Day							; 日进位发生
	lda		R_Date_Month
	cmp		#12									; 若是月份到已经计到12
	beq		L_Year_Add							; 月份进位
	inc		R_Date_Month						; 月份正常加
	rts

L_Day_Add:
	inc		R_Date_Day
	rts

L_Year_Add:
	lda		#1
	sta		R_Date_Month
	lda		R_Date_Year
	cmp		#99									; 年份走到2099
	beq		L_Reload_Year						; 则下一年回到2000
	inc		R_Date_Year
	rts
L_Reload_Year:
	lda		#0
	sta		R_Date_Year
	rts

; 判断平闰年函数
F_Is_Leap_Year:
	lda		R_Date_Year
	and		#0011B								; 取最后两位
	beq		L_Set_LeapYear_Flag					; 若都为0则能被4整除
	rmb0	Calendar_Flag
	rts
L_Set_LeapYear_Flag:
	smb0	Calendar_Flag
	rts


; 通过当前日期计算当前星期数
L_GetWeek:
	jsr		F_Is_Leap_Year

	ldx		R_Date_Day
	dex												; 当前日期-1->A
	txa
	jsr		L_MOD_A_7
	sta		P_Temp									; 当前日期相对月首日的星期数偏移量->P_Temp

	ldx		R_Date_Month
	dex
	bbs0	Calendar_Flag,L_DateToWeek_Leap
	lda		L_Table_Gap_CommonMonth,x				; 平年月份首日的星期数->A
	bra		L_Get_Week
L_DateToWeek_Leap:
	lda		L_Table_Gap_LeapMonth,x					; 闰年月份首日的星期数->A
L_Get_Week:
	sta		P_Temp+1								; 月份首日的星期数->P_Temp+1

	lda		R_Date_Year								; 获取当前年首日的星期数
	clc
	ror												; 年份除以2来查表
	tax
	lda		L_Table_WeekInYear,x
	bbs0	R_Date_Year,L_Odd_Year
	and		#0111B									; 偶数年份取低4位
	bra		L_Get_Weak_YearFirstDay
L_Odd_Year:
	jsr		L_LSR_4Bit
	and		#0111B									; 奇数年份取高4位
L_Get_Weak_YearFirstDay:
	clc
	adc		P_Temp
	clc
	adc		P_Temp+1								; 当前年首日的星期数+总偏移==当前星期数
	jsr		L_MOD_A_7
	sta		R_Date_Week
	rts


L_MOD_A_7:
	cmp		#7
	bcc		L_MOD_A_7Over
	sec
	sbc		#7
	bra		L_MOD_A_7
L_MOD_A_7Over:
	rts


F_DisYear_Set:
	lda		Key_Flag
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Year	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Year				; 没有半S标志不闪烁
	rts
L_Blink_Year:
	rmb0	Timer_Flag							; 清半S标志
	bbs1	Timer_Flag,L_Year_Clear				; 有1S标志时灭
L_KeyTrigger_NoBlink_Year:
	jsr		L_DisDate_Year
	rts
L_Year_Clear:
	rmb1	Timer_Flag							; 清1S标志
	jsr		F_UnDisplay_Year
	rts


F_DisMonth_Set:
	lda		Key_Flag
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Month	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Month			; 没有半S标志不闪烁
	rts
L_Blink_Month:
	rmb0	Timer_Flag							; 清半S标志
	bbs1	Timer_Flag,L_Month_Clear			; 有1S标志时灭
L_KeyTrigger_NoBlink_Month:
	jsr		L_DisDate_Month
	jsr		L_DisDate_Day
	rts	
L_Month_Clear:
	rmb1	Timer_Flag							; 清1S标志
	jsr		F_UnDisplay_Month
	rts


F_DisDay_Set:
	lda		Key_Flag
	bbs0	Key_Flag,L_KeyTrigger_NoBlink_Day	; 有按键时不闪烁
	bbs0	Timer_Flag,L_Blink_Day				; 没有半S标志不闪烁
	rts
L_Blink_Day:
	rmb0	Timer_Flag							; 清半S标志
	bbs1	Timer_Flag,L_Day_Clear				; 有1S标志时灭
L_KeyTrigger_NoBlink_Day:
	jsr		L_DisDate_Day
	jsr		L_DisDate_Month
	rts	
L_Day_Clear:
	rmb1	Timer_Flag							; 清1S标志
	jsr		F_UnDisplay_Day
	rts


; 平年的每月份天数表
L_Table_Month_Common:
	.byte	31	; January
	.byte	28	; February
	.byte	31	; March
	.byte	30	; April
	.byte	31	; May
	.byte	30	; June
	.byte	31	; July
	.byte	31	; August
	.byte	30	; September
	.byte	31	; October
	.byte	30	; November
	.byte	31	; December

; 闰年的每月份天数表
L_Table_Month_Leap:
	.byte	31	; January
	.byte	29	; February
	.byte	31	; March
	.byte	30	; April
	.byte	31	; May
	.byte	30	; June
	.byte	31	; July
	.byte	31	; August
	.byte	30	; September
	.byte	31	; October
	.byte	30	; November
	.byte	31	; December

L_Table_WeekInYear:
	.byte	$1E	; 2001,2000 E="1110"代表2000年1月1日是星期六(110),是闰年(1)
	.byte	$32	; 2003,2002
	.byte	$6C	; 2005,2004
	.byte	$10	; 2007,2006
	.byte	$4A	; 2009,2008
	.byte	$65	; 2011,2010
	.byte	$28	; 2013,2012
	.byte	$43	; 2015,2014
	.byte	$0D	; 2017,2016
	.byte	$21	; 2019,2018
	.byte	$5B	; 2021,2020
	.byte	$06	; 2023,2022
	.byte	$39	; 2025,2024
	.byte	$54	; 2027,2026
	.byte	$1E	; 2029,2028
	.byte	$32	; 2031,2030
	.byte	$6C	; 2033,2032
	.byte	$10	; 2035,2034
	.byte	$4A	; 2037,2036
	.byte	$65	; 2039,2038
	.byte	$28	; 2041,2040
	.byte	$43	; 2043,2042
	.byte	$0D	; 2045,2044
	.byte	$21	; 2047,2046
	.byte	$5B	; 2049,2048
	.byte	$06	; 2051,2050
	.byte	$39	; 2053,2052
	.byte	$54	; 2055,2054
	.byte	$1E	; 2057,2056
	.byte	$32	; 2059,2058
	.byte	$6C	; 2061,2060
	.byte	$10	; 2063,2062
	.byte	$4A	; 2065,2064
	.byte	$65	; 2067,2066
	.byte	$28	; 2069,2068
	.byte	$43	; 2071,2070
	.byte	$0D	; 2073,2072
	.byte	$21	; 2075,2074
	.byte	$5B	; 2077,2076
	.byte	$06	; 2079,2078
	.byte	$39	; 2081,2080
	.byte	$54	; 2083,2082
	.byte	$1E	; 2085,2084
	.byte	$32	; 2087,2086
	.byte	$6C	; 2089,2088
	.byte	$10	; 2091,2090
	.byte	$4A	; 2093,2092
	.byte	$65	; 2095,2094
	.byte	$28	; 2097,2096
	.byte	$43	; 2099,2098

; 平年里每月份首日对当前年份首日的星期偏移
L_Table_Gap_CommonMonth:
	.byte	$0	; 1月1日
	.byte	$3	; 2月1日
	.byte	$3	; 3月1日
	.byte	$6	; 4月1日
	.byte	$1	; 5月1日
	.byte	$4	; 6月1日
	.byte	$6	; 7月1日
	.byte	$2	; 8月1日
	.byte	$5	; 9月1日
	.byte	$0	; 10月1日
	.byte	$3	; 11月1日
	.byte	$5	; 12月1日

; 闰年里每月份首日对当前年份首日的星期偏移
L_Table_Gap_LeapMonth:
	.byte	$0	; 1月1日
	.byte	$3	; 2月1日
	.byte	$4	; 3月1日
	.byte	$0	; 4月1日
	.byte	$2	; 5月1日
	.byte	$5	; 6月1日
	.byte	$0	; 7月1日
	.byte	$3	; 8月1日
	.byte	$6	; 9月1日
	.byte	$1	; 10月1日
	.byte	$4	; 11月1日
	.byte	$6	; 12月1日
