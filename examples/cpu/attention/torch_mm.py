import torch
from torch._inductor.select_algorithm import extern_kernels

# Create test tensors
a = torch.randn(32, 512)
b = torch.randn(512, 32)
c = torch.empty(32, 32)

# Print a small sample of input tensors
print("First 2x2 of input a:")
print(a[:2, :2])
print("\nFirst 2x2 of input b:")
print(b[:2, :2])

# Perform the matrix multiplication
print("\nExecuting extern_kernels.mm...")
extern_kernels.mm(a, b, out=c)
print("Matrix multiplication completed")

# Print output result
print("\nFirst 2x2 of output c:")
print(c[:2, :2])

# Compare with PyTorch's native mm for verification
expected = torch.mm(a, b)
print("\nFirst 2x2 of expected output using torch.mm:")
print(expected[:2, :2])

# Check if the results match
print("\nDo results match?", torch.allclose(c, expected))
