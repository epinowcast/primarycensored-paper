tar_target(ebola_data_raw, {
  # Load Fang et al. 2016 Sierra Leone Ebola data
  read.csv(
    "data/raw/ebola_sierra_leone_2014_2016.csv",
    stringsAsFactors = FALSE
  )
})
