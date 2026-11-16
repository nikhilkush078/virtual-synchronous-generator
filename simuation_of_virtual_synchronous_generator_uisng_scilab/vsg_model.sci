// =====================================================
// GRID FORMING INVERTER
// VIRTUAL SYNCHRONOUS GENERATOR + BESS
// INTERNAL FREQUENCY GENERATION
// =====================================================

function [f_gfm_next, omega_next, theta_next] = ...
    gfm_vsg_model(P_e_meas, f_previous, theta_previous, dt)

    // Nominal system parameters
    f0 = 50;              // Nominal frequency (Hz)
    S_base = 100;         // Power base (kVA)

    // Battery power setpoint
    P_bess_ref = 20;      // kW

    // Virtual synchronous generator parameters
    H = 2.0;              // Virtual inertia constant (seconds)
    D = 1.0;              // Virtual damping coefficient

    // Convert power imbalance into per-unit
    delta_P = (P_bess_ref - P_e_meas)/S_base;

    // Frequency deviation in per-unit
    delta_f = (f_previous - f0)/f0;

    // Virtual swing equation
    df_dt = (f0/(2*H))*(delta_P - D*delta_f);

    // Update internally generated frequency
    f_gfm_next = f_previous + dt*df_dt;

    // Calculate angular frequency
    omega_next = 2*%pi*f_gfm_next;

    // Integrate angular frequency to obtain phase angle
    theta_next = theta_previous + ...
        2*%pi*((f_previous + f_gfm_next)/2)*dt;

    // Keep phase angle between 0 and 2*pi
    theta_next = modulo(theta_next, 2*%pi);

endfunction
