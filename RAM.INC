.Kdata
;***************************************
; RAM Address
;***************************************
RamStarAddr		EQU		1800H								;RAM的开始地址
LED_RamAddr		EQU		RamStarAddr+LED_Addr-Page0RamStarAddr		;LCD RAM的地址
Time_Addr		EQU		RamStarAddr+Time_Str_Addr-Page0RamStarAddr ;事件相关数据的地址


;***************************************
;Time_Addr		EUQ		B0H
;***************************************
.PAGE0     ;page 0的内存布局
;***************************************
;---------------------------------------------------------------------
	ORG	0080H
Page0RamStarAddr		EQU		$
LCDRAM					DS		6*6

LED_Addr				EQU		$
LED_Ram					DS		4*3

R_Int_Backup			DS		1

Counter_1Hz				DS		1
Counter_16Hz			DS		1
Counter_102Hz			DS		1

RR_Div_RT_H				DS		1
RR_Div_RT_L				DS		1
RH_Div_RR_H				DS		1
RH_Div_RR_L				DS		1

QuickAdd_Counter		DS		1
Backlight_Counter		DS		1
Return_Counter			DS		1

Clock_Flag				DS		1
;bit0 = 1 12h模式
;bit0 = 1 闰年
;bit1 = 1 增日期

Beep_Flag				DS		1


Timer_Flag				DS		1
;bit0 = 1 Timer2 半S计时
;bit1 = 1 Timer2 1S计时
;bit2 = 1 增S标志
;bit3 = 1 快加标志
;bit4 = 1 Timer1 16Hz计时
;bit5 = 1 Timer2 背光1S计时
;bit6 = 1 Timer0 16Hz标志
;bit7 = 1 DIV中断标志

Sys_Status_Flag			DS		1
;bit0 = 1 时间显示
;bit1 = 1 日期显示
;bit2 = 1 轮流显示
;bit3 = 1 闹钟显示
;bit4 = 1 设置时间
;bit5 = 1 设置闹钟

Settings_Ordinal		DS		1
; 设置模式的序号

Key_Flag				DS		1
;bit0 = 1 扫键标志位
;bit1 = 1 首次触发
;bit2 = 1 非走时
;bit3 = 1 背光激活
;bit4 = 1 快加间隔

SpecialKey_Flag			DS		1
;bit0 = 1 Alarm键待处理				|特殊按键
;bit1 = 1 SNZ/Backlight键待处理		|特殊按键
;bit2 = 1 Mode键待处理				|特殊按键

RFC_Flag				DS		1
;bit0 = 1 10ms标志，用于计数Frcx
;bit1 = 1 禁用RFC采样标志，这通常是因为TMR0、1被占用
;bit2 = 1 负温度
;bit3 = 1 湿度表查询完成标志位


RFC_ChannelCount		DS		1

RFC_TempCount_H			DS		1
RFC_TempCount_L			DS		1
RFC_HumiCount_H			DS		1
RFC_HumiCount_L			DS		1
RFC_StanderCount_H		DS		1
RFC_StanderCount_L		DS		1

R_Temperature			DS		1
R_Humidity				DS		1

Beep_Serial				DS		1
;响铃序列

PA_IO_Backup			DS		1
PC_IO_Backup			DS		1
;---------------------------------------
Time_Str_Addr	EQU		$
R_Time_Sec				DS		1	;时间秒
R_Time_Min				DS		1	;时间分
R_Time_Hour				DS		1	;时间小时
R_Date_Day				DS		1	;日期，从1开始
R_Date_Month			DS		1	;月份，从1开始
R_Date_Year				DS		1	;年份，由于只计2000-2099，所以由0-99代替
R_Date_Week				DS		1	;星期数，从1开始

CC0						DS		1

;---------------------------------------       
P_Temp					DS		16	
;---------------------------------------
;---------------------------------------
;***************************************
.ENDS
;***************************************
.Udata
;---------------------------------------
	ORG		1880H
;---------------------------------------
;---------------------------------------
.ENDS

