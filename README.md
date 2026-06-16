# RIS-Bench: A Unified Benchmarking Framework for Real-Time RIS Phase Optimization in 6G

This repository contains the official implementation of the paper:

> **RIS-Bench: A Unified Benchmarking Framework for Real-Time RIS Phase Optimization in 6G**  
> *Yinyan Li and Jianpei Chen*  
> IEEE Wireless Communications Letters (Under Review)

RIS-Bench is a standardized benchmarking framework designed to evaluate RIS phase optimization algorithms under **four practical 6G operational constraints**: execution latency, spatial scalability, hardware robustness, and CSI tolerance. The framework provides reproducible initialization, unified algorithm interfaces, and multi-dimensional performance evaluation.

---

## 📁 Repository Structure

```
RIS-Bench/
├── main_benchmark.m          # 主入口脚本，运行完整基准测试
├── config/
│   └── default_config.m      # 默认仿真参数配置
├── algorithms/
│   ├── AO_MMSE.m             # 交替优化最小均方误差（分析型）
│   ├── MO_PGD.m              # 流形优化近端梯度下降（流形型）
│   ├── PSO.m                 # 粒子群优化（启发式）
│   └── GA.m                  # 遗传算法（启发式）
├── channel/
│   ├── generate_channels.m   # 生成瑞利/莱斯信道
│   └── imperfect_CSI.m       # 非理想CSI建模（式4）
├── precoding/
│   └── RZF_precoding.m       # 正则化迫零预编码（式3）
├── utils/
│   ├── max_entropy_seed.m    # 最大熵初始化（主种子生成）
│   ├── performance_metrics.m # 计算和速率、运行时间等
│   └── quantization.m        # 1-bit相位量化
├── results/                  # 运行结果输出目录（自动生成）
├── plots/
│   ├── fig2_runtime_vs_N.m   # 复现 Fig.2: 运行时间 vs RIS单元数
│   ├── fig3_convergence.m    # 复现 Fig.3: 收敛曲线
│   ├── fig4_sumrate_vs_K.m   # 复现 Fig.4: 和速率 vs 用户数
│   ├── fig5_CSI_tolerance.m  # 复现 Fig.5: CSI误差容限
│   └── table_I_II.m          # 生成 Table I & II
└── README.md
```

---

## ⚙️ Requirements

- **MATLAB R2023b or later** (R2020a+ should also work but not officially tested)
- Required Toolboxes:
  - Communications Toolbox
  - Phased Array System Toolbox
  - Optimization Toolbox
  - Statistics and Machine Learning Toolbox
  - Parallel Computing Toolbox *(optional, for speeding up Monte Carlo trials)*

---

## 🚀 Quick Start

Clone the repository and run the main benchmark script:

```matlab
% In MATLAB command window
cd /path/to/RIS-Bench
main_benchmark
```

This will:
1. Load default configuration (`config/default_config.m`)
2. Generate channels with a fixed random seed (reproducible)
3. Run all three algorithms (AO-MMSE, MO-PGD, GA/PSO) under the four operational constraints
4. Save results to `results/` and generate summary tables

**Expected output** (partial, matching Table I in the paper):
```
AO-MMSE: Sum Rate = 230.99 bit/s/Hz, Runtime = 15.7 ms
MO-PGD : Sum Rate = 211.47 bit/s/Hz, Runtime = 0.843 s
GA     : Sum Rate = 215.91 bit/s/Hz, Runtime = 0.707 s
PSO    : Sum Rate = 210.19 bit/s/Hz, Runtime = 0.735 s
```

---

## 🎛️ Configuration Parameters

Modify `config/default_config.m` to customize the simulation:

| Parameter | Description | Default | Paper Reference |
|-----------|-------------|---------|-----------------|
| `M` | Number of BS antennas | 32 | Sec. IV-A |
| `N` | Number of RIS elements | 512 | Sec. IV-A |
| `K` | Number of users | 16 | Sec. IV-B |
| `fading_type` | 'Rayleigh' or 'Rician' | 'Rayleigh' | Eq. (2) |
| `K_Ric` | Rician K-factor (if Rician) | 3 | Eq. (2) |
| `num_iter_AO` | Iterations for AO-MMSE/MO-PGD | 30 | Sec. IV-A |
| `pop_size` | Population size for GA/PSO | 50 | Sec. IV-A |
| `num_generations` | Generations for GA/PSO | 50 | Sec. IV-A |
| `num_trials` | Monte Carlo trials | 100 | Sec. IV-A |
| `SNR_dB` | SNR in dB | 20 | (implicit) |
| `sigma_e2` | CSI error variance (for tolerance test) | 0:0.01:0.15 | Sec. IV-E, Eq. (4) |
| `quantization_bits` | Phase quantization bits (inf = continuous) | inf or 1 | Sec. IV-D |

