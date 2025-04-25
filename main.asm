	.CHIP		W65C02S								; cpu��ѡ��
	.MACLIST	ON

CODE_BEG	EQU		E000H							; ��ʼ��ַ

PROG		SECTION OFFSET CODE_BEG					; �������ε�ƫ������CODE_BEG��ʼ��������֯������롣
.include	50Px1x.h								; ͷ�ļ�
.include	RAM.INC	
.include	MACRO.mac

STACK_BOT		EQU		FFH							; ��ջ�ײ�
.PROG												; ����ʼ

V_RESET:
	nop
	nop
	nop
	ldx		#STACK_BOT
	txs												; ʹ�����ֵ��ʼ����ջָ�룬��ͨ����Ϊ�����ö�ջ�ĵײ���ַ��ȷ�����������ж�ջ����ȷʹ�á�
	lda		#$07									; #$97
	sta		SYSCLK									; ����ϵͳʱ��

	lda		#00										; ������RAM
	ldx		#$ff
	sta		$1800
L_Clear_Ram_Loop:
	sta		$1800,x
	dex
	bne		L_Clear_Ram_Loop

	jsr		F_ClearScreen							; ���Դ�

	lda		#$0
	sta		DIVC									; ��Ƶ����������ʱ����DIV�첽
	sta		IER										; �����ж�
	lda		FUSE
	sta		MF0										; Ϊ�ڲ�RC�����ṩУ׼����	

	jsr		F_Init_SystemRam						; ��ʼ��ϵͳRAM���������жϵ籣����RAM
	jsr		F_Port_Init								; ��ʼ���õ���IO��
	jsr		F_Beep_Init

	jsr		F_Timer_Init
	jsr		F_RFC_Init

	rmb4	IER										; �رհ����жϱ����ϵ���̱�����
	cli												; �����ж�

; �ϵ紦��
	lda		#1
	sta		Backlight_Level
	smb0	PC										; ��ʼ��������Ϊ����
	smb0	PC_IO_Backup

	jsr		F_Test_Mode								; �ϵ���ʾ����

	jsr		F_RFC_MeasureStart						; �ϵ���ʪ�Ȳ���
	rmb0	Key_Flag								; ��հ�����ر�־λ
	rmb1	RFC_Flag
Wait_RFC_MeasureOver:
	jsr		F_RFC_MeasureManage
	bbs0	RFC_Flag,Wait_RFC_MeasureOver

	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_SymbolRegulate
	jsr		F_Time_Display
	jsr		F_Display_Week

	lda		#4										; �ϵ��������2��
	sta		Beep_Serial
	smb0	TMRC
Loop_BeepTest:										; ��������
	jsr		F_Louding
	lda		Beep_Serial
	bne		Loop_BeepTest
	rmb0	TMRC

	lda		#0001B
	sta		Sys_Status_Flag
	lda		#0
	sta		Sys_Status_Ordinal

	jsr		F_KeyMatrix_Reset
	rmb4	IFR									; ��λ��־λ,�����жϿ���ʱֱ�ӽ����жϷ���
	smb4	IER									; ����������������¿���PA���ж�

	bra		Global_Run


; ״̬��
MainLoop:
	smb4	SYSCLK
	sta		HALT									; ����
	rmb4	SYSCLK
Global_Run:											; ȫ����Ч�Ĺ��ܴ���
	jsr		F_KeyHandler
	jsr		F_Louding
	jsr		F_PowerManage
	jsr		F_Time_Run								; ��ʱ
	jsr		F_SymbolRegulate
	jsr		F_Display_Week
	jsr		F_RFC_MeasureManage
	jsr		F_ReturnToDisTime						; ��ʱ����ʱ��ģʽ

Status_Juge:
	bbs0	Sys_Status_Flag,Status_DisClock
	bbs1	Sys_Status_Flag,Status_DisAlarm
	bbs2	Sys_Status_Flag,Status_SetClock
	bbs3	Sys_Status_Flag,Status_SetAlarm

	bra		MainLoop
Status_DisClock:
	jsr		F_Clock_Display
	jsr		F_Alarm_Handler							; ��ʾ״̬�������ж�
	bra		MainLoop
Status_DisAlarm:
	jsr		F_Alarm_Display
	jsr		F_Alarm_Handler							; ��ʾ״̬�������ж�
	bra		MainLoop
Status_SetClock:
	jsr		F_Clock_Set
	bra		MainLoop
Status_SetAlarm:
	jsr		F_Alarm_Set
	bra		MainLoop




F_ReturnToDisTime:
	bbs7	Clock_Flag,L_Return_Start
	rts
L_Return_Start:
	bbr0	Sys_Status_Flag,L_Return_Juge
	bbs0	Sys_Status_Ordinal,L_Return_Juge
	bbr2	Key_Flag,L_Return_Juge_Exit				; ʱ��ģʽ�£�������ԣ��򲻼���ִ��
	bbs6	Key_Flag,L_Return_Juge_Exit				; DP��ʾʱ��������
	lda		#10
	sta		Return_MaxTime
