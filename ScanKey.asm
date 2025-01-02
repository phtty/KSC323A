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
	bbr0	Key_Flag,L_KeyNoScanExit			; 没有扫键标志则为无按键处理了，判断是否取消禁用RFC采样

	bbr0	RFC_Flag,?RFC_Sample_Juge			; 按键会打断RFC采样
	jsr		F_RFC_Abort
?RFC_Sample_Juge:

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
	bbs3	Timer_Flag,Counter_NoAdd			; 在快加触发后不再继续增加计数
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
	sta		Counter_DP
	jsr		F_KeyMatrix_Reset
L_KeyScanExit:
	rts

L_KeyNoScanExit:								; 没有扫键的情况下是空闲状态，此时判断是否取消禁用RFC采样
	bbs4	Key_Flag,L_KeyScanExit				; 按键音和响闹模式下，则不取消禁用
	bbs2	Clock_Flag,L_KeyScanExit
	rmb1	RFC_Flag							; 取消禁用RFC采样						
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
	jsr		SwitchState_ClockDis				; 显示模式下切换日期显示、时间显示模式
	rts



; 按键触发函数，处理每个按键触发后的响应条件
L_KeyATrigger:
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹
	jsr		L_Universal_TriggerHandle			; 通用按键处理

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyA
	jmp		L_KeyExit							; 时钟设置模式A键无效
StatusCS_No_KeyA:
	cmp		#1000B
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
	jsr		Alarm_Snooze						; 响闹时贪睡处理
	jmp		L_KeyExit
StatusLM_No_KeyB:
	bbs3	Timer_Flag,L_DisMode_KeyB_LongTri
	smb1	SpecialKey_Flag
	rts
L_DisMode_KeyB_LongTri:
	jsr		TemperMode_Change					; 切换摄氏-华氏度
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyMTrigger:
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹
	jsr		L_Universal_TriggerHandle			; 通用按键处理

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyM
	jsr		SwitchState_ClockSet				; 时设模式切换设置内容
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
StatusCS_No_KeyM:
	cmp		#1000B
	bne		StatusAS_No_KeyM
	jmp		L_KeyExit							; 时设模式M键无效
StatusAS_No_KeyM:
	bbs3	Timer_Flag,L_DisMode_KeyM_LongTri	; 判断显示模式下的M长按
	cmp		#0001B
	bne		StatusTD_No_KeyM
	smb2	SpecialKey_Flag						; 时显下，M键才为特殊功能按键
StatusTD_No_KeyM:
	rts
L_DisMode_KeyM_LongTri:
	jsr		SwitchState_ClockSet				; 从显示模式切换到时间设置模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyUTrigger:
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	
	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyU				; 时钟显和闹显U键切换12/24h
	jsr		Switch_TimeMode						; 显示模式下切换12/24h模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
Status_NoDisMode_KeyU:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyU
	jsr		AddNum_CS							; 时设模式增数
StatusCS_No_KeyU:
	cmp		#1000B
	bne		StatusAS_No_KeyU
	jsr		AddNum_AS							; 闹设模式增数
StatusAS_No_KeyU:
	rts


L_KeyDTrigger:
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹
	jsr		L_Universal_TriggerHandle			; 通用按键处理

	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyD				; 判断是否为显示模式
	jsr		SwitchState_DisMode					; 切换固显-轮显
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
Status_NoDisMode_KeyD:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyD
	jsr		SubNum_CS							; 时设模式减数
	rts
StatusCS_No_KeyD:
	cmp		#1000B
	bne		StatusAS_No_KeyD
	jsr		SubNum_AS							; 闹设模式减数
StatusAS_No_KeyD:
	rts


; 按键打断贪睡和响闹
L_Key_NoSnoozeLoud:
	lda		Clock_Flag
	and		#00001100B
	beq		?NoSnoozeLoud
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	pla
	pla
	jmp		L_KeyExit
?NoSnoozeLoud:
	rts


