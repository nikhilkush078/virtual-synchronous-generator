# Inverter-Based Microgrid Simulation
### Grid-Forming BESS (VSG) + Grid-Following Solar Inverter + Dynamic Load

## 1. Project Overview

This project presents a mathematical simulation of an islanded inverter-based microgrid consisting of:

1. **Grid-Forming Inverter (GFM):** Battery Energy Storage System (BESS) using Virtual Synchronous Generator (VSG)-style control.
2. **Grid-Following Inverter (GFL):** Solar Photovoltaic (PV) system using frequency-watt control.
3. **Dynamic Electrical Load:** A load model that introduces a sudden demand increase during simulation.

All three components are represented through mathematical models and connected to a common AC bus.

The primary objective is to study how an inverter-based power system responds to a sudden load disturbance, particularly how frequency, voltage, active power, reactive power, and load current change during the transient period.

The simulation is developed using **Scilab**.

---

## 2. Project Objectives

The main objectives of this project are:

- Understand the operation of Grid-Forming and Grid-Following inverters in an islanded microgrid.
- Implement a simplified Virtual Synchronous Generator model.
- Study frequency response following a sudden load increase.
- Implement frequency-watt control for a solar-based Grid-Following inverter.
- Study active and reactive power distribution between the inverters and load.
- Observe the effect of virtual inertia and damping on frequency dynamics.
- Analyze common-bus voltage and phase-angle response.
- Understand the interaction between multiple inverter-based energy sources.

---

## 3. System Architecture

The simulated microgrid contains two inverter-based generation sources connected to a common AC bus.

### System Components

| Component | Description | Main Function |
|---|---|---|
| BESS + GFM | Battery Energy Storage System with Grid-Forming Inverter | Establishes the grid reference and provides power balancing support |
| Solar PV + GFL | Solar Photovoltaic system with Grid-Following Inverter | Follows the existing bus reference and provides frequency support |
| AC Common Bus | Shared electrical connection | Represents the common voltage and frequency of the microgrid |
| Electrical Load | Dynamic active and reactive load | Introduces a disturbance to test system response |

### Operating Principle

The Grid-Forming inverter establishes the voltage and frequency reference for the islanded microgrid.

The Grid-Following inverter synchronizes with the existing AC bus and adjusts its active power output according to the measured bus frequency.

When the electrical load increases, the generation initially becomes insufficient to meet the demand. This creates a power imbalance, causing the frequency to deviate.

The inverter controllers respond to this deviation by adjusting their active power references.

The purpose of the simulation is to observe this complete response.

---

## 4. Initial System Configuration

The simulation uses the following initial operating conditions:

| Parameter | Initial Value |
|---|---:|
| Nominal Frequency | 50 Hz |
| Nominal Bus Voltage | 230 V |
| Initial BESS Active Power | 40 kW |
| Initial Solar Active Power | 20 kW |
| Initial Load Active Power | 60 kW |
| Initial BESS Reactive Power | 10 kVAr |
| Initial Load Reactive Power | 10 kVAr |
| Simulation Duration | 8 seconds |
| Simulation Time Step | 0.001 seconds |
| Load Disturbance Time | 2 seconds |

Initially, the active power generation is:

\[
P_{generation}=P_{GFM}+P_{GFL}
\]

\[
P_{generation}=40+20=60\text{ kW}
\]

The initial load demand is also 60 kW.

Therefore:

\[
P_{imbalance}=P_{generation}-P_{load}=0
\]

The system starts with a balanced active-power condition.

---

## 5. Project File Structure

A typical project directory can be organized as follows:

```text
simuation_of_virtual_synchronous_generator_uisng_scilab/
│
├── main_simulation.sce
│
├── load_model.sci
│
├── vsg_model.sci
│
├── gfl_model.sci
│
└── README.md
```

### Description of Files

| File | Description |
|---|---|
| `main_simulation.sce` | Main simulation program. Initializes system parameters, connects the models, executes the simulation loop, generates graphs, and exports results. |
| `load_model.sci` | Defines the active and reactive load profile, including the sudden load increase at 2 seconds. |
| `vsg_model.sci` | Standalone VSG model file, if included. Contains the earlier independent VSG implementation. |
| `gfl_model.sci` | Standalone GFL model file, if included. Contains the earlier independent GFL implementation. |
| `README.md` | Project documentation and instructions. |

**Important implementation note:** In the latest revised main simulation script, the GFM and GFL control equations are implemented directly inside `main_simulation.sce`. That version only loads `load_model.sci` using `exec()`. The standalone `vsg_model.sci` and `gfl_model.sci` files are not required by that particular main script unless you modify it to call those functions.

