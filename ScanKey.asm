; 按键处理
F_KeyHandler:
	bbs3	Timer_Flag,L_Key4Hz					; 快加到来则4Hz扫一次，控制快加频率
	bbr1	Key_Flag,L_KeyScan					; 首次按键触发
	rmb1	Key_Flag							; 复位首次触发
	lda		#$00
	sta		P_Temp
L_DelayTrigger:									; 消抖延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_DelayTrigger						; 软件消抖
	lda		PA
	eor		#$1c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$1c
	cmp		#$00
	bne		L_KeyYes							; 检测是否有按键触发
	bra		L_KeyExit
	rts
L_KeyYes:
	sta		PA_IO_Backup
	bra		L_KeyHandle							; 首次触发处理结束

L_Key4Hz:
	bbr5	Key_Flag,L_KeyScanExit
	rmb5	Key_Flag
L_KeyScan:										; 长按处理部分
	bbr0	Key_Flag,L_KeyScanExit				; 没有扫键标志直接退出

	jsr		F_QuikAdd_Scan						; 矩阵扫描，需要开启IO口
	bbr4	Timer_Flag,L_KeyScanExit			; 没开始快加时，用16Hz扫描
	rmb4	Timer_Flag
	lda		PA
	eor		#$1c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$1c
	cmp		PA_IO_Backup						; 若检测到有按键的状态变化则退出快加判断并结束
	beq		L_4_16Hz_Count
	jsr		F_SpecialKey_Handle					; 长按终止时，进行一次特殊按键的处理
	bra		L_KeyExit
L_4_16Hz_Count:
	bbs3	Timer_Flag,Counter_NoAdd			; 在快加触发后不能继续快加计数
	inc		QuickAdd_Counter					; 否则计数溢出后会导致不触发按键功能
Counter_NoAdd:
	lda		QuickAdd_Counter
	cmp		#32
	bcs		L_QuikAdd
	rts											; 长按计时，必须满2S才有快加
L_QuikAdd:
	smb3	Timer_Flag
	rmb5	Key_Flag

L_KeyHandle:
	jsr		F_KeyMatrix_PC4Scan_Ready			; 判断Alarm键和Backlight键
	lda		PA
	eor		#$0c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$0c
	cmp		#$04
	bne		No_KeyATrigger						; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	jmp		L_KeyATrigger
No_KeyATrigger:
	cmp		#$08
	bne		No_KeyBTrigger
	jmp		L_KeyBTrigger
No_KeyBTrigger:
	jsr		F_KeyMatrix_PC5Scan_Ready			; 判断Mode键、Up键、Down键
	lda		PA
	eor		#$1c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$1c
	cmp		#$04
	bne		No_KeyMTrigger
	jmp		L_KeyMTrigger
No_KeyMTrigger:
	cmp		#$08
	bne		No_KeyUTrigger
	jmp		L_KeyUTrigger						; U键触发
No_KeyUTrigger:
	cmp		#$10
	bne		L_KeyExit
	jmp		L_KeyDTrigger						; D键触发			

L_KeyExit:
	rmb1	TMRC								; 关闭快加16Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter
	sta		SpecialKey_Flag
	jsr		F_KeyMatrix_Reset
L_KeyScanExit:
	rts

F_SpecialKey_Handle:							; 特殊按键的处理
	lda		SpecialKey_Flag
	bne		SpecialKey_Handle
	rts
SpecialKey_Handle:
	bbs0	SpecialKey_Flag, L_KeyA_ShortHandle	; 短按的特殊功能处理
	bbs1	SpecialKey_Flag, L_KeyB_ShortHandle
	bbs2	SpecialKey_Flag, L_KeyM_ShortHandle
L_KeyA_ShortHandle:
	jsr		SwitchState_AlarmDis				; 切换闹钟显示状态
	rts
L_KeyB_ShortHandle:
	jsr		LightLevel_Change					; 三档亮度切换
	rts
L_KeyM_ShortHandle:
	jsr		SwitchState_ClockDis				; 这里是切换两种时钟显示模式的业务逻辑函数
	rts



