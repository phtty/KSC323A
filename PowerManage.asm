F_PowerManage:
	bbr6	PB,No_5VDC_PWR
	rts
No_5VDC_PWR:
	bbs3	Key_Flag,WakeUp_Event_Yes
	smb4	PD									; 无唤醒事件，则拉高PD4关闭5020
	rts
WakeUp_Event_Yes:
	lda		Backlight_Counter
	cmp		#15
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
	rmb3	Key_Flag
	rts