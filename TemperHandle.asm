L_Temper_Handle:
	jsr		L_RT_Multi_256
	jsr		L_RT_Div_RR
	jsr		L_Search_TemperTable
	jsr		Temper_Compen
	sec
	lda		R_Temperature
	sbc		R_Temper_Comp
	sta		R_Temperature
	rts

; 通过Qt查表确定当前温度
L_Search_TemperTable:
	rmb2	RFC_Flag							; 清除负数温度标志位
	ldx		#255								; 初始值为255，进入循环后会+1溢出变为0
L_Sub_Temper:
	inx
	txa
	cmp		#61
	bcs		L_Temper_Overflow					; 大于等于50度则退出循环
	lda		RT_Div_RR_L
	sec
	sbc		Temperature_Table,x
	sta		RT_Div_RR_L
	lda		RT_Div_RR_H
	sbc		#0
	sta		RT_Div_RR_H
	bcs		L_Sub_Temper

L_Temper_Overflow:
	txa
	beq		Temper_LowerThan_M10				; -10度以下不在表中不需要递减1度
	dex
Temper_LowerThan_M10:
	stx		P_Temp
	txa
	sec
	sbc		#10
	bcs		L_Search_Over						; 大于0则为正数or0温度
	lda		#10									; 负数温度的处理
	sec
	sbc		P_Temp
	smb2	RFC_Flag							; 负数温度标志位
L_Search_Over:
	sta		R_Temperature
	rts

; 热敏电阻左移8位除以标准电阻，计算比值Qt，量程为-10~50度
L_RT_Div_RR:
	lda		#0
	sta		RT_Div_RR_H
	sta		RT_Div_RR_L
?Div_Juge:
	lda		RFC_TempCount_H
	cmp		RFC_StanderCount_H					; 比较热敏电阻和标准电阻的测量值高8位
	bcc		?Loop_Over
	lda		RFC_StanderCount_H
	cmp		RFC_TempCount_H
	bcc		?Div_Start

	lda		RFC_TempCount_M						; 比较热敏电阻中8位和标准电阻的测量值中8位
	cmp		RFC_StanderCount_M
	bcc		?Loop_Over							; 标准电阻大于热敏电阻时即为除完了
	lda		RFC_StanderCount_M
	cmp		RFC_TempCount_M
	bcc		?Div_Start							; RT<RR，则一定没除完

	lda		RFC_TempCount_L						; 高8位相等的情况下，看低8位
	cmp		RFC_StanderCount_L
	bcc		?Loop_Over							; 低8位RR<RT，则循环减除数
	beq		?Loop_Over							; 此时低8位RT==0，则不继续除，说明采样错误，直接返回
?Div_Start:
	sec
	lda		RFC_TempCount_L						; RT循环减RR
	sbc		RFC_StanderCount_L
	sta		RFC_TempCount_L
	lda		RFC_TempCount_M
	sbc		RFC_StanderCount_M
	sta		RFC_TempCount_M
	lda		RFC_TempCount_H
	sbc		RFC_StanderCount_H
	sta		RFC_TempCount_H

	lda		RT_Div_RR_L
	clc
	adc		#1
	sta		RT_Div_RR_L
	lda		RT_Div_RR_H
	adc		#0
	sta		RT_Div_RR_H							; 储存商
	bra		?Div_Juge
?Loop_Over:
	rts

; 热敏电阻乘以256
L_RT_Multi_256:
	lda		#8
	sta		P_Temp
RT_Multi_256_Loop:
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	dec		P_Temp
	bne		RT_Multi_256_Loop
	rts




; 摄氏->华氏度转换
F_C2F:
	lda		R_Temperature
	sta		P_Temp							; 初始化一些变量

	lda		#0
	sta		P_Temp+1

	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1
	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1
	clc
	rol		P_Temp							; 左移三位乘以8
	rol		P_Temp+1


	lda		P_Temp
	clc
	adc		R_Temperature					; 加上它自身完成乘9
	sta		P_Temp
	lda		P_Temp+1
	adc		#0
	sta		P_Temp+1

	ldx		#0								; 使用X寄存器来计数商
?Div_By_5_Loop:
	lda		P_Temp+1
	bne		?Div_By_5_Loop_Start			; 有高8位的时候，直接减
	lda		P_Temp							; 无高8位时，再判断低8位的情况
	cmp		#5
	bcc		?Loop_Over
?Div_By_5_Loop_Start:
	lda		P_Temp
	sec
	sbc		#5
	sta		P_Temp
	lda		P_Temp+1
	sbc		#0
	sta		P_Temp+1
	inx
	bra		?Div_By_5_Loop
?Loop_Over:
	stx		P_Temp							; 算出除以5的值
	bbs2	RFC_Flag,Minus_Temper
	txa
	clc
	adc		#32								; 正温度时，直接加上32即为华氏度结果
	sta		R_Temperature_F
	rts

Minus_Temper:								; 处理负温度的情况
	lda		#32
	sec
	sbc		P_Temp							; 负数温度则是32-计算值
	sta		R_Temperature_F
	rts


; 温度补偿，补偿区间3℃~46℃
Temper_Compen:
	lda		R_Temperature
	cmp		#3
	bcc		No_Compensation
	lda		R_Temperature
	cmp		#46
	bcc		Compensation_Trigger

No_Compensation:
	lda		#0
	sta		R_Temper_Comp					; 清空补偿值和补偿时间
	sta		R_Temper_Comp_Time
	rts

Compensation_Trigger:
	lda		R_Temper_Comp_Time				; 通过补偿时间计算补偿值
	jsr		L_A_Mod_5
	stx		R_Temper_Comp
	rts



CompensationTime_CHG:
	bbs4	PD,DecCompensation
	lda		R_Temper_Comp_Time
	cmp		Compensation_MaxTime	
	bcs		CompensationTime_Overflow		; 补偿计时若超过最大值则不自增
	inc		R_Temper_Comp_Time
CompensationTime_Overflow:
	rts

DecCompensation:
	lda		R_Temper_Comp_Time
	beq		CompensationTime_Overflow
	dec		R_Temper_Comp_Time
	rts



; 低亮时温补调整
L_LowLight_Comp:
	lda		R_Temper_Comp_Time					; 低亮时重置温补时间
	cmp		#8
	bcc		?No_OverFlow
	lda		#8
	sta		R_Temper_Comp_Time
?No_OverFlow:
	lda		#8
	sta		Compensation_MaxTime				; 低亮时最大计时改为8
	rts

; 高亮时温补调整
L_HighLight_Comp:
	lda		#18
	sta		Compensation_MaxTime				; 高亮时最大计时改为18
	rts