---

# 6. Individual Model Explanation

## 6.1 Load Model — `load_model.sci`

The load model introduces a sudden change in electrical demand.

Initially, the system operates with:

- Active Power: 60 kW
- Reactive Power: 10 kVAr

At 2 seconds, the load increases to:

- Active Power: 80 kW
- Reactive Power: 18 kVAr

### Mathematical Model

The load is represented using a step function.

Active power:

\[
P_{load}(t)=
\begin{cases}
60 & t<2\\
80 & t\geq 2
\end{cases}
\]

Reactive power:

\[
Q_{load}(t)=
\begin{cases}
10 & t<2\\
18 & t\geq 2
\end{cases}
\]

The resulting changes are:

\[
\Delta P_{load}=80-60=20\text{ kW}
\]

\[
\Delta Q_{load}=18-10=8\text{ kVAr}
\]

### Code Explanation

```scilab
function [P_load, Q_load] = load_model(t)

    P_initial = 60;
    Q_initial = 10;

    P_increased = 80;
    Q_increased = 18;

    if t < 2 then

        P_load = P_initial;
        Q_load = Q_initial;

    else

        P_load = P_increased;
        Q_load = Q_increased;

    end

endfunction
```

The function receives simulation time as its input.

It checks whether the current simulation time is below or above 2 seconds and returns the corresponding active and reactive power values.

This load disturbance is used to evaluate the response of the inverter-based microgrid.

---

## 6.2 Grid-Forming Inverter — BESS with VSG Control

The Grid-Forming inverter is responsible for establishing the voltage and frequency reference of the islanded microgrid.

In this project, the BESS provides active and reactive power support.

The control model uses the following concepts:

- Active power-frequency droop.
- Virtual synchronous generator dynamics.
- First-order power response.
- Reactive power-voltage control.
- Simplified bus voltage dynamics.

### A. Active Power-Frequency Droop

The GFM adjusts its active power reference according to the bus-frequency deviation.

The mathematical equation is:

\[
P_{GFM}^{*}=P_{GFM0}+K_{p}(f_0-f)
\]

Where:

| Symbol | Description |
|---|---|
| \(P_{GFM}^{*}\) | GFM active power reference |
| \(P_{GFM0}\) | Initial active power |
| \(K_p\) | Frequency droop coefficient |
| \(f_0\) | Nominal frequency |
| \(f\) | Common-bus frequency |

The implementation is:

```scilab
P_vsg_ref(k) = P_vsg0 + ...
               Kp_vsg*(f0-f_bus(k));
```

For example, if the bus frequency decreases to 49.9 Hz:

\[
P_{GFM}^{*}=40+300(50-49.9)
\]

\[
P_{GFM}^{*}=70\text{ kW}
\]

The controller therefore requests additional active power from the BESS.

### B. First-Order BESS Power Response

The actual BESS output does not change instantaneously.

A first-order response model is used:

\[
\frac{dP_{GFM}}{dt}
=
\frac{P_{GFM}^{*}-P_{GFM}}{T_{GFM}}
\]

The discrete-time implementation is:

\[
P_{GFM}(k+1)=P_{GFM}(k)
+
\frac{dt}{T_{GFM}}
[P_{GFM}^{*}(k)-P_{GFM}(k)]
\]

Code:

```scilab
P_vsg(k+1) = P_vsg(k) + ...
    (dt/T_vsg)*(P_vsg_ref(k)-P_vsg(k));
```

Here, `T_vsg` determines the response speed of the BESS power output.

### C. Virtual Synchronous Generator Dynamics

A conventional synchronous generator has a rotating mass that stores kinetic energy.

When electrical demand increases, the imbalance between mechanical input and electrical output affects rotor speed.

A VSG imitates this behaviour mathematically using virtual inertia and damping.

The simplified swing equation used in the common-bus model is:

\[
\frac{df}{dt}
=
\frac{f_0}{2HS_{base}}
\left[
P_{imbalance}-D(f-f_0)
\right]
\]

Where:

| Parameter | Description |
|---|---|
| \(H\) | Virtual inertia constant |
| \(S_{base}\) | System power base |
| \(D\) | Frequency damping coefficient |
| \(P_{imbalance}\) | Difference between generation and load |
| \(f_0\) | Nominal frequency |
| \(f\) | Common-bus frequency |

The power imbalance is:

\[
P_{imbalance}=P_{GFM}+P_{GFL}-P_{load}
\]

Code:

```scilab
P_generation = P_vsg(k) + P_gfl(k);

P_imbalance = P_generation - P_load(k);
```