; 按键触发函数，处理每个按键触发后的响应条件
L_KeyATrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		StatusCS_No_KeyA
	jmp		L_KeyExit							; 时钟设置模式A键无效
StatusCS_No_KeyA:
	cmp		#000010000B
	bne		StatusAS_No_KeyA
	jsr		SwitchState_AlarmSet				; 闹设模式切换设置内容
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
StatusAS_No_KeyA:
	bbs3	Timer_Flag,L_DisMode_KeyA_LongTri
	smb0	SpecialKey_Flag						; 显示模式下，A键为特殊功能按键
	rts
L_DisMode_KeyA_LongTri:
	jsr		SwitchState_AlarmSet				; 从显示模式切换到闹钟设置模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyBTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理

	bbr2	Clock_Flag,StatusLM_No_KeyB
	jsr		Alarm_Snooze						; 响闹时贪睡
	jmp		L_KeyExit
StatusLM_No_KeyB:
	bbs3	Timer_Flag,L_DisMode_KeyB_LongTri
	smb1	SpecialKey_Flag
	rts
L_DisMode_KeyB_LongTri:
	jsr		TemperMode_Change					; 切换摄氏-华氏度
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyMTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		StatusCS_No_KeyM
	jsr		SwitchState_ClockSet				; 时设模式切换设置内容
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
StatusCS_No_KeyM:
	cmp		#00010000B
	bne		StatusAS_No_KeyM
	jmp		L_KeyExit							; 时设模式M键无效
StatusAS_No_KeyM:
	bbs3	Timer_Flag,L_DisMode_KeyM_LongTri	; 判断显示模式下的M长按
	cmp		#00000001B
	bne		StatusTD_No_KeyM
	smb2	SpecialKey_Flag						; 时显下，M键才为特殊功能按键
StatusTD_No_KeyM:
	rts
L_DisMode_KeyM_LongTri:
	jsr		SwitchState_ClockSet				; 从显示模式切换到时间设置模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyUTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时
	
	lda		Sys_Status_Flag
	and		#00000111B
	beq		Status_NoDisMode_KeyU				; 时显、闹显和轮显模式U键切换12/24h
	jsr		Switch_TimeMode						; 显示模式下切换12/24h模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
Status_NoDisMode_KeyU:
	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		StatusCS_No_KeyU
	jsr		AddNum_CS							; 时设模式增数
StatusCS_No_KeyU:
	cmp		#00010000B
	bne		StatusAS_No_KeyU
	jsr		AddNum_AS							; 闹设模式增数
StatusAS_No_KeyU:
	rts


L_KeyDTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时

	lda		Sys_Status_Flag
	and		#00000111B
	beq		Status_NoDisMode_KeyD				; 判断是否为显示模式
	jsr		SwitchState_DisMode					; 切换固显-轮显
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
Status_NoDisMode_KeyD:
	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		StatusCS_No_KeyD
	jsr		SubNum_CS							; 时设模式减数
	rts
StatusCS_No_KeyD:
	cmp		#00010000B
	bne		StatusAS_No_KeyD
	jsr		SubNum_AS							; 闹设模式减数
StatusAS_No_KeyD:
	rts


; 按键触发通用功能，包括按键矩阵GPIO状态重置，按键音，唤醒屏幕
; 同时会给出是否存在唤醒事件
; 由于打断贪睡和响闹的功能B键没有，故不在本函数内处理
L_Universal_TriggerHandle:
	jsr		F_KeyMatrix_Reset					; 按键矩阵的GPIO状态重置

	bbs4	PD,No_Screen_WakeUp					; 唤醒事件是否产生
	smb3	Key_Flag
	bra		KeyBeep_Start
No_Screen_WakeUp:
	rmb3	Key_Flag
KeyBeep_Start:

	bbs3	Key_Flag,No_KeyBeep					; 唤醒事件会阻止按键音出现
	lda		#10B								; 设置按键提示音的响铃序列
	sta		Beep_Serial
	smb0	TMRC								; 开TIM0蜂鸣器时钟
	rmb4	Clock_Flag							; 序列响铃模式
	smb4	Key_Flag							; 置位按键提示音
	smb1	RFC_Flag							; 禁用RFC采样
