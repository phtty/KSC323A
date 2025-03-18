; 按键处理
F_KeyHandler:
	bbs3	Timer_Flag,L_Key4Hz					; 快加到来则4Hz扫一次，控制快加频率
	bbr1	Key_Flag,L_KeyScan					; 首次按键触发
	rmb1	Key_Flag							; 复位首次触发
	jsr		L_KeyDelay
	lda		PA
	eor		#$1c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$1c
	bne		L_KeyYes							; 检测是否有按键触发
	jmp		L_KeyNoScanExit
L_KeyYes:
	rmb4	IER									; 按键确定触发后，关闭中断避免误触发
	sta		PA_IO_Backup
	bra		L_KeyHandle							; 首次触发处理结束

L_Key4Hz:
	bbr5	Key_Flag,L_KeyScanExit
	rmb5	Key_Flag
L_KeyScan:										; 长按处理部分
	bbr0	Key_Flag,L_KeyNoScanExit			; 没有扫键标志则为无按键处理了，判断是否取消禁用RFC采样

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
	bbs3	Timer_Flag,NoQuikAdd_Beep
	jsr		L_Key_Beep
NoQuikAdd_Beep:
	smb3	Timer_Flag
	rmb5	Key_Flag


L_KeyHandle:
	jsr		F_KeyMatrix_PC5Scan_Ready			; 判断Down键和Backlight键
	lda		PA
	eor		#$0c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$0c
	cmp		#$04
	bne		No_KeyDTrigger						; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	jmp		L_KeyDTrigger
No_KeyDTrigger:
	cmp		#$08
	bne		No_KeyBTrigger
	jmp		L_KeyBTrigger
No_KeyBTrigger:
	jsr		F_KeyMatrix_PC4Scan_Ready			; 判断Mode键、Alarm键、Up键
	lda		PA
	eor		#$1c								; 按键是反逻辑的，将指定的几位按键口取反
	and		#$1c
	cmp		#$04
	bne		No_KeyUTrigger
	jmp		L_KeyUTrigger
No_KeyUTrigger:
	cmp		#$08
	bne		No_KeyATrigger
	jmp		L_KeyATrigger
No_KeyATrigger:
	cmp		#$10
	bne		L_KeyExit
	jmp		L_KeyMTrigger						; M键触发

L_KeyExit:
	rmb1	TMRC								; 关闭快加16Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter
	sta		SpecialKey_Flag
	sta		Counter_DP
	jsr		F_KeyMatrix_Reset
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	smb4	IER									; 按键处理结束，重新开启PA口中断
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
	bbs3	Timer_Flag,SpecialKey_NoBeep
	jsr		L_Key_Beep
SpecialKey_NoBeep:
	bbs0	SpecialKey_Flag,L_KeyA_ShortHandle	; 短按的特殊功能处理
	bbs1	SpecialKey_Flag,L_KeyB_ShortHandle
	bbs2	SpecialKey_Flag,L_KeyM_ShortHandle
	bbs3	SpecialKey_Flag,L_KeyU_ShortHandle
	bbs4	SpecialKey_Flag,L_KeyD_ShortHandle
L_KeyA_ShortHandle:
	lda		Sys_Status_Flag
	cmp		#1000B
	bne		No_SwitchState_AlarmSet				; 闹设模式切换设置内容
	jsr		SwitchState_AlarmSet
	rts
No_SwitchState_AlarmSet:
	jsr		SwitchState_AlarmDis				; 切换闹钟显示状态
	rts

L_KeyB_ShortHandle:
	jsr		LightLevel_Change					; 三档亮度切换
	rts

L_KeyM_ShortHandle:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		No_SwitchState_ClockSet
	jsr		SwitchState_ClockSet				; 时设模式切换设置内容
	rts
No_SwitchState_ClockSet:
	jsr		SwitchState_ClockDis				; 显示模式下切换日期显示、时间显示模式
	rts

L_KeyU_ShortHandle:
	lda		Sys_Status_Flag
	and		#0011B
	beq		KeyU_NoDisMode
	lda		#0001B
	sta		Sys_Status_Flag
	jsr		DM_SW_TimeMode						; 显示模式下切换12/24h模式
	rts
