F_Init_SystemRam:								; 系统内存初始化
	lda		#0001B
	sta		Sys_Status_Flag

	lda		#12
	sta		R_Time_Hour
	;lda		#00
	;sta		R_Time_Min
	;lda		#00
	;sta		R_Time_Sec

	lda		#12
	sta		R_Alarm1_Hour
	;lda		#00
	;sta		R_Alarm1_Min

	lda		#12
	sta		R_Alarm2_Hour
	;lda		#00
	;sta		R_Alarm2_Min

	lda		#12
	sta		R_Alarm3_Hour
	;lda		#00
	;sta		R_Alarm3_Min

	lda		#01
	sta		R_Date_Day
	lda		#01
	sta		R_Date_Month
	lda		#24
	sta		R_Date_Year
	;lda		#00
	;sta		R_Date_Week

	lda		#29
	sta		Count_RFC

	rts


F_Beep_Init:
	lda		#C_T000_Fsub
	sta		PADF1
	rmb0	TMCLK								; TIM0选择时钟源为Fsub
	rmb1	TMCLK

	lda		#256-8								; 配置TIM0频率为2048Hz
	sta		TMR0

	rmb3	PB_TYPE								; PB3选择NMOS输出0避免漏电

	rmb1	PADF0								; PB3 PWM输出控制，初始化不输出
	rmb3	PADF0								; 配置PB3的PWM输出模式，频率为TIM0/2
	smb4	PADF0

	rts


F_Port_Init:
	lda		#$1c								; PA5不需要唤醒
	sta		PA_WAKE
	lda		#$1c
	sta		PA_DIR
	lda		#$1c
	sta		PA
	smb4	IER									; 打开PA口外部中断

	lda		#$0
	sta		PC_DIR								; PC配置为输出
	lda		#$0
	sta		PC

	lda		PB
	and		#$b7
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
	rmb1	IER									; 关TMR0、1定时器中断
	rmb1	IFR									; 清除TMR0、1中断标志位
	rmb2	IER
	rmb2	IFR
	rmb0	TMRC								; 关闭TMR0
	rmb1	TMRC								; 关闭TMR1

	lda		#C_TMR1_Fsub_64+C_TMR0_Fsub			; TIM0时钟源T000
	sta		TMCLK								; TIM1时钟源Fsub/64(512Hz)
	lda		#C_T000_Fsub
	sta		PADF1								; T000选择为Fsub

	; TIM2时钟源DIV,Fsub 64分频512Hz，关闭定时器同步
	lda		#C_Asynchronous+C_DIVC_Fsub_64
	sta		DIVC								; 关闭定时器同步，DIV时钟源为Fsub/64(512Hz)

	lda		#256-8								; 配置TIM0频率为4096Hz
	sta		TMR0
	lda		#$0
	sta		TMR2

	lda		#$256-32							; 16Hz一次中断
	sta		TMR1

	lda		IER									; 开定时器中断
	ora		#C_TMR0I+C_TMR1I+C_TMR2I+C_LCDI
	sta		IER

	lda		#C_TMR2ON
	sta		TMRC								; 初始化只开TIM2用于走时

	lda		#C_COM_2_42_38+C_LCDIS_Rate
	sta		LCD_COM								; 开LCD中断用于定时显示LED
	lda		#$02
	sta		FRAME

	rts



F_Timer_NormalMode:
	rmb1	IER									; 关TMR0、1定时器中断
	rmb1	IFR									; 清除TMR0、1中断标志位
	rmb2	IER
	rmb2	IFR
	lda		TMRC
	pha
	rmb0	TMRC								; 关闭TMR0
	rmb1	TMRC								; 关闭TMR1
	lda		#C_TMR1_Fsub_64+C_TMR0_Fsub			; TIM0时钟源T000
	sta		TMCLK								; TIM1时钟源Fsub/64(512Hz)
	lda		#C_T000_Fsub
	sta		PADF1								; T000选择为Fsub
	lda		#C_Asynchronous+C_DIVC_Fsub_64
	sta		DIVC								; 关闭定时器同步并选择DIV时钟源为Fsub/64(512Hz)

	lda		#256-8								; 配置TIM0频率为4096Hz
	sta		TMR0
	lda		#256-32								; 配置TIM1频率为16Hz
	sta		TMR1

	pla
	sta		TMRC

	rmb0	IER									; 关闭DIV中断
	smb1	IER									; 开TIM0、1定时器中断
	smb2	IER

	rmb0	RFC_Flag							; 清除采样启用中标志位
	rmb3	RFC_Flag
	rmb6	RFC_Flag

	rts




F_RFC_Init:
	lda		#$0f
	sta		PD_DIR								; PD0-4配置为三态输入，其余为输出
	lda		#$0
	sta		PD

	rmb6	PC_SEG

	lda		RFCC0								; PD0-3配置为RFC功能
	ora		#$0f
	sta		RFCC0

	lda		#$00
	sta		RFCC1								; 关闭RFC测量功能
	sta		PD_SEG								; PD口全部作IO口使用

	rts


F_KeyMatrix_PC4Scan_Ready:
	;rmb4	IER									; 关闭PA口中断，避免误触发中断

	rmb4	PC
	smb5	PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	jsr		L_KeyDelay
	rts

F_KeyMatrix_PC5Scan_Ready:
	;rmb4	IER									; 关闭PA口中断，避免误触发中断

	smb4	PC
	rmb5	PC
	rmb4	IFR									; 复位标志位,避免中断开启时直接进入中断服务
	jsr		L_KeyDelay
	rts

F_KeyMatrix_Reset:
	bbs3	Timer_Flag,L_QuikAdd_ScanReset
F_QuikAdd_Scan:
	rmb4	PC
	rmb5	PC
	rts
L_QuikAdd_ScanReset:							; 有长按时PC4,PC5输出高，避免长按时漏电
	smb4	PC
	smb5	PC									; 快加下不需要开启中断，定时扫描IO口即可
	rts