No_KeyBeep:

	bbs3	Key_Flag,No_WakeUp_Screen
	smb4	PD									; 按键会唤醒屏幕显示
No_WakeUp_Screen:
	lda		#0
	sta		Backlight_Counter					; 清空亮屏幕计数

	rts



; 状态转换函数,切换到闹钟显示状态
SwitchState_AlarmDis:
	lda		Sys_Status_Flag
	cmp		#00000100B
	beq		L_Change_Ordinal_AD					; 判断当前状态是否已经是闹钟显示
	lda		#00000100B
	sta		Sys_Status_Flag						; 当前状态非闹显则切换至闹显
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	rts
L_Change_Ordinal_AD:
	inc		Sys_Status_Ordinal					; 当前状态为闹显，则递增子模式序号
	lda		Sys_Status_Ordinal
	cmp		#3
	bcc		L_Ordinal_Exit_AD
	lda		#0
	sta		Sys_Status_Ordinal					; 子模式序号大于2时，则回到时显模式，并清空序号
	lda		#00000001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_AD:
	rts




; 切换背光亮度
; 0熄屏，1低亮，2高亮
LightLevel_Change:
	inc		Backlight_Level
	cmp		#3
	bcs		Backlight_Add
	lda		#0
	sta		Backlight_Add
	bra		LightLevel_Change_Exit
Backlight_Add:
	inc		Backlight_Level
LightLevel_Change_Exit:
	rts




; 时钟模式的时显和日显切换
SwitchState_ClockDis:
	lda		Sys_Status_Ordinal					; 对第一位取反，在日期显示和时间显示之间切换
	eor		#1
	sta		Sys_Status_Ordinal
	rts




SwitchState_AlarmSet:
	lda		Sys_Status_Flag
	cmp		#00010000B
	beq		L_Change_Ordinal_AS					; 判断当前状态是否已经是闹钟设置
	lda		#00010000B
	sta		Sys_Status_Flag						; 当前状态非闹设则切换至闹设
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	rts
L_Change_Ordinal_AS:
	inc		Sys_Status_Ordinal					; 当前状态为闹设，则递增子模式序号
	lda		Sys_Status_Ordinal
	cmp		#9
	bcc		L_Ordinal_Exit_AS
	lda		#0
	sta		Sys_Status_Ordinal					; 子模式序号大于8时，则回到时显模式，并清空序号
	lda		#00000001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_AS:
	rts




Alarm_Snooze:
	smb6	Clock_Flag							; 贪睡按键触发						
	smb3	Clock_Flag							; 进入贪睡模式
	
	lda		R_Snooze_Min						; 贪睡闹钟的时间加5
	clc
	adc		#5
	cmp		#60
	bcs		L_Snooze_OverflowMin
	sta		R_Snooze_Min
	bra		L_Snooze_Exit
L_Snooze_OverflowMin:
	sec
	sbc		#60
	sta		R_Snooze_Min						; 产生贪睡响闹的分钟进位
	inc		R_Snooze_Hour
	lda		R_Snooze_Hour
	cmp		#24
	bcc		L_Snooze_Exit
	lda		#00									; 产生贪睡小时进位
	sta		R_Snooze_Hour
L_Snooze_Exit:
	rts




TemperMode_Change:
	lda		RFC_Flag							; 取反标志位，切换华氏度和摄氏度
	eor		#00010000B
	sta		RFC_Flag
	jsr		F_Display_Temper

	rts




SwitchState_ClockSet:
	lda		Sys_Status_Flag
	cmp		#00001000B
	beq		L_Change_Ordinal_CS					; 判断当前状态是否已经是时钟设置
	lda		#00001000B
	sta		Sys_Status_Flag						; 当前状态非时设则切换至时设
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	rts
L_Change_Ordinal_CS:
	inc		Sys_Status_Ordinal					; 当前状态为时设，则递增子模式序号
	lda		Sys_Status_Ordinal
	cmp		#6
	bcc		L_Ordinal_Exit_CS
	lda		#0
	sta		Sys_Status_Ordinal					; 子模式序号大于5时，则回到时显模式，并清空序号
	lda		#00000001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_CS:
	rts