KeyU_NoDisMode:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyU
	jsr		AddNum_CS							; 时设模式增数
	rts
StatusCS_No_KeyU:
	cmp		#1000B
	bne		KeyU_ShortHandle_Exit
	jsr		AddNum_AS							; 闹设模式增数
KeyU_ShortHandle_Exit:
	rts

L_KeyD_ShortHandle:
	lda		Sys_Status_Flag
	and		#0011B
	beq		KeyD_NoDisMode
	jsr		SwitchState_DisMode					; 切换固显-轮显	
	rts
KeyD_NoDisMode:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyD_Short
	jsr		SubNum_CS							; 时设模式减数
	rts
StatusCS_No_KeyD_Short:
	cmp		#1000B
	bne		KeyD_ShortHandle_Exit
	jsr		SubNum_AS							; 闹设模式减数
KeyD_ShortHandle_Exit:
	rts



; 按键触发函数，处理每个按键触发后的响应条件
L_KeyATrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyA
	jmp		L_KeyExit							; 时钟设置模式A键无效
StatusCS_No_KeyA:
	cmp		#1000B
	bne		StatusAS_No_KeyA
	bbr3	Timer_Flag,L_ASMode_KeyA_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; 闹钟设置模式A键长按无效
L_ASMode_KeyA_ShortTri:
	smb0	SpecialKey_Flag						; 闹设模式下，A键为特殊功能按键
	rts
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
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyM
	bbr3	Timer_Flag,L_CSMode_KeyM_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; 时设模式M键长按无效
L_CSMode_KeyM_ShortTri:
	smb2	SpecialKey_Flag
	rts
StatusCS_No_KeyM:
	cmp		#1000B
	bne		StatusAS_No_KeyM
	jmp		L_KeyExit							; 闹设模式M键无效
StatusAS_No_KeyM:
	bbs3	Timer_Flag,L_DisMode_KeyM_LongTri	; 判断显示模式下的M长按
	lda		Sys_Status_Flag
	and		#0011B
	beq		StatusDM_No_KeyM
	smb2	SpecialKey_Flag						; 显示模式下，M键为特殊功能按键
StatusDM_No_KeyM:
	rts
L_DisMode_KeyM_LongTri:
	jsr		SwitchState_ClockSet				; 从显示模式切换到时间设置模式
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyUTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹

	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyU				; 时钟显和闹显U键切换12/24h
	bbr3	Timer_Flag,L_DMode_KeyU_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; 显示模式U键长按无效
L_DMode_KeyU_ShortTri:
	smb3	SpecialKey_Flag
	rts
Status_NoDisMode_KeyU:
	bbr3	Timer_Flag,KeyU_NoQuikAdd
	rmb3	SpecialKey_Flag
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyU_Short
	jmp		AddNum_CS							; 时设模式增数
StatusCS_No_KeyU_Short:
	cmp		#1000B
	bne		L_KeyUTrigger_Exit
	jmp		AddNum_AS							; 闹设模式增数
KeyU_NoQuikAdd:
	smb3	SpecialKey_Flag
L_KeyUTrigger_Exit:
	rts


L_KeyDTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_Key_NoSnoozeLoud					; 按键处理贪睡和响闹

	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyD				; 判断是否为显示模式
	bbr3	Timer_Flag,L_DMode_KeyD_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; 显示模式D键长按无效
L_DMode_KeyD_ShortTri:
	smb4	SpecialKey_Flag
	rts
Status_NoDisMode_KeyD:
	bbr3	Timer_Flag,KeyD_NoQuikAdd
	rmb4	SpecialKey_Flag
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyD
	jmp		SubNum_CS							; 时设模式减数
StatusCS_No_KeyD:
	cmp		#1000B
	bne		L_KeyDTrigger_Exit
	jmp		SubNum_AS							; 闹设模式减数
KeyD_NoQuikAdd:
	smb4	SpecialKey_Flag
L_KeyDTrigger_Exit:
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


