# Fly Personality — Reproducibility Code

**Paper:** Forkosh et al. (2026). *Life Events Reshape Individuality in Flies Without Losing Consistency.* PLOS Biology.

This repository contains the MATLAB code used to reproduce the figures and statistical analyses in the paper. Raw behavioral data are hosted separately (see [Data](#data) below).

---

## Repository Structure

```
fly-personality-clean/
├── MainFlyIndividuality.m   ← Main script — run this to reproduce all figures
├── startup.m                ← Run once per session to set up the path
│
├── utils/                   ← Analysis functions written for this paper
│   ├── conturMesh.m         — Kernel-density contour maps per condition
│   ├── figtosave.m          — Export figures as PDF / PNG / EPS / FIG
│   ├── findmonth.m          — Extract recording month from filename timestamps
│   ├── meanOnSeg.m          — Average a time-series over a temporal segment
│   ├── normalize.m          — Within-month z-score normalization
│   ├── permutationTestOneWayANOVA.m  — Permutation-based one-way ANOVA
│   ├── plotIDs.m            — Scatter-plot individual identities in ID space
│   ├── redblue.m            — Red–blue diverging colormap
│   ├── saveStatTbl4Fig.m    — Format p-value tables for export
│   ├── sigstar.m            — Significance star annotations for plots
│   └── Statspersonality.m   — Class: Hinton maps, behavior–ID correlations
│
├── external/                ← Third-party dependencies (see licenses below)
│   ├── Q.m                  — Utility class (accumrows, nwarp, …)
│   ├── DimReduction.m       — LDA wrapper
│   ├── Fig.m                — Figure styling helpers
│   ├── Colormaps.m          — Colormap utilities
│   ├── Colors.m / Console.m / Identity.m / Patches.m / Plot.m
│   ├── fdr_bh.m             — Benjamini–Hochberg FDR correction
│   ├── compare_correlation_coefficients.m
│   ├── violinplot/          — Violin plot (bastibe/Violinplot-Matlab, MIT)
│   │   ├── violinplot.m
│   │   └── Violin.m
│   └── ParTI/               — Pareto Task Inference (Hart et al. 2015)
│       ├── ParTI_lite.m
│       └── PCHA/PCHA1.m
│
├── SupportFiles/
│   ├── W.mat                — Pre-computed LDA projection matrix
│   └── allBehaviorsExplain.csv  — Behavior codes, short names, descriptions
│
├── Data/                    ← Large .mat files — download separately (see below)
│   ├── MainFemalesMales.mat
│   ├── SocialContext.mat
│   ├── Rejected30min.mat
│   ├── SocialDefeat.mat
│   └── Microbiome.mat
│
└── Figs/                    ← Output figures (created automatically)
    ├── MainFemalesMales/
    ├── SocialContext/
    ├── Rejected30min/
    ├── SocialDefeat/
    └── Microbiome/
```

---

## Requirements

- **MATLAB R2022b** or later
- **Statistics and Machine Learning Toolbox** (for `anova1`, `ksdensity`, `lasso`)
- **Image Processing Toolbox** (for `bwboundaries` in `conturMesh`)
- All other dependencies are included in `external/`

---

## Quickstart

```matlab
% 1. Open MATLAB and navigate to this folder
% 2. Add everything to the path:
run('startup.m')

% 3. Run the main script (figures only, no saving):
MainFlyIndividuality
```

To save all figures as PDF/PNG/EPS to `Figs/<experiment>/`, open `MainFlyIndividuality.m` and set:

```matlab
opt.want2save = true;
```

---

## Data

The behavioral data files are too large for GitHub (~1–5 GB each). Download them from:

> **https://doi.org/10.5281/zenodo.20339311**

Place all `.mat` files in the `Data/` folder before running the script.

| File | Experiment | N flies |
|------|-----------|---------|
| `MainFemalesMales.mat` | Main cohort: grouped / isolated / mated × female / male | ~420 |
| `SocialContext.mat` | Familiar vs. unfamiliar partner | ~120 |
| `Rejected30min.mat` | Within-session consistency (split-half) | ~120 |
| `SocialDefeat.mat` | Winner vs. loser after aggressive encounter | ~96 |
| `Microbiome.mat` | Axenic vs. conventionally reared | ~144 |

---

## Figure Map

| Figure | Script section | Key output |
|--------|---------------|-----------|
| Fig. 1 — Personality space | Section 1c | `PersonalitySpace_ID1_ID2.pdf` |
| Fig. 2 — Fisher-Rao separability | Section 1b | `Fisher-Rao.pdf` |
| Fig. 3 — Behavior correlations | Section 1g | `HintonIDs.pdf`, `TreePlot_ID*.pdf` |
| Fig. 4 — ID statistics | Section 1f | `Violins.pdf` |
| Fig. 5 — Social context | Section 2 | `SocialContext/DensityMap.pdf` |
| Fig. 6 — Consistency | Section 3 | `Rejected30min/Consistency30min.pdf` |
| Fig. 7 — Social defeat | Section 4 | `SocialDefeat/DensityMap.pdf` |
| Fig. 8 — Microbiome | Section 5 | `Microbiome/DensityMap.pdf` |

---

## Reproducibility Notes

- **LDA projection (W):** By default the script loads the pre-computed matrix `SupportFiles/W.mat` so all figures are exactly reproducible. To recompute from scratch, set `opt.computeAll = true` in `MainFlyIndividuality.m`. Minor numerical differences may appear due to random initialization in LDA.
- **Permutation tests:** Each run of `permutationTestOneWayANOVA` uses 1,000 random permutations. Results are stable across runs (p-values should agree to ±0.01).
- **Normalization:** Behavioral scores are z-scored within recording month to remove batch effects.

---

## Citation

If you use this code, please cite:

```
Forkosh O, et al. (2026). Life Events Reshape Individuality in Flies Without
Losing Consistency. PLOS Biology. https://doi.org/[DOI]
```

---

## License

Code written for this paper is released under the **MIT License** (see `LICENSE`).  
Third-party code in `external/` retains its original licenses:
- `violinplot/`: MIT License (Bechtold & Bastibe)
- `ParTI/`: see `external/ParTI/` for license
- `fdr_bh.m`: BSD License (Groppe et al.)
