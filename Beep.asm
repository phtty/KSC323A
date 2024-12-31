F_Louding:
	bbs6	Timer_Flag,L_Beeping
	rts
L_Beeping:
	rmb6	Timer_Flag
	bbs4	Clock_Flag,L_ConstBeep_Mode
	lda		Beep_Serial							; 序列响铃模式
	beq		L_NoBeep_Serial_Mode
	dec		Beep_Serial
	bbr0	Beep_Serial,L_NoBeep_Serial_Mode
	smb0	SYSCLK
	smb4	PADF0								; PB3配置为IO口
	smb3	PB_TYPE								; PB3 设置CMOS输出
	smb1	PADF0								; PB3 PWM输出控制
	rts
L_NoBeep_Serial_Mode:
	rmb1	PADF0								; PB3 PWM输出控制
	rmb4	PADF0								; PB3配置为IO口
	rmb3	PB_TYPE								; PB3选择NMOS输出1避免漏电
	smb3	PB
	rmb0	SYSCLK

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

	bbr0	Beep_Serial,L_NoBeep_Const_Mode

	smb0	SYSCLK
	smb4	PADF0								; PB3配置为IO口
	smb3	PB_TYPE								; PB3 设置CMOS输出
	smb1	PADF0								; PB3 PWM输出控制
	rts
L_NoBeep_Const_Mode:
	rmb1	PADF0								; PB3 PWM输出控制
	rmb4	PADF0								; PB3配置为IO口
	rmb3	PB_TYPE								; PB3选择NMOS输出1避免漏电
	smb3	PB
	rmb0	SYSCLK
	rmb4	Key_Flag
	rts