; 按键触发通用功能，包括按键矩阵GPIO状态重置，唤醒屏幕
; 同时会给出是否存在唤醒事件
; 由于打断贪睡和响闹的功能B键没有，故不在本函数内处理
L_Universal_TriggerHandle:
	jsr		F_KeyMatrix_Reset					; 按键矩阵的GPIO状态重置
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时

	bbs4	PD,WakeUp_Event						; 若此时熄屏，按键会导致亮屏
	bbs3	Timer_Flag,?Handle_Exit
	rmb1	Backlight_Flag
	lda		#0
	sta		Backlight_Counter
?Handle_Exit:
	rts
WakeUp_Event:
	rmb4	PD
	smb3	Key_Flag							; 熄屏状态有按键，则触发唤醒事件
	bbr0	Sys_Status_Flag,DP_2Mode_Reset
	bbr2	Key_Flag,DP_2Mode_Reset
	lda		#0
	sta		Sys_Status_Ordinal					; 时钟显示模式下熄屏亮屏会回到时显
DP_2Mode_Reset:
	jsr		L_Open_5020							; 亮屏开启LCD中断
	bbr2	Backlight_Flag,No_RFCMesure_KeyBeep	; 手动熄屏不会测量温湿度
	rmb2	Backlight_Flag
	jsr		F_RFC_MeasureStart					; 自动熄屏唤醒后立刻进行一次温湿度测量
No_RFCMesure_KeyBeep:
	pla
	pla
	jmp		L_KeyExit							; 唤醒触发的那次按键，没有按键功能
WakeUp_Event_Exit:
	rts


L_Key_Beep:
	lda		#10B								; 设置按键提示音的响铃序列
	sta		Beep_Serial
	smb0	TMRC								; 开TIM0蜂鸣器时钟
	smb4	Key_Flag							; 置位按键提示音标志
	rts

L_Key_NoBeep:
	lda		#0									; 清除按键提示音的响铃序列
	sta		Beep_Serial
	rmb0	TMRC								; 关TIM0蜂鸣器时钟
	rmb4	Key_Flag							; 复位按键提示音标志
	rts




; 时钟模式的时显和日显切换
SwitchState_ClockDis:
	bbs0	Sys_Status_Flag,CD_ModeCHG
	lda		#0
	sta		Sys_Status_Ordinal					; 从别的模式切换到时显时，需要清空一次子模式
CD_ModeCHG:
	lda		Sys_Status_Ordinal					; 对第一位取反，在日期显示和时间显示之间切换
	eor		#1
	sta		Sys_Status_Ordinal

	lda		#0001B
	sta		Sys_Status_Flag						; 切换时钟显示

	rmb6	Key_Flag							; 清除DP显示

	bbr0	Sys_Status_Ordinal,?SWState_ClockDis_Eixt
	lda		#5
	sta		Return_MaxTime						; 日显示模式，返回时间设为5S
	jsr		F_Date_Display
	rts
?SWState_ClockDis_Eixt:
	jsr		L_TimeDot_Out
	rts




; 切换轮流显示-固定显示
SwitchState_DisMode:
	smb7	Key_Flag							; 设置DP显示1S标志
	smb6	Key_Flag							; 设置DP显示标志
	lda		#0
	sta		Counter_DP
	sta		Sys_Status_Ordinal
	lda		#0001B
	sta		Sys_Status_Flag						; 切换轮、固显会将当前状态设置为时显

	lda		Key_Flag
	eor		#100B
	sta		Key_Flag							; 取反轮显标志位

	jsr		F_Clock_Display
	rts




; 切换到闹钟显示状态
SwitchState_AlarmDis:
	lda		#5
	sta		Return_MaxTime						; 显示模式，5S返回时显
	jsr		DP_Display_Over						; 清空DP模式和计时，防止回去继续显示DP

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
	jsr		DP_Display_Over						; 清空DP模式和计时，防止回去继续显示DP

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
	jsr		DP_Display_Over						; 清空DP模式和计时，防止回去继续显示DP

	lda		Sys_Status_Flag
	cmp		#1000B
	beq		L_Change_Ordinal_AS					; 判断当前状态是否已经是闹钟设置
	bbr1	Sys_Status_Flag,No_AlarmDis2Set
	lda		#1000B
	sta		Sys_Status_Flag						; 当前状态非闹设则切换至闹设
	lda		Sys_Status_Ordinal					; 若当前处于闹显状态
	clc
	rol
	clc
	adc		Sys_Status_Ordinal					; 则对当前显示的闹组设置
	sta		Sys_Status_Ordinal
	bra		L_Ordinal_Exit_AS
