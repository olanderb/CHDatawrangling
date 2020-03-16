library(readxl)
library(writexl)

cadre_harmonise_caf_ipc <- read_excel("data/processed/cadre_harmonise_caf_ipc.xlsx")

caf_ipc_old <- read_excel("data/raw/IPC_CAF/adm0_CAF_IPC_reports.xlsx") %>% filter(UseThisPeriod == "Y") %>% 
  mutate(exercise_label = case_when(
  exercise_label == "Septembre - Decembre" ~ "Sep-Dec",
  exercise_label == "January - Mai" ~ "Jan-May",
  exercise_label == "Juin - Aout" ~ "Jun-Aug"),
  reference_label = case_when(
  reference_label == "Septembre - Decembre" ~ "Sep-Dec",
  reference_label == "January - Mai" ~ "Jan-May",
  reference_label == "Juin - Aout" ~ "Jun-Aug"))
  
caf_ipc_old$adm0_gaulcode <- as.character(caf_ipc_old$adm0_gaulcode)

cadre_harmonise_caf_ipc_v2 <- bind_rows(cadre_harmonise_caf_ipc, caf_ipc_old)

write_xlsx(cadre_harmonise_caf_ipc_v2, "data/processed/cadre_harmonise_caf_ipc_v2.xlsx")