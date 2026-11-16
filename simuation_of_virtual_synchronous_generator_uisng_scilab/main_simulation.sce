// =====================================================
// VSG + GFL + LOAD
// COMMON BUS SIMULATION
// DISTURBANCE AT t = 2 SECONDS
// =====================================================

clc;
clear;
close;


// -----------------------------------------------------
// 1. LOAD MODEL
// -----------------------------------------------------

exec("load_model.sci", -1);


// -----------------------------------------------------
// 2. SYSTEM PARAMETERS
// -----------------------------------------------------

f0 = 50;                  // Nominal frequency (Hz)
V0 = 1.0;                 // Nominal voltage (pu)

// VSG parameters
H = 3;                    // Virtual inertia (seconds)
Sbase = 100;              // Power base (kW)
D = 5;                    // Frequency damping (kW/Hz)

// GFM parameters
P_vsg0 = 40;              // Initial BESS power (kW)
Kp_vsg = 300;             // GFM frequency droop (kW/Hz)
T_vsg = 0.25;              // GFM power response time (s)

P_vsg_min = 0;
P_vsg_max = 80;

// GFL parameters
P_gfl0 = 20;              // Initial solar power (kW)
Kf_gfl = 150;             // Frequency-watt gain (kW/Hz)
T_gfl = 0.15;              // GFL response time (s)

P_gfl_min = 0;
P_gfl_max = 60;

P_available = 60;          // Available solar power (kW)

// Voltage and reactive power parameters
Q_vsg0 = 10;              // Initial reactive power (kVAr)
Kq = 100;                 // Voltage-reactive power gain
Xq = 0.002;
T_voltage = 0.15;

T_reactive = 0.2;


// -----------------------------------------------------
// 3. SIMULATION SETTINGS
// -----------------------------------------------------

Tsim = 8;
dt = 0.001;

t = 0:dt:Tsim;
N = length(t);


// -----------------------------------------------------
// 4. INITIALIZE BUS VARIABLES
// -----------------------------------------------------

f_bus = zeros(1,N);
V_bus = zeros(1,N);

theta_bus = zeros(1,N);
omega_bus = zeros(1,N);

f_bus(1) = f0;
V_bus(1) = V0;

theta_bus(1) = 0;
omega_bus(1) = 2*%pi*f0;


// -----------------------------------------------------
// 5. INITIALIZE POWER VARIABLES
// -----------------------------------------------------

P_vsg = zeros(1,N);
Q_vsg = zeros(1,N);

P_gfl = zeros(1,N);

P_load = zeros(1,N);
Q_load = zeros(1,N);

P_vsg_ref = zeros(1,N);
P_gfl_ref = zeros(1,N);
Q_vsg_ref = zeros(1,N);

// Initial power balance:
//
// GFM  = 40 kW
// GFL  = 20 kW
// Load = 60 kW

P_vsg(1) = P_vsg0;
P_gfl(1) = P_gfl0;

Q_vsg(1) = Q_vsg0;


// -----------------------------------------------------
// 6. INITIALIZE CURRENT VARIABLES
// -----------------------------------------------------

I_load = zeros(1,N);
I_gfl = zeros(1,N);


// -----------------------------------------------------
// 7. INITIALIZE PHASE DEVIATION
// -----------------------------------------------------

phase_deviation = zeros(1,N);


// -----------------------------------------------------
// 8. MAIN SIMULATION LOOP
// -----------------------------------------------------

