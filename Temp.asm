;------------------------------------------------
;------------------------------------------------
;************************************************
;------------------------------------------------
;L_RR_Fail_Program:
;	lda		R_Temperature_L
;	AND		#0	;#$0F
;	ORA		#$10
;	sta		R_Temperature_L
;	LDA		#$BB
;	STA		R_Temperature
;	STA		R_Temperature_F_H
;   STA     R_Temperature_F_M
;	RTS
;------------------------------------------------
;************************************************
;------------------------------------------------
L_Counter_Temperature_Prog:
        LDA     R_RT_M
;        ORA     R_RT_H
		BNE	 	L_OK1
        LDA     R_RT_L
		CMP		#10
		BCS		L_OK1	;L_RR_Fail_Program
		JMP		L_Temperature_Low
L_OK1:
        LDA     R_RR_M
;		ORA     R_RR_H
		BNE		L_OK2
        LDA     R_RR_L
		CMP		#10
		BCS		L_OK2	;L_RR_Fail_Program
		JMP		L_Temperature_Low
L_OK2:	
		CLD
        LDA     R_RT_L
        STA     P_Temp+10 ; 0 ; 3
        LDA     R_RT_M
        STA     P_Temp+11 ; 1 ; 4
        LDA     #0H
        STA     P_Temp+12 ; 2 ; 5

        LDA     R_RR_L
        STA     P_Temp+13 ; 3 ; 0
        LDA     R_RR_M
        STA     P_Temp+14 ; 4 ; 1
        LDA     #0H
        STA     P_Temp+15 ; 5 ; 2

        JSR     L_Counter_T_Sbc_Prog

        LDA     P_Temp+9
        STA     P_Temp+7
        JSR     L_R0Data_LeftMove4Bit
        JSR     L_Counter_T_Sbc_Prog

        LDA     P_Temp+9
        STA     P_Temp+8
		CLC
		ROL		P_Temp+8
		CLC
		ROL		P_Temp+8
		CLC
		ROL		P_Temp+8
		CLC
		ROL		P_Temp+8
        JSR     L_R0Data_LeftMove4Bit
        JSR     L_Counter_T_Sbc_Prog

        LDA     P_Temp+9
        ORA     P_Temp+8
        STA     P_Temp+8
        JSR     L_R0Data_LeftMove4Bit
        JSR     L_Counter_T_Sbc_Prog

        CLC
        LDA     #$F8
        ADC     P_Temp+9
        LDA     #0
        ADC     P_Temp+8
        STA     P_Temp+8
        LDA     #0
        ADC     P_Temp+7
        STA     P_Temp+7
        LDA     #0
        STA     P_Temp+6
        LDX     #0
		
;		 SEC				;xwx
;        LDA     P_Temp+7
;        SBC     #1
;        BCC     L_Counter_T_Step2		
;		 SEC
;        LDA     P_Temp+7
;        SBC     #1
;        STA     P_Temp+7	;xwx	;��0�ȿ�ʼ������255 		

L_Loop_Counter_T_Step1:
		SEC
        LDA     P_Temp+8
        SBC     Table_Temperature,X
        LDA     P_Temp+7
        SBC     #0
        BCC     L_Counter_T_Step2
        SEC
        LDA     P_Temp+8
        SBC     Table_Temperature,X
        STA     P_Temp+8
        LDA     P_Temp+7
        SBC     #0
        STA     P_Temp+7
        INX
;        SED
;        CLC
;        LDA     #1
;        ADC     P_Temp+6
;        STA     P_Temp+6
;        CLD
		INC		P_Temp+6	
		
        JMP     L_Loop_Counter_T_Step1

L_Counter_T_Step2:
    LDA     P_Temp+6
    BNE     L_Counter_T_Step2_1
L_Temperature_Low:
;	JMP		L_RR_Fail_Program
	LDA		R_Temperature_L
	AND		#0	;#$0F
	ORA		#$20
	STA		R_Temperature_L
	LDA		#0
	STA		R_Temperature
;	JMP		L_Test_Ok	
;	ORA		#$89
;	sta		R_Temperature_L
;	LDA		#09
;	STA		R_Temperature
;	JMP		L_TestOkExit
	RTS


L_Counter_T_Step2_1:
	SEC
    LDA     #61		;-10~50
    SBC     P_Temp+6
    BCS     L_Counter_T_Step2_2
