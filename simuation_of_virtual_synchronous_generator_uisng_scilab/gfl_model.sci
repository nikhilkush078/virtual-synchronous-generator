// =====================================================
// GRID FOLLOWING INVERTER
// SOLAR PV + FREQUENCY-WATT CONTROL
// =====================================================

function [P_gfl_next, P_gfl_ref, I_gfl] = ...
    gfl_model(f_bus, V_bus, P_previous, P_available, dt)

    // Nominal frequency
    f0 = 50;

    // Initial solar power injection
    P0 = 40;                 // kW

    // Frequency response coefficient
    Kf = 150;                // kW/Hz

    // Inverter power limitations
    Pmax = 60;               // kW
    Pmin = 0;                // kW

    // Response time
    T_gfl = 0.15;

    // Frequency-watt control
    P_gfl_ref = P0 + Kf*max(0, f0-f_bus);

    // Solar availability and inverter limitations
    P_gfl_ref = min(P_available, Pmax);
    P_gfl_ref = min(P_gfl_ref, ...
                    max(Pmin, P0 + Kf*max(0, f0-f_bus)));

    // First-order power response
    P_gfl_next = P_previous + ...
        (dt/T_gfl)*(P_gfl_ref-P_previous);

    // Actual voltage
    V_actual = 230*V_bus;

    // Single-phase active current calculation
    if V_actual > 1 then
        I_gfl = P_gfl_next*1000/V_actual;
    else
        I_gfl = 0;
    end

endfunction