L_Return_Juge:
	rmb7	Clock_Flag
	lda		Return_Counter
	cmp		Return_MaxTime							; ��ǰģʽ�ķ���ʱ��
	bcs		L_Return_Stop
	inc		Return_Counter
	bra		L_Return_Juge_Exit
L_Return_Stop:
	lda		#0
	sta		Return_Counter
	bbr0	Sys_Status_Flag,No_TimeDis_Return		; Sys Flag��һλΪ0����ʱ��
	bbs0	Sys_Status_Ordinal,No_TimeDis_Return	; Sys Ordinal��Ϊ0����ʱ��
	jsr		SwitchState_ClockDis					; ʱ�����������ԣ����ʱ������������
	bra		L_Return_Juge_Exit

No_TimeDis_Return:
	lda		#0
	sta		Sys_Status_Ordinal						; ��ʱ������ʱ�����򷵻�ʱ��

Return_Over:
	lda		#0001B									; �ص�ʱ��ģʽ
	sta		Sys_Status_Flag
L_Return_Juge_Exit:
	rts




; �жϷ�����
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
	jmp		L_EndIrq

L_DivIrq:
	rmb0	IFR									; ���жϱ�־λ
	sei
	inc		Counter_20ms
	lda		Counter_20ms
	cmp		#1
	beq		RFC_Start
	cmp		#11
	beq		RFC_Sample
	cli
	bra		L_EndIrq
RFC_Start:
	jsr		F_RFC_Channel_Select
	cli
	bra		L_EndIrq
RFC_Sample:
	jsr		L_Get_RFC_Data
	lda		#0
	sta		Counter_20ms
	cli
	bra		L_EndIrq

L_Timer0Irq:									; ���ڷ�����
	rmb1	IFR									; ���жϱ�־λ

	inc		Counter_16Hz
	lda		Counter_16Hz						; 16Hz����
	cmp		#192
	bcs		L_16Hz_Out
	bra		L_EndIrq
L_16Hz_Out:
	lda		#0
	sta		Counter_16Hz
	smb6	Timer_Flag							; 16Hz��־
	bra		L_EndIrq

L_Timer1Irq:									; ���ڿ�Ӽ�ʱ
	rmb2	IFR									; ���жϱ�־λ
	smb4	Timer_Flag							; ɨ��16Hz��־
	lda		Counter_4Hz							; 4Hz����
	cmp		#03
	bcs		L_4Hz_Out
	inc		Counter_4Hz
	bra		L_EndIrq
L_4Hz_Out:
	lda		#$0
	sta		Counter_4Hz
	smb5	Key_Flag							; ���4Hz��־
	bra		L_EndIrq

L_Timer2Irq:
	rmb3	IFR									; ���жϱ�־λ
	jmp		I_Timer2IRQ_Handler

L_PaIrq:
	rmb4	IFR									; ���жϱ�־λ
	rmb4	SYSCLK
	bbr0	RFC_Flag,?RFC_Sample_Juge			; ��������RFC����
	jsr		F_RFC_Abort
?RFC_Sample_Juge:
	smb0	Key_Flag
	smb1	Key_Flag							; �״δ���
	rmb3	Timer_Flag							; ������µ��½��ص��������ӱ�־λ
	rmb4	Timer_Flag							; 16Hz��ʱ
	smb1	TMRC								; �򿪿�Ӷ�ʱ

	bra		L_EndIrq

L_LcdIrq:
	rmb6	IFR									; ���жϱ�־λ

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


;I_PaIRQ_Handler:
;	smb0	Key_Flag
;	smb1	Key_Flag							; �״δ���
;	rmb3	Timer_Flag							; ������µ��½��ص��������ӱ�־λ
;	rmb4	Timer_Flag							; 16Hz��ʱ
;
;	smb1	TMRC								; �򿪿�Ӷ�ʱ
;	bra		L_EndIrq

I_Timer2IRQ_Handler:
	smb0	Timer_Flag							; �����־
	smb0	Symbol_Flag
	lda		Counter_1Hz
	cmp		#01
	bcs		L_1Hz_Out
	inc		Counter_1Hz
	bra		L_EndIrq
L_1Hz_Out:
	lda		#$0
	sta		Counter_1Hz
	lda		Timer_Flag
	ora		#10100110B							; 1S����S��Ϩ����1S������1S��־λ
	sta		Timer_Flag
	smb1	Backlight_Flag						; ����1S��ʱ
	smb7	Key_Flag							; DP��ʾ1S��ʱ
	smb1	Symbol_Flag
	smb7	Clock_Flag							; ����ʱ��1S��ʱ
	smb5	RFC_Flag							; 30S������ʱ
	rmb4	Clock_Flag							; �������������־
	bra		L_EndIrq


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


.BLKB	0FFFFH-$,0FFH							; �ӵ�ǰ��ַ��FFFFȫ�����0xFF

.ORG	0FFF8H
	DB		C_PY_SEL+C_OMS_BR
	DB		C_PROTB
	DW		0FFFFH

.ORG	0FFFCH
	DW		V_RESET
	DW		V_IRQ

.ENDS
.END