; 显示模式下的12、24h模式切换
Switch_TimeMode:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	rts




AddNum_CS:
	lda		Sys_Status_Ordinal
	bne		No_CS_TMSwitch
	jsr		Switch_TimeMode
	pla
	pla
	jmp		L_KeyExit							; 在时钟设置的12/24h模式切换下，按键只生效1次
No_CS_TMSwitch:
	cmp		#1
	bne		No_CS_HourAdd
	jmp		L_TimeHour_Add
No_CS_HourAdd:
	cmp		#2
	bne		No_CS_MinAdd
	jmp		L_TimeMin_Add
No_CS_MinAdd:
	cmp		#3
	bne		No_CS_YearAdd
	jmp		L_DateYear_Add
No_CS_YearAdd:
	cmp		#4
	bne		No_CS_MonthAdd
	jmp		L_DateMonth_Add
No_CS_MonthAdd:
	jmp		L_DateDay_Add
	rts




AddNum_AS:
	lda		Sys_Status_Ordinal
	bne		No_AS_Alarm1_Switch
	jmp		L_Alarm1_Switch
No_AS_Alarm1_Switch:
	cmp		#1
	bne		No_AS_Alarm1_HourAdd
	jmp		L_Alarm1Hour_Add
No_AS_Alarm1_HourAdd:
	cmp		#2
	bne		No_AS_Alarm1_MinAdd
	jmp		L_Alarm1Min_Add
No_AS_Alarm1_MinAdd:
	cmp		#3
	bne		No_AS_Alarm2_Switch
	jmp		L_Alarm2_Switch
No_AS_Alarm2_Switch:
	cmp		#4
	bne		No_AS_Alarm2_HourAdd
	jmp		L_Alarm2Hour_Add
No_AS_Alarm2_HourAdd:
	cmp		#6
	bne		No_AS_Alarm2_MinAdd
	jmp		L_Alarm2Min_Add
No_AS_Alarm2_MinAdd:
	cmp		#7
	bne		No_AS_Alarm3_Switch
	jmp		L_Alarm3_Switch
No_AS_Alarm3_Switch:
	cmp		#8
	bne		No_AS_Alarm3_HourAdd
	jmp		L_Alarm3Hour_Add
No_AS_Alarm3_HourAdd:
	jmp		L_Alarm3Min_Add

	rts




SwitchState_DisMode:
	lda		Sys_Status_Flag
	and		#00000010B
	beq		L_ChangeToRotateDis
	lda		#00000001B							; 回到时显模式
	sta		Sys_Status_Flag
	lda		#0
	sta		Sys_Status_Ordinal
	rts
L_ChangeToRotateDis:
	lda		#00000010B
	sta		Sys_Status_Flag
	lda		#0
	sta		Sys_Status_Ordinal
	rts




; 闹设模式减数
SubNum_CS:
	lda		Sys_Status_Ordinal
	bne		No_CS_TMSwitch2
	jsr		Switch_TimeMode
	pla
	pla
	jmp		L_KeyExit							; 在时钟设置的12/24h模式切换下，按键只生效1次
No_CS_TMSwitch2:
	cmp		#1
	bne		No_CS_HourSub
	jmp		L_TimeHour_Sub
No_CS_HourSub:
	cmp		#2
	bne		No_CS_MinSub
	jmp		L_TimeMin_Sub
No_CS_MinSub:
	cmp		#3
	bne		No_CS_YearSub
	jmp		L_DateYear_Sub
No_CS_YearSub:
	cmp		#4
	bne		No_CS_MonthSub
	jmp		L_DateMonth_Sub
No_CS_MonthSub:
	jmp		L_DateDay_Sub
	rts




; 闹设模式减数
SubNum_AS:
	lda		Sys_Status_Ordinal
	bne		No_AS_Alarm1_Switch2
	jmp		L_Alarm1_Switch
No_AS_Alarm1_Switch2:
	cmp		#1
	bne		No_AS_Alarm1_HourSub
	jmp		L_Alarm1Hour_Sub