for k = 1:N-1

    // =============================================
    // A. LOAD MODEL
    // =============================================

    [P_load(k), Q_load(k)] = load_model(t(k));


    // =============================================
    // B. GRID FOLLOWING INVERTER (SOLAR PV)
    // =============================================

    // GFL responds to under-frequency only.

    P_gfl_ref(k) = P_gfl0 + ...
                   Kf_gfl*max(0, f0-f_bus(k));

    // Limit by solar availability and inverter rating.

    P_gfl_ref(k) = max(P_gfl_min, ...
                   min(P_gfl_max, ...
                   min(P_available, P_gfl_ref(k))));

    // First-order GFL power response.

    P_gfl(k+1) = P_gfl(k) + ...
        (dt/T_gfl)*(P_gfl_ref(k)-P_gfl(k));


    // =============================================
    // C. GRID FORMING INVERTER (BESS)
    // =============================================

    // GFM active power droop.
    // It increases power when frequency falls.

    P_vsg_ref(k) = P_vsg0 + ...
                   Kp_vsg*(f0-f_bus(k));

    // Apply inverter power limits.

    P_vsg_ref(k) = max(P_vsg_min, ...
                   min(P_vsg_max, P_vsg_ref(k)));

    // First-order BESS power response.

    P_vsg(k+1) = P_vsg(k) + ...
        (dt/T_vsg)*(P_vsg_ref(k)-P_vsg(k));


    // =============================================
    // D. COMMON BUS ACTIVE POWER BALANCE
    // =============================================

    // Actual generation at the present time step.

    P_generation = P_vsg(k) + P_gfl(k);

    // Power imbalance.

    P_imbalance = P_generation - P_load(k);


    // =============================================
    // E. VSG SWING EQUATION
    // =============================================

    // The common bus frequency follows the
    // virtual swing dynamics.

    df_dt = (f0/(2*H*Sbase))* ...
        (P_imbalance - D*(f_bus(k)-f0));

    // Update internally generated frequency.

    f_bus(k+1) = f_bus(k) + dt*df_dt;

    // Angular frequency.

    omega_bus(k+1) = 2*%pi*f_bus(k+1);


    // =============================================
    // F. COMMON BUS PHASE ANGLE
    // =============================================

    theta_bus(k+1) = theta_bus(k) + ...
        2*%pi*((f_bus(k)+f_bus(k+1))/2)*dt;


    // =============================================
    // G. REACTIVE POWER / VOLTAGE CONTROL
    // =============================================

    // GFM voltage-reactive power controller.

    Q_vsg_ref(k) = Q_vsg0 + ...
                   Kq*(V0-V_bus(k));

    Q_vsg_ref(k) = max(0, min(40, Q_vsg_ref(k)));

    // Reactive power response.

    Q_vsg(k+1) = Q_vsg(k) + ...
        (dt/T_reactive)*(Q_vsg_ref(k)-Q_vsg(k));

    // Simplified bus voltage dynamics.

    dV_dt = (V0 - V_bus(k) + ...
        Xq*(Q_vsg(k)-Q_load(k)))/T_voltage;

    V_bus(k+1) = V_bus(k) + dt*dV_dt;


    // =============================================
    // H. LOAD CURRENT
    // =============================================

    if V_bus(k) > 0.01 then

        I_load(k) = 1000*sqrt( ...
            P_load(k)^2 + Q_load(k)^2) / ...
            (230*V_bus(k));

        I_gfl(k) = P_gfl(k)*1000 / ...
            (230*V_bus(k));

    else

        I_load(k) = 0;
        I_gfl(k) = 0;

    end

end


// -----------------------------------------------------
// 9. FINAL SAMPLE
// -----------------------------------------------------

[P_load(N), Q_load(N)] = load_model(t(N));

P_vsg_ref(N) = P_vsg_ref(N-1);
P_gfl_ref(N) = P_gfl_ref(N-1);
Q_vsg_ref(N) = Q_vsg_ref(N-1);

if V_bus(N) > 0.01 then

    I_load(N) = 1000*sqrt( ...
        P_load(N)^2 + Q_load(N)^2) / ...
        (230*V_bus(N));

    I_gfl(N) = P_gfl(N)*1000 / ...
        (230*V_bus(N));

else

    I_load(N) = 0;
    I_gfl(N) = 0;

end


// -----------------------------------------------------
// 10. DERIVED VARIABLES
// -----------------------------------------------------

P_total = P_vsg + P_gfl;

P_bess_extra = P_vsg - P_vsg0;

V_bus_actual = V_bus*230;

theta_degrees = modulo(theta_bus*180/%pi, 360);

phase_deviation_degrees = phase_deviation*180/%pi;


// Calculate phase deviation from nominal rotation.
// This should remain zero before the disturbance.

for k = 1:N

    phase_deviation_degrees(k) = ...
        (theta_bus(k)-2*%pi*f0*t(k))*180/%pi;

end


// -----------------------------------------------------
// 11. GRAPH 1: BUS FREQUENCY
// -----------------------------------------------------

scf(1);
clf();

