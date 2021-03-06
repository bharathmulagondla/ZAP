//
// Startup file for factorial.
//

.global _Reset

// Set up an interrupt vector table.
_Reset   : b there
_Undef   : b UNDEF
_Swi     : b SWI
_Pabt    : b __pabt
_Dabt    : b __dabt
reserved : b _Reset
irq      : b IRQ
fiq      : b FIQ  

UNDEF:

// Undefined vector.
// LR Points to next instruction.
stmfa sp!, {r0-r12, r14}

// Corrupt registers.
mov r0, #1
mov r1, #2
mov r2, #3
mov r3, #4
mov r4, #5
mov r5, #6
mov r6, #7
mov r7, #8
mov r8, #9
mov r9, #10
mov r10, #12
mov r11, #13
mov r12, #14
mov r14, #15

// Restore them.
ldmfa sp!, {r0-r12, pc}^

// IRQ.
IRQ:
sub r14, r14, #4
stmfd sp!, {r0-r12, r14}

mov r0, #1
mov r1, #2
mov r2, #3
mov r3, #4
mov r4, #5
mov r5, #6
mov r6, #7
mov r7, #8
mov r8, #9
mov r9, #10
mov r10, #12
mov r11, #13
mov r12, #14
mov r14, #15

# Restart timer
ldr r0 ,=#0xFFFFFFC0    // Timer base address.
add r0, r0, #12
ldr r1, =#0x1
str r1, [r0]            // Restart the timer.

# Clear interrupt in VIC.
ldr r0, =#0xFFFFFFA0    // VIC base address
add r0, r0, #8  
ldr r1, =#0xFFFFFFFF    
str r1, [r0]            // Clear all interrupt pending status

ldmfd sp!, {r0-r12, pc}^

FIQ:
# Return from FIQ after writing to FIQ registers.
mov r8,  #9
mov r9,  #10
mov r10, #12
mov r11, #13
mov r12, #14
mov r8, #0
mov r9, #0
mov r10, #0
mov r11, #10
mov r12, #0
subs pc, r14, #4

SWI:
ldr sp,=#2500
ldr r11, =#2004
mov r0, #12
mov r1, #0
mov r2, r0, lsr #32
mov r3, r0, lsr r1
mov r4, #-1
mov r5, #-1
muls r6, r5, r4
umull r8,  r7, r5, r4
smull r10, r9, r5, r4
mov r2, r10
str r10, [r11, #4]!
str r9,  [r11, #4]!
add r11, r11, #4
str r8,  [r11], #4
str r7,  [r11], #4
str r6,  [r11]
stmib r11, {r6-r10}
stmfd sp!, {r0-r12, r14}
mrs r1, spsr
orr r1, r1, #0x80
msr spsr_c, r1
mov r4, #0
mcr p15, 0, r4, c7, c15, 0
mov r4, #-1
ldmfd sp!, {r0-r12, pc}^

there:
// Switch to IRQ mode.
mrs r2, cpsr
bic r2, r2, #31
orr r2, r2, #18 
msr cpsr_c, r2
ldr sp, =#3000

// Switch to UND mode.
mrs r3, cpsr
bic r3, r3, #31
orr r3, r3, #27
msr cpsr_c, r3
mov r4, #1
ldr sp, =#3500

// Enable interrupts (FIQ and IRQ).
mrs r1, cpsr
bic r1, r1, #0xC0
msr cpsr_c, r1

// Enable cache (Uses a single bit to enable both caches).
ldr r1, =#4100
mcr p15, 0, r1, c1, c1, 0

// Write out identitiy section mapping. Write 16KB to register 2.
mov r1, #1
mov r1, r1, lsl #14
mcr p15, 0, r1, c2, c0, 1

// Set domain access control to all 1s.
mvn r1, #0
mcr p15, 0, r1, c3, c0, 0

// Set up a section desctiptor for identity mapping that is Cachaeable.
mov r1, #1
mov r1, r1, lsl #14     // 16KB
mov r2, #14             // Cacheable identity descriptor.
str r2, [r1]            // Write identity section desctiptor to 16KB location.
ldr r6, [r1]            // R6 holds the descriptor.
mov r7, r1              // R7 holds the address.

// Set up a section descriptor for upper 1MB of virtual address space.
// This is identity mapping. Uncacheable.
mov r1, #1
mov r1, r1, lsl #14     // 16KB. This is descriptor 0.
// Go to descriptor 4095. This is the address BASE + (#DESC * 4).
ldr r2,=#16380
add r1, r1, r2
// Prepare a descriptor. Descriptor = 0xFFF00002 (Uncacheable section descriptor).
ldr r2 ,=#0xFFF00002
str r2, [r1]
ldr r6, [r1]
mov r7, r1

// ENABLE MMU
ldr r1, =#4101
mcr p15, 0, r1, c1, c1, 0

// Switch mode.
mrs r2, cpsr
bic r2, r2, #31
orr r2, r2, #16
msr cpsr_c, r2
ldr sp,=#3500

// Run main loop.

// Program VIC to allow timer interrupts.
ldr r0, =#0xFFFFFFA0    // VIC base address.
add r0, r0, #4          // Move to INT_MASK
ldr r1, =#0x0           // Prepare mask value
str r1, [r0]            // Unmask all interrupt sources.

// Program timer peripheral to tick every 255 clock cycles.
ldr r0 ,=#0xFFFFFFC0    // Timer base address.
ldr r1 ,=#1
str r1, [r0]            // Enable timer
add r0, r0, #4
ldr r1, =#255     
str r1, [r0]            // Program to 255 clocks.
add r0, r0, #8
ldr r1, =#0x1
str r1, [r0]            // Start the timer.


bl main
swi #0x00
here: b here

