tar_target(ebola_data_raw, {
  read.csv(ebola_data_file, stringsAsFactors = FALSE)
})