No_AlarmDis2Set:
	lda		#0
	sta		Sys_Status_Ordinal					; 清零子模式序号
	lda		#1000B
	sta		Sys_Status_Flag						; 当前状态非闹设则切换至闹设
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
; 0熄屏，1低亮
LightLevel_Change:
	lda		Backlight_Level
	beq		Level0

	lda		#0
	sta		Backlight_Level
	rmb4	PD									; 低亮
	rmb0	PC
	rmb0	PC_IO_Backup

	rts

Level0:
	rmb0	PC
	jsr		L_Close_5020						; 熄屏后关闭LCD中断
	lda		#1
	sta		Backlight_Level
	smb4	PD									; 下一次亮屏是高亮
	smb0	PC_IO_Backup						; 设置记忆亮度为高亮，下次唤醒为高亮
	rmb3	Key_Flag							; 置零屏幕唤醒标志
	rmb2	Backlight_Flag						; 手动熄屏，按键唤醒不进行温湿度测量
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




; 时钟设置下的12、24h模式切换
ClockSet_SW_TimeMode:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	jsr		L_Dis_xxHr
	rts

; 显示模式下12、24h模式切换
DM_SW_TimeMode:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	rmb6	Key_Flag							; 清除DP显示
	lda		#0
	sta		Sys_Status_Ordinal					; 如果是轮显模式，切换小时制会回到时显

	jsr		F_Display_Time
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
	jmp		ClockSet_SW_TimeMode
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
	jsr		L_A_Div_3
	cmp		#0
	bne		No_AlarmSwitch_AddCHG
	lda		#1
	jsr		L_A_LeftShift_XBit
	jmp		L_Alarm_Switch
No_AlarmSwitch_AddCHG:
	cmp		#1
	bne		No_AlarmHourSet_Add
	jmp		L_AlarmHour_Add						; 闹钟小时减数
No_AlarmHourSet_Add:
	jmp		L_AlarmMin_Add						; 闹钟分钟减数




; 时设模式减数
SubNum_CS:
	lda		Sys_Status_Ordinal
	bne		No_CS_TMSwitch2
	jmp		ClockSet_SW_TimeMode
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
	jsr		L_A_Div_3
	cmp		#0
	bne		No_AlarmSwitch_SubCHG
	lda		#1
	jsr		L_A_LeftShift_XBit
	jmp		L_Alarm_Switch
No_AlarmSwitch_SubCHG:
	cmp		#1
	bne		No_AlarmHourSet_Sub
	jmp		L_AlarmHour_Sub						; 闹钟小时减数
No_AlarmHourSet_Sub:
	jmp		L_AlarmMin_Sub						; 闹钟分钟减数




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
	jsr		L_LightLevel_WithKeyU
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
	jsr		L_LightLevel_WithKeyD
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
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为当前允许最大日
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
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为当前允许最大日
	jsr		F_Is_Leap_Year
	jsr		L_DisDate_Year
	rts




; 月增加
L_DateMonth_Add:
	lda		R_Date_Month
	cmp		#12
	bcs		DateMonth_AddOverflow
	inc		R_Date_Month
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为当前允许最大日
	bra		DateMonth_Add_Exit
DateMonth_AddOverflow:
	lda		#1
	sta		R_Date_Month
DateMonth_Add_Exit:
	jsr		F_Date_Display
	rts

; 月减少
L_DateMonth_Sub:
	lda		R_Date_Month
	cmp		#1
	beq		DateMonth_SubOverflow
	dec		R_Date_Month
	jsr		L_DayOverflow_Juge					; 若当前日期超过当前月份允许的最大值，则日期变为当前允许最大日
	bra		DateMonth_Sub_Exit
DateMonth_SubOverflow:
	lda		#12
	sta		R_Date_Month
DateMonth_Sub_Exit:
	jsr		F_Date_Display
	rts




