# ISPC Builtin Macros Reference (util.m4)

## Table of Contents
- [Utility Macros](#utility-macros)
- [Conversion Macros](#conversion-macros)
- [Vector Conversion Macros](#vector-conversion-macros)
- [Unary/Binary Operations](#unarybinary-operations)

## Utility Macros

### Basic Utilities
- **`argn`** - Argument extraction from macro parameter lists
- **`CONCAT`** - String concatenation: `CONCAT(a,b)` → `ab`
- **`TYPE_SUFFIX`** - Generates type suffix with vector width
- **`SIZEOF`** - Size calculation utilities
- **`LLVM_OVERLOADED_TYPE`** - LLVM type resolution

### Mask Operations
- **`ALL_ON_MASK`** - Creates masks with all bits set
- **`MASK_HIGH_BIT_ON`** - High bit mask generation
- **`PTR_OP_ARGS`** - Pointer operation argument handling

### Type Mappings
- **`MdORi64`** - Maps to double or i64 based on context
- **`MfORi32`** - Maps to float or i32 based on context

## Conversion Macros

These handle **vector width conversions** with **data truncation**.

### Pattern: `convertXtoY`
- **X** = source vector width, **Y** = target vector width
- **Behavior** = Truncates by taking first Y elements

### Available Conversions:
- **Narrowing:** `convert8to1/4`, `convert16to1/4/8`, `convert32to4/8/16`
- **Widening:** `convert1to8/16`, `convert4to8/16/32`, `convert8to16/32`

**Use Cases:** Cross-architecture compatibility, type system compliance, performance optimization

## Vector Conversion Macros

These handle **vector decomposition/composition** with **no data loss**.

### Pattern: `vXtoY`
- **X** = source vector width, **Y** = target vector width per output
- **Result** = Multiple Y-wide vectors containing ALL X elements

### Available Operations:
- **Split:** `v8tov4`, `v16tov8`, `v16tov4`, `v32tov16`
- **Combine:** `v4tov8`, `v8tov16`, `v16tov32`

### Key Difference from `convertXtoY`:
| Aspect | `convertXtoY` | `vXtoY` |
|--------|---------------|---------|
| **Data Loss** | Yes (truncates) | No (preserves all) |
| **Outputs** | Single vector | Multiple vectors |

## Unary/Binary Operations

These macros implement **function vectorization** when native wide-vector instructions aren't available.

### Strategies:
1. **Scalarization** - Process each element individually
2. **Chunking** - Split into smaller supported vector widths

### Unary Operations
- **`unary1toX`** - Scalarized operation (extract each element, apply scalar function, insert back)
- **`unaryXtoY`** - Chunked operation (split into Y-wide chunks, apply Y-wide function, combine)
- **`unaryXtoYconv`** - Type-converting chunked operation

### Binary Operations
- **`binaryXtoY`** - Split both inputs into Y-wide chunks, apply Y-wide function, combine results

### Available Operation Families:
| Macro Pattern | Input Width | Target Width | Strategy |
|---------------|-------------|--------------|----------|
| `unary1toX` | X-wide | scalar | Scalarize each element |
| `unary2toX` | X-wide | 2-wide | Split into 2-wide chunks |
| `unary4toX` | X-wide | 4-wide | Split into 4-wide chunks |
| `unary8toX` | X-wide | 8-wide | Split into 8-wide chunks |
| `binary2toX` | X-wide | 2-wide | Split both inputs into 2-wide |
| `binary4toX` | X-wide | 4-wide | Split both inputs into 4-wide |
| `binary8toX` | X-wide | 8-wide | Split both inputs into 8-wide |

## Reduce Operations

These macros implement **parallel reduction** operations that combine all elements of a vector into a single scalar value using tree-based reduction.

### Available Reduce Macros

- **`reduce_func`** - Width-aware dispatcher that selects appropriate reduction based on `WIDTH`
- **`reduce4/8/16/32/64`** - Direct reductions for specific vector widths
- **`reduce8by4`** - 8-wide reduction using 4-wide operations (hybrid approach)
- **`reduce_equal`** - Checks if all active vector elements are equal across multiple data types

### Parameters:
- **`result_type`** - Scalar type of final result
- **`vector_op`** - Vector operation function name  
- **`scalar_op`** - Scalar operation function name

## Usage Guidelines

### When to Use Each Macro Type:

1. **`convertXtoY`** - Change vector width, accepts data loss
2. **`vXtoY`** - Decompose/compose vectors without data loss
3. **`unaryXtoY/binaryXtoY`** - Implement functions across vector widths
4. **`reduce_func`** - Combine vector elements into scalar result

### Performance Notes:
- **Scalarization** (`unary1toX`) - Slowest, most compatible
- **Chunking** (`unaryXtoY`) - Balanced performance/compatibility
- **Direct operations** - Fastest when hardware supports them
