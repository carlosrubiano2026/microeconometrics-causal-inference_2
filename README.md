# Microeconometrics: Discrete Choice and Causal Inference

This repository contains applied microeconometric exercises using individual-level data, with a focus on discrete outcome models and causal inference under selection on observables.

The repository combines two empirical applications:

1. **Discrete choice modeling of fertility outcomes**
2. **Propensity score matching using the LaLonde / Dehejia-Wahba training program data**

The objective is to show how econometric methods can be used to model individual decisions and evaluate treatment effects when the researcher must deal with non-random selection, observable heterogeneity, and model specification choices.

---

## Repository Structure

```text
microeconometrics-causal-inference/
├── README.md
├── MAIN_results.txt
├── data/
│   ├── soep_lebensz_en.dta
│   └── dw.dta
└── stata/
    ├── fertility_discrete_choice_models.do
    └── lalonde_psm_analysis.do
