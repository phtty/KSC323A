F_Louding:
	bbs6	Timer_Flag,L_Beeping
	rts
L_Beeping:
	rmb6	Timer_Flag
	bbs4	Clock_Flag,L_ConstBeep_Mode
	lda		Beep_Serial							; 序列响铃模式
	cmp		#0
	beq		L_NoBeep_Serial_Mode
	dec		Beep_Serial
	bbr0	Beep_Serial,L_NoBeep_Serial_Mode
	smb1	PADF0								; 设置PB3为PWM模式
	smb3	PB_TYPE
	smb7	TMRC
	rts
L_NoBeep_Serial_Mode:
	rmb7	TMRC
	rmb1	PADF0								; PB3设置为CMOS输出低
	smb3	PB_TYPE
	rmb3	PB
	bbr4	Key_Flag,No_KeyBeep_Over			; 如果是按键音则需要在响铃结束后关闭蜂鸣定时器
	rmb4	Key_Flag
	rmb1	RFC_Flag							; 按键音的响铃完毕重新取消禁用RFC采样
	rmb0	TMRC
No_KeyBeep_Over:
	rts

L_ConstBeep_Mode:
	lda		Beep_Serial							; 持续响铃模式
	eor		#01B								; Beep_Serial翻转第一位
	sta		Beep_Serial

	lda		Beep_Serial
	bbr0	Beep_Serial,L_NoBeep_Const_Mode
	smb1	PADF0
	smb3	PB_TYPE
	smb7	TMRC
	rts
L_NoBeep_Const_Mode:
	rmb7	TMRC
	rmb1	PADF0								; PB3设置为CMOS输出低
	smb3	PB_TYPE
	rmb3	PB
	rmb4	Key_Flag
	rts