// codegen_tail_macros.h — force-included for generated guest-code TUs.
// arm-recomp-core codegen emits GBARECOMP_TAIL_* transfers. They live at
// the end of src/armv4t/runtime_arm.h, but some generated TUs can miss
// them depending on include order. Defining them here is harmless
// (same expansion) and keeps bios/cart shards compiling.
#pragma once

#ifndef GBARECOMP_TAIL_CALL
#define GBARECOMP_TAIL_CALL(fn)  do { (fn)(); return; } while (0)
#endif
#ifndef GBARECOMP_TAIL_DISPATCH
#define GBARECOMP_TAIL_DISPATCH(pc)  do { runtime_dispatch(pc); return; } while (0)
#endif
#ifndef GBARECOMP_TAIL_DISPATCH_WITH_EXCHANGE
#define GBARECOMP_TAIL_DISPATCH_WITH_EXCHANGE(pc) \
    do { runtime_dispatch_with_exchange(pc); return; } while (0)
#endif
#ifndef GBARECOMP_TAIL_SWI
#define GBARECOMP_TAIL_SWI(imm)  do { runtime_swi(imm); return; } while (0)
#endif
