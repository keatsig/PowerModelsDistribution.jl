using Revise, PowerModelsDistribution, Ipopt, SCS
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer,"print_level"=>0)
scs_solver = optimizer_with_attributes(SCS.Optimizer,"verbose"=>0)
silence!()

case_name = "C:/Users/358598/.julia/dev/PowerModelsDistribution/test/data/opendss/IEEE13_RegControl.dss"

case_name = "C:/Users/358598/Desktop/13Bus/IEEE13Nodeckt.dss"
case_name = "C:/Users/358598/.julia/dev/PowerModelsDistribution/test/data/opendss/trans_3w_center_tap.dss"
# dss = parse_dss(case_name)
case_name = "C:/Users/358598/Downloads/Repositories/p1rhs0_1247--p1rdt6163/Master.dss"
case_name = "C:/Users/358598/Downloads/Repositories/powersystemslibrary-main/distribution/PNNL/case_r1_1247_3.dss"
case_name = "C:/Users/358598/Downloads/Repositories/DynaGrid_Wildfire/Data/Grid_Data/p17uhs_13/p17uhs13_1247--p17udt1222/Master.dss"

eng = parse_file(case_name)
# eng = parse_file(case_name; transformations=[remove_line_limits!, remove_transformer_limits!])
apply_voltage_bounds!(eng; vm_lb=0.90, vm_ub=1.10)

math = transform_data_model(eng)
# pm = instantiate_mc_model(math, LPUBFDiagPowerModel, build_mc_opf)
result = solve_mc_opf(eng, SOCNLPUBFPowerModel, ipopt_solver; solution_processors=[sol_data_model!], make_si=false)
result = solve_mc_opf(eng, SOCConicUBFPowerModel, scs_solver; solution_processors=[sol_data_model!], make_si=false)

for (idx,data) in get(math,"branch",Dict{String,Any}())
    @show data["f_bus"]
end

for (idx,data) in get(math,"branch",Dict{String,Any}())
    if data["f_bus"] == 71
        @show idx
    end
end
[idx for (idx,data) in get(math,"branch",Dict{String,Any}()) if data["f_bus"] == 71][1]

isapprox(sum(result["solution"]["voltage_source"]["source"]["pg"]), 40.26874; atol=1)
isapprox(sum(result["solution"]["voltage_source"]["source"]["qg"]),  17.1721; atol=1)

vbase = eng["settings"]["vbases_default"]["sourcebus"]
all(isapprox.(result["solution"]["bus"]["primary"]["vm"] ./ vbase, [0.98514,0.98945,0.98929]; atol=5e-2))
all(isapprox.(result["solution"]["bus"]["loadbus"]["vm"] ./ vbase, [0.97007,0.97949,0.97916]; atol=5e-2))


x=[idx for (idx,data) in get(eng,"solar",Dict{String,Any}()) if data["configuration"]==DELTA];

eng = parse_file("C:/Users/358598/.julia/dev/PowerModelsONM/test/data/ieee13_feeder.dss")
eng["settings"]["sbase_default"] = 100
eng["switch_close_actions_ub"] = Inf
apply_voltage_bounds!(eng)
math = transform_data_model(eng)
result = solve_mc_opf(eng, LPUBFDiagPowerModel, ipopt_solver)
