---
title: "Learning pendulum swing-up from demonstration"
description: "Fitting a dynamics model, adjusting a demonstrated motion, and handing control to a balancing controller."
date: 2026-04-11
permalink: /projects/2026/learning-pendulum/
topic: Robotics
cover: /images/posts/mva-favorite-projects/arm_pendulum/franka_robot.png
tags: [MVA, Robotics, System Identification, Trajectory Optimization, LQR]
---

In this MVA robotics project with Alexandre Ducorroy, we control a pendulum attached to a simulated Franka Panda arm. The pendulum joint is passive: the arm must move its attachment point to make it swing, then balance it upright. A recorded human demonstration provides a candidate motion. We adjust that motion through trajectory optimization, test its execution in simulation, and switch to a local feedback controller when the pendulum approaches the top with sufficiently low angular velocity.

<figure>
<video controls muted loop playsinline preload="metadata" width="1334" height="1068" aria-label="Pendulum swing-up in the robot simulator" aria-describedby="pendulum-video-caption" poster="{{ '/images/posts/mva-favorite-projects/arm_pendulum/franka_robot.png' | relative_url }}">
  <source src="{{ '/images/posts/mva-favorite-projects/arm_pendulum/demo.mp4' | relative_url }}" type="video/mp4">
  <a href="{{ '/images/posts/mva-favorite-projects/arm_pendulum/demo.mp4' | relative_url }}">Open the pendulum simulation video.</a>
</video>
<figcaption id="pendulum-video-caption">A recorded execution in PyBullet. The arm moves the passive pendulum, then balances it near the upright position.</figcaption>
</figure>

## A reduced model of the motion

The swing-up planner uses four state variables,

$$
s_k=(\theta_k,\dot\theta_k,x_k,\dot x_k)^\top,
\qquad u_k=\ddot x_k,
$$

where $x$ is the horizontal position of the attachment point and $u$ is its acceleration. In the swing-up convention, $\theta=0$ is the downward position and $\theta=\pm\pi$ is upright. The control scripts use a time step of $\Delta t=0.01$ seconds.

The angular dynamics are represented by a model with three fitted coefficients:

$$
\dot\theta_{k+1}
=(1-\alpha_1)\dot\theta_k
+\alpha_2\sin\theta_k
+\alpha_3u_k\cos\theta_k.
$$

The remaining updates are $\theta_{k+1}=\theta_k+\Delta t\,\dot\theta_k$, $x_{k+1}=x_k+\Delta t\,\dot x_k$, and $\dot x_{k+1}=\dot x_k+\Delta t\,u_k$. The fitted coefficients incorporate the time discretization of the angular-velocity update.

Although this model is nonlinear in the state, it is linear in its unknown coefficients. Identification therefore uses ordinary least squares on the features $\dot\theta_k$, $\sin\theta_k$, and $u_k\cos\theta_k$, with the next angular velocity as the target. This retains a pendulum-shaped model while estimating the damping, gravity, and acceleration terms from recorded transitions.

## Adjusting the demonstration

The demonstration is collected by steering the simulated arm with the keyboard. The recording contains the pendulum angle and angular velocity, the attachment point's horizontal position and velocity, and its acceleration.

Given $N$ recorded states $s_k^d$, the trajectory optimizer solves

$$
\min_{s,u}\sum_{k=0}^{N-2}
\left(\lVert s_k-s_k^d\rVert_2^2+\lambda_u u_k^2\right)
$$

subject to the learned dynamics and the demonstrated initial state. CasADi formulates the problem and IPOPT solves it. The recorded states and accelerations also initialize the solver.

The demonstration thus has two roles: it supplies the initial guess and remains the reference in the objective. The optimizer can change the trajectory to reduce acceleration while respecting the model, but deviations from the demonstrated states carry a cost.

There is no explicit terminal constraint requiring an upright pendulum at rest, and no explicit acceleration bound in this optimization. A solution can consequently fit the demonstration reasonably well without producing a useful transition to balancing. We check that transition by executing the planned horizontal motion in the full robot simulation.

## Choosing the acceleration penalty

The adaptive script first tries the recorded horizontal trajectory directly. If it fails the handover test, it searches over $\lambda_u$, the acceleration penalty. Each candidate requires both an optimization and a simulated execution.

The handover test uses the angular error relative to upright,

$$
e_\theta=\operatorname{wrap}_{[-\pi,\pi)}(\theta-\pi),
\qquad |e_\theta|<0.3,
\qquad |\dot\theta|<2\ \mathrm{rad/s}.
$$

This explains why the phase plot places the handover regions at both $-\pi$ and $\pi$: they represent the same physical orientation. The local balancing controller uses the corresponding error centered at zero.

If a candidate enters the angular neighborhood too quickly, the search increases the acceleration penalty. If it never reaches that neighborhood during execution, the search decreases it. This is a practical interval-halving heuristic; the nonlinear optimization and execution do not provide a guarantee that the outcome varies monotonically with the penalty.

<figure>
  <a class="figure-link" href="{{ '/images/posts/mva-favorite-projects/arm_pendulum/swing_up_dichotomy_phase.png' | relative_url }}"><img src="{{ '/images/posts/mva-favorite-projects/arm_pendulum/swing_up_dichotomy_phase.png' | relative_url }}" alt="Phase trajectories for the tested acceleration penalties, with handover windows shaded green at both upright angles" width="720" height="576" loading="lazy"></a>
  <figcaption>The two green windows represent the same upright orientation, at $-\pi$ and $\pi$. The legend distinguishes trajectories that do not reach the window from those that enter it too quickly.</figcaption>
</figure>

In this recorded search, $\lambda_u\approx4.85$ produces a trajectory labeled successful. Other candidates either remain below the upright neighborhood or enter it too fast. That value belongs to this demonstration and setup; the useful observation is the difference between reaching the top and reaching it slowly enough to hand over control.

## Executing the motion and balancing

During swing-up, the arm tracks the optimized horizontal positions through differential inverse kinematics using Pink. Joint feedback then converts the kinematic targets into torques, using the mass matrix and gravity compensation computed with Pinocchio. PyBullet simulates the resulting motion, with no motor torque applied to the pendulum joint.

Balancing uses a separate linear model fitted to state increments near the upright equilibrium. This gives discrete matrices $A$ and $B$ for an LQR controller, whose feedback is $u=-Ke$. Its error vector contains the wrapped pendulum angle, angular velocity, horizontal displacement, and horizontal velocity. At handover, the current horizontal position becomes the position reference.

The LQR output is a desired horizontal acceleration. The implementation converts Cartesian acceleration to joint torques through an operational-space mass matrix and the frame Jacobian, while feedback regulates the other translational directions and gravity compensation is added.


These results are from the PyBullet simulation. The handover thresholds are experimental settings, rather than a certified region of attraction for the balancing controller.