; 按键触发通用功能，包括按键矩阵GPIO状态重置，按键音，唤醒屏幕
; 同时会给出是否存在唤醒事件
; 由于打断贪睡和响闹的功能B键没有，故不在本函数内处理
L_Universal_TriggerHandle:
	jsr		F_KeyMatrix_Reset					; 按键矩阵的GPIO状态重置
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时

	bbs4	PD,WakeUp_Event
	bbs3	Timer_Flag,?Handle_Exit
	lda		#10B								; 设置按键提示音的响铃序列
	sta		Beep_Serial
	smb0	TMRC								; 开TIM0蜂鸣器时钟
	rmb4	Clock_Flag							; 序列响铃模式
	smb4	Key_Flag							; 置位按键提示音标志
	lda		#0
	sta		Backlight_Counter
?Handle_Exit:
	rts
WakeUp_Event:
	lda		Backlight_Level
	bne		No_Extinguish
	lda		#2
	sta		Backlight_Level						; 若是手动熄屏状态被唤醒，则直接变为高亮显示
	smb0	PC
No_Extinguish:
	rmb4	PD
	smb3	Key_Flag							; 熄屏状态有按键，则触发唤醒事件
	jsr		F_RFC_MeasureStart					; 唤醒后立刻进行一次温湿度测量
	lda		#2
	sta		Backlight_Counter					; 熄屏后有按键，则亮度等级设置为最高并亮屏
	pla
	pla
	jmp		L_KeyExit							; 唤醒触发的那次按键，没有按键功能

	rts




; 时钟模式的时显和日显切换
SwitchState_ClockDis:
	lda		Sys_Status_Ordinal					; 对第一位取反，在日期显示和时间显示之间切换
	eor		#1
	sta		Sys_Status_Ordinal

	lda		#0001B
	sta		Sys_Status_Flag						; 切换时钟显示

	rmb6	Key_Flag							; 清除DP显示

	bbr0	Sys_Status_Ordinal,?SWState_ClockDis_Eixt
	lda		#5
	sta		Return_MaxTime						; 日显示模式，返回时间设为5S
?SWState_ClockDis_Eixt:
	rts




; 切换轮流显示-固定显示
SwitchState_DisMode:
	smb7	Key_Flag							; 设置DP显示1S标志
	smb6	Key_Flag							; 设置DP显示标志
	lda		#0
	sta		Counter_DP
	sta		Sys_Status_Ordinal
	lda		#0001B
	sta		Sys_Status_Flag						; 切换轮、固显会切换状态为时显状态

	lda		Key_Flag
	eor		#100B
	sta		Key_Flag							; 取反轮显标志位

	bbr2	Key_Flag,L_NoRotateDis				; 若是切换到固显，则直接退出
	lda		#10
	sta		Return_MaxTime						; 若是切换到轮显，则设置一次返回时间10s
L_NoRotateDis:	
	jsr		F_Clock_Display
	rts




; 切换到闹钟显示状态
SwitchState_AlarmDis:
	lda		#5
	sta		Return_MaxTime						; 显示模式，5S返回时显

	lda		Sys_Status_Flag
	cmp		#0010B
	beq		L_Change_Ordinal_AD					; 判断当前状态是否已经是闹钟显示
	lda		#0010B
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
	sta		Sys_Status_Ordinal					; 子模式序号大于2时，重置子模式序号
L_Ordinal_Exit_AD:
	rts




; 切换到时钟设置模式
SwitchState_ClockSet:
	lda		#15
	sta		Return_MaxTime						; 设置模式，15S返回时显

	lda		Sys_Status_Flag
	cmp		#0100B
	beq		L_Change_Ordinal_CS					; 判断当前状态是否已经是时钟设置
	lda		#0100B
	sta		Sys_Status_Flag						; 当前状态非时设则切换至时设
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	bra		L_Ordinal_Exit_CS
L_Change_Ordinal_CS:
	inc		Sys_Status_Ordinal					; 当前状态为时设，则递增子模式序号
	lda		Sys_Status_Ordinal
	cmp		#6
	bcc		L_Ordinal_Exit_CS
	lda		#0
	sta		Sys_Status_Ordinal					; 子模式序号大于5时，则回到时显模式，并清空序号
	lda		#0001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_CS:
	smb0	Timer_Flag							; 退出后立即进行一次显示
	rmb1	Timer_Flag
	rts




