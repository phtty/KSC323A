; 按键处理
F_KeyTrigger:
	bbs3	Timer_Flag,L_Key16Hz				; 有快加则直接判断16Hz标志位
	bbr1	Key_Flag,L_KeyScan					; 首次按键触发
	rmb1	Key_Flag
	lda		#$00
	sta		P_Temp
L_DelayTrigger:									; 消抖延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_DelayTrigger						; 软件消抖
	lda		PA
	and		#$1c
	cmp		#$00
	bne		L_KeyYes							; 检测是否有按键触发
	bra		L_KeyExit
	rts
L_KeyYes:
	sta		PA_IO_Backup
	bra		L_KeyHandle							; 首次触发处理结束

L_KeyScan:										; 长按处理部分
	bbr0	Key_Flag,L_Key16HzExit				; 没有扫键标志直接退出
L_Key16Hz:
	bbr4	Timer_Flag,L_Key16HzExit			; 16Hz标志位到来前也不进行按键处理(快加时)
	rmb4	Timer_Flag
	jsr		F_QuikAdd_Scan						; 矩阵扫描，需要开启IO口
	lda		PA
	and		#$1c
	cmp		PA_IO_Backup						; 若检测到有按键的状态变化则退出快加判断并结束
	beq		L_16Hz_Count
	jsr		F_SpecialKey_Handle					; 长按终止时，进行一次特殊按键的处理
	bra		L_KeyExit
L_16Hz_Count:
	inc		QuickAdd_Counter
	lda		QuickAdd_Counter
	cmp		#32
	bcs		L_QuikAdd
	rts											; 长按计时，必须满2S才有快加
L_QuikAdd:
	smb3	Timer_Flag

L_KeyHandle:
	jsr		F_KeyMatrix_PC4Scan_Ready			; 判断Alarm键和Backlight键
	lda		PA
	and		#$0c
	cmp		#$04
	bne		No_KeyATrigger						; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	jsr		L_KeyATrigger
No_KeyATrigger:
	cmp		#$08
	bne		No_KeyBTrigger
	jsr		L_KeyBTrigger
No_KeyBTrigger:
	jsr		F_KeyMatrix_PC5Scan_Ready			; 判断Mode键、Up键、Down键
	lda		PA
	and		#$1c
	cmp		#$04
	bne		No_KeyMTrigger
	jsr		L_KeyMTrigger
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
	rmb1	Key_Flag
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter
	jsr		F_KeyMatrix_Reset
L_Key16HzExit:
	rts

F_SpecialKey_Handle:							; 特殊按键的处理
	lda		SpecialKey_Flag
	bne		SpecialKey_Handle
	rts
SpecialKey_Handle:
	bbs3	Timer_Flag,LongPress_Handle			; 通过有无快加判断是短按还是长按

	bbs0	SpecialKey_Flag, L_KeyA_ShortHandle	; 短按的特殊功能处理
	bbs1	SpecialKey_Flag, L_KeyB_ShortHandle
	bbs2	SpecialKey_Flag, L_KeyM_ShortHandle
L_KeyA_ShortHandle:
	; 这里是进闹钟显示模式的业务逻辑函数
L_KeyB_ShortHandle:
	; 这里是三档亮度切换的业务逻辑函数
L_KeyM_ShortHandle:
	; 这里是切换三种时钟显示模式的业务逻辑函数
	rts

LongPress_Handle:
	bbs0	SpecialKey_Flag, L_KeyA_LongHandle	; 长按的特殊功能处理
	bbs1	SpecialKey_Flag, L_KeyB_LongHandle
	bbs2	SpecialKey_Flag, L_KeyM_LongHandle
L_KeyA_LongHandle:
	; 这里是进闹钟设置模式的业务逻辑函数
L_KeyB_LongHandle:
	; 这里是切换摄氏-华氏度的业务逻辑函数
L_KeyM_LongHandle:
	; 这里是进时间设置模式的业务逻辑函数
	rts

; 按键触发函数，处理每个按键触发后的响应条件
L_KeyATrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyA
	rmb1	Key_Flag							; 复位首次触发
	jsr		L_KeyExit							; 时钟设置模式A键无效
StatusCS_No_KeyA:
	cmp		#00100000B
	bne		StatusAS_No_KeyA
	bbr1	Key_Flag,StatusCS_KeyA_NoFirst		; 每次按键只进1次
	rmb1	Key_Flag							; 复位首次触发