; 日增加
L_DateDay_Add:
	inc		R_Date_Day
	jsr		L_DayOverflow_To_1					; 若当前日期超过当前月份允许的最大值，则日期变为1日
	jsr		F_Date_Display
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
	jsr		F_Date_Display
	rts





; 闹钟开关
; A闹钟组（按bit）
L_Alarm_Switch:
	eor		Alarm_Switch
	sta		Alarm_Switch
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_Alarm_SwitchStatue				; 刷新一次闹钟开关显示
	rts


; 闹钟分增加
; X闹钟组，0~2
L_AlarmMin_Add:
	lda		Alarm_MinAddr,x
	cmp		#59
	bcs		AlarmMin_AddOverflow
	clc
	adc		#1
	sta		Alarm_MinAddr,x
	bra		AlarmMin_Add_Exit
AlarmMin_AddOverflow:
	lda		#0
	sta		Alarm_MinAddr,x
AlarmMin_Add_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmMin_Set
	rts

; 闹钟分减少
; X闹钟组，0~2
L_AlarmMin_Sub:
	lda		Alarm_MinAddr,x
	beq		AlarmMin_SubOverflow
	sec
	sbc		#1
	sta		Alarm_MinAddr,x
	bra		AlarmMin_Sub_Exit
AlarmMin_SubOverflow:
	lda		#59
	sta		Alarm_MinAddr,x
AlarmMin_Sub_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmMin_Set
	rts


; 闹钟时增加
; X闹钟组，0~2
L_AlarmHour_Add:
	lda		Alarm_HourAddr,x
	cmp		#23
	bcs		AlarmHour_AddOverflow
	clc
	adc		#1
	sta		Alarm_HourAddr,x
	bra		AlarmHour_Add_Exit
AlarmHour_AddOverflow:
	lda		#0
	sta		Alarm_HourAddr,x
AlarmHour_Add_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmHour_Set
	rts

; 闹钟时减少
; X闹钟组，0~2
L_AlarmHour_Sub:
	lda		Alarm_HourAddr,x
	beq		AlarmHour_SubOverflow
	sec
	sbc		#1
	sta		Alarm_HourAddr,x
	bra		AlarmHour_Sub_Exit
AlarmHour_SubOverflow:
	lda		#23
	sta		Alarm_HourAddr,x
AlarmHour_Sub_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmHour_Set
	rts




; 天数是否溢出的判断
L_DayOverflow_Juge:
	jsr		F_Is_Leap_Year
	bbs0	Calendar_Flag,L_LeapYear_Handle		; 平年闰年的表分开查
	ldx		R_Date_Month						; 查平年每月份天数表
	dex
	lda		L_Table_Month_Common,x
	sta		P_Temp
	bra		Day_Overflow_Juge
L_LeapYear_Handle:
	ldx		R_Date_Month						; 查闰年每月份天数表
	dex
	lda		L_Table_Month_Leap,x
	sta		P_Temp
Day_Overflow_Juge:
	lda		P_Temp								; 当前日期和天数表的日期对比
	cmp		R_Date_Day
	bcs		DateDay_NoOverflow
	lda		P_Temp
	sta		R_Date_Day
DateDay_NoOverflow:
	rts

; 天数是否溢出的判断
L_DayOverflow_To_1:
	jsr		F_Is_Leap_Year
	bbs0	Calendar_Flag,L_LeapYear_Handle2	; 平年闰年的表分开查
	ldx		R_Date_Month						; 查平年每月份天数表
	dex
	lda		L_Table_Month_Common,x
	sta		P_Temp
	bra		Day_Overflow_Juge2
L_LeapYear_Handle2:
	ldx		R_Date_Month						; 查闰年每月份天数表
	dex
	lda		L_Table_Month_Leap,x
	sta		P_Temp
Day_Overflow_Juge2:
	lda		P_Temp								; 当前日期和天数表的日期对比
	cmp		R_Date_Day
	bcs		DateDay_NoOverflow2
	lda		#1
	sta		R_Date_Day
DateDay_NoOverflow2:
	rts


L_KeyDelay:
	lda		#0
	sta		P_Temp
DelayLoop:
	inc		P_Temp
	lda		P_Temp
	cmp		#129
	bcc		DelayLoop
	
	rts