; 切换到闹钟设置模式
SwitchState_AlarmSet:
	lda		#15
	sta		Return_MaxTime						; 设置模式，15S返回时显
	smb0	Timer_Flag							; 切换时给一个半S标志，立刻更新显示

	lda		Sys_Status_Flag
	cmp		#1000B
	beq		L_Change_Ordinal_AS					; 判断当前状态是否已经是闹钟设置
	lda		#1000B
	sta		Sys_Status_Flag						; 当前状态非闹设则切换至闹设
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	bra		L_Ordinal_Exit_AS
L_Change_Ordinal_AS:
	inc		Sys_Status_Ordinal					; 当前状态为闹设，则递增子模式序号
	lda		Sys_Status_Ordinal
	cmp		#9
	bcc		L_Ordinal_Exit_AS
	lda		#0
	sta		Sys_Status_Ordinal					; 子模式序号大于8时，则回到时显模式，并清空序号
	lda		#0001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_AS:
	smb0	Timer_Flag							; 退出后立即进行一次显示
	rmb1	Timer_Flag
	rts




; 切换灯光亮度
; 0熄屏，1低亮，2高亮
LightLevel_Change:
	dec		Backlight_Level						; 递减亮度等级

	lda		Backlight_Level						; 熄屏后亮度在唤醒里切换
	bne		No_Level0
	smb4	PD									; 熄屏
	smb0	PC
	rts
No_Level0:
	rmb4	PD									; 低亮
	rmb0	PC
	rts






; 进入贪睡模式
Alarm_Snooze:
	smb6	Clock_Flag							; 贪睡按键触发						
	smb3	Clock_Flag							; 进入贪睡模式
	rmb2	Clock_Flag							; 关闭响闹模式

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




; 12、24h模式切换
Switch_TimeMode:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	rmb6	Key_Flag							; 清除DP显示

	bbr2	Key_Flag,SW_TimeMode_Exit
	lda		#0
	sta		Sys_Status_Ordinal					; 如果是轮显模式，切换小时制会回到时显
SW_TimeMode_Exit:
	smb0	Timer_Flag							; 退出后立即进行一次显示
	rmb1	Timer_Flag
	rts




; 切换温度单位
TemperMode_Change:
	lda		RFC_Flag							; 取反标志位，切换华氏度和摄氏度
	eor		#00010000B
	sta		RFC_Flag
	jsr		F_Display_Temper

	rts




; 时设模式增数
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




; 闹设模式增数
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
	cmp		#5
	bne		No_AS_Alarm2_MinAdd
	jmp		L_Alarm2Min_Add
No_AS_Alarm2_MinAdd:
	cmp		#6
	bne		No_AS_Alarm3_Switch
	jmp		L_Alarm3_Switch
No_AS_Alarm3_Switch:
	cmp		#7
	bne		No_AS_Alarm3_HourAdd
	jmp		L_Alarm3Hour_Add
No_AS_Alarm3_HourAdd:
	jmp		L_Alarm3Min_Add




; 时设模式减数
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
	cmp		#5
	bne		No_AS_Alarm2_MinSub
	jmp		L_Alarm2Min_Sub
No_AS_Alarm2_MinSub:
	cmp		#6
	bne		No_AS_Alarm3_Switch2
	jmp		L_Alarm3_Switch
No_AS_Alarm3_Switch2:
	cmp		#7
	bne		No_AS_Alarm3_HourSub
	jmp		L_Alarm3Hour_Sub
No_AS_Alarm3_HourSub:
	jmp		L_Alarm3Min_Sub





; 时增加
L_TimeHour_Add:
	lda		R_Time_Hour
	cmp		#23
	bcs		TimeHour_AddOverflow
	inc		R_Time_Hour
	bra		TimeHour_Add_Exit
TimeHour_AddOverflow:
	lda		#0
	sta		R_Time_Hour
TimeHour_Add_Exit:
	jsr		F_Display_Time
	rts

; 时减少
L_TimeHour_Sub:
	lda		R_Time_Hour
	beq		TimeHour_SubOverflow
	dec		R_Time_Hour
	bra		TimeHour_Sub_Exit
TimeHour_SubOverflow:
	lda		#23
	sta		R_Time_Hour
TimeHour_Sub_Exit:
	jsr		F_Display_Time
	rts




; 分增加
L_TimeMin_Add:
	lda		#0
	sta		R_Time_Sec							; 调整分钟会清空秒

	lda		R_Time_Min
	cmp		#59
	bcs		TimeMin_AddOverflow
	inc		R_Time_Min
	bra		TimeMin_Add_Exit
