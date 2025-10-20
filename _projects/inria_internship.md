---
title: "The Generalization Paradox: Why Symmetries Break Our Best Theoretical Guarantees in Deep Learning"
date: 2025-10-14
permalink: /projects/2025/project_inria/
author_profile: false
tags: [Deep Learning, Generalization Theory, PAC-Bayes, Invariance, Theoretical Machine Learning]
---
A story of how rescaling symmetries in ReLU networks undermine PAC-Bayes generalization bounds, and our theoretical solution to restore meaningful guarantees.

## Unpacking the Generalization Enigma

The remarkable success of deep neural networks (DNNs) presents a profound paradox: these models are often **heavily overparameterized**, meaning they possess millions of weights yet perform flawlessly on **unseen data**. Classical learning theory, which suggests that high capacity should lead to severe **overfitting** (memorizing the training set and failing to generalize), struggles to explain this phenomenon.

To build reliable AI, we need theoretical tools that can rigorously **quantify the difference** between a model's performance on the training data ($$\hat{L}_{\mathcal{S}}$$, the empirical risk) and its true performance on the entire unknown data distribution ($$L$$, the expected risk).

Traditional bounds, derived from concepts like **VC-Dimension** and **Rademacher Complexity**, aim to provide a uniform guarantee for an entire *class* of functions (ie all the possible functions output by our learning algorithm) . However, because these bounds are worst-case and independent of the actual learning process, they are notoriously **loose**, often yielding vacuous results (e.g., "the error is less than 100%").

This failure motivated the shift toward frameworks that incorporate the learning algorithm and the data, such as the **PAC-Bayes theory**.

## The PAC-Bayes Framework: A Localized Measure of Complexity

The **PAC-Bayes** framework offers a more adaptive approach. Instead of analyzing a single deterministic model, it analyzes a **distribution over models** $$Q$$ (the posterior), comparing it against a reference distribution $$P$$ (the prior). This framework yields a bound that is **data-dependent** and often much tighter:
<p>
$$
\text{Expected Risk } (L) \leq \text{Empirical Risk } (\hat{L}_{\mathcal{S}}) + \text{Complexity Penalty}
$$
</p>

The **Complexity Penalty** is where the problem lies. It is primarily driven by the **Kullback-Leibler (KL) Divergence** 
$$D_{KL}(Q||P)$$ between the learned posterior $$Q$$ and the prior $$P$$ in the high-dimensional **weight space** $$\mathcal{W}$$. 

<p>
$$
\text{Complexity Penalty} \propto \sqrt{\frac{D_{KL}(Q||P)}{|\mathcal{S}|}}
$$
</p>

The logic is sound: if the learned distribution $$Q$$ is simple and close to a chosen prior $$P$$ (low $$D_{KL}$$), the model hasn't used much capacity and should generalize well. The problem is that the **weight space is redundant**.

## The Redundancy Trap: Rescaling Invariances

Our work focuses on networks that use the **Rectified Linear Unit (ReLU)** activation function, $x \mapsto \mathrm{max}(0, x)$. This function has the critical property of **positive homogeneity**: for any $$\lambda > 0,\; \mathrm{ReLU}(\lambda x) = \lambda \mathrm{ReLU}(x)$$.

This property creates a redundancy known as **rescaling invariance**. For any hidden neuron in the network, we can construct an entire **equivalence class** of weight vectors $$\diamond^{\lambda}(w)$$ that all realize the **exact same function** $$f_w$$. This is achieved by:
1.  Multiplying the weights entering the neuron by $$\lambda$$.
2.  Dividing the weights leaving the neuron by $$1 / \lambda$$.
![](/images/img_rescaling.jpg "Rescaling invariances of ReLU networks")

**The devastating consequence for PAC-Bayes:**
Because the standard bound measures complexity in the raw weight space $$\mathcal{W}$$, two weight distributions $$Q$$ and $$P$$ that are functionally identical (i.e., they define the same network function $$f$$) can be arbitrarily far apart in terms of $$D_{KL}(Q||P)$$ simply by choosing different internal scaling factors $$\lambda$$.

This means the $$D_{KL}$$ term—the supposed measure of functional complexity—can be **artificially inflated** by simple scaling, leading to generalization bounds that are **vacuously large** and theoretically useless, despite the function being simple and generalizing well in practice. The complexity measure is fundamentally misaligned with the functional equivalence of the models.

## Our Theoretical Correction: Invariant Lifted Representations

To restore the validity of the PAC-Bayes framework, we must analyze complexity in a space that is **invariant** to these arbitrary scaling factors. We introduce the concept of an **Invariant Lifted Representation** $$\mathcal{Z}$$.

The solution involves defining a map, or "**lift**" $$\psi: \mathcal{W} \rightarrow \mathcal{Z}$$, which projects the high-dimensional, redundant weight space $$\mathcal{W}$$ down into a lower-dimensional, **symmetry-free space** $$\mathcal{Z}$$. Any two weight vectors belonging to the same functional equivalence class (i.e., related by a rescaling operation) will be mapped to the same point $$\psi(w) = \psi(\diamond^{\lambda}(w))$$. A special candidate for this lift is called the **path-lifting**.

**The Core Result:**
We formally prove that the PAC-Bayes bound holds when the complexity is measured using the **lifted divergence** $$D_{KL}(\psi_\sharp Q||\psi_\sharp P)$$ in this new space $$\mathcal{Z}$$.

Furthermore, we use the **Data Processing Inequality (DPI)** from information theory to establish the superiority of this approach: applying any function (like our lift $\psi$) to two random variables (the weight distributions $$Q$$ and $$P$$) can only reduce or preserve the information distance between them. This yields the crucial theoretical guarantee:

<p>
$$
D_{KL}(\psi_\sharp Q||\psi_\sharp P) \le D_{KL}(Q||P)
$$
</p>

This guarantees that the invariant, lifted bound is **always tighter** than the original weight-space bound, formally demonstrating that correcting for symmetries leads to better theoretical guarantees.

## Practical Implementation and Impact

While calculating the exact optimal lifted KL is challenging, the DPI provides a computable upper bound that is guaranteed to be tighter than the original: the **Deterministic Rescaling Infimum**. This term involves minimizing the KL divergence across all possible scaling factors $$\lambda$$.

<p>
$$
D_{KL}(\psi_\sharp Q||\psi_\sharp P)\le \inf_{\lambda,\lambda^{\prime}}D_{KL}(\diamond_\sharp^{\lambda}Q||\diamond_\sharp^{\lambda^{\prime}}P) \leq D_{KL}(Q||P)
$$
</p>

We developed an efficient and provably convergent **Block Coordinate Descent (BCD) algorithm** to find the optimal scaling vector $$\lambda^*$$ that minimizes this proxy bound.

Our experiments confirmed the practical impact:

1.  **Divergence Reduction:** The optimal rescaling procedure consistently reduced the measured KL complexity term by factors of **up to five**.
2.  **Bound Tightening:** This reduction directly translated into significantly **tighter PAC-Bayes generalization bounds**, often reducing them by half.
3.  **Validity Restoration:** Critically, in many real-world scenarios, this correction transformed bounds that were **vacuous** (offering no useful information) into **informative, non-vacuous guarantees**.

This research provides a necessary theoretical improvement to the PAC-Bayes framework, ensuring that our complexity measures are robust against the architectural symmetries inherent in ReLU networks, thereby bridging the gap between deep learning practice and generalization theory.

![](/images/pac_bound.png)

