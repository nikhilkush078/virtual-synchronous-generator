// =====================================================
// ELECTRICAL LOAD MODEL
// =====================================================

function [P_load, Q_load] = load_model(t)

    // Initial load
    P_initial = 60;       // kW
    Q_initial = 10;       // kVAr

    // Increased load
    P_increased = 80;     // kW
    Q_increased = 18;     // kVAr

    // Load disturbance at 2 seconds

    if t < 2 then

        P_load = P_initial;
        Q_load = Q_initial;

    else

        P_load = P_increased;
        Q_load = Q_increased;

    end

endfunction
