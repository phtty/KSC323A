.Kdata
;***************************************
; RAM Address
;***************************************
RamStarAddr		EQU		1800H											;RAM的开始地址
LED_RamAddr		EQU		RamStarAddr+LED_Addr-Page0RamStarAddr			;LED RAM的地址
LED_RamBKAddr	EQU		RamStarAddr+LED_Addr_BK-Page0RamStarAddr		;LED RAM的地址
Time_Addr		EQU		RamStarAddr+Time_Str_Addr-Page0RamStarAddr		;事件相关数据的地址
Alarm_MinAddr	EQU		RamStarAddr+Alarm_Min_Addr-Page0RamStarAddr		;闹钟组分钟数据地址
Alarm_HourAddr	EQU		RamStarAddr+Alarm_Hour_Addr-Page0RamStarAddr	;闹钟组小时数据地址
;***************************************
;Time_Addr		EUQ		B0H
;***************************************
.PAGE0     ;page 0的内存布局
;***************************************
;---------------------------------------------------------------------
	ORG	0080H
Page0RamStarAddr		EQU		$
;LCDRAM					DS		6*6
LED_Addr				EQU		$
LED_Ram					DS		4*3

LED_Addr_BK				EQU		$
LED_Ram_BK				DS		4*3

R_Int_Backup			DS		1

Counter_1Hz				DS		1
Counter_4Hz				DS		1
Counter_16Hz			DS		1
Counter_20ms			DS		1
Counter_DP				DS		1
Count_RFC				DS		1

QuickAdd_Counter		DS		1
Backlight_Counter		DS		1
Return_Counter			DS		1
Return_MaxTime			DS		1
AlarmLoud_Counter		DS		1
COM_Counter				DS		1

Calendar_Flag			DS		1
;bit0 = 1 闰年
;bit1 = 1 增日期

Clock_Flag				DS		1
;bit0 = 1 12h模式
;bit1 = 1 闹钟触发
;bit2 = 1 响闹模式
;bit3 = 1 贪睡模式
;bit4 = 1 响闹阻塞标志，防止短时间内关闭响闹继续进闹钟触发
;bit5	  上次的响闹模式，判断是响闹结束还是未响闹
;bit6 = 1 贪睡按键触发导致的响闹结束
;bit7 = 1 返回时显模式1S计时


Timer_Flag				DS		1
;bit0 = 1 Timer2 半S计时
;bit1 = 1 Timer2 1S计时
;bit2 = 1 增S标志
;bit3 = 1 快加标志
;bit4 = 1 Timer1 16Hz计时
;bit5 = 1 Timer2 熄屏1S计时
;bit6 = 1 Timer0 16Hz标志
;bit7 = 1 Timer2 响铃1S计时

Symbol_Flag				DS		1	; 符号操作
;bit0 = 1 ALM点半S标志
;bit1 = 1 ALM点1S标志

Sys_Status_Flag			DS		1
;bit0 = 1 时钟显示
;bit1 = 1 闹钟显示
;bit2 = 1 设置时钟
;bit3 = 1 设置闹钟

Sys_Status_Ordinal		DS		1
; 子模式的序号

Key_Flag				DS		1
;bit0 = 1 扫键标志位
;bit1 = 1 首次触发
;bit2 = 1 轮流显示标志位
;bit3 = 1 屏幕唤醒事件标志位
;bit4 = 1 按键提示音标志位
;bit5 = 1 长按扫键4Hz标志
;bit6 = 1 DP显示标志位
;bit7 = 1 DP显示1S标志

; 长短按功能不同的按键
SpecialKey_Flag			DS		1
;bit0 = 1 Alarm键待处理				|特殊按键
;bit1 = 1 SNZ/Backlight键待处理		|特殊按键
;bit2 = 1 Mode键待处理				|特殊按键
;bit3 = 1 Up键待处理				|特殊按键
;bit4 = 1 Down键待处理				|特殊按键

RFC_Flag				DS		1
;bit0 = 1 采样启用标志位
;bit1 = 1 禁用RFC采样标志，这通常是因为TMR0、1被占用
;bit2 = 1 负温度
;bit3 = 1 湿度表查询完成标志位
;bit4 = 1 华氏度模式
;bit5 = 1 温湿度测量1S标志
;bit6 = 1 温湿度测量完成标志

Backlight_Flag			DS		1
;bit0 = 1 DC5V接入时唤醒
;bit1 = 1 亮屏1S计时
;bit2 = 1 手动进入熄屏模式

Backlight_Level			DS		1	; 亮度等级
;0 低亮
;1 高亮

Alarm_Switch			DS		1	; 各个闹钟开关
;bit0 = 1 闹钟1开启
;bit1 = 1 闹钟2开启
;bit2 = 1 闹钟3开启

Triggered_AlarmGroup	DS		1

RFC_ChannelCount		DS		1

RT_Div_RR_H				DS		1
RT_Div_RR_L				DS		1
RR_Div_RH_H				DS		1
RR_Div_RH_L				DS		1
RFC_TempCount_H			DS		1
RFC_TempCount_M			DS		1
RFC_TempCount_L			DS		1
RFC_HumiCount_H			DS		1
RFC_HumiCount_M			DS		1
RFC_HumiCount_L			DS		1
RFC_StanderCount_H		DS		1
RFC_StanderCount_M		DS		1
RFC_StanderCount_L		DS		1

R_Temperature			DS		1
R_Temperature_F			DS		1
R_Humidity				DS		1

R_Temper_Comp			DS		1
R_Temper_Comp_Time		DS		1

Beep_Serial				DS		1
;响铃序列

PA_IO_Backup			DS		1
PC_IO_Backup			DS		1
PD_IO_Backup			DS		1

;---------------------------------------
Time_Str_Addr			EQU		$
R_Time_Sec				DS		1	;时间秒
R_Time_Min				DS		1	;时间分
R_Time_Hour				DS		1	;时间小时
R_Alarm_Min				DS		1	;触发闹钟分
R_Alarm_Hour			DS		1	;触发闹钟小时
R_Date_Day				DS		1	;日期，从1开始
R_Date_Month			DS		1	;月份，从1开始
R_Date_Year				DS		1	;年份，由于只计2000-2099，所以由0-99代替
R_Date_Week				DS		1	;星期数，从1开始

Alarm_Min_Addr			EQU		$
R_Alarm1_Min			DS		1	;闹钟1分
R_Alarm2_Min			DS		1	;闹钟2分
R_Alarm3_Min			DS		1	;闹钟3分

Alarm_Hour_Addr			EQU		$
R_Alarm1_Hour			DS		1	;闹钟1小时
R_Alarm2_Hour			DS		1	;闹钟2小时
R_Alarm3_Hour			DS		1	;闹钟3小时

R_Snooze_Min			DS		1	;贪睡闹钟分钟
R_Snooze_Hour			DS		1	;贪睡闹钟小时
CC0						DS		1

;---------------------------------------       
P_Temp					DS		8
LED_Temp				DS		5
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
