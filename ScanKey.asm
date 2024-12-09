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
	eor		#$1c								; 将指定的几位取反，用于检测1
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
	eor		#$1c								; 将指定的几位取反，用于检测1
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
	eor		#$0c								; 将指定的几位取反，用于检测1
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
	eor		#$1c								; 将指定的几位取反，用于检测1
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
	nop											; 这里是进闹钟显示模式的业务逻辑函数
	rts
L_KeyB_ShortHandle:
	nop											; 这里是三档亮度切换的业务逻辑函数
	rts
L_KeyM_ShortHandle:
	nop											; 这里是切换三种时钟显示模式的业务逻辑函数
	rts



; 按键触发函数，处理每个按键触发后的响应条件
L_KeyATrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyA
	jmp		L_KeyExit							; 时钟设置模式A键无效
StatusCS_No_KeyA:
	cmp		#00100000B
	bne		StatusAS_No_KeyA
	nop											; 这里是闹钟设置模式A键的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
StatusAS_No_KeyA:
	bbs3	Timer_Flag,L_DisMode_KeyA_LongTri
	smb0	SpecialKey_Flag						; 显示模式下，A键为特殊功能按键
	rts
L_DisMode_KeyA_LongTri:
	nop											; 这里是进闹钟设置模式的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyBTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理

	bbr2	Clock_Flag,StatusLM_No_KeyB
	nop											; 这里是响闹时贪睡的业务逻辑函数
	rts
StatusLM_No_KeyB:
	bbs3	Timer_Flag,L_DisMode_KeyB_LongTri
	smb1	SpecialKey_Flag
	rts
L_DisMode_KeyB_LongTri:
	nop											; 这里是切换摄氏-华氏度的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyMTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyM
	nop											; 这里是时钟设置模式M键的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
StatusCS_No_KeyM:
	cmp		#00100000B
	bne		StatusAS_No_KeyM
	jmp		L_KeyExit							; 闹钟设置模式M键无效
StatusAS_No_KeyM:
	bbs3	Timer_Flag,L_DisMode_KeyM_LongTri
	smb2	SpecialKey_Flag						; 显示模式下，M键为特殊功能按键
	rts
L_DisMode_KeyM_LongTri:
	nop											; 这里是进时间设置模式的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数


L_KeyUTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时
	
	lda		Sys_Status_Flag
	and		#00001101B
	beq		Status_NoDis_Mode					; 时显、闹显和轮显模式U键切换12/24h
	nop											; 这里是切换12/24h的业务逻辑函数
	jmp		L_KeyExit							; 快加时，不重复执行功能函数
Status_NoDis_Mode:
	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyU
	nop											; 这里是时设模式下的增数业务逻辑函数
StatusCS_No_KeyU:
	cmp		#00100000B
	bne		StatusAS_No_KeyU
	nop											; 这里是闹设模式下的增数业务逻辑函数
StatusAS_No_KeyU:
	rts


L_KeyDTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	lda		#0
	sta		Return_Counter						; 重置返回时显模式计时

	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyD
	nop											; 这里是时设模式减数业务逻辑函数
	rts
StatusCS_No_KeyD:
	cmp		#00100000B
	bne		StatusAS_No_KeyD
	nop											; 这里是闹设模式减数业务逻辑函数
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




; 12、24h时间模式切换的U键处理
L_KeyUTrigger_TimeMode_Set:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	rts