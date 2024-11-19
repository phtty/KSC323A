.Kdata
;***************************************
; RAM Address
;***************************************
RamStarAddr		EQU		1800H			;RAM的开始地址
LCD_RamAddr		EQU		RamStarAddr		;LCD RAM的地址
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

R_Int_Backup			DS		1

Frame_Counter			DS		1
Anim_Phase				DS		1

Counter_1Hz				DS		1
Counter_16Hz			DS		1
Counter_Lcd				DS		1

QuickAdd_Counter		DS		1
Backlight_Counter		DS		1
Return_Counter			DS		1

Calendar_Flag			DS		1
;bit0 = 1 闰年
;bit1 = 1 增日期

Clock_Flag				DS		1
;bit0 = 1 12h模式

Timer_Flag				DS		1
;bit0 = 1 Timer2 半S计时
;bit1 = 1 Timer2 1S计时
;bit2 = 1 增S标志
;bit3 = 1 快加标志
;bit4 = 1 Timer1 8Hz计时
;bit5 = 1 Timer2 背光1S计时
;bit6 = 1 Timer0 16Hz标志
;bit7 = 1 Timer2 4D 1S计时

Sys_Status_Flag			DS		1
;bit0 = 1 正常走时
;bit1 = 1 4D模式
;bit2 = 1 12h/24h切换
;bit3 = 1 设置小时
;bit4 = 1 设置分钟
;bit5 = 1 设置年份
;bit6 = 1 设置月份
;bit7 = 1 设置日期

Key_Flag				DS		1
;bit0 = 1 扫键标志位
;bit1 = 1 首次触发
;bit2 = 1 按键处理
;bit3 = 1 背光激活
;bit4 = 1 非走时

Random_Flag				DS		1
;bit0 = 1 滚动显示开始
;bit1 = 1 帧更新
;bit2 = 1 停止随机数采样
;bit3 = 1 4D日

Frame_Serial			DS		1

Frame_Counter_D0		DS		1
Frame_Counter_D1		DS		1
Frame_Counter_D2		DS		1
Frame_Counter_D3		DS		1

Beep_Serial				DS		1
;响铃序列

Table_Digit_LByte		DS		1
Table_Digit_HByte		DS		1

Target_Digit_LByte		DS		1
Target_Digit_HByte		DS		1

Mask_LByte				DS		1
Mask_HByte				DS		1

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

R_Seed0					DS		1
R_Seed1					DS		1
R_Seed2					DS		1
R_Seed3					DS		1

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

