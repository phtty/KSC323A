F_Test_Mode:
	jsr		F_FillScreen

Loop_FillScr:
	
	bra		Loop_FillScr

	lda		#4									; 上电蜂鸣器响1声
	sta		Beep_Serial
	rmb4	Clock_Flag
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


L_DisDigit_Test:
	ldx		#led_d0
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d1
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d2
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d5
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d6
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d7
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d8
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d9
	lda		P_Temp
	jsr		L_Dis_7Bit_DigitDot
	rts