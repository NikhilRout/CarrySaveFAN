# AMD Xilinx Vivado 2023.2 Synthesis

Board - AMD Xilinx Alveo U55C FPGA: xcu55c-fsvh2892-2L-e

## Combinational

Parameters: N = 8, W = 32, V = 3
Max Path Delay: 10ns

| Design | Worst Negative Slack (WNS) | Total Negative Slack (TNS) | LUTs |
| --- | --- | --- | --- |
| RedTree | -1.297 | -53.651 | 1274 |
| SigmaBaseFAN | 0.133 | 0 | 953 |
| CarrySaveFAN | -1.443 | -94.021 | 1565 |

![RedTee_Imp](synth/vivado/img/RedTree_Imp.png "RedTree Implementation Report")
![SigmaBaseFAN_Imp](synth/vivado/img/SigmBaseFAN_Imp.png "SigmBaseFAN Implementation Report")
![CarrySaveFAN_Imp](synth/vivado/img/CarrySaveFAN_Imp.png "CarrySaveFAN Implementation Report")