No_AS_Alarm1_HourSub:
	cmp		#2
	bne		No_AS_Alarm1_MinSub
	jmp		L_Alarm1Min_Sub
No_AS_Alarm1_MinSub:
	cmp		#3
	bne		No_AS_Alarm2_Switch2
	jmp		L_Alarm2_Switch
No_AS_Alarm2_Switch2:
	cmp		#4
	bne		No_AS_Alarm2_HourSub
	jmp		L_Alarm2Hour_Sub
No_AS_Alarm2_HourSub:
	cmp		#6
	bne		No_AS_Alarm2_MinSub
	jmp		L_Alarm2Min_Sub
No_AS_Alarm2_MinSub:
	cmp		#7
	bne		No_AS_Alarm3_Switch2
	jmp		L_Alarm3_Switch
No_AS_Alarm3_Switch2:
	cmp		#8
	bne		No_AS_Alarm3_HourSub
	jmp		L_Alarm3Hour_Sub
No_AS_Alarm3_HourSub:
	jmp		L_Alarm3Min_Sub

	rts




; 时增加
L_TimeHour_Add:
	lda		R_Time_Hour
	cmp		#24
	bcs		TimeHour_AddOverflow
	inc		R_Time_Hour
	rts
TimeHour_AddOverflow:
	lda		#0
	sta		R_Time_Hour
	rts

; 时减少
L_TimeHour_Sub:
	lda		R_Time_Hour
	cmp		#0
	beq		TimeHour_SubOverflow
	dec		R_Time_Hour
TimeHour_SubOverflow:
	rts




; 分增加
L_TimeMin_Add:
	lda		R_Time_Min
	cmp		#60
	bcs		TimeMin_AddOverflow
	inc		R_Time_Min
	rts
TimeMin_AddOverflow:
	lda		#0
	sta		R_Time_Min
	rts

; 分减少
L_TimeMin_Sub:
	lda		R_Time_Min
	cmp		#0
	beq		TimeMin_SubOverflow
	dec		R_Time_Min
TimeMin_SubOverflow:
	rts




; 年增加
L_DateYear_Add:
	lda		R_Date_Year
	cmp		#100
	bcs		DateYear_AddOverflow
	inc		R_Date_Year
	jsr		F_Is_Leap_Year
	rts
DateYear_AddOverflow:
	lda		#0
	sta		R_Date_Year
	jsr		F_Is_Leap_Year
	rts

; 年减少
L_DateYear_Sub:
	lda		R_Date_Year
	cmp		#0
	beq		DateYear_SubOverflow
	dec		R_Date_Year
DateYear_SubOverflow:
	rts




; 月增加
L_DateMonth_Add:
	lda		R_Date_Month
	cmp		#12
	bcs		DateMonth_AddOverflow
	inc		R_Date_Month
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为1日
	rts
DateMonth_AddOverflow:
	lda		#1
	sta		R_Date_Month
	rts

; 月减少
L_DateMonth_Sub:
	lda		R_Date_Month
	cmp		#0
	beq		DateMonth_SubOverflow
	dec		R_Date_Month
DateMonth_SubOverflow:
	rts




; 日增加
L_DateDay_Add:
	inc		R_Date_Day
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为1日
	rts

; 日减少
L_DateDay_Sub:
	lda		R_Date_Day
	cmp		#0
	beq		DateDay_SubOverflow
	dec		R_Date_Day
DateDay_SubOverflow:
	rts




; 闹钟1开关
L_Alarm1_Switch:
	lda		Alarm_Switch
	eor		#001B
	sta		Alarm_Switch
	rts


; 闹钟1小时增加
L_Alarm1Hour_Add:
	lda		R_Alarm1_Hour
	cmp		#24
	bcs		Alarm1Hour_AddOverflow
	inc		R_Alarm1_Hour
	rts
Alarm1Hour_AddOverflow:
	lda		#0
	sta		R_Alarm1_Hour
	rts

; 闹钟1小时减少
L_Alarm1Hour_Sub:
	lda		R_Alarm1_Hour
	cmp		#0
	beq		Alarm1Hour_SubOverflow
	dec		R_Alarm1_Hour
