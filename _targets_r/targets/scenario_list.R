# Create a list of scenarios for branching
tar_target(
  scenario_list,
  split(scenarios, scenarios$scenario_id)
)
