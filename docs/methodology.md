# Methodology

## Treatment Effect Framework

We define potential outcomes:

Y(1): earnings if treated  
Y(0): earnings if not treated  

Observed outcome:

Y = D·Y(1) + (1-D)·Y(0)

Parameter of interest:

ATT = E[Y(1) - Y(0) | D = 1]

---

## Problem

E[Y(0) | D = 1] is unobserved.

Naive comparison:

E[Y | D=1] - E[Y | D=0]

is biased due to selection.

---

## Propensity Score

p(X) = P(D=1 | X)

(Rosenbaum & Rubin, 1983)

Matching on p(X) balances covariates.

---

## Matching Estimators

### Nearest Neighbor
Minimizes |p_i - p_j|

### Radius Matching
Uses all controls within ε distance

### Kernel Matching
Weighted average using kernel function

---

## Identification Assumptions

1. Conditional Independence  
2. Common Support  
3. SUTVA  

---

## Diagnostics

- Standardized bias
- Variance ratios
- Pseudo R²