The frequency update is:

```scilab
df_dt = (f0/(2*H*Sbase))* ...
    (P_imbalance - D*(f_bus(k)-f0));

f_bus(k+1) = f_bus(k) + dt*df_dt;
```

When the load increases, the generation initially becomes insufficient.

The resulting negative power imbalance causes the virtual rotor to decelerate, producing a frequency decrease.

The inverter controllers then respond to this frequency deviation.

**Note:** This implementation uses an aggregate common-bus swing equation. It is a simplified VSG-style frequency model rather than a complete internal VSG oscillator connected to a detailed inverter electrical plant.

### D. Reactive Power-Voltage Control

The GFM also provides reactive power support.

The simplified voltage-reactive power relationship is:

\[
Q_{GFM}^{*}=Q_{GFM0}+K_q(V_0-V)
\]

Where:

- \(Q_{GFM}^{*}\) is the reactive power reference.
- \(Q_{GFM0}\) is the initial reactive power.
- \(K_q\) is the voltage-reactive power gain.
- \(V_0\) is nominal voltage.
- \(V\) is the measured bus voltage.

Code:

```scilab
Q_vsg_ref(k) = Q_vsg0 + ...
               Kq*(V0-V_bus(k));
```

A first-order response is then applied:

\[
Q_{GFM}(k+1)=Q_{GFM}(k)
+
\frac{dt}{T_Q}
[Q_{GFM}^{*}(k)-Q_{GFM}(k)]
\]

This allows the reactive power output to gradually follow its reference.

---

## 6.3 Grid-Following Inverter — Solar PV

The Grid-Following inverter operates differently from the Grid-Forming inverter.

It does not independently establish the AC bus frequency.

Instead, it measures the existing bus frequency and adjusts its active power output.

This project uses frequency-watt control.

### A. Frequency-Watt Control

The GFL increases its active power reference when the bus frequency falls below nominal frequency.

The mathematical relationship is:

\[
P_{GFL}^{*}
=
P_{GFL0}
+
K_f\max(0,f_0-f)
\]

Where:

| Symbol | Description |
|---|---|
| \(P_{GFL}^{*}\) | GFL active power reference |
| \(P_{GFL0}\) | Initial solar power |
| \(K_f\) | Frequency-watt coefficient |
| \(f_0\) | Nominal frequency |
| \(f\) | Measured bus frequency |

Code:

```scilab
P_gfl_ref(k) = P_gfl0 + ...
               Kf_gfl*max(0, f0-f_bus(k));
```

The `max(0, ...)` function ensures that the controller responds only to under-frequency conditions.

For example, if frequency falls to 49.9 Hz:

\[
P_{GFL}^{*}=20+150(50-49.9)
\]

\[
P_{GFL}^{*}=35\text{ kW}
\]

The solar inverter therefore requests an increase from 20 kW to 35 kW.

### B. Solar Power Availability

The solar inverter cannot generate more power than the available solar energy allows.

The reference is limited by:

- Minimum inverter power.
- Maximum inverter power.
- Available solar power.

The mathematical limitation is:

\[
P_{GFL}^{*}
=
\min(P_{max},P_{available},P_{request})
\]

Code:

```scilab
P_gfl_ref(k) = max(P_gfl_min, ...
               min(P_gfl_max, ...
               min(P_available, P_gfl_ref(k))));
```

For example:

If the requested solar power is 50 kW but only 35 kW is available, the actual reference is limited to 35 kW.

### C. First-Order Solar Power Response

The solar inverter output follows its power reference through a first-order response model.

\[
\frac{dP_{GFL}}{dt}
=
\frac{P_{GFL}^{*}-P_{GFL}}{T_{GFL}}
\]

Discrete implementation:

\[
P_{GFL}(k+1)=P_{GFL}(k)
+
\frac{dt}{T_{GFL}}
[P_{GFL}^{*}(k)-P_{GFL}(k)]
\]

Code:

```scilab
P_gfl(k+1) = P_gfl(k) + ...
    (dt/T_gfl)*(P_gfl_ref(k)-P_gfl(k));
```

This represents the gradual response of the solar inverter.

---

# 7. Main Simulation — `main_simulation.sce`

The main simulation connects the load model, GFM and GFL control systems.

It is responsible for:

1. Loading the required model files.
2. Defining system parameters.
3. Initializing bus and power variables.
4. Executing the simulation loop.
5. Calculating power imbalance.
6. Updating frequency, voltage and phase angle.
7. Calculating load and inverter currents.
8. Generating response graphs.
9. Exporting simulation variables.

