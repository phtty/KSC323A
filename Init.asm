F_Init_SystemRam:							; 系统初始化
	lda		#0
	sta		Counter_1Hz
	sta		Counter_4Hz
	sta		Counter_16Hz
	sta		Counter_102Hz
	sta		Key_Flag
	sta		Timer_Flag
	sta		Clock_Flag
	sta		Calendar_Flag
	sta		Backlight_Flag
	sta		QuickAdd_Counter					; 快加标志的计数
	sta		Backlight_Counter
	sta		Return_Counter
	sta		AlarmLoud_Counter
	sta		COM_Counter

	lda		#01
	sta		Sys_Status_Flag

	lda		#00
	sta		R_Time_Hour
	lda		#00
	sta		R_Time_Min
	lda		#00
	sta		R_Time_Sec

	lda		#01
	sta		R_Date_Day
	lda		#01
	sta		R_Date_Month
	lda		#24
	sta		R_Date_Year
	lda		#00
	sta		R_Date_Week

	rts


F_LCD_Init:
	; 设置为强模式，1/3Bias 3.0V
	lda		#C_BIS_C_1_3_V30+C_HIS_Strong
	sta		LCD_CTRL

	; 设置为4COM 28SEG模式，打开Charge Pump， LCD中断频率为1/2FrameRate
	lda		#C_COM_4_28+C_ENCH_Enable+C_LCDIS_Rate_2
	sta		LCD_COM

	; 设置Seg线 除了S0、S1做IO口，其他全作Seg线
	lda		#C_PC2S+C_PC3S+C_PC54S+C_PC76S+C_PD30S+C_PD74S
	sta		PC_SEG
	lda		#$ff
	sta		PD_SEG

	lda		TMRC
	ora		#C_LCDON
	sta		TMRC

	jsr		F_ClearScreen						; 清屏

	rts


F_Port_Init:
	lda		#$3c								; PA5不需要唤醒
	sta		PA_WAKE
	lda		#$3c
	sta		PA_DIR
	lda		#$3c
	sta		PA
	smb4	IER									; 打开PA口外部中断

	lda		#$0
	sta		PC_DIR								; PC配置为输出
	lda		#$0
	sta		PC

	lda		PB
	and		#$bf
	sta		PB

	lda		#$07
	sta		PD_DIR								; PD0-3配置为三态输入，其余为输出
	lda		#$00
	sta		PD
	sta		PD_SEG								; PD口全部作IO口使用

	lda		#C_PB2S								; PB2作PP声音输出
	sta		PADF0

	rts


F_Timer_Init:
	lda		#C_TMR1_Fsub_64+C_TMR0_Fsub			; TIM0时钟源T000
	sta		TMCLK								; TIM1时钟源Fsub/64(512Hz)
	lda		#C_T000_Fsub
	sta		PADF1								; T000选择为Fsub

	; TIM2时钟源DIV,Fsub 64分频512Hz，关闭定时器同步
	lda		#C_Asynchronous+C_DIVC_Fsub_64
	sta		DIVC								; 关闭定时器同步，DIV时钟源为Fsub/64(512Hz)

	lda		#$0									; 重装载计数设置为0
	sta		TMR0
	lda		#$0
	sta		TMR2

	lda		#$df								; 8Hz一次中断
	sta		TMR1

	lda		IER									; 开定时器中断
	ora		#C_TMR0I+C_TMR1I+C_TMR2I+C_LCDI
	sta		IER

	lda		#C_TMR2ON
	sta		TMRC								; 初始化只开TIM2用于走时

	lda		#C_COM_2_42_38+C_LCDIS_Rate
	sta		LCD_COM								; 开LCD中断用于定时显示LED
	lda		#$03
	sta		FRAME

	rts


F_RFC_Init:
	lda		#$0f
	sta		PD_DIR								; PD0-4配置为三态输入，其余为输出
	lda		#$0
	sta		PD

	lda		RFCC0								; PD0-3配置为RFC功能
	ora		#$07
	sta		RFCC0

	lda		#$00
	sta		RFCC1								; 关闭RFC测量功能

	rts


F_KeyMatrix_PC4Scan_Ready:
	rmb4	IER									; 关闭PA口中断，避免误触发中断

	rmb4	PC
	smb5	PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	nop											; 确保IO口翻转到位
	nop
	nop
	rts

F_KeyMatrix_PC5Scan_Ready:
	rmb4	IER									; 关闭PA口中断，避免误触发中断

	smb4	PC
	rmb5	PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	nop
	nop
	nop
	rts

F_KeyMatrix_Reset:
	bbs3	Timer_Flag,L_QuikAdd_ScanReset
F_QuikAdd_Scan:
	rmb4	PC
	rmb5	PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	smb4	IER									; 开启PA口中断
	rts
L_QuikAdd_ScanReset:							; 有长按时PC4,PC5输出高，避免长按时漏电
	smb4	PC
	smb5	PC									; 快加下不需要开启中断，定时扫描IO口即可
	rts


F_Delay:
	lda		#$f5
	sta		P_Temp
L_Delay_f5:										; 延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_Delay_f5
	rts