---

## 📊 Reproducing Paper Figures

Run the following scripts individually to reproduce the paper's figures:

```matlab
% Fig. 2: Runtime vs. Number of RIS Elements (N = 32 to 512)
run plots/fig2_runtime_vs_N.m

% Fig. 3: Convergence Behavior (iteration/generation vs. sum rate)
run plots/fig3_convergence.m

% Fig. 4: Sum Rate vs. Number of Users (K = 4 to 32)
run plots/fig4_sumrate_vs_K.m

% Fig. 5: CSI Tolerance (error variance σ_e² = 0 to 0.15)
run plots/fig5_CSI_tolerance.m

% Table I & II: Summary of sum rate and runtime
run plots/table_I_II.m
```

All plots will be saved to `results/figures/` automatically.

---

## 🔬 Framework Overview

RIS-Bench evaluates algorithms across **four operational constraints** defined in the paper:

| Constraint | Evaluation Metric | Test Description |
|------------|-------------------|------------------|
| **Execution Latency** | Wall-clock runtime | Single-threaded CPU runtime (ms) |
| **Spatial Scalability** | Sum rate vs. K | Vary user count from K=4 to K=32 (DoF exhaustion) |
| **Hardware Robustness** | Sum rate under 1-bit | Compare continuous vs. 1-bit phase quantization |
| **CSI Tolerance** | Sum rate vs. σ_e² | Imperfect CSI with error variance up to 0.15 (Eq. 4) |

### Standardized Initialization (Maximum Entropy)

All algorithms share a **primary seed** that generates a uniform phase distribution over `[0, 2π)`. Population-based methods (GA/PSO) derive initial individuals by injecting small Gaussian perturbations, ensuring performance variations stem from algorithmic logic, not stochastic initialization.

---

## 🧪 Included Algorithms

| Algorithm | Type | Description | Paper Reference |
|-----------|------|-------------|-----------------|
| **AO-MMSE** | Analytical | Alternating Optimization with Minimum Mean Square Error | Sec. I, Table I |
| **MO-PGD** | Manifold | Manifold Optimization with Proximal Gradient Descent | Sec. I, Table I |
| **PSO** | Heuristic | Particle Swarm Optimization | Sec. I, Table I |
| **GA** | Heuristic | Genetic Algorithm | Sec. I, Table I |

---

## 📈 Key Results (from Paper)

| Algorithm | Sum Rate (bit/s/Hz) | Runtime | Typical 6G Scenario |
|-----------|---------------------|---------|---------------------|
| AO-MMSE | 230.99 | 15.7 ms | Real-time V2X, drone cruising, dense multi-user cells |
| GA/PSO | ~216 | >700 ms | Offline network planning, complex joint optimization |
| MO-PGD | 211.47 | >700 ms | High-capacity backhaul links, slow fading channels |

> Under 1-bit quantization, **all algorithms converge to an identical sum rate of 206.45 bit/s/Hz**, indicating that high algorithmic precision is unnecessary when hardware is the bottleneck.

---

## 📝 Citation

If you use this code in your research, please cite our paper:

```bibtex
@article{li2026risbench,
  title   = {RIS-Bench: A Unified Benchmarking Framework for Real-Time RIS Phase Optimization in 6G},
  author  = {Li, Yinyan and Chen, Jianpei},
  journal = {IEEE Wireless Communications Letters},
  year    = {2026},
  note    = {Under review}
}
```

---

## 📧 Contact

For questions, issues, or suggestions, please:
- Open an issue on GitHub
- Contact the corresponding author: yinyan1207@gmail.com

---

## 🙏 Acknowledgments

This work was supported by the Yunnan Fundamental Research Projects, China under Grant No. 202401AT070042.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