TimeMin_AddOverflow:
	lda		#0
	sta		R_Time_Min
TimeMin_Add_Exit:
	jsr		F_Display_Time
	rts

; 分减少
L_TimeMin_Sub:
	lda		#0
	sta		R_Time_Sec							; 调整分钟会清空秒

	lda		R_Time_Min
	beq		TimeMin_SubOverflow
	dec		R_Time_Min
	bra		TimeMin_Sub_Exit
TimeMin_SubOverflow:
	lda		#59
	sta		R_Time_Min
TimeMin_Sub_Exit:
	jsr		F_Display_Time
	rts




; 年增加
L_DateYear_Add:
	lda		R_Date_Year
	cmp		#99
	bcs		DateYear_AddOverflow
	inc		R_Date_Year
	bra		DateYear_Add_Exit
DateYear_AddOverflow:
	lda		#0
	sta		R_Date_Year
DateYear_Add_Exit:
	jsr		F_Is_Leap_Year
	jsr		L_DisDate_Year
	rts

; 年减少
L_DateYear_Sub:
	lda		R_Date_Year
	beq		DateYear_SubOverflow
	dec		R_Date_Year
	bra		DateYear_Sub_Exit
DateYear_SubOverflow:
	lda		#99
	sta		R_Date_Year
DateYear_Sub_Exit:
	jsr		F_Is_Leap_Year
	jsr		L_DisDate_Year
	rts




; 月增加
L_DateMonth_Add:
	lda		R_Date_Month
	cmp		#12
	bcs		DateMonth_AddOverflow
	inc		R_Date_Month
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为1日
	bra		DateMonth_Add_Exit
DateMonth_AddOverflow:
	lda		#1
	sta		R_Date_Month
DateMonth_Add_Exit:
	jsr		L_DisDate_Month
	rts

; 月减少
L_DateMonth_Sub:
	lda		R_Date_Month
	cmp		#1
	beq		DateMonth_SubOverflow
	dec		R_Date_Month
	bra		DateMonth_Sub_Exit
DateMonth_SubOverflow:
	lda		#12
	sta		R_Date_Month
DateMonth_Sub_Exit:
	jsr		L_DisDate_Month
	rts




; 日增加
L_DateDay_Add:
	inc		R_Date_Day
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为1日
	jsr		L_DisDate_Day
	rts

; 日减少
L_DateDay_Sub:
	lda		R_Date_Day
	cmp		#1
	beq		DateDay_SubOverflow
	dec		R_Date_Day
	bra		DateDay_Sub_Exit
DateDay_SubOverflow:
	bbr0	Calendar_Flag,Common_Year_Get
	ldx		R_Date_Month
	dex
	lda		L_Table_Month_Leap,x
	sta		R_Date_Day
	bra		DateDay_Sub_Exit
Common_Year_Get:
	ldx		R_Date_Month
	dex
	lda		L_Table_Month_Common,x
	sta		R_Date_Day
DateDay_Sub_Exit:
	jsr		L_DisDate_Day
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
	cmp		#23
	bcs		Alarm1Hour_AddOverflow
	inc		R_Alarm1_Hour
	bra		Alarm1Hour_Add_Exit
Alarm1Hour_AddOverflow:
	lda		#0
	sta		R_Alarm1_Hour
Alarm1Hour_Add_Exit:
	jsr		F_AlarmHour_Set
	rts

; 闹钟1小时减少
L_Alarm1Hour_Sub:
	lda		R_Alarm1_Hour
	beq		Alarm1Hour_SubOverflow
	dec		R_Alarm1_Hour
	bra		Alarm1Hour_Sub_Exit
Alarm1Hour_SubOverflow:
	lda		#23
	sta		R_Alarm1_Hour
Alarm1Hour_Sub_Exit:
	jsr		F_AlarmHour_Set
	rts

; 闹钟1分增加
L_Alarm1Min_Add:
	lda		R_Alarm1_Min
	cmp		#59
	bcs		Alarm1Min_AddOverflow
	inc		R_Alarm1_Min
	bra		Alarm1Min_Add_Exit
Alarm1Min_AddOverflow:
	lda		#0
	sta		R_Alarm1_Min
