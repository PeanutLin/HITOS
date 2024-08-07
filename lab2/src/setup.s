INITSEG = 0x9000

entry _start

_start:
  ; 首先读入光标位置
  mov    ah, #0x03        
  xor    bh, bh
  int    0x10

  ; 显示字符串 "Now we are in SETUP"
  mov    cx, #25
  mov    bx, #0x000c
  mov    bp, #msg1
  mov    ax, cs
  mov    es, ax
  mov    ax, #0x1301
  int    0x10

	; 将硬件参数取出来放在内存0x90000处
	mov ax, #INITSEG
	mov ds, ax      ; 数据段的基地址 0x9000

  ; 读光标位置
	xor bh, bh
	mov ah, #0x03
	int 0x10
	mov [0], dx     ; dh=行号,dl=列号

  ; 读扩展内存大小
	mov ah, #0x88
	int 0x15
	mov [2], ax

  ; 从0x41处拷贝16个字节(磁盘参数表)
  ; 读第1个磁盘参数表,共16个字节大小. 其首地址在int 0x41的中断向量位置
	; 中断向量表的起始地址是0x000, 共1KB大小, 并且每个表项占4B
	; 所以第1个磁盘参数表的首地址的地址:0x41*4=0x104, 此处4B由段地址和偏移地址组成
   mov ax, #0x0000
	mov ds,ax           ; 中断向量表的起始地址
	lds si, [4*0x41]    ; 先存入的是偏移地址,取出存到si中. 取出的4个字节,高位存入ds,低位存入si
	
	mov ax, #INITSEG
	mov es, ax
	mov di, #0x0004     ; 光标和内存已经占用4B

	mov cx, #16
	rep
  movsb

; 打印前的准备
	mov ax, cs
	mov es, ax      ; setup 所在的代码段	
	mov ax, #INITSEG
	mov ds, ax      ; 数据段, 指向参数所在的地方

; 显示光标位置
	mov ah, #0x03
	xor bh, bh
	int 0x10
	
	mov cx, #18             ; 长度 : 16 + 2
	mov bx, #0x0007
	mov bp, #msg_cursor     ; "Cursor position:" es:bp
	mov ax, #0x1301
	int 0x10

	; 存好的光标位置读出存到 dx 中, 那没必要再读光标了吧. 显示字符串需要放置光标，所以要读
    ; 打印光标位置
	mov dx, [0] 
	call print_hex

; 显示内存大小
	mov ah, #0x03
	xor bh, bh
	int 0x10
	
	mov cx, #14          ; 长度12+2
	mov bx, #0x0007
	mov bp, #msg_memory  ; "Memory Size:"
	mov ax, #0x1301
	int 0x10
	mov dx, [2]
	call print_hex	

; 补上KB
	mov ah, #0x03
	xor bh, bh
	int 0x10
	
	mov cx, #2
	mov bx, #0x0007
	mov bp, #msg_kb
	mov ax, #0x1301
	int 0x10

; 柱面, cylinder Cyles
	mov ah, #0x03
	xor bh, bh
	int 0x10
	
	mov cx, #8
	mov bx, #0x0007
	mov bp, #msg_cyles
	mov ax, #0x1301
	int 0x10
	mov dx, [4]         ; 4 + 0
	call print_hex
	
; 磁头 Heads
	mov ah,#0x03
	xor bh,bh
	int 0x10
	
	mov cx, #8
	mov bx, #0x0007
	mov bp, #msg_heads
	mov ax, #0x1301
	int 0x10
	mov dx, [6]        ; 4 + 2
	call print_hex
	
; 扇区 sectors
	mov ah,#0x03
	xor bh,bh
	int 0x10
	
	mov cx, #10
	mov bx, #0x0007
	mov bp, #msg_sectors
	mov ax, #0x1301
	int 0x10
	mov dx, [0x12]
	call print_hex
	
inf_loop:
	jmp inf_loop


; 以16进制方式打印栈顶的16位数
print_hex:
    mov    cx, #4 		; 4个十六进制数字
    ; mov    dx, (bp) 	; 将(bp)所指的值放入dx中, 如果bp是指向栈顶的话
   
print_digit:
    rol    dx, #4        ; 循环以使低4比特用上, 取dx的高4比特移到低4比特处。
    mov    ax, #0xe0f    ; ah = 请求的功能值,al = 半字节(4个比特)掩码。
    and    al, dl        ; 取dl的低4比特值。
    add    al, #0x30     ; 给al数字加上十六进制0x30
    cmp    al, #0x3a
    jl     outp          ; 是一个不大于十的数字
    add    al, #0x07     ; 是a~f,要多加7

outp: 
    int    0x10
    loop    print_digit
    ret

; 打印回车换行
print_nl:
    mov    ax,#0xe0d    ; CR
    int    0x10
    mov    al,#0xa     	; LF
    int    0x10
    ret

; msg1 处放置字符串
msg1:
    .byte 13,10                     ; 换行 + 回车
    .ascii "Now we are in SETUP"
    .byte 13,10,13,10               ; 两对换行 + 回车

msg_cursor:
	.byte 13,10
	.ascii "Cursor position:"

msg_memory:
    .byte 13,10
	.ascii "Memory Size:"
	  
msg_cyles:
    .byte 13,10
    .ascii "Cyles:"
          
msg_heads:
    .byte 13,10
    .ascii "Heads:"
          
msg_sectors:
    .byte 13,10
    .ascii "Sectors:"
           
msg_kb:
    .ascii "KB"

.org 510

boot_flag:
    .word 0xAA55
