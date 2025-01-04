F_PowerManage:
	jsr		L_HLightLevel_WithTime				; 7点后设为高亮
	jsr		L_LLightLevel_WithTime				; 18点后设为低亮

	bbr2	Clock_Flag,NoAlarm_WakeUp
	rmb4	PD									; 响闹时5020开启
	smb6	IER									; 亮屏开启LCD中断
	rts

NoAlarm_WakeUp:
	bbr6	PB,No_5VDC_PWR
	bbr0	Backlight_Flag,No_First_DCWake
	rmb0	Backlight_Flag
	rmb4	PD									; 插入DC5V时进行一次亮屏
No_First_DCWake:
	rts

No_5VDC_PWR:
	smb0	Backlight_Flag
	bbs3	Key_Flag,WakeUp_Event_Yes
	smb4	PD									; 无唤醒事件，则拉高PD4关闭5020
	rmb6	IER									; 熄屏后关闭LCD中断
	rts
WakeUp_Event_Yes:
	lda		Backlight_Counter
	cmp		#16
	bcs		L_ShutDown_Display					; 计满15S则断开5020供电，熄屏等待按键唤醒
	bbr1	Backlight_Flag,BacklightCount_NoAdd
	rmb1	Backlight_Flag
	inc		Backlight_Counter
BacklightCount_NoAdd:
	rts
L_ShutDown_Display:
	lda		#$00
	sta		Backlight_Counter
	smb4	PD									; 屏幕唤醒结束，拉高PD4关闭5020
	rmb6	IER									; 熄屏后关闭LCD中断
	rmb3	Key_Flag
	rts



L_HLightLevel_WithTime:
	lda		R_Time_Hour
	cmp		#7
	bne		?LightLevel_Exit
	lda		R_Time_Min
	cmp		#0
	bne		?LightLevel_Exit
	lda		R_Time_Sec
	cmp		#0
	bne		?LightLevel_Exit
	smb0	PC									; 设置为高亮
?LightLevel_Exit:
	rts

L_LLightLevel_WithTime:
	lda		R_Time_Hour
	cmp		#18
	bne		?LightLevel_Exit
	lda		R_Time_Min
	cmp		#0
	bne		?LightLevel_Exit
	lda		R_Time_Sec
	cmp		#0
	bne		?LightLevel_Exit
	rmb0	PC									; 设置为低亮
?LightLevel_Exit:
	rts



L_LightLevel_WithKeyU:
	lda		R_Time_Hour
	cmp		#7
	beq		KeyU_HighLight
	cmp		#18
	beq		KeyU_LowLight
	rts
KeyU_HighLight:
	smb0	PC									; 设置为高亮
	rts
KeyU_LowLight:
	rmb0	PC									; 设置为低亮
	rts


L_LightLevel_WithKeyD:
	lda		R_Time_Hour
	cmp		#17
	beq		KeyD_HighLight
	cmp		#6
	beq		KeyD_LowLight
	rts
KeyD_HighLight:
	smb0	PC									; 设置为高亮
	rts
KeyD_LowLight:
	rmb0	PC									; 设置为低亮
	rts