---
title: "Deep dive into generalization and rescaling invariances of Neural Networks"
date: 2025-10-14
permalink: /projects/2025/project_inria2/
author_profile: false
tags:
---

# Challenges and Questions in Generalization

A fundamental question in deep learning is whether neural networks truly learn meaningful patterns or merely memorize training
data. Indeed, we train a neural network on a finite dataset, but we expect it to extract general patterns that can be applied
to unseen data points. If the model performs well on the training data but fails on new inputs, we say it _overfits_.
Conversely, if it performs poorly on both training and test data, it _underfits_.

Strikingly, it has been shown that neural networks can perfectly fit random labels, highlighting their enormous capacity and
raising serious concerns about overfitting. To evaluate generalization in practice, models are typically tested on a
test dataset (i.e., data unseen during training). Strong performance on this dataset is often considered empirical evidence
of good generalization. However, this approach has limitations: test sets are finite and may not fully capture the underlying
data distribution. In statistical learning theory, data points are assumed to be drawn from an unknown distribution \\(\mathcal{D}\\).
Since \\(\mathcal{D}\\) is not fully known, we cannot directly compute the expected risk (or true error) over this distribution.

Fortunately, theoretical tools have been developed to upper-bound the true risk even without access to \\(\mathcal{D}\\). Measures
such as the VC-dimension and Rademacher complexity quantify the capacity of function classes and are foundational in statistical
learning theory. The VC-dimension, introduced by Vapnik and Chervonenkis, describes the size of the largest set that a model
can shatter. Rademacher complexity, on the other hand, captures how well a function class can fit random noise. While these tools
offer valuable insights, they often lead to loose generalization bounds that do not align with the empirical success of
heavily overparameterized models. These bounds are typically loose because they are uniform over the entire considered
function class, rather than being tailored to the specific model or learning algorithm under consideration. To address these
limitations, alternative frameworks, such as PAC-Bayes, have been proposed to provide tighter and more adaptive generalization guarantees.

# Mesure the generalization

A principal area of research is the object we use to measure the generalization. For instance, a classical choice for fully
connected neural networks (FCNNs) is the product of the norms of the weights across layers. However, these metrics may be
ill-suited for certain architectures. Specificaly, ReLU networks exhibit intersting symmetries: two differents parameters vector
\\( \theta \\) and \\( \theta' \\) may lead to the same neural network realization \\(f_\theta = f_{\theta'}\\). However, 
standard complexity measures based on the weights fail to account for these symmetries, which is undesirable. In fact, some 
of these measures can even grow arbitrarily large while the induced network function remains unchanged.

# Rescaling invariances of ReLU neural network
ReLU networks are a specific subclass of neural network using the ReLU activation function \\( x \mapsto \mathrm{max}(0, x) \\), this type
of activation benefits from positive homogeneity property: for a scaling factor \\(\lambda > 0, \; \mathrm{ReLU}(\lambda x) = \lambda 
\mathrm{ReLU}(x) \\). This property leads to invariances that is often refers to rescaling invariances. Let \\( \theta \\) be the parameters
of a ReLU networks, for each hidden neuron, one can rescale the incomming weights by a factor \\(\lambda \\) and the outgoing 
weights by a factor \\(\frac{1}{\lambda} \\). The following operation on the full network is refered as \\( \lambda \diamond \theta \\) with \\( \lambda \\) a vector
of the size of the number of hidden neurons. 

![Rescaling invariances of ReLU networks](/images/img_rescaling.jpg "Rescaling invariances of ReLU networks")

# Generalization bounds
In machine learning, the perofmance of the model are evaluated through a loss function \\( \ell \\) measuring the discrepancy between the true label
and the predicted label. While this loss function is often referred as a function of the parameters \\( \theta \\), it is more accurate to consider 
it as a function of the realization of the neural network \\( f_\theta \\). The goal of the generalization bounds is to upper-bound
the expected risk, which is the loss over all the unknown data distribution \\( \mathcal{D} \\). It's mathematically defined as: 
<p>
$$
L(f_\theta) = \mathbb{E}_{(x,y) \sim \mathcal{D}} [\ell(f_\theta(x), y)].
$$
</p>
This quantity being inaccessible, we rather consider the empirical risk, which is the loss over a finite training set $\mathcal{S}$. It's mathematically defined as:
<p>
$$
\hat{L}_\mathcal{S}(f_\theta) = \frac{1}{|S|} \sum_{(x,y) \in \mathcal{S}} \ell(f_\theta(x), y).
$$
</p>
The all game of generalization bounds is to find a quanity $$\mathrm{complexity}$$ such that:
<p>
$$
L(f_\theta) \leq \hat{L}_\mathcal{S}(f_\theta) + \frac{\mathrm{complexity}}{\sqrt{|\mathcal{S}|}}.
$$
</p>
However, classical generalization complexity are express in term of the weights, and can then be arbitrarily large by rescaling the weights,
while the function $$f_\theta$$ remains unchanged.


# Bibliography

1. Maennel, H., Alabdulmohsin, I., Tolstikhin, I., Baldock, R. J. N., Bousquet, O.,
   Gelly, S., and Keysers, D. (2020). [arXiv:2006.10455](What do neural networks learn when trained with random labels?)
2. Vapnik, V. N. and Chervonenkis, A. Y. (2015). On the Uniform Convergence of Relative Frequencies of Events to Their Probabilities, page 11–30. Springer International
   Publishing, Cham.
3. Bach, F. (2024). Learning theory from first principles.
4. Dziugaite et al., 2020