L_Temperature_High:
	lda		R_Temperature_L
	AND		#0	;#$0F
	ORA		#$40
	sta		R_Temperature_L
	LDA		#50
	STA		R_Temperature
;	JMP		L_TestOkExit
	RTS

L_Counter_T_Step2_2:
    JSR     L_Counter_T_Decimals
    SEC
    LDA     P_Temp+6		
    SBC     #11		;#52	
    BCS     L_Temperature_Over_0
	JMP		L_Temperature_Low
	
	LDA		#10
	STA		P_Temp
    LDA     P_Temp+5
	BEQ     L_Measure_Small0_Temp_L
	LDA     #10
	STA     P_Temp
L_Measure_Small0_Temp_L:
	SEC
    LDA     P_Temp
    SBC     P_Temp+6
    STA     R_Temperature
	
;	LDA		P_Temp+5
;	BEQ		?NoInc
;	CMP		#10-7
;	BCS		?NoInc
;	INC		R_Temperature
;?NoInc:
	
	LDA		R_Temperature
	BNE		?Continue
    LDA     P_Temp+5
	BNE		?Continue
	LDA		#0
	STA		R_Temperature_L	
	JMP		L_Test_Ok
?Continue:
	JMP		L_Temperature_Low

	LDA		R_Temperature_L	;P_Temp+5	;
	AND		#$00
	ORA		#$80
	STA		R_Temperature_L ;�¶ȸ�ֵ��־
	LDA		R_Temperature
	CMP		#21
	BCC		L_End_CounteP_Temp_Small_0
	JMP		L_Temperature_Low
L_End_CounteP_Temp_Small_0:	
	JMP		L_Test_Ok
;========================================
L_Temperature_Over_0:
	STA		R_Temperature

	LDA		#0
	STA		R_Temperature_L

;	LDA		P_Temp+5
;	AND		#$0F
;	CMP		#$07
;	BCC		?Skip
;	STA		R_Temperature_L
;	INC		R_Temperature
?Skip:


L_ExitDisDeal:
L_Test_Ok:
	
	LDA		R_Temperature
	CMP		#51	;71	;65	;
	BCS		L_Temperature_High
L_TestOkExit:
	LDA		R_Temperature
	JSR		F_Hex_To_Dec
	STA		R_Temperature			;*С��100��ʮ������תʮ����
	JMP		L_C_SwitchTo_F_Program
;------------------------------------------------
L_Counter_T_Decimals:
        LDA     #$A
        STA     P_Temp
        LDA     #0
        STA     P_Temp+1
        STA     P_Temp+2
L_Loop_Mul10:
        LDA     P_Temp
        BEQ     L_Counter_T_Decimals_1
        CLC
        LDA     P_Temp+8
        ADC     P_Temp+2
        STA     P_Temp+2
        LDA     P_Temp+7
        ADC     P_Temp+1
        STA     P_Temp+1
        DEC     P_Temp
        JMP     L_Loop_Mul10

L_Counter_T_Decimals_1:
        LDA     #0
        STA     P_Temp+5
L_Loop_Counter_T_Decimals:
		SEC
        LDA     P_Temp+2                                              
        SBC     Table_Temperature,X
        STA     P_Temp+2
        LDA     P_Temp+1
        SBC     #0
        STA     P_Temp+1
        BCC     L_End_Counter_T_Decimals
        INC     P_Temp+5
        JMP     L_Loop_Counter_T_Decimals
L_End_Counter_T_Decimals:
	RTS
;------------------------------------------------
L_R0Data_LeftMove4Bit:
        LDA     #4
        STA     P_Temp
L_Loop_LeftMove4Bit:
        LDA     P_Temp
        BEQ     L_End_R0Data_LeftMove4Bit
;        ASL     P_Temp+10
		CLC
		ROL		P_Temp+10
        ROL     P_Temp+11
        ROL     P_Temp+12
        DEC     P_Temp
        JMP     L_Loop_LeftMove4Bit
L_End_R0Data_LeftMove4Bit:
	RTS
;------------------------------------------------
L_Counter_T_Sbc_Prog:
        LDA     #0
        STA     P_Temp+9
