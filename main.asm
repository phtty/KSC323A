	.CHIP	W65C02S									; cpu的选型
	.MACLIST	ON

CODE_BEG	EQU		F000H							; 起始地址

PROG	SECTION	OFFSET	CODE_BEG					; 定义代码段的偏移量从CODE_BEG开始，用于组织程序代码。

.include	50Px1x.h								; 头文件
.include	RAM.INC	
.include	50P104.mac
.include	MACRO.mac

STACK_BOT		EQU		FFH							; 堆栈底部



	.PROG											; 程序开始
V_RESET:
	nop
	nop
	nop
	ldx		#STACK_BOT
	txs												; 使用这个值初始化堆栈指针，这通常是为了设置堆栈的底部地址，确保程序运行中堆栈的正确使用。
	lda		#$17									; #$97
	sta		SYSCLK									; 设置系统时钟
	
	lda		#00										; 清整个RAM
	ldx		#$ff
	sta		$1800
L_Clear_Ram_Loop:
	sta		$1800,x
	dex
	bne		L_Clear_Ram_Loop

	lda		#$0
	sta		DIVC									; 分频控制器，定时器与DIV异步
	sta		IER										; 除能中断
	sta		IFR										; 初始化中断标志位
	lda		FUSE
	sta		MF0										; 为内部RC振荡器提供校准数据	

	jsr		F_Init_SystemRam						; 初始化系统RAM并禁用所有断电保留的RAM

	jsr		F_LCD_Init
	jsr		F_Port_Init

	jsr		F_RandomSeed0_Get
	jsr		F_RandomSeed1_Get
	jsr		F_RandomSeed2_Get
	jsr		F_RandomSeed3_Get

	lda		#$07									; 系统时钟和中断使能
	sta		SYSCLK

	jsr		F_Timer_Init

	cli												; 开总中断

	jsr		F_Test_Mode

; 状态机
MainLoop:
	jsr		F_Time_Run							; 走时全局生效
	jsr		L_4D_Day_Display					; 判断是否为4D日
	jsr		F_Display_Week						; 星期显示只有4D模式不生效
	jsr		F_Backlight							; 背光全局生效
	jsr		F_SymbolRegulate

Status_Juge:
	bbs0	Sys_Status_Flag,Status_Runtime
	bbs1	Sys_Status_Flag,Status_4D_Mode
	bbs2	Sys_Status_Flag,Status_TimeMode_Set
	bbs3	Sys_Status_Flag,Status_Hour_Set
	bbs4	Sys_Status_Flag,Status_Min_Set
	bbs5	Sys_Status_Flag,Status_Year_Set
	bbs6	Sys_Status_Flag,Status_Month_Set
	bbs7	Sys_Status_Flag,Status_Day_Set
	bra		MainLoop
Status_Runtime:
	jsr		F_KeyTrigger_Short						; RunTime模式下只有短按
	jsr		F_DisTime_Run
	sta		HALT
	bra		MainLoop
Status_4D_Mode:
	jsr		F_KeyTrigger_Short						; 4D模式下只有短按
	jsr		F_Display_Random_Rolling
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	bra		MainLoop
Status_TimeMode_Set:
	jsr		F_KeyTrigger_Short						; 12/24h切换下只有短按
	jsr		F_DisTimeMode_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	bra		MainLoop
Status_Hour_Set:
	jsr		F_KeyTrigger_Long						; 小时设置模式下有长按
	jsr		F_DisHour_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	bra		MainLoop
Status_Min_Set:
	jsr		F_KeyTrigger_Long						; 分钟设置模式下有长按
	jsr		F_DisMin_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	bra		MainLoop
Status_Year_Set:
	jsr		F_KeyTrigger_Long						; 年份设置模式下有长按
	jsr		F_DisYear_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	bra		MainLoop
Status_Month_Set:
	jsr		F_KeyTrigger_Long						; 月份设置模式下有长按
	jsr		F_DisMonth_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	jmp		MainLoop
