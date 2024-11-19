; 单按的按键处理
F_KeyTrigger_Short:
	bbs0	Key_Flag,L_KeyTrigger_Short
	rts
L_KeyTrigger_Short:
	rmb0	Key_Flag
	rmb1	Key_Flag
	rmb1	TMRC								; 没有快加功能不需要开Timer1的8Hz计时
	lda		#$00
	sta		P_Temp
L_DelayTrigger_Short:							; 消抖延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_DelayTrigger_Short				; 软件消抖

	jsr		F_KeyMatrix_PA5Scan_Ready			; 判断4D和LED键
	lda		PA									; 正常走时模式下只对2个按键有响应
	and		#$8c
	cmp		#$80
	bne		No_KeyLTrigger_Short				; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	jmp		L_KeyLTrigger_Short					; LED键触发
No_KeyLTrigger_Short:
	cmp		#$08
	bne		No_KeyKTrigger_Short
	jmp		L_KeyKTrigger_Short					; K键触发
No_KeyKTrigger_Short:
	cmp		#$04
	bne		No_KeyDTrigger_Short
	jmp		L_KeyDTrigger_Short					; 4D键触发
No_KeyDTrigger_Short:
	jsr		F_KeyMatrix_PC0Scan_Ready			; 判断SET键和UP键
	lda		PA
	and		#$8c
	cmp		#$80
	bne		No_KeyUTrigger_Short
	jmp		L_KeyUTrigger_Short					; Up键触发
No_KeyUTrigger_Short:
	cmp		#$04
	bne		L_KeyExit_Short
	jmp		L_KeySTrigger_Short					; Set键触发

L_KeyExit_Short:
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	bbs2	Random_Flag,L_NoRandom_Get			; 在滚动随机数时，停止随机数变更
	jsr		F_RandomSeed1_Get
	jsr		F_RandomSeed3_Get
L_NoRandom_Get:
	rts

; 根据状态进入不同的模式的按键处理
L_KeyLTrigger_Short:							; 背光功能全状态都一样
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	smb3	Key_Flag
	smb2	PB
	lda		#0
	sta		Backlight_Counter					; 每次按背光都会重置计时
	rts

L_KeyDTrigger_Short:
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	smb4	Key_Flag							; 非走时模式
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时

	lda		Sys_Status_Flag
	cmp		#00000010B
	bne		No_Status4D_KeyD
	jmp		L_KeyDTrigger_4DMode				; 4D模式的4D键会触发随机数滚动
No_Status4D_KeyD:
	jmp		L_KeyDTrigger_No4DMode				; 非4D模式的4D键会进入4D模式
	rts

L_KeyKTrigger_Short:
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时

	lda		Sys_Status_Flag
	cmp		#00000010B
	bne		No_Status4D_KeyK
	jmp		L_KeyKTrigger_4DMode				; 4D模式的K键会触发随机数滚动
No_Status4D_KeyK:
	rts

L_KeyUTrigger_Short:
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时

	lda		Sys_Status_Flag
	cmp		#00000001B
	bne		No_StatusRT_KeyU
	jmp		L_KeyUTrigger_RunTimeMode
No_StatusRT_KeyU:
	cmp		#00000010B
	bne		No_Status4D_KeyU
	jmp		L_KeyUTrigger_4DMode
No_Status4D_KeyU:
	cmp		#00000100B
	bne		No_StatusTM_KeyU
	jmp		L_KeyUTrigger_TimeMode_Set
No_StatusTM_KeyU:
	rts

L_KeySTrigger_Short:
	jsr		F_KeyMatrix_Reset					; 重新打开PA中断，矩阵状态重置
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时

	lda		Sys_Status_Flag
	cmp		#00000001B
	bne		No_StatusRT_KeyS
	jmp		L_KeySTrigger_RunTimeMode
No_StatusRT_KeyS:
	cmp		#00000010B
	bne		No_Status4D_KeyS
	jmp		L_KeySTrigger_4DMode
No_Status4D_KeyS:
	cmp		#00000100B
	bne		No_StatusTM_KeyS
	jmp		L_KeySTrigger_TimeMode_Set
No_StatusTM_KeyS:
	rts




; 有长按的按键处理
F_KeyTrigger_Long:
	bbs3	Timer_Flag,L_Key8Hz_Long			; 有快加则直接判断8Hz标志位
	bbr1	Key_Flag,L_KeyScan_Long				; 首次按键触发
	rmb1	Key_Flag
	lda		#$00
	sta		P_Temp
L_DelayTrigger_Long:							; 消抖延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_DelayTrigger_Long					; 软件消抖
	lda		PA
	and		#$84
	cmp		#$00
	bne		L_KeyYes_Long						; 检测是否有按键触发
	bra		L_KeyExit_Long
	rts
L_KeyYes_Long:
	sta		PA_IO_Backup
	bra		L_KeyHandle_Long					; 首次触发处理结束

L_KeyScan_Long:									; 长按处理部分
	bbr0	Key_Flag,L_Key8HzExit_Long			; 没有扫键标志直接退出
L_Key8Hz_Long:
	bbr4	Timer_Flag,L_Key8HzExit_Long		; 8Hz标志位到来前也不进行按键处理(快加下)
	rmb4	Timer_Flag
	jsr		F_QuikAdd_Scan						; 矩阵扫描，需要开启IO口
	lda		PA
	and		#$84
	cmp		PA_IO_Backup						; 若检测到有按键的状态变化则退出快加判断并结束
	beq		L_8Hz_Count_Long
	bra		L_KeyExit_Long
	rts
