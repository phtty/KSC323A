;========================================================================================
;				RFC 50P008_Program
;========================================================================================
;1��Set PD as input tri-state
;2��Disable TMR0 and TMR1 interrupt
;3��Set TRM0S0 to '1' to select TMR0 clock source as Frcx
;4��Clear TMR1S[1:0]='00' to select TMR1 clock source as TMR0 output
;5��Set TMR_SYNC to '1'
;6��Write 00h to both TMR0 and TMR1
;7��Select a desired RC combination for measurement by setting RFC[1:0], CRT0S and RT01S register bits
;8��Set RFCEN0 or RFCEN1 to ��1��.The external RC combination will start oscillating.
;9��Clear DIVF interrupt flag.
;10��Enable DIV interrupt then wait a DIV interrupt occurs
;11��Clear TMR0F,TMR1F and DIVF interrupt flags.
;12��Set TMR0On and TMR1ON at the same time.TMR0 and TMR1 will not start counting until the next DIV interrupt occurs(1st DIV occurs).
;13��Wait while the nth DIV occurs, clear TMR0ON and TMR0ON at the same time.
;    TMR0 and TMR1 will not stop counting until the (n+1)th DIV occurs.
;14��Read TMR0 and TMR1 data and check TMR1F to get the RC counts of this measurement
;15��Clear RFCEN0 or RFCEN1 to finish the RC oscillation measurement
;16��Repeat step 6 to 15 will get the RC counts of other RC combination
;========================================================================================
C_RfcTime		equ		5 ;10 	;n(div)=1KHZ 10mS
;========================================================================================
PD03_RFC:	.MACRO
		smb0	RFCC0
		smb1	RFCC0
		smb2	RFCC0
		smb3	RFCC0
		
		rmb6	PC_SEG
		
		rmb0	PD_SEG
		rmb1	PD_SEG
		rmb2	PD_SEG
		rmb3	PD_SEG			
		.ENDM   

M_PD0PD3:	.MACRO
		rmb0	RFCC0
		rmb1	RFCC0
		rmb2	RFCC0
		rmb3	RFCC0
		
		smb0	PD_DIR
		smb1	PD_DIR
		smb2	PD_DIR
		smb3	PD_DIR
    
		smb0	PD
		smb1	PD
		smb2	PD
		smb3	PD
		.ENDM
;=================================================
F_GetFrcMode0:		;input R_RFCCH : wait time, Xcc : Which Port
		sta		R_RFCCH

		rmb1	IER			;clear Tmr0 int
		rmb2	IER			;clear Tmr1 int
		rmb0	IFR			;clear div int flag
?L_WaitDiv:
		bbr0	IFR,?L_WaitDiv

		rmb0	IFR			;clear div int flag		
		rmb1	IFR			;clear tm0 int flag
		rmb2	IFR			;clear tm1 int flag

		rmb0	<TMRC			
		rmb1	<TMRC			;close tmr0 and tmr1

		lda		#0
		sta		TMR0
		sta		TMR1

		lda		#00000011B
		sta		TMCLK			;set timer0 from T01 ,timer1 from timer0

		smb6	DIVC			;set sync with tm0 and tm1
		smb6	TMRC			;T0I=Frcx

		lda		T_RFCTable,x
		sta		RFCC1			;ʹ��ͨ��RFC

		smb0	TMRC			
		smb1	TMRC			;open tmr0 and tmr1	
?L_WaitDiv2:
		bbr0	<IFR,?L_WaitDiv2
		rmb0	<IFR			;clear div int flag
		dec		R_RFCCH
		bne		?L_WaitDiv2
?L_Exit:
		rmb0	<TMRC			
		rmb1	<TMRC			;close tmr0 and tmr1
?L_WaitDiv3:
		bbr0	<IFR,?L_WaitDiv3
		rmb0	<IFR			;clear div int flag

		lda		#0
		sta		RFCC1			;�ر�RFC
		rmb6	TMRC			;T0I = Fosc/4		
		rts

T_RFCTable:
;;;;;;2nd  ��ʱ
	db	00100000B	; PD3_CTRT0		;2 PD3	RR
	db	00010000B	; PD2_RS0 		;1 PD2	RT
	db	01100000B	; PD1_CSRT0		;0 PD1	RH
	db	00110000B	; PD4_RT01		;3 PD4	CS---GND	

;;;;;;2nd
	db	01100000B	; PD1_CSRT0		;0 PD1
	db	00010000B	; PD2_RS0 		;1 PD2
	db	00100000B	; PD3_CTRT0		;2 PD3
	db	00110000B	; PD4_RT01		;3 PD4	CS---GND

	db	10010000B	; PD2_RS0		;4 PD2
	db	10100000B	; PD3_CTRT0		;5 PD3
	db	10110000B	; PD4_RT01		;6 PD4	CS---CSRT0