StatusCS_KeyA_NoFirst:
	; 这里是闹钟设置模式A键的业务逻辑函数
StatusAS_No_KeyA:
	smb0	SpecialKey_Flag						; 显示模式下，A键为特殊功能按键
	rts


L_KeyBTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	
	bbr2	Clock_Flag,StatusLM_No_KeyB
	; 这里是响闹时贪睡的业务逻辑函数
StatusLM_No_KeyB:
	smb1	SpecialKey_Flag
	rts


L_KeyMTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

	lda		Sys_Status_Flag
	cmp		#00010000B
	bne		StatusCS_No_KeyM
	bbr1	Key_Flag,StatusCS_KeyM_NoFirst		; 每次按键只进1次
	rmb1	Key_Flag							; 复位首次触发
StatusCS_KeyM_NoFirst:
	; 这里是时钟设置模式M键的业务逻辑函数
StatusCS_No_KeyM:
	cmp		#00100000B
	bne		StatusAS_No_KeyM
	rmb1	Key_Flag							; 复位首次触发
	jsr		L_KeyExit							; 闹钟设置模式M键无效
StatusAS_No_KeyM:
	smb2	SpecialKey_Flag						; 显示模式下，M键为特殊功能按键
	rts


L_KeyUTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹
	
	rts


L_KeyDTrigger:
	jsr		L_Universal_TriggerHandle			; 通用按键处理
	jsr		L_NoSnooze_CloseLoud				; 打断贪睡和响闹

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
	smb4	PD
	jsr		F_DisPlay_Frame						; 按键会唤醒屏幕显示
No_WakeUp_Screen:
	lda		#0
	sta		Backlight_Counter					; 清空亮屏幕计数

	rts



; 非4D模式下的D键处理
L_KeyDTrigger_No4DMode:
	lda		#0010B
	sta		Sys_Status_Flag

	lda		#0
	ldx		#lcd_d0
	jsr		L_Dis_15Bit_DigitDot
	lda		#0
	ldx		#lcd_d1
	jsr		L_Dis_15Bit_DigitDot
	lda		#0
	ldx		#lcd_d2
	jsr		L_Dis_15Bit_DigitDot
	lda		#0
	ldx		#lcd_d3
	jsr		L_Dis_15Bit_DigitDot

	pla
	pla
	jmp		MainLoop




; 走时模式下的U键处理
L_KeyUTrigger_RunTimeMode:

	rts

; 走时模式下的S键处理
L_KeySTrigger_RunTimeMode:
	lda		#00000100B
	sta		Sys_Status_Flag						; 12h/24h切换
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	smb2	Key_Flag							; 非走时状态
	pla
	pla
	jmp		MainLoop




; 4D模式的D、K键处理
L_KeyKTrigger_4DMode:
L_KeyDTrigger_4DMode:

	rts

; 4D模式的U键处理
L_KeyUTrigger_4DMode:
	lda		#0
	sta		Return_Counter
	sta		Frame_Counter
	sta		Frame_Serial
	sta		Anim_Phase
	rmb2	Key_Flag
	jsr		L_Return_Stop						; 4D模式下U键可以回到时间模式
	rts

; 4D模式的S键处理
L_KeySTrigger_4DMode:
	pla
	pla
	jmp		MainLoop





; 12、24h时间模式切换的U键处理
L_KeyUTrigger_TimeMode_Set:
	lda		Clock_Flag
	eor		#01									; 翻转12/24h模式的状态
	sta		Clock_Flag

	rts

; 12、24h时间模式切换的S键处理
L_KeySTrigger_TimeMode_Set:
	lda		#00001000B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		F_Display_Time
	pla
	pla
	jmp		MainLoop




; 小时设置模式的U键处理
L_KeyUTrigger_HourSet:
	inc		R_Time_Hour
	lda		#23
	cmp		R_Time_Hour
	bcs		L_HourSet_Juge
	lda		#00
	sta		R_Time_Hour
L_HourSet_Juge:
	jsr		L_DisTime_Hour
	rts

; 小时设置模式的S键处理
L_KeySTrigger_HourSet:
	; 状态切换时应当初始化一次按键
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter

	lda		#00010000B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		F_Display_Time
	pla
	pla
	jmp		MainLoop




; 分钟设置模式的U键处理
L_KeyUTrigger_MinSet:
	lda		#0
	sta		R_Time_Sec							; 设置分会重置秒
	inc		R_Time_Min
	lda		#59
	cmp		R_Time_Min
	bcs		L_MinSet_Juge
	lda		#00
	sta		R_Time_Min
