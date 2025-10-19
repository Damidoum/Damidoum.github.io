---
layout: archive
title: "CV"
permalink: /cv/
author_profile: true
redirect_from:
  - /resume
---

## Education

---

### Master MVA – "Mathématiques, Vision, Apprentissage"

_École Normale Supérieure Paris-Saclay | Paris, France_
2025–2026

- Main courses: Advanced Learning for Text and Graph Data, Geometric Data Analysis, Optimal Transport, Robotics, Computational Statistics, Convex Optimization.

### Master’s Degree in Science and Executive Engineering, Major in Mathematics and Computer Science

_Mines Paris – PSL | Paris, France_
2022–2026

- Main courses: Machine & Deep Learning, Generative Models, Probability Theory, Advanced Statistics, Applied Mathematics, Computer Science (Python, C++, Haskell).

### Preparatory Classes MPSI - MP\*

_Lycée Hoche | Versailles, France_
2020–2022

- 2 years of intensive preparation for French Grande Écoles exams (Ranked top 2% in national entrance exams).
- Research project: Radon Transform for tomography.

---

## Research & Professional Experience

### Machine Learning Research Intern – Deep Learning Generalization Theory

_Inria (Supervised by A. Gonon, R. Gribonval, and B. Guedj) | Lyon, France & London, UK_
2025 (4 months)

- Conducted research on the theoretical foundations of deep learning generalization.
- Leveraged symmetries of ReLU networks (weight-rescaling invariances) to improve standard PAC-Bayesian bounds.
- Implemented, and evaluated the derived method using PyTorch Lightning and wandb.
- Achieved a 2× improvement over standard bounds on MNIST/CIFAR-10, successfully transforming vacuous bounds into non-vacuous ones.
- First author of a paper under review at ICLR 2026 ([arxiv.org/abs/2509.26149](https://arxiv.org/abs/2509.26149)).

### AI Research & Software Engineering Intern – Industrial Vision

_Scortex – TRIGO Group | Paris, France_
2024–2025 (6 months)

- Adapted advanced computer vision models (e.g., diffusion/reconstruction methods) for high-speed industrial anomaly detection.
- Systematically fine-tuned and evaluated model performance across client use cases using PyTorch and MLflow.
- Industrialized promising models into the product codebase, prioritizing speed optimization to meet strict real-time processing requirements.

### Research Intern – Programmable Metamaterials & Optimization

_Harvard SEAS (Bertoldi Group) | Boston, USA_
2024 (5 months)

- Conducted research on programmable origami metamaterials, including mathematical modeling of origami pattern compatibility, origami fabrication and state-of-the-art analysis.
- Developed a Python-based automation tool for the design-to-fabrication origami pipeline (.dxf files generation), accelerating the research process.
- Explored multi-stability transitions of origami through Abaqus simulation and experimental validation using macro/micro scale prototypes; results contributed to an ongoing paper.

### Oral Examiner in Mathematics

_French Ministry of Education | Versailles, France_
2023–2024 (6 months)

- Mentored and assessed advanced STEM students preparing for the competitive oral exams of the top engineering schools.

### Corporate Relations & Partnerships Manager (Volunteering)

_Trium Forum Organization | Paris, France_
2023–2024 (1 year)

- Managed a team coordinating 100+ corporate partners for a forum with €1.3M turnover.

---

## Technical & Soft Skills

### Technical Skills

- **Programming**: _Python_ (Advanced), _C/C++_ (Basics), Functional programming (Learning Haskell / Lean).
- **Machine Learning**: PyTorch, PyTorch Lightning, Transformers, Sklearn, Numpy, Weights & Biases.
- **Tools**: Git, Bash, Linux, Docker, GCP, LaTeX.

### Soft Skills & Hobbies

- **Languages**: French (Native), English (Advanced).
- **Hobbies**: Trail, Running, Climbing, Mountaineering, Chess, Cooking, Photography.

---

## Publications

<ul>{% for post in site.publications reversed %}
  {% include archive-single-cv.html %}
{% endfor %}</ul>

---

<div class="cv-download-links">
  <a href="{{ base_path }}/files/cv.pdf" class="btn btn--primary">Download CV as PDF</a>
</div>