L_8Hz_Count_Long:
	inc		QuickAdd_Counter
	lda		QuickAdd_Counter
	cmp		#12
	bcs		L_QuikAdd_Long
	rts											; 长按计时，必须满1S才有快加
L_QuikAdd_Long:
	smb3	Timer_Flag

L_KeyHandle_Long:
	jsr		F_KeyMatrix_PA5Scan_Ready
	lda		PA									; 判断4D键和LED键
	and		#$84
	bbs3	Timer_Flag,No_KeyDTrigger_Long		; L、D键不需要快加
	cmp		#$80
	bne		No_KeyLTrigger_Long					; 由于跳转指令寻址能力的问题，这里采用jmp进行跳转
	jmp		L_KeyLTrigger_Long					; LED键触发
No_KeyLTrigger_Long:
	cmp		#$04
	bne		No_KeyDTrigger_Long
	jmp		L_KeyDTrigger_Long					; 4D键触发
No_KeyDTrigger_Long:
	jsr		F_KeyMatrix_PC0Scan_Ready
	lda		PA									; 判断SET键和UP键
	and		#$84
	cmp		#$80
	bne		No_KeyUTrigger_Long
	jmp		L_KeyUTrigger_Long					; UP键触发
No_KeyUTrigger_Long:
	bbs3	Timer_Flag,L_KeyExit_Long			; S键不需要快加
	cmp		#$04
	bne		L_KeyExit_Long
	jmp		L_KeySTrigger_Long					; SET键触发

L_KeyExit_Long:
	rmb1	TMRC								; 关闭快加8Hz计时的定时器
	rmb0	Key_Flag							; 清相关标志位
	rmb3	Timer_Flag
	lda		#0									; 清理相关变量
	sta		QuickAdd_Counter
	bbs2	Random_Flag,L_Key8HzExit_Long		; 在滚动随机数时，停止随机数变更
	jsr		F_RandomSeed1_Get
	jsr		F_RandomSeed3_Get
	jsr		F_KeyMatrix_Reset
L_Key8HzExit_Long:
	rts

; 根据状态进入不同的模式的按键处理
L_KeyLTrigger_Long:								; 背光键全状态功能都一样
	jsr		F_KeyMatrix_Reset
	rmb0	Key_Flag
	smb3	Key_Flag
	smb2	PB
	lda		#0
	sta		Backlight_Counter					; 每次按背光都会重置计时
	rts

L_KeyDTrigger_Long:
	jsr		F_KeyMatrix_Reset
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时
	rmb0	Key_Flag
	jmp		L_KeyDTrigger_No4DMode
	rts

L_KeyUTrigger_Long:
	jsr		F_KeyMatrix_Reset
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时

	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		No_StatusHS_KeyU
	jmp		L_KeyUTrigger_HourSet
No_StatusHS_KeyU:
	cmp		#00010000B
	bne		No_StatusMiS_KeyU
	jmp		L_KeyUTrigger_MinSet
No_StatusMiS_KeyU:
	cmp		#00100000B
	bne		No_StatusYS_KeyU
	jmp		L_KeyUTrigger_YearSet
No_StatusYS_KeyU:
	cmp		#01000000B
	bne		No_StatusMoS_KeyU
	jmp		L_KeyUTrigger_MonthSet
No_StatusMoS_KeyU:
	cmp		#10000000B
	bne		No_StatusDS_KeyU
	jmp		L_KeyUTrigger_DaySet
No_StatusDS_KeyU:
	rts

L_KeySTrigger_Long:
	jsr		F_KeyMatrix_Reset
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
	lda		#0
	sta		Return_Counter						; 重置返回走时模式计时
	rmb0	Key_Flag

	lda		Sys_Status_Flag
	cmp		#00001000B
	bne		No_StatusHS_KeyS
	jmp		L_KeySTrigger_HourSet
No_StatusHS_KeyS:
	cmp		#00010000B
	bne		No_StatusMiS_KeyS
	jmp		L_KeySTrigger_MinSet
No_StatusMiS_KeyS:
	cmp		#00100000B
	bne		No_StatusYS_KeyS
	jmp		L_KeySTrigger_YearSet
No_StatusYS_KeyS:
	cmp		#01000000B
	bne		No_StatusMoS_KeyS
	jmp		L_KeySTrigger_MonthSet
No_StatusMoS_KeyS:
	cmp		#10000000B
	bne		No_StatusDS_KeyS
	jmp		L_KeySTrigger_DaySet
No_StatusDS_KeyS:
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

	lda		Random_Flag

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
	smb4	Key_Flag							; 非走时状态
	pla
	pla
	jmp		MainLoop




; 4D模式的D、K键处理
L_KeyKTrigger_4DMode:
L_KeyDTrigger_4DMode:
	smb0	Random_Flag							; 开始滚动动画
	smb2	Random_Flag							; 停止采样随机数
	jsr		F_RandomSeed0_Get
	jsr		F_RandomSeed2_Get

	rts

; 4D模式的U键处理
L_KeyUTrigger_4DMode:
	lda		#0
	sta		Return_Counter
	sta		Frame_Counter
	sta		Frame_Serial
	sta		Anim_Phase
	rmb0	Random_Flag							; 滚动显示停止
	rmb2	Random_Flag							; 重新开始采样随机数
	rmb4	Key_Flag
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
	rmb4	Key_Flag							; 回到走时模式，关闭30s计数
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
