; *********************************************
; Attractor - 256b Atari XE/XL mini-demo
; Kane / Suspect
; 13-14/08/2024, Kaszuby
; Copyright (C) 2024 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
; Assemble using MADS
; 
; Silly Venture 2024 Summer Edition (15-18/08/2024) Atari 256-bytes compo entry
; *********************************************

start 	= $4000		; do not change as the DL list is assumed to be in $40H
scr		= $7000
sparks  = $3200
;width	= 32
width	= 40
heigth	= 32

	icl "Includes/registers.asm"
	icl "Includes/zeropage.asm"

	org	start

	// create display list
	ldx	#heigth+>scr-1
dlcreate
	ldy #3
dlc1
	jsr	dl_elem_add
	dey
	bpl dlc1
	dex
	cpx #>scr
	bpl	dlcreate

;	dec	SDMCTL		; $21 = narrow playfield (32 chars), $22 = normal (40 chars)
	lda	#<dl
	sta	SDLSTL
	lda #$40
	sta	SDLSTH
	sta GPRIOR		; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	lda	#$10		; TBD: Colour, could be removed or replaced by lsr #2?
	sta COLOR4

;init (by default all t are expected to be 0 on clean boot)
;	lsr
;	sta	t3			; X start
;	sta	t4			; Y start
;	sta	t1			; timer

; main loop
mainloop:
 	lda	#100			; remove?
vsync:
 	cmp	VCOUNT
 	bne	vsync

	lda	t1				; timer L
	bne	timer2
	inc	t2				; timer H
timer2:
	and	#63
	bne timer3
	inc t5				; timer M
timer3:
	inc t1

	lda	t5
	and	#15
	sta	t6
	and	#7
	sta	t7

	.proc fadeScreen
	lda	t1
	and	#3
	bne	fadeSkip
	ldy	#heigth+>scr-1
fadeY:
	tya
	sty f1+2
	sty f2+2
 	bit RANDOM
 	bpl	r1
	iny
r1	sty f3+2

	ldx	#0
 	bit RANDOM
 	bpl	r2
	inx
r2	stx f3+1

	tay
	dey
	ldx #width-1
fadeX:
f1	lda	scr,x
	beq	f4
	sbc	#$11
f2	sta	scr,x
f3	sta	scr-$100,x
f4	dex
	bpl	fadeX
	cpy #>scr
	bne	fadeY
fadeSkip:
	.endp


	.proc moveSparks
m1	inc	t3
	lda	t3
	bne	m2
	ldx	#$E6	;inc
	stx	m1
m2	cmp	#width-1-1
	bne	m3
	ldx	#$C6	;dec
	stx	m1

	lda	COLOR4			; change colour palette
	clc
	adc #3*16
	sta COLOR4
m3
m4	inc	t4
	lda	t4
	bne	m5
	ldx	#$E6	;inc
	stx	m4
m5	cmp	#heigth-1
	bne	m6
	ldx	#$C6	;dec
	stx	m4
m6	
	; draw sparks around attractor at random positions
	lda	t5		; nr of sparks
	and	#7
	tax
	inx
sloop:
	lda	RANDOM
	and	t6
	adc	t3
	sta	s1+1
	lda	RANDOM
	and	t7
	adc	t4
	adc #>scr
	sta	s1+2
	
 	lda	#$ff
s1	sta scr+$1000+20

	dex
	bne	sloop

	.endp


 	jmp mainloop

; add Display List element - one mode 15 line and one blank line
dl_elem_add:
	lda	#$4f
	jsr	s1
	txa
		
s1:	sta dl1			; for this to work, "dl" must start on an even address
	inc s1+1
	bne s2
	inc s1+2
s2:
	inc s1+1
	rts

	; filler
	.byte	"SUSPECT!!!"

 	.align 2,0			; TBD - remove
	;.byte	$70, $4F, a(scr), 0, $4F, a(scr), 0, $41, a(dl)
dl:	.byte 	$70			; MUST be at even address
dl1:

endmain1:

;	org	dl1+[2*4*heigth]
	org	dl1+[4*4*heigth]
	
dl2	.byte	$41, a(dl)

endmain2:

	.print	"----------------------------"
	.print	"Start: ", start, " DL: ", endmain1, " End: ", endmain2, " (Len: ", endmain1-start+endmain2-dl2, ")"
	.print	"File:  ", endmain1-start+endmain2-dl2+10  ; this includes org markers etc.
	.print	"----------------------------"
	