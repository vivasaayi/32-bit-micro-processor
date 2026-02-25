# Hobby OS Test Cases

## Terminal smoke tests (automated via serial)

1. Boot OS and check banner appears.
2. Run `help` and confirm builtin help text.
3. Run `ls` and confirm `echo`, `sum`, `about` are listed.
4. Run `run echo smoke_test` and confirm argument echoing.
5. Run `run sum 7 35` and confirm output includes `42`.
6. Run `run noexist` and confirm graceful error (`utility not found`).

Run with:

```bash
make test-terminal
```

## Program packaging tests

1. Compile sample C utilities.
2. Assemble sample ASM utility object.
3. Execute compiled `sum_util` and assert expected result (`42`).
4. Bundle generated utilities into `out/program_bundle/` with a manifest.

Run with:

```bash
make test-programs
make bundle-programs
```

## VirtualBox packaging check

1. Ensure VirtualBox is installed (`VBoxManage` in PATH).
2. Build image and convert to VDI.

Run with:

```bash
make vdi
```

## End-to-end test

```bash
make test
```