plot(t, f_bus);
gce().children.thickness = 3;

xtitle("Common Bus Frequency", ...
       "Time (seconds)", "Frequency (Hz)");

xgrid();


// -----------------------------------------------------
// 12. GRAPH 2: BUS VOLTAGE
// -----------------------------------------------------

scf(2);
clf();

plot(t, V_bus_actual);
gce().children.thickness = 3;

xtitle("Common Bus Voltage", ...
       "Time (seconds)", "Voltage (V)");

xgrid();


// -----------------------------------------------------
// 13. GRAPH 3: ACTIVE POWER
// -----------------------------------------------------

scf(3);
clf();

plot(t, P_load, "r");
gce().children.thickness = 3;

plot(t, P_vsg, "b");
gce().children.thickness = 3;

plot(t, P_gfl, "g");
gce().children.thickness = 3;

legend("Load Power", "GFM/BESS Power", "GFL/Solar Power");

xtitle("Active Power Distribution", ...
       "Time (seconds)", "Power (kW)");

xgrid();


// -----------------------------------------------------
// 14. GRAPH 4: LOAD CURRENT
// -----------------------------------------------------

scf(4);
clf();

plot(t, I_load);
gce().children.thickness = 3;

xtitle("Load Current", ...
       "Time (seconds)", "Current (A)");

xgrid();


// -----------------------------------------------------
// 15. GRAPH 5: PHASE DEVIATION
// -----------------------------------------------------

scf(5);
clf();

plot(t, phase_deviation_degrees);
gce().children.thickness = 3;

xtitle("Phase Angle Deviation", ...
       "Time (seconds)", "Deviation (degrees)");

xgrid();


// -----------------------------------------------------
// 16. GRAPH 6: POWER BALANCE
// -----------------------------------------------------

scf(6);
clf();

plot(t, P_total, "b");
gce().children.thickness = 3;

plot(t, P_load, "r");
gce().children.thickness = 3;

legend("Total Generation", "Load Demand");

xtitle("Common Bus Active Power Balance", ...
       "Time (seconds)", "Power (kW)");

xgrid();


// -----------------------------------------------------
// 17. GRAPH 7: REACTIVE POWER
// -----------------------------------------------------

scf(7);
clf();

plot(t, Q_load, "r");
gce().children.thickness = 3;

plot(t, Q_vsg, "b");
gce().children.thickness = 3;

legend("Load Reactive Power", "GFM Reactive Power");

xtitle("Reactive Power Distribution", ...
       "Time (seconds)", "Reactive Power (kVAr)");

xgrid();


// -----------------------------------------------------
// 18. PRINT RESULTS
// -----------------------------------------------------

disp("======================================");
disp("VSG + GFL POWER SYSTEM SIMULATION");
disp("======================================");

disp("Initial frequency (Hz):");
disp(f_bus(1));

disp("Minimum frequency (Hz):");
disp(min(f_bus));

disp("Final frequency (Hz):");
disp(f_bus(N));

disp("Initial voltage (V):");
disp(V_bus_actual(1));

disp("Final voltage (V):");
disp(V_bus_actual(N));

disp("Final GFM power (kW):");
disp(P_vsg(N));

disp("Final GFL power (kW):");
disp(P_gfl(N));

disp("Final load power (kW):");
disp(P_load(N));

disp("Final total generation (kW):");
disp(P_total(N));

disp("======================================");
disp("SIMULATION COMPLETED");
disp("======================================");


// -----------------------------------------------------
// 19. EXPORT VARIABLES
// -----------------------------------------------------

t = t(:);

bus_frequency.time = t;
bus_frequency.values = f_bus(:);

bus_voltage.time = t;
bus_voltage.values = V_bus_actual(:);

bus_phase.time = t;
bus_phase.values = theta_degrees(:);

phase_deviation.time = t;
phase_deviation.values = phase_deviation_degrees(:);

load_power.time = t;
load_power.values = P_load(:);

vsg_power.time = t;
vsg_power.values = P_vsg(:);

gfl_power.time = t;
gfl_power.values = P_gfl(:);

load_current.time = t;
load_current.values = I_load(:);

gfl_current.time = t;
gfl_current.values = I_gfl(:);

disp("Simulation variables exported successfully.");
