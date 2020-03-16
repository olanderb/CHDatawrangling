library(tidyverse)
library(readxl)

tmp <- read_xlsx("wca_wfp_adm2_code_join_20180523newNiger.xlsx")
names(tmp)

tmp <- select(tmp,
              adm0_name = admin0Name,
              adm1_name = adm1_name,
              adm1_name,
              adm1_code,
              adm1_pcod3 = adm1Pcod3,
              adm2_name,
              adm2_code,
              adm2_pcod3 = adm2Pcod3) %>%
    mutate(adm1_namechanged = adm1_name,
           adm2_namechanged = adm2_name)

adm0 <- read.csv("adm0.csv")

tmp <- left_join(tmp, adm0)
View(tmp)

tmp <- select(tmp,
       adm0_name,
       adm1_name, adm1_namechanged, adm1_code, adm1_pcod3,
       adm2_name, adm2_namechanged, adm2_code, adm2_pcod3,
       adm0_code,
       adm0_pcod3)

write_csv(tmp, "tmp_adm2.csv")

filter(tmp, adm0_name == "Guinea-Bissau") %>%
    select(
       adm0_name,
       adm1_name, adm1_namechanged, adm1_code, adm1_pcod3,
       adm0_code,
       adm0_pcod3) %>%
    distinct() %>%
    write_csv("gnb.csv")





tmp <- read_xlsx("wca_wfp_adm1_code_join_20180523.xlsx")
names(tmp)

tmp <- select(tmp,
              adm0_name = admin0Name,
              adm1_name = adm1_name,
              adm1_name,
              adm1_code,
              adm1_pcod3 = adm1Pcod3) %>%
    mutate(adm1_namechanged = adm1_name)

adm0 <- read.csv("adm0.csv")

tmp <- left_join(tmp, adm0)
View(tmp)

tmp <- select(tmp,
       adm0_name,
       adm1_name, adm1_namechanged, adm1_code, adm1_pcod3,
       adm0_code,
       adm0_pcod3)

write_csv(tmp, "tmp_adm1.csv")

filter(tmp, adm0_name == "Guinea-Bissau") %>%
    select(
       adm0_name,
       adm1_name, adm1_namechanged, adm1_code, adm1_pcod3,
       adm0_code,
       adm0_pcod3) %>%
    distinct() %>%
    write_csv("gnb.csv")

