library(tidyverse)
library(stringr)
library(readxl)
library(writexl)
library(validate)

### Check that phase35 is the sum of phase3:phase5
ch <- read_xlsx("../data/processed/cadre_harmonise.xlsx")
glimpse(ch)

ch %>%
    check_that(phase35 >= 0)

ch %>%
    mutate(x = phase3 + phase4 + phase5) %>%
    pull(x)

ch %>%
    check_that(phase35 == phase3 + phase4 + phase5) %>%
    summary()

ch %>%
    check_that(abs(phase35 - (phase3 + phase4 + phase5)) < 100) %>%
    summary()

id <- ch %>%
    check_that(abs(phase35 - (phase3 + phase4 + phase5)) < 100) %>%
    aggregate(by = "record")
glimpse(id)
sum(id$nfail)


###
fiche_adm0 <- read_excel("../data/Adm0FichedeCommunication.xlsx")
### Make nameng of reference label and exercise label coherent on #

df_orig <- ch %>%
    group_by(adm0_name, chtype, exercise_year, exercise_code, exercise_label, reference_year, reference_code, reference_label) %>%
    summarise(tot3tp5 = sum(phase35, na.rm = TRUE)) %>%
    mutate(tot3tp5_orig = round(tot3tp5)) %>%
    select(-tot3tp5) %>%
    ungroup()

###
df_fiche <- fiche_adm0 %>%
    group_by(adm0_name = Adm0_name, chtype = CHType, exercise_year = ExerciseYear, exercise_code = ExercisePeriodCode, reference_year = ReferenceYear, reference_code = ReferencePeriodCode) %>%
    summarise(tot3tp5 = sum(TotalPhase3to5, na.rm = TRUE)) %>%
    mutate(tot3tp5_fiche = round(tot3tp5)) %>%
    select(-tot3tp5) %>%
    ungroup() %>%
    mutate(chtype = tolower(chtype))

compar_df <- left_join(df_orig, df_fiche) %>%
    select(-reference_code, -exercise_code) %>%
    mutate(diff_abs = abs(tot3tp5_orig - tot3tp5_fiche),
           diff_perc = round(100 * (diff_abs / tot3tp5_orig), 2))
compar_df$diff_perc

compar_df %>%
    check_that(diff_perc <= 5) %>%
    summary()

compar_df %>%
    check_that(diff_perc <= 5) %>%
    aggregate(by = "record") -> id

glimpse(id)

View(compar_df[as.logical(id$nfail), ])