L_Loop_Counter_T_Sbc:
		SEC
        LDA     P_Temp+10
        SBC     P_Temp+13
        LDA     P_Temp+11
        SBC     P_Temp+14
        LDA     P_Temp+12
        SBC     P_Temp+15
        BCC     L_End_Counter_T_Sbc_Prog
        SEC
        LDA     P_Temp+10
        SBC     P_Temp+13
        STA     P_Temp+10
        LDA     P_Temp+11
        SBC     P_Temp+14
        STA     P_Temp+11
        LDA     P_Temp+12
        SBC     P_Temp+15
        STA     P_Temp+12
        INC     P_Temp+9
        JMP     L_Loop_Counter_T_Sbc
L_End_Counter_T_Sbc_Prog:
	RTS
;-----------------------------------------------
;-----------------------------------------------
;===============================================
;R_Temperature_F_L
;R_Temperature_F_H
;-----------------------------------------------
L_C_SwitchTo_F_Program:
		LDA     #0	;R_Temperature_L 	;#0		;��С����	LDA     
        STA     P_Temp+2
        LDA     R_Temperature
        STA     P_Temp+3
        LDA     #0
        STA     P_Temp+4
		CLC
		ROL		P_Temp+2
		CLC
		ROL		P_Temp+2
		CLC
		ROL		P_Temp+2
		CLC
		ROL		P_Temp+2
        SED
        CLC
        LDA     P_Temp+2
        ADC     P_Temp+2
        STA     P_Temp+2
        LDA     P_Temp+3
        ADC     P_Temp+3
        STA     P_Temp+3
        LDA     P_Temp+4
        ADC     P_Temp+4
        STA     P_Temp+4
        CLD
        LDA     #0
        STA     P_Temp+5
        STA     P_Temp+6
        STA     P_Temp+7
        LDA     #9
        STA     P_Temp+1
L_C_SwitchTo_F_Multiply9:
        LDA     P_Temp+1
        BEQ     L_Judge_TF_LL_Over_5
        SED
        CLC
        LDA     P_Temp+2
        ADC     P_Temp+5
        STA     P_Temp+5
        LDA     P_Temp+3
        ADC     P_Temp+6
        STA     P_Temp+6
        LDA     P_Temp+4
        ADC     P_Temp+7
        STA     P_Temp+7
        CLD
        DEC     P_Temp+1
        JMP     L_C_SwitchTo_F_Multiply9
L_Judge_TF_LL_Over_5:
        LDA     P_Temp+5
        SBC     #$50
        BCC     L_C_SwitchTo_F_Adc32
        SED
        CLC
        LDA     #$01
        ADC     P_Temp+6
        STA     P_Temp+6
        LDA     #00
        ADC     P_Temp+7
        STA     P_Temp+7
		CLD
L_C_SwitchTo_F_Adc32:
		LDA		R_Temperature_L
		AND		#$80

		BNE		L_C_SwitchTo_F_32Sub
        SED
        CLC
        LDA     #$20
        ADC     P_Temp+6
        STA     P_Temp+6
        LDA     #03
        ADC     P_Temp+7
        STA     P_Temp+7
		CLD
L_Exit_C_SwitchTo_F_Prog:
        LDA      P_Temp+6
        STA      R_Temperature_F_L
        LDA      P_Temp+7
        STA      R_Temperature_F_H ;BIT8Ϊ1������ʾ-F
		RTS

L_C_SwitchTo_F_32Sub:
	SED
	SEC
	LDA		#$20
	SBC		P_Temp+6
	LDA		#$03
	SBC		P_Temp+7
	BCS		L_yuanlai	;FֵΪ��
	SEC
	LDA		P_Temp+6
	SBC		#$20
	STA		P_Temp+6
	LDA		P_Temp+7
	SBC		#$03
	ORA		#$80
	STA		P_Temp+7	;BIT7Ϊ��ʾ-F
	CLD
	JMP		L_Exit_C_SwitchTo_F_Prog
L_yuanlai:
	LDA		#$20
	SBC		P_Temp+6
	STA		P_Temp+6
	LDA		#$03
	SBC		P_Temp+7
	STA		P_Temp+7
	CLD
	JMP		L_Exit_C_SwitchTo_F_Prog
;-------------------------------------------------------
;*******************************************************
;-------------------------------------------------------
.INCLUDE	RR_39K.ASM
;-------------------------------------------------------