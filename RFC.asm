F_RFC_MeasureStart:
	smb0	IER									; 打开DIV中断
	rmb1	IER									; 关TMR0、1定时器中断
	rmb2	IER

	lda		TMRC								; T0I设置为Frcx
	ora		#C_T0I_1
	sta		TMRC
	lda		#C_TMR0_T0I+C_TMR1_TMR0				; 配置TM0时钟源为T0I,TM1时钟源为TM0,级联TM0和TM1
	sta		TMCLK

	lda		#C_SyncWithDIV+C_DIVC_Fsub_64
	sta		DIVC								; 开启定时器同步，DIV时钟源为Fsub/64(512Hz)

	lda		#$0									; 清0定时器重装载值
	sta		TMR0
	sta		TMR1

	rts

F_RFC_MeasureManage:
	bbs3	Clock_Flag,L_RFC_Exit				; 存在响闹和按键音的时候，TIM0、1被占用，不进行测量
	bbs4	Key_Flag,L_RFC_Exit
	bbs0	RFC_Flag,L_RFC_Juge
L_RFC_Exit:
	rts
L_RFC_Juge:
	rmb7	RFC_Flag
	lda		RFC_ChannelCount
	cmp		#01									; PD3口采样湿度
	bne		L_NoHumi
	lda		TMR0
	sta		RFC_HumiCount_L
	lda		TMR1
	sta		RFC_HumiCount_H
	bra		L_Sample_Over
L_NoHumi:
	lda		RFC_ChannelCount
	cmp		#02									; PD2口采样温度
	bne		L_NoTemp
	lda		TMR0
	sta		RFC_TempCount_L
	lda		TMR1
	sta		RFC_TempCount_H
	bra		L_Sample_Over
L_NoTemp:
	lda		RFC_ChannelCount
	cmp		#03									; PD1口采样标准电阻
	bne		L_Sample_Over
	lda		TMR0
	sta		RFC_StanderCount_L
	lda		TMR1
	sta		RFC_StanderCount_H
	jsr		L_RFC_Handler						; 只有采样到标准电阻才会进处理函数去计算具体值
L_Sample_Over:
	lda		RFC_ChannelCount
	cmp		#04									; 检测是否溢出
	bcc		L_RFC_NoOverflow
	lda		#0
	sta		RFC_ChannelCount
L_RFC_NoOverflow:
	inc		RFC_ChannelCount					; 每次采样后，递增检测通道

	ldx		RFC_ChannelCount
	lda		T_RFC_Channel,x
	sta		RFCC1

	rts



F_RFC_MeasureStop:
	smb1	RFC_Flag							; 禁用RFC标志 
	jsr		F_Timer_Init						; 定时器配置为响铃和长按状态,关闭定时器同步
	rmb0	IER									; 关闭DIV中断

	lda		#0
	sta		RFC_TempCount_H						; 清理相关变量	
	sta		RFC_TempCount_L
	sta		RFC_HumiCount_H
	sta		RFC_HumiCount_L
	sta		RFC_StanderCount_H
	sta		RFC_StanderCount_L

	lda		#0									; 关闭RFC功能
	sta		RFC_ChannelCount					; 重置RFC Channel计数
	sta		RFCC1

	rts


L_RFC_Handler:
	jsr		L_Temper_Handle
	jsr		L_Humid_Handle

	rts



T_RFC_Channel:
	db		$00 ; disable
	db		$20	; CTRT0	PD3
	db		$10	; RS0	PD2
	db		$60	; CSRT0	PD1
