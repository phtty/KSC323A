F_Init_SystemRam:							; 系统初始化
	lda		#0
	sta		Frame_Counter
	sta		Frame_Serial
	sta		Frame_Counter_D0
	sta		Frame_Counter_D1
	sta		Frame_Counter_D2
	sta		Frame_Counter_D3
	sta		Anim_Phase
	sta		Counter_1Hz
	sta		Counter_16Hz
	sta		Counter_Lcd
	sta		Key_Flag
	sta		Timer_Flag
	sta		Clock_Flag
	sta		Calendar_Flag
	sta		QuickAdd_Counter					; 快加标志的计数
	sta		Backlight_Counter
	sta		Return_Counter

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
	lda		#$ac
	sta		PA_WAKE
	lda		#$8c
	sta		PA_DIR
	lda		#$ac
	sta		PA
	
	smb4	IER									; 打开PA口外部中断

	lda		PC_DIR								; PC0、1配置为输出
	and		#$fc
	sta		PC_DIR
	smb0	PC									; PC0配置输出高
	rmb1	PC									; PC1配置输出低

	rmb2	PB
	smb2	PB_TYPE								; PB2口作背光输出
	lda		#C_PB3S								; PB3作PN声音输出
	sta		PADF0

	rts


F_Timer_Init:
	TMR0_CLK_FSUB								; TIM0时钟源Fsub(32768Hz)
	TMR1_CLK_512Hz								; TIM1时钟源Fsub/64(512Hz)
	; TIM2时钟源DIV,Fsub 64分频512Hz，关闭定时器同步
	lda		DIVC
	ora		#C_DIVC_Fsub_64+C_Asynchronous
	sta		DIVC

	lda		#$0									; 重装载计数设置为0
	sta		TMR0
	lda		#$0
	sta		TMR2

	lda		#$bf								; 8Hz一次中断
	sta		TMR1

	lda		IER									; 开定时器中断
	ora		#C_TMR0I+C_TMR1I+C_TMR2I+C_LCDI
	sta		IER

	smb0	TMRC								; 初始化只开TIM2用于走时
	rmb1	TMRC
	smb2	TMRC

	rts




F_KeyMatrix_PA5Scan_Ready:
	rmb4	IER									; 关闭PA口中断，避免误触发中断
	lda		#$ac
	sta		PA

	lda		PC
	and		#$fe
	sta		PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	jsr		F_Delay
	rts

F_KeyMatrix_PC0Scan_Ready:
	rmb4	IER									; 关闭PA口中断，避免误触发中断
	lda		#$8c
	sta		PA

	lda		PC
	ora		#$01
	sta		PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	jsr		F_Delay
	rts

F_KeyMatrix_Reset:
	bbs3	Timer_Flag,L_QuikAdd_ScanReset
F_QuikAdd_Scan:
	lda		#$ac
	sta		PA

	lda		PC
	ora		#$01
	sta		PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	smb4	IER									; 开启PA口中断
	rts
L_QuikAdd_ScanReset:							; 有长按时PA5,PC0输出低，避免长按时漏电
	lda		#$8c
	sta		PA

	lda		PC
	and		#$fe
	sta		PC
	rts


F_Delay:
	lda		#$f5
	sta		P_Temp
L_Delay_f5:										; 延时循环用标签
	inc		P_Temp
	lda		P_Temp
	bne		L_Delay_f5
	rts
