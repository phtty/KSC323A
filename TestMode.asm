F_Test_Mode:
	jsr		F_ClearScreen

	ldx		#led_d0
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d1
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d2
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d3
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	lda		#2									; 上电蜂鸣器响1声
	sta		Beep_Serial
	rmb4	Clock_Flag
	smb4	Key_Flag
	smb0	TMRC

	bbs6	PB,StartUp_WakeUp					; 如果没有5V供电
	smb3	Key_Flag							; 上电先给一个唤醒事件，免得上电不显示
	rmb4	PD
StartUp_WakeUp:
	lda		#0
	sta		P_Temp
L_Test_Loop:
	jsr		F_Louding
	bbr0	TMRC,L_Test_Over
	bra		L_Test_Loop
L_Test_Over:
	;rmb0	SYSCLK
	rts