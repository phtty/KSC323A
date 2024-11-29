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
	rts
L_16Hz_Count:
	inc		QuickAdd_Counter
	lda		QuickAdd_Counter
	cmp		#32
	bcs		L_QuikAdd
	rts											; 长按计时，必须满2S才有快加
L_QuikAdd:
	smb3	Timer_Flag

L_KeyHandle:
	jsr		F_KeyMatrix_PC4Scan_Ready
	lda		PA									; 判断Alarm键和Backlight键
	and		#$0c
	cmp		#$04
	bne		No_KeyATrigger						; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	smb0	SpecialKey_Flag						; A键待处理
No_KeyATrigger:
	cmp		#$08
	bne		No_KeyBTrigger
	smb1	SpecialKey_Flag						; B键待处理
No_KeyBTrigger:
	jsr		F_KeyMatrix_PC5Scan_Ready
	lda		PA									; 判断Mode键、Up键、Down键
	and		#$1c
	cmp		#$04
	bne		No_KeyMTrigger
	smb2	SpecialKey_Flag						; M键待处理
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
	jsr		F_KeyMatrix_Reset
L_Key16HzExit:
	rts

F_SpecialKey_Handle:							; 特殊按键的处理
	lda		SpecialKey_Flag
	bne		SpecialKey_Handle
	rts
SpecialKey_Handle:
	bbs0	SpecialKey_Flag, L_KeyA_Handle
	bbs1	SpecialKey_Flag, L_KeyB_Handle
	bbs2	SpecialKey_Flag, L_KeyM_Handle
L_KeyA_Handle:
	jmp		L_KeyATrigger
L_KeyB_Handle:
	jmp		L_KeyBTrigger
L_KeyM_Handle:
	jmp		L_KeyMTrigger
	rts

; 根据状态进入不同的模式的按键处理
L_KeyATrigger:
	jsr		F_KeyMatrix_Reset
	
	lda		Sys_Status_Flag
	cmp		#00000001B
	bne		No_StatusTD_KeyA

No_StatusTD_KeyA:								; 非时间显示模式
	cmp		#00000010B
	bne		No_StatusDD_KeyA

No_StatusDD_KeyA:								; 非日期显示模式
	cmp		#00000100B
	bne		No_StatusRD_KeyA
	
No_StatusRD_KeyA:								; 非轮流显示模式
	cmp		#00000010B
	bne		No_StatusAD_KeyA
	
No_StatusAD_KeyA:								; 非闹钟显示模式
	rts

L_KeyBTrigger:
	jsr		F_KeyMatrix_Reset
	
	rts

L_KeyMTrigger:
	jsr		F_KeyMatrix_Reset
	
	rts

L_KeyUTrigger:
	jsr		F_KeyMatrix_Reset
	
	rts

L_KeyDTrigger:
	jsr		F_KeyMatrix_Reset

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