L_MinSet_Juge:
	jsr		L_DisTime_Min
	rts

; 分钟设置模式的S键处理
L_KeySTrigger_MinSet:
	; 状态切换时应当初始化一次按键
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter

	lda		#00100000B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		L_DisDate_Year
	pla
	pla
	jmp		MainLoop




; 年份设置模式的U键处理
L_KeyUTrigger_YearSet:
	lda		R_Date_Year
	cmp		#99
	bcc		L_Year_Juge
	lda		#0
	sta		R_Date_Year
	jsr		L_DisDate_Year
	rts
L_Year_Juge:
	inc		R_Date_Year							; 调整年份
	jsr		F_Is_Leap_Year						; 检查调整后的年份里日期有没有越界
	ldx		R_Date_Month						; 月份数作为索引，查月份天数表
	dex											; 表头从0开始，而月份是从1开始
	bbs0	Calendar_Flag,L_Leap_Year_Set2		; 闰年查闰年月份天数表
	lda		L_Table_Month_Common,x				; 否则查平年月份天数表
	bra		L_Day_Juge_Set2
L_Leap_Year_Set2:
	lda		L_Table_Month_Leap,x
L_Day_Juge_Set2:
	cmp		R_Date_Day
	bcs		L_Year_Add_Set
	lda		#1
	sta		R_Date_Day							; 日期如果超过当前月份最大值，则初始化日期
L_Year_Add_Set:
	jsr		L_DisDate_Year
	rts

; 年份设置模式的S键处理
L_KeySTrigger_YearSet:
	; 状态切换时应当初始化一次按键
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter

	lda		#01000000B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		F_Display_Date
	pla
	pla
	jmp		MainLoop




; 月份设置模式的U键处理
L_KeyUTrigger_MonthSet:
	lda		R_Date_Month
	cmp		#12
	bcc		L_Month_Juge
	lda		#1
	sta		R_Date_Month
	jsr		F_Display_Date
	rts
L_Month_Juge:
	inc		R_Date_Month						; 调整月份
	jsr		F_Is_Leap_Year						; 检查调整后的月份里日期有没有越界
	ldx		R_Date_Month						; 月份数作为索引，查月份天数表
	dex											; 表头从0开始，而月份是从1开始
	bbs0	Calendar_Flag,L_Leap_Year_Set1		; 闰年查闰年月份天数表
	lda		L_Table_Month_Common,x				; 否则查平年月份天数表
	bra		L_Day_Juge_Set1
L_Leap_Year_Set1:
	lda		L_Table_Month_Leap,x
L_Day_Juge_Set1:
	cmp		R_Date_Day
	bcs		L_Month_Add_Set
	lda		#1
	sta		R_Date_Day							; 日期如果和当前月份数不匹配，则初始化日期
L_Month_Add_Set:
	jsr		F_Display_Date
	rts

; 月份设置模式的S键处理
L_KeySTrigger_MonthSet:
	; 状态切换时应当初始化一次按键
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter

	lda		#10000000B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		F_Display_Date
	pla
	pla
	jmp		MainLoop




; 日期设置模式的U键处理
L_KeyUTrigger_DaySet:
	jsr		F_Is_Leap_Year
	ldx		R_Date_Month						; 月份数作为索引，查月份天数表
	dex											; 表头从0开始，而月份是从1开始
	bbs0	Calendar_Flag,L_Leap_Year_Set		; 闰年查闰年月份天数表
	lda		L_Table_Month_Common,x				; 否则查平年月份天数表
	bra		L_Day_Juge_Set
L_Leap_Year_Set:
	lda		L_Table_Month_Leap,x
L_Day_Juge_Set:
	cmp		R_Date_Day
	bne		L_Day_Add_Set
	lda		#1
	sta		R_Date_Day							; 日进位，重新回到1
	jsr		F_Display_Date						; 显示调整后的日期
	rts
L_Day_Add_Set:
	inc		R_Date_Day
	jsr		F_Display_Date						; 显示调整后的日期
	rts

; 日期设置模式的S键处理
L_KeySTrigger_DaySet:
	; 状态切换时应当初始化一次按键
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	rmb2	Key_Flag							; 回到走时模式，关闭30s计数
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter
	sta		Return_Counter

	lda		#00000001B
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	jsr		F_Display_Time
	pla
	pla
	jmp		MainLoop
