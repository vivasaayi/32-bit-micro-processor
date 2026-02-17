# Rust + Tauri IDE Feasibility Study (for Java→RISC/JVM Workflow)

## Executive Summary

Porting the current Java-oriented workflow to a **Rust + Tauri + React** desktop IDE is highly feasible and a good strategic move.

- **Feasibility:** High (core capabilities already exist as scriptable pipelines).
- **Expected gains:** Better UX, cross-platform packaging, stronger process control, richer editor/debugging features, and a cleaner plugin architecture.
- **Main migration challenge:** Standardizing current shell/Python/script flows into stable Rust backend services with explicit APIs and robust job orchestration.

---

## Current Capabilities (Observed in this repository)

The existing setup already behaves like a lightweight toolchain IDE, but distributed across scripts and utilities:

### 1) Java build and transformation flow
- Detects and iterates Java programs from `test_programs/java`.
- Compiles Java (`javac`).
- Extracts/transforms bytecode through `tools/java_to_risc.py`.
- Builds interpreter path via custom compiler + assembler to produce executable `.hex` artifacts.

### 2) End-to-end execution pipeline management
- Batch processing, per-program status reporting, and final success/failure summary are present.
- Produces output artifacts in dedicated result/output folders.
- Provides primitive but useful “ready for execution” milestones.

### 3) Simulation/test orchestration
- Auto-generates testbench scaffolding for simulation runs.
- Can run with iverilog when available; degrades gracefully when not available.
- Includes workflow scripts that validate JVM/C test paths.

### 4) Console and runtime monitoring UX
- Extended console monitor supports:
  - timestamped logs,
  - line numbering,
  - semantic highlighting for boot/errors/frames/success,
  - interactive menu mode,
  - single-run and continuous-run options.

### 5) Graphics and visualization support
- Python/Tk-based graphics viewer demonstrates frame-buffer style visualization and statistics.
- Existing display system/demo scripts provide a foundation for richer visualization panes in a desktop IDE.

### 6) Toolchain composition already modular enough to wrap
- Distinct responsibilities exist (compile, convert, assemble, run, inspect).
- This is ideal for wrapping each step as a Rust command/service with structured outputs.

---

## Feasibility Assessment: Port to Rust + Tauri + React

## Is it feasible?
**Yes—strongly feasible.**

The current flow is already decomposed into command-line steps. Tauri is especially well-suited because:
- Rust backend can safely orchestrate local binaries/scripts and file workflows.
- React frontend can provide an IDE-style experience (projects, tabs, logs, run configs, visual tools).
- Tauri supports secure IPC (`invoke`) and desktop packaging on macOS/Linux/Windows.

## Recommended Target Architecture

### Frontend (React)
- Project explorer (Java/C/ASM/testbench/artifacts).
- Editor tabs (Monaco recommended).
- Build/Run panel with selectable pipeline profiles:
  - Java → Bytecode → JVM-on-RISC
  - C → ASM → HEX → Simulation
  - ASM → HEX → Simulation
- Live console panel with filters (INFO/WARN/ERROR, stage tags).
- Artifact viewers:
  - bytecode disassembly,
  - generated ASM,
  - HEX preview,
  - optional waveform/framebuffer view.

### Backend (Rust in Tauri)
- `PipelineService`: orchestration of multi-step build/run jobs.
- `ToolchainService`: compiler/assembler/java tools wrappers.
- `SimulationService`: testbench generation + simulator invocation.
- `WorkspaceService`: project scanning, path management, file watching.
- `DiagnosticsService`: normalized logs, stage timing, structured errors.
- `ConfigService`: tool paths, profiles, environment presets.

### IPC contract
Use strongly typed command payloads and responses:
- `run_pipeline(profile, entry_file, options) -> job_id`
- `stream_job_events(job_id) -> {stage, level, message, timestamp}`
- `get_artifacts(job_id) -> [paths]`
- `open_artifact(path)`

---

## Feature Mapping: Existing vs Rust/Tauri

| Existing capability | Rust/Tauri implementation | Complexity |
|---|---|---|
| Scripted Java compile/convert/build | Rust job graph calling `javac`, bytecode converter, compiler, assembler | Medium |
| Batch execution summary | Unified job runner + persistent run history | Low |
| Testbench generation and simulation run | Template-based generators + simulator adapter trait | Medium |
| Colorized console scripts | Structured event stream + React console renderer | Low |
| Interactive CLI menus | UI command palette + run configurations | Low |
| Python graphics monitor | React canvas/WebGL panel fed by parsed artifacts/logs | Medium/High |

---

## Major Risks & Mitigations

1. **External tool dependency variance (javac/javap/iverilog).**
   - Mitigation: startup diagnostics page + per-tool health checks + actionable install guides.

2. **Pipeline brittleness from script assumptions.**
   - Mitigation: define explicit intermediate artifact contracts and stable working directories.

3. **Long-running process management and cancellation.**
   - Mitigation: Rust async job supervisor, process group kill, bounded log buffers.

4. **Cross-platform path/process edge cases.**
   - Mitigation: use Rust `PathBuf`, avoid shell-escaped chains, direct command invocation.

5. **Scope creep into full VSCode clone.**
   - Mitigation: ship a focused domain IDE first (toolchain + simulation + artifact inspection).

---

## Suggested Phased Roadmap

### Phase 0 — Discovery and contract freeze (1–2 weeks)
- Catalog current scripts and artifacts.
- Freeze pipeline profiles and required I/O contracts.
- Define canonical workspace layout and temp/artifact conventions.

### Phase 1 — Backend orchestration MVP (2–3 weeks)
- Implement Rust wrappers for existing commands.
- Add structured logs/events and job lifecycle states.
- Support at least one complete path: Java → HEX artifact.

### Phase 2 — React IDE shell (2–4 weeks)
- File explorer + editor + build/run buttons.
- Real-time console and artifact list.
- Persisted settings for tool paths and run profiles.

### Phase 3 — Simulation UX and debugging (3–5 weeks)
- Simulator integration panel.
- Stage timing, error diagnostics, and rerun controls.
- Basic visualization panes (wave/log/frame summaries).

### Phase 4 — Advanced features (ongoing)
- Multi-program workspace support.
- Reproducible run presets and CI export.
- Optional plugin hooks for new backends/languages.

---

## Additional Features You Can Add Easily in Rust/Tauri

- Multi-pipeline presets per project.
- Deterministic run manifests (exact command/version/artifacts).
- Rich searchable build logs with stage tags.
- One-click “open generated ASM/HEX/disassembly”.
- Parallel batch run dashboard with pass/fail clustering.
- Better failure triage (missing tool vs compile error vs simulation timeout).

---

## Recommendation

Proceed with the migration.

You already have the critical foundation: a functioning end-to-end domain workflow. The move to Rust + Tauri + React primarily requires **productization of orchestration and UX**, not reinvention of the core compiler/simulator logic.

If you want, next step can be a concrete **implementation blueprint** with:
- Tauri command API draft,
- crate/module layout,
- React component tree,
- and a first MVP backlog (sprint-by-sprint).