Alarm1Min_Add_Exit:
	jsr		F_AlarmMin_Set
	rts

; 闹钟1分钟减少
L_Alarm1Min_Sub:
	lda		R_Alarm1_Min
	beq		Alarm1Min_SubOverflow
	dec		R_Alarm1_Min
	bra		Alarm1Min_Sub_Exit
Alarm1Min_SubOverflow:
	lda		#59
	sta		R_Alarm1_Min
Alarm1Min_Sub_Exit:
	jsr		F_AlarmMin_Set
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
	cmp		#23
	bcs		Alarm2Hour_AddOverflow
	inc		R_Alarm2_Hour
	bra		Alarm2Hour_Add_Exit
Alarm2Hour_AddOverflow:
	lda		#0
	sta		R_Alarm2_Hour
Alarm2Hour_Add_Exit:
	jsr		F_AlarmHour_Set
	rts

; 闹钟2小时减少
L_Alarm2Hour_Sub:
	lda		R_Alarm2_Hour
	beq		Alarm2Hour_SubOverflow
	dec		R_Alarm2_Hour
	bra		Alarm2Hour_Sub_Exit
Alarm2Hour_SubOverflow:
	lda		#23
	sta		R_Alarm2_Hour
Alarm2Hour_Sub_Exit:
	jsr		F_AlarmHour_Set
	rts


; 闹钟2分增加
L_Alarm2Min_Add:
	lda		R_Alarm2_Min
	cmp		#59
	bcs		Alarm2Min_AddOverflow
	inc		R_Alarm2_Min
	bra		Alarm2Min_Add_Exit
Alarm2Min_AddOverflow:
	lda		#0
	sta		R_Alarm2_Min
Alarm2Min_Add_Exit:
	jsr		F_AlarmMin_Set
	rts

; 闹钟2分钟减少
L_Alarm2Min_Sub:
	lda		R_Alarm2_Min
	beq		Alarm2Min_SubOverflow
	dec		R_Alarm2_Min
	bra		Alarm2Min_Sub_Exit
Alarm2Min_SubOverflow:
	lda		#59
	sta		R_Alarm2_Min
Alarm2Min_Sub_Exit:
	jsr		F_AlarmMin_Set
	rts




; 闹钟3开关
L_Alarm3_Switch:
	lda		Alarm_Switch
	eor		#100B
	sta		Alarm_Switch
	rts

; 闹钟3小时增加
L_Alarm3Hour_Add:
	lda		R_Alarm3_Hour
	cmp		#23
	bcs		Alarm3Hour_AddOverflow
	inc		R_Alarm3_Hour
	bra		Alarm3Hour_Add_Exit
Alarm3Hour_AddOverflow:
	lda		#0
	sta		R_Alarm3_Hour
Alarm3Hour_Add_Exit:
	jsr		F_AlarmHour_Set
	rts

; 闹钟3小时减少
L_Alarm3Hour_Sub:
	lda		R_Alarm3_Hour
	beq		Alarm3Hour_SubOverflow
	dec		R_Alarm3_Hour
	bra		Alarm3Hour_Sub_Exit
Alarm3Hour_SubOverflow:
	lda		#23
	sta		R_Alarm3_Hour
Alarm3Hour_Sub_Exit:
	jsr		F_AlarmHour_Set
	rts

; 闹钟3分增加
L_Alarm3Min_Add:
	lda		R_Alarm3_Min
	cmp		#59
	bcs		Alarm3Min_AddOverflow
	inc		R_Alarm3_Min
	bra		Alarm3Min_Add_Exit
Alarm3Min_AddOverflow:
	lda		#0
	sta		R_Alarm3_Min
Alarm3Min_Add_Exit:
	jsr		F_AlarmMin_Set
	rts

; 闹钟3分钟减少
L_Alarm3Min_Sub:
	lda		R_Alarm3_Min
	beq		Alarm3Min_SubOverflow
	dec		R_Alarm3_Min
	bra		Alarm3Min_Sub_Exit
Alarm3Min_SubOverflow:
	lda		#59
	sta		R_Alarm3_Min
Alarm3Min_Sub_Exit:
	jsr		F_AlarmMin_Set
	rts




; 天数是否溢出的判断
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
