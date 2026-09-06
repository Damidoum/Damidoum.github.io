---
layout: archive
title: "CV"
permalink: /cv/
nav: cv
description: Education, research experience, and technical skills.
redirect_from:
  - /resume
---

## Education

### M.Sc. Mathematics, Vision and Learning (MVA)

_École normale supérieure Paris-Saclay · Gif-sur-Yvette, France · 2025-2026_

- Relevant coursework: optimal transport, convex optimization, computational statistics, geometric data analysis, graph machine learning, random matrix theory, inverse problems, generative models, stochastic calculus and robotics.

### Diplôme d'ingénieur (M.Sc. equivalent), Mathematics and Computer Science

_Mines Paris - PSL · Paris, France · 2022-2026_

- Relevant coursework: measure theory, probability, statistics, machine learning, generative models, functional analysis and signal processing.

### CPGE MPSI-MP* - intensive mathematics and physics program

_Lycée Hoche · Versailles, France · 2020-2022_

- TIPE: Radon transform for tomography.

## Research Experience

### Research Intern - Weak error analysis for discrete diffusion samplers

_École normale supérieure - Department of Mathematics and Applications (DMA) · Paris, France · 2026-present_

Supervisors: Julie Delon, Rémi Gribonval and Gabriel Peyré.

- Derived the leading weak-error term of the matrix Euler discretization for Bayesian time reversals of finite-state continuous-time Markov chains.
- Obtained a spectral representation showing how the bias depends on the corruption generator, noise schedule, data distribution, and test observable.
- Analyzed the interaction between terminal mismatch, reverse-rate perturbations, and Euler bias on a two-state graph.

### Research Intern - PAC-Bayesian generalization bounds

_Inria · Lyon, France / London, UK · 2025 (4 months)_

Supervisors: Antoine Gonon, Rémi Gribonval, and Benjamin Guedj.

- Studied neuron-wise rescaling symmetries of ReLU networks and their effect on PAC-Bayes complexity terms.
- Formulated PAC-Bayes bounds in an invariant lifted representation and analyzed their guarantees through data processing.
- Implemented KL-based optimization procedures and evaluated them on neural-network experiments using PyTorch Lightning and Weights & Biases.

### Research Intern - Programmable origami metamaterials

_Harvard SEAS - Bertoldi Group · Boston, USA · 2024 (5 months)_

- Modeled compatibility constraints for programmable origami patterns.
- Studied multistable transitions using Abaqus simulations and experimental validation on macro- and microscale prototypes.
- Implemented a Python pipeline generating DXF fabrication files from geometric design parameters.

## Preprint

{% for publication in site.publications reversed %}
{% if publication.citation %}
- {{ publication.citation }} [Read the paper]({{ publication.paperurl }}).
{% else %}
- {{ publication.authors }}. [{{ publication.title }}]({{ publication.paperurl }}). {{ publication.venue }}, {{ publication.date | date: '%Y' }}.
{% endif %}
{% endfor %}

## Additional Experience

### Computer Vision Intern

_Scortex - TRIGO Group · Paris, France · 2024-2025 (6 months)_

- Adapted diffusion- and distillation-based computer vision methods for high-speed industrial anomaly detection.
- Benchmarked and deployed selected models under real-time constraints using PyTorch and MLflow.

### Oral Examiner in Mathematics

_French Ministry of Education · Versailles, France · 2023-2024 (6 months)_

- Prepared and assessed oral mathematics examinations for students preparing engineering-school entrance examinations.

## Technical Skills

- **Programming:** Python (PyTorch, PyTorch Lightning, NumPy, scikit-learn), working knowledge of C/C++.
- **Tools:** Git, Linux, Docker, LaTeX, MLflow, Weights & Biases.
- **Languages:** French (native), English (TOEFL iBT: 110/120).
