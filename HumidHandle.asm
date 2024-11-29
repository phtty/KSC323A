L_Humid_Handle:
	jsr		L_RH_Multi_256
	jsr		L_RR_Div_2
	jsr		L_RH_Div_RR
	jsr		L_Search_HumidTable

	rts

L_Search_HumidTable:
	lda		R_Temperature
	jsr		L_A_Mod_5							; 将温度值除以5得到湿度表索引N
	cmp		#2
	bcs		N_GreaterThan1
	bra		Temper_GapSmall						; 余数为0和1时用索引N查表
N_GreaterThan1:
	cmp		#4
	bcs		N_GreaterThan3
	bra		Temper_GapMiddle					; 余数为2和3时用索引N和N+1查两次表，取二者的平均数
N_GreaterThan3:
	inc		P_Temp
	bra		Temper_GapLong						; 余数为4则用索引值为N+1查表

Temper_GapSmall:
	jsr		L_SearchTable_N						; 在温度的余数较小时，直接采用接近的湿度表查出湿度值
	rts
Temper_GapMiddle:
	jsr		L_SearchTable_N						; 余数较大时，采用两个湿度表计算出的平均值作为湿度值
	lda		R_Humidity
	sta		P_Temp+2
	inc		P_Temp								; 查索引值为N+1的湿度表
	jsr		L_SearchTable_N
	lda		R_Humidity
	clc
	adc		P_Temp+2							; 前后取得的湿度值相加然后除以2，获得平均值
	clc
	ror
	sta		R_Humidity							; 计算出的平均值为最终湿度值
	rts
Temper_GapLong:
	jsr		L_SearchTable_N						; 在温度的余数较大时，用下一阶的湿度表查出湿度值
	rts

; 用N作为索引，查湿度表得出当前湿度值
; P_Temp为湿度表索引N，Qh为L_RH_Div_RR
L_SearchTable_N:
	lda		P_Temp
	clc
	rol											; N值乘以2得到正确的偏移
	sta		P_Temp
	lda		#0
	sta		R_Humidity							; 湿度值
Loop_Start:
	bbs3	RFC_Flag,Loop_Over					; 如果在递减查表函数中减完，则退出循环
	lda		Humid_SearchLoop_Addr+1,x			; 入栈循环开始标签的地址
	pha											; 以便能在递减查表函数中
	lda		Humid_SearchLoop_Addr,x				; 能返回到该函数循环开始
	pha

	ldx		P_Temp
	lda		Temper_Humid_table+1,x
	pha											; 入栈对应的递减查表函数地址
	lda		Temper_Humid_table,x
	pha
	rts											; 跳转到对应递减查表函数
Loop_Over:
	rmb3	RFC_Flag							; 复位递减完成标志位
	lda		R_Humidity
	clc
	ror											; 循环查表得到的值除以2加20
	clc
	adc		#20
	sta		R_Humidity							; 才是实际湿度值
	rts


Humid_SearchLoop_Addr:							; 子程序的地址表
	dw		Loop_Start-1

Temper_Humid_table:
	dw		L_0Degree_Humid-1
	dw		L_5Degree_Humid-1
	dw		L_10Degree_Humid-1
	dw		L_15Degree_Humid-1
	dw		L_20Degree_Humid-1
	dw		L_25Degree_Humid-1
	dw		L_30Degree_Humid-1
	dw		L_35Degree_Humid-1
	dw		L_40Degree_Humid-1
	dw		L_45Degree_Humid-1
	dw		L_50Degree_Humid-1

; 湿度电阻左移8位除以2分之1标准电阻，计算比值Qh
L_RH_Div_RR:
	lda		#0
	sta		RH_Div_RR_H
	sta		RH_Div_RR_L
?Div_Juge:
	lda		RFC_HumiCount_H						; 比较标准电阻和湿度电阻的测量值高8位
	cmp		RFC_StanderCount_H
	bcc		?Loop_Over							; 高8位RR大于RH时即为除完了
	lda		RFC_StanderCount_H
	cmp		RFC_HumiCount_H
	bcc		?Div_Start							; 高8位RR<RH，则循环减除数

	lda		RFC_HumiCount_L						; 高8位相等的情况下，看低8位
	cmp		RFC_StanderCount_L
	bcc		?Loop_Over							; 低8位RH<RR，也是除完了
?Div_Start:
	sec
	lda		RFC_HumiCount_L						; RH循环减RR
	sbc		RFC_StanderCount_L
	sta		RFC_HumiCount_L
	lda		RFC_HumiCount_H						; 直到RH<RR则除法结束
	sbc		RFC_StanderCount_H
	sta		RFC_HumiCount_H

	inc		RR_Div_RT_L
	bne		?Loop_Over
	inc		RR_Div_RT_H							; 储存商
	bra		?Div_Juge
?Loop_Over:
	rts


L_0Degree_Humid:
	ldx		R_Humidity
	lda		Humid_0Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_0Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_0Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_0Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_5Degree_Humid:
	ldx		R_Humidity
	lda		Humid_5Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_5Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_5Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_5Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_10Degree_Humid:
	ldx		R_Humidity
	lda		Humid_10Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_10Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_10Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_10Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_15Degree_Humid:
	ldx		R_Humidity
	lda		Humid_15Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_15Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_15Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_15Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_20Degree_Humid:
	ldx		R_Humidity
	lda		Humid_20Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_20Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_20Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_20Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_25Degree_Humid:
	ldx		R_Humidity
	lda		Humid_25Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_25Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_25Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_25Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_30Degree_Humid:
	ldx		R_Humidity
	lda		Humid_30Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_30Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_30Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_30Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_35Degree_Humid:
	ldx		R_Humidity
	lda		Humid_35Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_35Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_35Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_35Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_40Degree_Humid:
	ldx		R_Humidity
	lda		Humid_40Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_40Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_40Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_40Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_45Degree_Humid:
	ldx		R_Humidity
	lda		Humid_45Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_45Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_45Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_45Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts

L_50Degree_Humid:
	ldx		R_Humidity
	lda		Humid_50Degree_Table,x
	sec
	sbc		RH_Div_RR_L
	inx
	lda		Humid_50Degree_Table,x
	sec
	sbc		RH_Div_RR_H
	bcs		L_50Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	rts
L_50Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	rts


L_RH_Multi_256:
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	clc
	rol		RFC_HumiCount_L
	rol		RFC_HumiCount_H
	rts

L_RR_Div_2:
	clc
	ror		RFC_StanderCount_H
	ror		RFC_StanderCount_L
	rts


; P_Temp存商，A为余数
L_A_Mod_5:
	lda		#0
	sta		P_Temp
L_A_Mod_5_Start:
	cmp		#5
	bcc		L_A_Mod_5_Over
	sec
	sbc		#5
	inc		P_Temp
	bra		L_A_Mod_5_Start
L_A_Mod_5_Over:
	rts