Alarm1Hour_SubOverflow:
	rts


; 闹钟1分增加
L_Alarm1Min_Add:
	lda		R_Alarm1_Min
	cmp		#60
	bcs		Alarm1Min_AddOverflow
	inc		R_Alarm1_Min
	rts
Alarm1Min_AddOverflow:
	lda		#0
	sta		R_Alarm1_Min
	rts

; 闹钟1分钟减少
L_Alarm1Min_Sub:
	lda		R_Alarm1_Min
	cmp		#0
	beq		Alarm1Min_SubOverflow
	dec		R_Alarm1_Min
Alarm1Min_SubOverflow:
	rts




; 闹钟2开关
L_Alarm2_Switch:
	lda		Alarm_Switch
	eor		#010B
	sta		Alarm_Switch
	rts


; 闹钟2小时增加
L_Alarm2Hour_Add:
	lda		R_Alarm2_Hour
	cmp		#24
	bcs		Alarm2Hour_AddOverflow
	inc		R_Alarm2_Hour
	rts
Alarm2Hour_AddOverflow:
	lda		#0
	sta		R_Alarm2_Hour
	rts

; 闹钟2小时减少
L_Alarm2Hour_Sub:
	lda		R_Alarm2_Hour
	cmp		#0
	beq		Alarm2Hour_SubOverflow
	dec		R_Alarm2_Hour
Alarm2Hour_SubOverflow:
	rts


; 闹钟2分增加
L_Alarm2Min_Add:
	lda		R_Alarm2_Min
	cmp		#60
	bcs		Alarm2Min_AddOverflow
	inc		R_Alarm2_Min
	rts
Alarm2Min_AddOverflow:
	lda		#0
	sta		R_Alarm2_Min
	rts

; 闹钟2分钟减少
L_Alarm2Min_Sub:
	lda		R_Alarm2_Min
	cmp		#0
	beq		Alarm2Min_SubOverflow
	dec		R_Alarm2_Min
Alarm2Min_SubOverflow:
	rts




; 闹钟3开关
L_Alarm3_Switch:
	lda		Alarm_Switch
	eor		#010B
	sta		Alarm_Switch
	rts


; 闹钟3小时增加
L_Alarm3Hour_Add:
	lda		R_Alarm3_Hour
	cmp		#24
	bcs		Alarm3Hour_AddOverflow
	inc		R_Alarm3_Hour
	rts
Alarm3Hour_AddOverflow:
	lda		#0
	sta		R_Alarm3_Hour
	rts

; 闹钟3小时减少
L_Alarm3Hour_Sub:
	lda		R_Alarm3_Hour
	cmp		#0
	beq		Alarm3Hour_SubOverflow
	dec		R_Alarm3_Hour
Alarm3Hour_SubOverflow:
	rts


; 闹钟3分增加
L_Alarm3Min_Add:
	lda		R_Alarm3_Min
	cmp		#60
	bcs		Alarm3Min_AddOverflow
	inc		R_Alarm3_Min
	rts
Alarm3Min_AddOverflow:
	lda		#0
	sta		R_Alarm3_Min
	rts

; 闹钟3分钟减少
L_Alarm3Min_Sub:
	lda		R_Alarm3_Min
	cmp		#0
	beq		Alarm3Min_SubOverflow
	dec		R_Alarm3_Min
Alarm3Min_SubOverflow:
	rts




L_DayOverflow_Juge:
	bbs0	Calendar_Flag,L_LeapYear_Handle		; 平年闰年的表分开查
	ldx		R_Date_Month						; 查平年每月份天数表
	lda		L_Table_Month_Common,x
	sta		P_Temp
	bra		Day_Overflow_Juge
L_LeapYear_Handle:
	ldx		R_Date_Month						; 查闰年每月份天数表
	lda		L_Table_Month_Leap,x
	sta		P_Temp
Day_Overflow_Juge:
	lda		P_Temp								; 当前日期和天数表的日期对比
	cmp		R_Date_Day
	bcs		DateDay_NoOverflow
	lda		#1
	sta		R_Date_Day
DateDay_NoOverflow:
	rts