;=========================================================
;=========================================================
F_RfcTest:
;		DIV_512HZ
;		DIS_DIV_IRQ
;		Fsys_4MHZ		
;		Fcpu_Fext
;		NOP
;		Fosc_OFF
;		NOP
		SEI
		PD03_RFC
		ldx		#0	;#1	;
  		lda		#C_RfcTime
		jsr		F_GetFrcMode0
		lda		TMR0
		STA 	R_RR_L
		lda		TMR1
		STA 	R_RR_M
		LDA 	#$00
		STA 	R_RR_H

		ldx		#1	;#2	;
  		lda		#C_RfcTime
		jsr		F_GetFrcMode0
		LDA 	TMR0
		STA 	R_RT_L
		LDA 	TMR1
		STA 	R_RT_M
		LDA		#$00
		STA 	R_RT_H
		
		ldx		#2	;#2	;
  		lda		#C_RfcTime
		jsr		F_GetFrcMode0		
		LDA 	TMR0
		STA 	R_RH_L
		LDA 	TMR1
		STA 	R_RH_M
		LDA		#$00
		STA 	R_RH_H
;		Fosc_ON
;		NOP
;		Fsys_2MHZ		
;		Fcpu_Fsys
;		NOP
;		EN_DIV_IRQ
		JSR		L_Counter_Temperature_Prog
		JSR		L_Counter_Humidity_Prog
		CLI
		RTS	
;=======================================================
;===============================================
L_LoadRfcTest:
		bbs1	RFC_Flag,?RTS
		BNE		?RTS		;������ ������
		
		SEI
		PD03_RFC
		LDA		#D_RFC_CH_MAX
		STA		R_RFC_CH
		LDA		#D_RFC_TIME
		STA		R_RFC_TIME
		SMB0	R_RFCFLAG		;RFC Run
		CLI
?RTS:
		RTS
;;===============================================
;;===============================================
L_RFC_Int:
L_IntRfcTest:
		LDA		R_RFC_TIME
		BEQ		?RTS
		DEC		R_RFC_TIME
		BEQ		L_GetRfcData
		LDA		R_RFC_TIME
		CMP		#D_EN_RFC	;#D_EN_TIMER
		BEQ		L_SartRfc	;L_EnableTimer
		CMP		#D_DIS_TIMER
		BEQ		L_DisableTimer
?RTS:
		RTS

L_SartRfc:
;		LDA		#D_EN_RFC
;		STA		R_RFC_TIME

;		RMB0	IFR			;clear div int flag		
		RMB1	IFR			;clear tm0 int flag
		RMB2	IFR			;clear tm1 int flag

		RMB0	TMRC			
		RMB1	TMRC			;close tmr0 and tmr1

		LDA		#0
		STA		TMR0
		STA		TMR1								

		LDA		#%00000011	
		STA		TMCLK			;set timer0 from T01 ,timer1 from timer0

		SMB6	DIVC			;set sync with tm0 and tm1
		SMB6	TMRC			;T01=Frcx

		LDX		R_RFC_CH
		LDA		T_RFCTable,X
		STA		RFCC1

		SMB0	TMRC			
		SMB1	TMRC			;open tmr0 and tmr1		
		RTS

L_EnableTimer:
		RMB1	IFR			;clear tm0 int flag
		RMB2	IFR			;clear tm1 int flag
		LDA		#0
		STA		TMR0
		STA		TMR1
		
		SMB0	TMRC			
		SMB1	TMRC			;open tmr0 and tmr1		
		RTS		
		
L_DisableTimer:
		RMB0	TMRC			
		RMB1	TMRC			;close tmr0 and tmr1	
		RTS
;
L_GetRfcData:
		LDA		#0
		STA		RFCC1		;RFC CLOSE
		RMB6	TMRC		;T01=Frcx	
		
		LDA		R_RFC_CH
		BEQ		?GetRRData
		DEC		R_RFC_CH
		BEQ		?GetRtData
		JSR		?GetRhData
		RTS
		
?GetRRData:	
;		LDA		#0
;		STA		RFCC1		;RFC CLOSE
;		RMB6	TMRC		;T01=Frcx		
		LDA		TMR0
		STA 	R_RR_L
		LDA		TMR1
		STA 	R_RR_M
		
		RMB0	R_RFCFLAG	;RFC STOP
		SMB7	R_RFCFLAG	;RFC TEST OVER	
		RTS

?GetRtData:
		LDA		TMR0
		STA 	R_RT_L
		LDA		TMR1
		STA 	R_RT_M	
;		LDA 	#$00
;		STA 	R_RT_H
		LDA		#D_RFC_TIME
		STA		R_RFC_TIME
		RTS
		
?GetRhData:
		LDA		TMR0
		STA 	R_RH_L
		LDA		TMR1
		STA 	R_RH_M	
;;		LDA 	#$00
;;		STA 	R_RH_H
		LDA		#D_RFC_TIME
		STA		R_RFC_TIME
		RTS
;;===============================================	
L_Calc_RfcTemp:
		BBR7	R_RFCFLAG,?RTS
		RMB7	R_RFCFLAG
		JSR		L_Counter_Temperature_Prog
		JSR		L_Counter_Humidity_Prog		
?RTS		
		RTS
;;===============================================
F_Div10:
		LDX	#$ff
		SEC
?div_10_loop:
		SBC	#10
		INX
		BCS	?div_10_loop
		ADC	#10
		RTS
;----------------------------------------------------------------------
F_Hex_To_Dec:			;*С��100��ʮ������תʮ����
	JSR		F_Div10
	sta		P_Temp
	txa
	clc
	rol
	clc
	rol
	clc
	rol
	clc
	rol
	ora		P_Temp
	rts
;----------------------------------------------------------------------