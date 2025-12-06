# CarrySaveFAN

Microarchitecture design space exploration of the [SIGMA DNN Accelerator's](https://ieeexplore.ieee.org/document/9065523/) Forward-Adder-Network (FAN) that enables supporting multi-vector, multi-operand addition within the same PE for sparse and irregular GEMM workloads.

## Modifying a Carry Save Adder to function as a FAN

![Carry Save FAN Diagram](docs\arch_diag\CarrySaveFAN.drawio.png "Carry Save FAN Diagram")

- For a N-operand W-bit addition, time complexity should reduce from Reduction Tree based uarch's[O(log2(N)) * O(log2(W))] to approximately [O(log2(N)) + O(log2(W))]
- Each vector groups sums (output) are already in the same order they arrived in
- Don't need Flip-Flops at every MUX
