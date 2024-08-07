BOOTSEG     = 0x07c0    ; 左移4位后就是0x7c00, 占512B, 所以偏移512B(0x0200)后得0x7e00
SETUPSEG    = 0x07e0        
SETUPLEN    = 2         ; linus 写的是4, 教程是2

entry _start
_start:
    ; 首先读入光标位置
    mov    ah, #0x03        
    xor    bh, bh
    int    0x10

    ; 显示字符串 "XOS is Loading..."
    ; BIOS中断0x10 功能号ah = 0x13, 显示字符串
    ; input : al = 放置光标的方式及规定属性。0x01表示使用bl中的属性值,光标停在字符串结尾处。
    ; bh = 显示页面号, bl = 字符属性。
    ; cx = 显示的字符串字符数, 这里是 17+6=23, 即 msg1 所占的字符。
    ; es:bp 指向需显示的字符串起始位置处
    mov    cx, #23
    mov    bx, #0x000c
    mov    bp, #msg1
    mov    ax, #BOOTSEG  
    mov    es, ax
    mov    ax, #0x1301
    int    0x10

; 加载 setup
load_setup:
     mov dx, #0x0000
     mov cx, #0x0002  ; 扇区不是从 0 开始的,而是从 1 开始的, 1是 bootsect 所在的扇区, setup 从扇区 2 开始
     mov bx, #0x200   ; es:bx 指向将要存放的内存地址
     mov ax, #0x0200+SETUPLEN   ; 读 2 个扇区到内存
     int 0x13
     jnc ok_load_setup  ; 成功就跳转到 ok_load_setup 执行
     mov dx,#0x0000
     mov ax,#0x0000     ; 复位软盘
     int 0x13
     jmp load_setup

; 跳转到setup执行
ok_load_setup:
     jmpi 0, SETUPSEG   ; 段间跳转指令  cs = SETUPSEG, ip = 0

; msg1 处放置字符串
msg1:
    .byte 13,10                     ; 换行 + 回车
    .ascii "XOS is Loading..."
    .byte 13,10,13,10               ; 两对换行 + 回车


.org 510

; boot_flag的2个魔数在最后2个字节
boot_flag:
    .word 0xAA55
