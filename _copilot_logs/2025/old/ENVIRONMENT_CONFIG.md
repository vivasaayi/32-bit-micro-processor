# Environment Configuration for AruviXIDE

AruviXIDE now supports flexible environment configuration that automatically adapts to different development setups.

## How It Works

1. **Environment File**: The IDE looks for a `.env` file in the project directory
2. **Intelligent Defaults**: If no `.env` file is found, the IDE automatically detects paths based on your project structure
3. **Fallback System**: Multiple fallback mechanisms ensure the IDE works even in unexpected environments

## Setting Up Your Environment

### Option 1: Use the .env file (Recommended)

1. Copy the `.env` file to your project root
2. Edit the paths to match your system:
   ```bash
   # Example .env file
   HDL_BASE_DIR=/your/path/to/hdl
   TEMP_DIR=/your/path/to/hdl/temp
   PROCESSOR_BASE_DIR=/your/path/to/hdl/processor
   # ... other paths
   ```

### Option 2: Let the IDE Auto-Detect (Zero Configuration)

Simply run the IDE! It will:
- Look for common project structure patterns
- Find your HDL directories automatically
- Create sensible defaults based on your working directory
- Display detected paths in the console for verification

## Path Detection Logic

The IDE searches for these patterns to determine your project structure:

1. **Project Root Detection**:
   - Looks for `pom.xml` (Maven project)
   - Looks for `AruviXPlatform` directory
   - Looks for directories containing both `processor` and `AruviXIDE`

2. **HDL Directory Detection**:
   - Searches for `hdl/`, `processor/`, `work/hdl/`, `src/hdl/`, or `hardware/` directories
   - Uses the first match found
   - Creates default structure if none found

3. **Fallback Behavior**:
   - If detection fails, uses current working directory
   - Creates necessary subdirectories as needed
   - Provides sensible relative paths for Verilog modules

## Environment Variables

| Variable | Description | Auto-Detection Logic |
|----------|-------------|---------------------|
| `HDL_BASE_DIR` | Base directory for HDL files | Searches for hdl/processor directories |
| `TEMP_DIR` | Temporary files directory | `{HDL_BASE_DIR}/temp` |
| `PROCESSOR_BASE_DIR` | Processor modules directory | `{HDL_BASE_DIR}/processor` |
| `*_V` variables | Individual Verilog module paths | Relative to processor directory |

## Benefits for Team Development

- **No Manual Setup**: New team members can clone and run immediately
- **Flexible Paths**: Each developer can customize paths without affecting others
- **Version Control Friendly**: `.env` can be gitignored while providing a template
- **Cross-Platform**: Works on Windows, macOS, and Linux with appropriate path detection

## Debugging

To see what paths the IDE is using, check the console output when starting the application. You'll see messages like:

```
Loaded environment file: /path/to/.env
Using auto-detected paths:
  HDL_BASE_DIR: /detected/path/to/hdl
  TEMP_DIR: /detected/path/to/hdl/temp
  ...
```

## Migration from Hardcoded Paths

If you're migrating from an older version with hardcoded paths:

1. The IDE will work immediately with auto-detection
2. Create a `.env` file for fine-tuned control
3. Remove any hardcoded paths from your local configuration
4. Share the `.env.template` with your team