Status_Day_Set:
	jsr		F_KeyTrigger_Long						; 日期设置模式下有长按
	jsr		F_DisDay_Set
	jsr		F_ReturnToRunTime_Juge					; 30S无操作返回RT模式
	sta		HALT
	jmp		MainLoop




F_ReturnToRunTime_Juge:
	bbr4	Key_Flag,L_Return_Juge_Exit
	bbr7	Timer_Flag,L_Return_Juge_Exit

	rmb7	Timer_Flag
	lda		Return_Counter
	cmp		#31
	bcs		L_Return_Stop
	inc		Return_Counter
	bra		L_Return_Juge_Exit
L_Return_Stop:
	lda		#0
	sta		Return_Counter
	rmb4	Key_Flag
	lda		#00000001B							; 30S未响应则回到走时模式
	sta		Sys_Status_Flag
	jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
L_Return_Juge_Exit:
	rts




; 中断服务函数
V_IRQ:
	pha
	lda		IER
	and		IFR
	sta		R_Int_Backup

	bbs0	R_Int_Backup,L_DivIrq
	bbs1	R_Int_Backup,L_Timer0Irq
	bbs2	R_Int_Backup,L_Timer1Irq
	bbs3	R_Int_Backup,L_Timer2Irq
	bbs4	R_Int_Backup,L_PaIrq
	bbs6	R_Int_Backup,L_LcdIrq

	bra		L_EndIrq

L_DivIrq:
	CLR_DIV_IRQ_FLAG
	bra		L_EndIrq

L_Timer2Irq:
	CLR_TMR2_IRQ_FLAG
	smb0	Timer_Flag							; 半秒标志
	lda		Counter_1Hz
	cmp		#01
	bcs		L_1Hz_Out
	inc		Counter_1Hz
	bra		L_EndIrq
L_1Hz_Out:
	lda		#$0
	sta		Counter_1Hz
	lda		Timer_Flag
	ora		#10100110B							; 1S、增S、背光、4D的1S标志位
	sta		Timer_Flag
	bra		L_EndIrq

L_Timer0Irq:									; 用于蜂鸣器
	CLR_TMR0_IRQ_FLAG
	lda		Counter_16Hz						; 16Hz计数
	cmp		#07
	bcs		L_16Hz_Out
	inc		Counter_16Hz
	bra		L_EndIrq
L_16Hz_Out:
	lda		#$0
	sta		Counter_16Hz
	smb6	Timer_Flag							; 16Hz标志
	bra		L_EndIrq

L_Timer1Irq:									; 用于快加计时
	CLR_TMR1_IRQ_FLAG
	smb4	Timer_Flag							; 8Hz标志
	bra		L_EndIrq

L_PaIrq:
	CLR_KEY_IRQ_FLAG

	smb0	Key_Flag
	smb1	Key_Flag							; 首次触发
	rmb3	Timer_Flag							; 如果有新的下降沿到来，清快加标志位
	rmb4	Timer_Flag							; 8Hz计时

	smb1	TMRC								; 打开快加定时

	jsr		F_RandomSeed0_Get
	jsr		F_RandomSeed2_Get

	bra		L_EndIrq

L_LcdIrq:
	CLR_LCD_IRQ_FLAG
	inc		CC0
	inc		Counter_Lcd
	lda		Counter_Lcd
	cmp		#1
	bne		L_EndIrq
	lda		#0
	sta		Counter_Lcd
	smb1	Random_Flag							; 帧更新标志位

L_EndIrq:
	pla
	rti


.include	ScanKey.asm
.include	Time.asm
.include	Calendar.asm
.include	Backlight.asm
.include	Init.asm
.include	Disp.asm
.include	Display.asm
.include	Lcdtab.asm
.include	TestMode.asm
.include	Random.asm


.BLKB	0FFFFH-$,0FFH							; 从当前地址到FFFF全部填充0xFF

.ORG	0FFF8H
	DB		C_RST_SEL+C_VOLT_V30+C_OMS0+C_PAIM
	DB		C_PB32IS+C_PROTB
	DW		0FFFFH

.ORG	0FFFCH
	DW		V_RESET
	DW		V_IRQ

.ENDS
.END
	