### A. Loading Model Files

```scilab
exec("load_model.sci", -1);
```

This loads the load model function into the Scilab environment.

In the latest version, the GFM and GFL equations are implemented directly inside the main simulation script.

### B. Simulation Time

```scilab
Tsim = 8;
dt = 0.001;

t = 0:dt:Tsim;
N = length(t);
```

The simulation runs for 8 seconds with a time step of 1 millisecond.

The number of simulation samples is:

\[
N=\frac{T_{sim}}{dt}+1
\]

For this configuration:

\[
N=\frac{8}{0.001}+1=8001
\]

### C. Initial Conditions

The bus variables are initialized at nominal values:

```scilab
f_bus(1) = f0;
V_bus(1) = V0;

theta_bus(1) = 0;
```

The initial active power outputs are:

```scilab
P_vsg(1) = 40;
P_gfl(1) = 20;
```

This ensures that the initial generation matches the initial load demand.

### D. Main Simulation Loop

```scilab
for k = 1:N-1
```

This loop executes the complete system model at every simulation time step.

During each iteration:

1. The current load is obtained.
2. The GFL calculates its power reference and output.
3. The GFM calculates its power reference and output.
4. The common-bus active-power imbalance is calculated.
5. The swing equation updates frequency.
6. Phase angle is integrated.
7. Reactive power and bus voltage are updated.
8. Load and inverter currents are calculated.

The loop continues until the simulation reaches its final time.

### E. Phase Angle Calculation

Angular frequency is:

\[
\omega=2\pi f
\]

The phase angle is obtained by integrating angular frequency:

\[
\theta(k+1)=\theta(k)+2\pi
\left(\frac{f(k)+f(k+1)}{2}\right)dt
\]

Code:

```scilab
theta_bus(k+1) = theta_bus(k) + ...
    2*%pi*((f_bus(k)+f_bus(k+1))/2)*dt;
```

The phase deviation is calculated relative to nominal frequency:

\[
\Delta\theta(t)=\theta(t)-2\pi f_0t
\]

This helps identify the phase change caused by the load disturbance rather than the continuous nominal phase rotation.

### F. Load Current Calculation

The load current is estimated using apparent power.

\[
S=\sqrt{P^2+Q^2}
\]

For the single-phase equivalent system:

\[
I_{load}=
\frac{\sqrt{P_{load}^2+Q_{load}^2}\times1000}
{230V_{pu}}
\]

Where:

- Active power is expressed in kW.
- Reactive power is expressed in kVAr.
- Voltage is represented in per unit.
- 230 V is the nominal voltage base.

This calculates the approximate RMS load current.

---

# 8. Expected Simulation Behaviour

The most important event in the simulation occurs at 2 seconds.

### Stage 1: Normal Operation (0–2 Seconds)

Initially:

| Component | Active Power |
|---|---:|
| BESS / GFM | 40 kW |
| Solar / GFL | 20 kW |
| Load | 60 kW |

Generation and load are balanced.

Expected behaviour:

- Frequency remains at 50 Hz.
- Bus voltage remains at approximately 230 V.
- BESS output remains at its initial operating point.
- Solar output remains at its initial operating point.
- Phase deviation remains approximately zero.

### Stage 2: Load Disturbance (At 2 Seconds)

The load increases from 60 kW to 80 kW.

Initially:

\[
P_{generation}=60\text{ kW}
\]

\[
P_{load}=80\text{ kW}
\]

Therefore:

\[
P_{imbalance}=-20\text{ kW}
\]

The sudden power deficit causes the frequency to decrease.

### Stage 3: Inverter Response (After 2 Seconds)

The GFM and GFL controllers detect the under-frequency condition.

The GFM increases its active power reference.

The GFL also increases its active power reference, provided sufficient solar power is available.

Their actual power outputs gradually follow their references.

### Stage 4: New Operating Condition

The system approaches a new operating point.

The BESS and solar inverter contribute to meeting the increased demand.

Because the control system uses droop-based frequency response without secondary frequency restoration, the final frequency may remain slightly different from 50 Hz.

---

# 9. Simulation Graphs

The main program generates separate graphs to study the system response.

| Graph | Description |
|---|---|
| Bus Frequency | Shows frequency variation following the load disturbance. |
| Bus Voltage | Shows the simplified common-bus voltage response. |
| Active Power Distribution | Compares load power, GFM power and GFL power. |
| Load Current | Shows the change in load current after the load increase. |
| Phase Angle Deviation | Shows phase deviation relative to nominal-frequency rotation. |
| Active Power Balance | Compares total generation against load demand. |
| Reactive Power Distribution | Compares load reactive power and GFM reactive power. |

