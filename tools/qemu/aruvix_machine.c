/*
 * QEMU AruviX Machine Model
 *
 * This file defines the AruviX machine for QEMU.
 * It maps the memory and peripherals for the AruviX platform.
 *
 * Memory Map:
 * - 0x00000000 - 0x000FFFFF: Internal RAM (1MB)
 * - 0x00002000: Status/Control Register (MMIO)
 * - 0x00100000 - ...: External RAM
 * - 0xFF000000 - ...: Display I/O
 *
 * Entry Point: 0x8000
 */

#include "hw/boards.h"
#include "hw/riscv/boot.h"
#include "hw/riscv/riscv_hart.h"
#include "hw/sysbus.h"
#include "qapi/error.h"
#include "qemu/osdep.h"
#include "target/riscv/cpu.h"

#define ARUVIX_RAM_BASE 0x00000000
#define ARUVIX_RAM_SIZE (1 * 1024 * 1024)
#define ARUVIX_ENTRY 0x8000
#define ARUVIX_STATUS_REG 0x2000

typedef struct AruviXState {
  MachineState parent;
  RISCVHartArrayState soc;
  MemoryRegion ram;
  MemoryRegion status_reg;
} AruviXState;

#define TYPE_ARUVIX_MACHINE MACHINE_TYPE_NAME("aruvix")
#define ARUVIX_MACHINE(obj)                                                    \
  OBJECT_CHECK(AruviXState, (obj), TYPE_ARUVIX_MACHINE)

/* Minimal Status Register Implementation */
static uint64_t aruvix_status_read(void *opaque, hwaddr addr, unsigned size) {
  return 0; // Placeholder
}

static void aruvix_status_write(void *opaque, hwaddr addr, uint64_t val,
                                unsigned size) {
  printf("ARUVIX STATUS WRITE: 0x%" PRIx64 "\n", val);
}

static const MemoryRegionOps aruvix_status_ops = {
    .read = aruvix_status_read,
    .write = aruvix_status_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
};

static void aruvix_machine_init(MachineState *machine) {
  AruviXState *s = ARUVIX_MACHINE(machine);
  MemoryRegion *system_memory = get_system_memory();

  /* Initialize CPU (RISC-V 32-bit) */
  object_initialize_child(OBJECT(machine), "soc", &s->soc,
                          TYPE_RISCV_HART_ARRAY);
  object_property_set_str(OBJECT(&s->soc), "cpu-type", TYPE_RISCV_CPU_BASE32,
                          &error_abort);
  object_property_set_int(OBJECT(&s->soc), "num-harts", 1, &error_abort);
  sysbus_realize(SYS_BUS_DEVICE(&s->soc), &error_abort);

  /* RAM */
  memory_region_init_ram(&s->ram, NULL, "aruvix.ram", machine->ram_size,
                         &error_fatal);
  memory_region_add_subregion(system_memory, ARUVIX_RAM_BASE, &s->ram);

  /* Status Register */
  memory_region_init_io(&s->status_reg, NULL, &aruvix_status_ops, s,
                        "aruvix.status", 4);
  memory_region_add_subregion(system_memory, ARUVIX_STATUS_REG, &s->status_reg);

  /* Bootloader / Entry Point */
  riscv_setup_rom_reset_vec(machine, &s->soc, ARUVIX_RAM_BASE, 0, ARUVIX_ENTRY,
                            0, NULL);

  /* Load kernel/image if provided */
  if (machine->kernel_filename) {
    riscv_load_kernel(machine->kernel_filename, machine->kernel_cmdline,
                      ARUVIX_ENTRY, false, NULL);
  }
}

static void aruvix_machine_class_init(ObjectClass *oc, void *data) {
  MachineClass *mc = MACHINE_CLASS(oc);

  mc->desc = "AruviX RISC-V Machine";
  mc->init = aruvix_machine_init;
  mc->max_cpus = 1;
  mc->default_cpu_type = TYPE_RISCV_CPU_BASE32;
  mc->default_ram_size = ARUVIX_RAM_SIZE;
}

static const TypeInfo aruvix_machine_typeinfo = {
    .name = TYPE_ARUVIX_MACHINE,
    .parent = TYPE_MACHINE,
    .instance_size = sizeof(AruviXState),
    .class_init = aruvix_machine_class_init,
};

static void aruvix_machine_register_types(void) {
  type_register_static(&aruvix_machine_typeinfo);
}

type_init(aruvix_machine_register_types)
