library(tidyverse)
library(readxl)

###
ch <- read_excel("cadre_harmonise_draft_Pcodrevised.xlsx")
glimpse(ch)
pcode <- ch %>%
    select(adm0_name, adm0_code, adm0_pcod3, adm0_pcod2 = adminPcod0,
           adm1_name, adm1_code = adm1_gaulcode, adm1_pcod3, adm1_pcod2 = adminPcod1,
           adm2_name, adm2_code = adm2_gaulcode, adm2_pcod3, adm2_pcod2 = adminPcod2) %>%
    distinct()

pcode
write_csv(pcode, "pcode_iso2.csv")
