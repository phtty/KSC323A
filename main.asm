	.CHIP	W65C02S									; cpu的选型
	.MACLIST	ON

CODE_BEG	EQU		E000H							; 起始地址

PROG	SECTION	OFFSET	CODE_BEG					; 定义代码段的偏移量从CODE_BEG开始，用于组织程序代码。

.include	50Px1x.h								; 头文件
.include	RAM.INC	
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

	jsr		F_ClearScreen							; 清屏

	lda		#$0
	sta		DIVC									; 分频控制器，定时器与DIV异步
	sta		IER										; 除能中断
	sta		IFR										; 初始化中断标志位
	lda		FUSE
	sta		MF0										; 为内部RC振荡器提供校准数据	

	jsr		F_Init_SystemRam						; 初始化系统RAM并禁用所有断电保留的RAM

	jsr		F_Port_Init								; 初始化用到的IO口

	jsr		F_Beep_Init

	lda		#$07									; 系统时钟和中断使能
	sta		SYSCLK

	jsr		F_Timer_Init
	jsr		F_RFC_Init

	cli												; 开总中断

; Test Code
	jsr		F_Test_Mode
	lda		#2
	sta		Backlight_Level
	smb0	PC										; 亮度设置为高亮

	lda		#00000001B
	sta		Sys_Status_Flag
	lda		#0
	sta		Sys_Status_Ordinal


; 状态机
MainLoop:
	sta		HALT									; 休眠
	nop
Global_Run:											; 全局生效的功能处理
	jsr		F_KeyHandler
	jsr		F_PowerManage
	jsr		F_Time_Run								; 走时
	jsr		F_Louding
	jsr		F_AlarmSW_Display
	jsr		F_Display_Week
	;jsr		F_RFC_MeasureManage

Status_Juge:
	bbs0	Sys_Status_Flag,Status_DisClock
	bbs1	Sys_Status_Flag,Status_DisRotate
	bbs2	Sys_Status_Flag,Status_DisAlarm
	bbs3	Sys_Status_Flag,Status_SetClock
	bbs4	Sys_Status_Flag,Status_SetAlarm

	bra		MainLoop
Status_DisClock:
	jsr		F_Clock_Display
	bra		MainLoop
Status_DisRotate:
	jsr		F_Rotate_Display
	bra		MainLoop
Status_DisAlarm:
	jsr		F_Alarm_Display
	bra		MainLoop
Status_SetClock:
	jsr		F_Clock_Set
	bra		MainLoop
Status_SetAlarm:
	jsr		F_Alarm_Set
	bra		MainLoop




F_ReturnToDisTime_Juge:
	bbr2	Key_Flag,L_Return_Juge_Exit

	lda		Return_Counter
	cmp		#15
	bcs		L_Return_Stop
	inc		Return_Counter
	bra		L_Return_Juge_Exit
L_Return_Stop:
	lda		#0
	sta		Return_Counter
	rmb2	Key_Flag
	lda		#00000001B								; 15S未响应则回到时显模式
	sta		Sys_Status_Flag
	lda		#0
	sta		Sys_Status_Ordinal
	;jsr		F_SymbolRegulate					; 显示对应模式的常亮符号
L_Return_Juge_Exit:
	rts




; 中断服务函数
V_IRQ:
	pha
	txa
	pha
	php
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
	rmb0	IFR									; 清中断标志位
	inc		Counter_102Hz
	lda		Counter_102Hz
	cmp		#5
	bne		L_EndIrq
	lda		#0
	sta		Counter_102Hz
	smb0	RFC_Flag							; 102Hz标志，用于计数Frcx
	bra		L_EndIrq

L_Timer0Irq:									; 用于蜂鸣器
	rmb1	IFR									; 清中断标志位

	inc		Counter_16Hz
	lda		Counter_16Hz						; 16Hz计数
	beq		L_16Hz_Out
	bra		L_EndIrq
L_16Hz_Out:
	smb6	Timer_Flag							; 16Hz标志
	bra		L_EndIrq

L_Timer1Irq:									; 用于快加计时
	rmb2	IFR									; 清中断标志位
	smb4	Timer_Flag							; 扫键16Hz标志
	lda		Counter_4Hz							; 4Hz计数
	cmp		#03
	bcs		L_4Hz_Out
	inc		Counter_4Hz
	bra		L_EndIrq
L_4Hz_Out:
	lda		#$0
	sta		Counter_4Hz
	smb5	Key_Flag							; 快加4Hz标志
	bra		L_EndIrq

L_Timer2Irq:
	rmb3	IFR									; 清中断标志位
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
	ora		#00100110B							; 1S、增S、熄屏的1S标志位
	sta		Timer_Flag
	smb1	Backlight_Flag						; 亮屏1S计时
	bra		L_EndIrq

L_PaIrq:
	rmb4	IFR									; 清中断标志位

	smb0	Key_Flag
	smb1	Key_Flag							; 首次触发
	rmb3	Timer_Flag							; 如果有新的下降沿到来，清快加标志位
	rmb4	Timer_Flag							; 16Hz计时

	smb1	TMRC								; 打开快加定时

	bra		L_EndIrq

L_LcdIrq:
	rmb6	IFR									; 清中断标志位

	lda		COM_Counter
	cmp		#3
	bcc		COM_Display
	lda		#0
	sta		COM_Counter
COM_Display:
	jsr		L_Send_Buffer_COM
	inc		COM_Counter

L_EndIrq:
	plp
	pla
	tax
	pla
	rti


.include	ScanKey.asm
.include	Time.asm
.include	Calendar.asm
.include	Beep.asm
.include	Init.asm
.include	Disp.asm
.include	Display.asm
.include	Alarm.asm
.include	Ledtab.asm
.include	RFC.asm
.include	RFCTable.asm
.include	TemperHandle.asm
.include	HumidHandle.asm
.include	PowerManage.asm
.include	TestMode.asm


.BLKB	0FFFFH-$,0FFH							; 从当前地址到FFFF全部填充0xFF

.ORG	0FFF8H
	DB		C_PY_SEL+C_OMS_BR
	DB		C_PROTB
	DW		0FFFFH

.ORG	0FFFCH
	DW		V_RESET
	DW		V_IRQ

.ENDS
.END
	