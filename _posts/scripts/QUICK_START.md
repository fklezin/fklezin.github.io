# Quick Start Guide

## TL;DR

```bash
cd _posts/scripts
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python run_benchmark.py --sizes 1 2
```

## What Gets Installed

```bash
pip install -r requirements.txt
```

This installs:
- **Polars 1.17+** - Modern data processing library
- **Pandas 2.2+** - Traditional data processing library
- **NumPy 1.26+** - Numerical computing
- **Matplotlib 3.8+** - Chart generation
- **psutil 5.9+** - Memory monitoring
- **PyArrow 18+** - Columnar data format

## Available Commands

### 1. Check Setup
```bash
python check_versions.py
```
**Time:** < 1 second  
**What it does:** Verifies all dependencies are installed and shows versions

---

### 2. Quick Test
```bash
python test_installation.py
```
**Time:** ~30 seconds  
**What it does:** Runs mini benchmark to verify everything works

---

### 3. Small Benchmark (Recommended)
```bash
python run_benchmark.py --sizes 1 2
```
**Time:** ~5-10 minutes  
**RAM needed:** 8GB  
**What it does:** Benchmarks 1GB and 2GB datasets

---

### 4. Medium Benchmark
```bash
python run_benchmark.py --sizes 1 2 4 8
```
**Time:** ~30-45 minutes  
**RAM needed:** 32GB  
**What it does:** Benchmarks up to 8GB datasets

---

### 5. Full Benchmark
```bash
python run_benchmark.py
```
**Time:** ~1-2 hours  
**RAM needed:** 32GB (Pandas will OOM on 16GB test)  
**What it does:** Benchmarks all sizes: 1, 2, 4, 8, 16 GB

---

## Output Files

After running benchmarks:

```
_posts/scripts/
├── benchmark_results.csv       # Raw data (timing, memory)
├── benchmark_results.png       # Charts with comparisons
└── benchmark_data/
    ├── test_data_1gb.parquet   # Generated test data
    ├── test_data_2gb.parquet   # (reused across runs)
    └── ...
```

## Understanding Results

### CSV Columns
- `library`: "Polars" or "Pandas"
- `size_gb`: Dataset size tested
- `duration_sec`: Time to complete deduplication
- `memory_mb`: Peak memory usage
- `rows_out`: Number of unique rows after dedup

### Chart Content
- **Left plot:** Execution time (log scale) with speedup annotations
- **Right plot:** Memory usage with overhead annotations
- **Red X:** Indicates Pandas OOM

## Customization

### Custom Output Directory
```bash
python run_benchmark.py --sizes 1 2 --output-dir ./my_results
```

### Specific Sizes Only
```bash
python run_benchmark.py --sizes 1 4 16
```

### Help
```bash
python run_benchmark.py --help
```

## System Requirements

### Minimum (for testing)
- **RAM:** 8GB
- **Disk:** 5GB free
- **Time:** 10 minutes
- **Sizes:** `--sizes 1 2`

### Recommended (for serious benchmarking)
- **RAM:** 32GB
- **Disk:** 50GB free
- **Time:** 1-2 hours
- **Sizes:** All (default)

### For 16GB Test
- **Polars:** 32GB RAM minimum
- **Pandas:** 64GB RAM minimum (will OOM on less)

## Troubleshooting

### "ModuleNotFoundError"
```bash
pip install -r requirements.txt
```

### "Out of memory"
Run smaller sizes:
```bash
python run_benchmark.py --sizes 1 2
```

### "File already exists"
The script reuses existing test data. To regenerate:
```bash
rm -rf benchmark_data/
python run_benchmark.py
```

### Pandas OOM on 16GB test
This is expected on machines with <64GB RAM. The benchmark will report it as "OOM ❌" in results.

## Next Steps

1. ✅ Run quick test: `python test_installation.py`
2. ✅ Run small benchmark: `python run_benchmark.py --sizes 1 2`
3. ✅ Review `benchmark_results.csv` and `benchmark_results.png`
4. ✅ Share results or use in blog post
5. ✅ (Optional) Run full benchmark: `python run_benchmark.py`

## Questions?

See full documentation in `README.md`