These graphs help evaluate the transient behaviour and power-sharing characteristics of the simulated microgrid.

---

# 10. System Parameters

The following parameters are used in the latest simulation configuration.

| Parameter | Value | Description |
|---|---:|---|
| `f0` | 50 Hz | Nominal frequency |
| `V0` | 1.0 pu | Nominal voltage |
| `H` | 3 s | Virtual inertia |
| `Sbase` | 100 kW | Power base |
| `D` | 5 kW/Hz | Frequency damping |
| `Kp_vsg` | 300 kW/Hz | GFM active-power droop gain |
| `Kf_gfl` | 150 kW/Hz | GFL frequency-watt gain |
| `T_vsg` | 0.25 s | BESS power response time |
| `T_gfl` | 0.15 s | Solar inverter response time |
| `P_available` | 60 kW | Available solar power |
| `Kq` | 100 | Voltage-reactive-power gain |
| `T_reactive` | 0.2 s | Reactive-power response time |
| `T_voltage` | 0.15 s | Simplified voltage response time |
| `dt` | 0.001 s | Simulation time step |
| `Tsim` | 8 s | Total simulation duration |

These are simulation parameters and illustrative values, not validated hardware specifications.

---

# 11. Software Requirements

### Required Software

- Scilab
- Operating System: Windows or Linux

### Installation

Download Scilab from:

https://www.scilab.org/

Install and launch Scilab.

### Running the Project

1. Download or clone this repository.
2. Extract the project files into a folder.
3. Open Scilab.
4. Set the current working directory to the project folder.
5. Open `main_simulation.sce`.
6. Execute the script.

Alternatively, execute the main file from the Scilab console:

```scilab
exec("main_simulation.sce", -1);
```

Make sure that `load_model.sci` is present in the same directory as the main simulation script.

---

# 12. Model Assumptions and Limitations

This project is a simplified averaged mathematical simulation intended for understanding inverter-based microgrid control behaviour.

It does not represent a complete switching-level power-electronics simulation.

The current implementation has the following limitations:

1. **Simplified VSG dynamics:** The frequency equation represents aggregate common-bus swing dynamics. A complete VSG implementation would include its internal oscillator and coupling to measured inverter electrical output power.

2. **Simplified BESS:** Battery state of charge, battery electrochemical behaviour, DC voltage and DC-link dynamics are not explicitly modelled.

3. **Simplified solar PV:** Solar irradiance, PV characteristics and MPPT dynamics are not modelled. Solar availability is represented by a fixed power limit.

4. **Simplified voltage dynamics:** The voltage equation is an approximate mathematical model, not a complete AC network or inverter voltage-control model.

5. **No PWM switching model:** The simulation does not generate actual inverter switching pulses.

6. **No detailed electrical network:** Cable impedance, transformer impedance, LCL filters and detailed power-flow equations are not included.

7. **No secondary frequency restoration:** Droop control alone may result in a steady-state frequency different from nominal frequency.

These limitations define the scope of the current project and should be considered when interpreting the simulation results.

---

# 13. Possible Future Improvements

The project can be extended toward a more detailed inverter-based microgrid simulation.

Possible improvements include:

- Implementing a complete VSG swing equation with an internal virtual rotor state.
- Adding a GFM voltage-reference generation and inner voltage/current control loops.
- Implementing a phase-locked loop (PLL) and current control for the GFL.
- Adding a detailed solar PV model with MPPT.
- Modelling BESS state of charge and DC-link dynamics.
- Adding DC-AC inverter bridges and PWM generation.
- Implementing LCL filters.
- Modelling three-phase AC voltage and current.
- Adding network impedance and power-flow calculations.
- Implementing secondary frequency restoration.

These improvements would move the project from a control-level mathematical model toward a more realistic power-electronics and microgrid simulation.

---

# 14. Conclusion

This project demonstrates the fundamental interaction between Grid-Forming and Grid-Following inverters in an islanded microgrid.

The Grid-Forming BESS provides the grid reference and supports active and reactive power balance, while the Grid-Following solar inverter follows the common bus and contributes additional active power during under-frequency conditions when solar reserve is available.

A sudden load increase is used to study the resulting power imbalance, frequency deviation, inverter response and approximate power-sharing behaviour.

The project provides a foundation for understanding inverter-based power systems and can be further developed into a more detailed microgrid and power-electronics simulation.

---

**Project Domain:** Electrical Engineering | Power Systems | Power Electronics | Renewable Energy | Microgrids | Inverter Control

**Simulation Platform:** Scilab
