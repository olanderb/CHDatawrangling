library(tidyverse)
library(stringr)
library(sf)
library(readxl)
library(writexl)
library(fs)
library(stringdist)
library(googledrive)
library(googlesheets4)

## File template
file_regex <- "^\\w{3}_(mar|nov|jun)\\d{4}_(cur|proj)\\.csv"

##
files <- dir_ls("data/csv", type = "file", recurse = TRUE)

## Check if all files follow the patterns
stopifnot(all(str_detect(basename(files), file_regex)))
files[which(!str_detect(basename(files), file_regex))]

## Remove June
files <- files[!str_detect(files, "jun")]

exercise_code <- function(file) {
  case_when(
    str_detect(file, "nov") ~ 1L,
    str_detect(file, "mar") ~ 2L,
    str_detect(file, "jun") ~ 3L,
    TRUE ~ 0L
  )
}


exercise_label <- function(file) {
  case_when(
    str_detect(file, "nov") ~ "Sep-Dec",
    str_detect(file, "mar") ~ "Jan-May",
    str_detect(file, "jun") ~ "Jun-Aug",
    TRUE ~ ""
  )
}

exercise_year <- function(file)
  as.integer(str_extract(file, "\\d{4}"))

reference_code <- function(file) {
  if_else(str_detect(file, "proj"), if_else(str_detect(file, "nov2014"), 2L, 3L), exercise_code(file))
}

reference_label <- function(file) {
  if_else(str_detect(file, "proj"), if_else(str_detect(file, "nov2014"), "Jan-May", "Jun-Aug"), exercise_label(file))
}

reference_year <- function(file) {
  ex_year <- exercise_year(file)
  ex_code <- exercise_code(file)
  if_else(str_detect(file, "proj") & ex_code == 1L, ex_year + 1L, ex_year)
}


dd <- map(files, function(l) {
  df <- suppressMessages(read_csv(l))
  df$exercise_year <- exercise_year(l)
  df$exercise_code <- exercise_code(l)
  df$reference_year <- reference_year(l)
  df$reference_code <- reference_code(l)
  df$exercise_label <- exercise_label(l)
  df$reference_label <- reference_label(l)
  df$chtype <- if_else(str_detect(l, "proj"), "projected", "current")
  df
})

## Bind all data
df <- bind_rows(dd)

## Remove accent and replace them by non ascii version
df$country <- iconv(str_to_title(df$country), from="UTF-8", to = "ASCII//TRANSLIT")
df$country[str_which(df$country, regex("ivoire", ignore_case = TRUE))] <- "Cote d'Ivoire"
df$region <- iconv(str_to_title(df$region), from="UTF-8",to = "ASCII//TRANSLIT")
df$adm1 <- iconv(str_to_title(df$adm1), from="UTF-8", to = "ASCII//TRANSLIT")
df$adm2 <- iconv(str_to_title(df$adm2), from="UTF-8", to = "ASCII//TRANSLIT")


### Rename columns and pick countries from the Sahel
all <- df %>%
  filter(!is.na(classif)) %>%
  select(adm0_name = country, region, adm1_name = adm1, adm2_name = adm2,
         population = pop, phase_class = classif, phase1:phase35,
         chtype, exercise_code, exercise_label, exercise_year, reference_code, reference_label, reference_year)

## View(all)

## Add geo dictionnary
url <- "https://docs.google.com/spreadsheets/d/1S9OPO-x8YUQbpJ06mrbOUDgZgQroJkbtwPjYM-9Eo6g"
geo_dict <- read_sheet(url)
glimpse(geo_dict)

#fixes adm2_code, region and adm1_code being imported as a list - otherwise get an error
geo_dict <- geo_dict %>% mutate(adm2_code = map(adm2_code, ~ifelse(length(.) == 0, NA_character_, as.character(.))) %>% unlist())
geo_dict <- geo_dict %>% mutate(region = map(region, ~ifelse(length(.) == 0, NA_character_, as.character(.))) %>% unlist())
geo_dict <- geo_dict %>% mutate(adm1_code = map(adm1_code, ~ifelse(length(.) == 0, NA_character_, as.character(.))) %>% unlist())



## Adm0 check
setdiff(unique(geo_dict$adm0_name), unique(all$adm0_name))
setdiff(unique(all$adm0_name), unique(geo_dict$adm0_name))

## Adm0 check
setdiff(unique(all$region), unique(geo_dict$region))
setdiff(unique(geo_dict$region), unique(all$region))

## Adm1 check
setdiff(unique(all$adm1_name), unique(geo_dict$adm1_name))
setdiff(unique(geo_dict$adm1_name), unique(all$adm1_name))

## Adm2 check
setdiff(unique(all$adm2_name), unique(geo_dict$adm2_name))
setdiff(unique(geo_dict$adm2_name), unique(all$adm2_name))



## Inner join with the geo_dict table
all_matched <- left_join(all, geo_dict) %>%
  select(-region, -adm1_name, -adm2_name,
         adm0_name, adm0_gaulcode = adm0_code, adm0_pcod3, adm0_pcod2,
         region = region_namechanged, adm1_name = adm1_namechanged, adm1_gaulcode = adm1_code, adm1_pcod3, adm1_pcod2,
         adm2_name = adm2_namechanged, adm2_gaulcode = adm2_code, adm2_pcod3, adm2_pcod2) %>%
  distinct()


## Check if some admin name
all_non_matched <- distinct(anti_join(all, geo_dict))
View(all_non_matched)

### Reorganise columuns for export
all_matched <- select(all_matched,
                      adm0_name, adm0_gaulcode, adm0_pcod3, adm0_pcod2, region, adm1_name, adm1_gaulcode, adm1_pcod3, adm1_pcod2, adm2_name, adm2_gaulcode, adm2_pcod3, adm2_pcod2, everything())

## Clean names, start with Caps
all_matched <- distinct(all_matched)
all_matched <- mutate_if(all_matched, is.numeric, ~ as.integer(round(.x)))
all_matched$phase_class[all_matched$phase_class == 0] <- NA
all_matched <- distinct(all_matched)

### Save 2014-2018 Sahel/Nigeria + 2017+ for the rest (Coastal Countries)
sahel_countries_pcod3 <- c("BFA", "MLI", "MRT", "NER", "NGA", "SEN", "TCD")
sahel_nigeria <- filter(all_matched,
                        adm0_pcod3 %in% sahel_countries_pcod3)
rest <- filter(all_matched,
               !adm0_pcod3 %in% sahel_countries_pcod3,
               exercise_year >= 2017)
final <- bind_rows(sahel_nigeria, rest)


###
adm0_fiche_comm <- read_excel("data/adm0_fiche_comm.xlsx")
### Make nameng of reference label and exercise label coherent on #

## all_matched %>%
##     group_by(adm0_name, chtype, exercise_year, exercise_code, exercise_label, reference_year, reference_code, reference_label) %>%
##     summarise_at(vars(phase1:phase5), sum, na.rm = TRUE) %>%
##     ungroup() %>%
##     filter(exercise_year == 2018, exercise_label == "Sep-Dec", adm0_name == "Mali") %>%
##     View()

df_orig <- all_matched %>%
  group_by(adm0_name, chtype, exercise_year, exercise_code, exercise_label, reference_year, reference_code, reference_label) %>%
  summarise(tot3tp5 = sum(phase35, na.rm = TRUE)) %>%
  mutate(tot3tp5_orig = round(tot3tp5)) %>%
  select(-tot3tp5) %>%
  ungroup()


###
df_fiche <- adm0_fiche_comm %>%
  group_by(adm0_name, chtype, exercise_year, exercise_code, reference_year, reference_code) %>%
  summarise(tot3tp5 = sum(phase35, na.rm = TRUE)) %>%
  mutate(tot3tp5_fiche = round(tot3tp5)) %>%
  select(-tot3tp5) %>%
  ungroup() %>%
  mutate(chtype = tolower(chtype))

compar_df <- left_join(df_orig, df_fiche) %>%
  select(-reference_code, -exercise_code)

### Add percentage of discrepancy
compar_df %>%
  mutate(diff_abs = abs(tot3tp5_orig - tot3tp5_fiche),
         diff_perc = round(100 * (diff_abs / tot3tp5_orig), 2)) %>%
  View()


compar_df %>%
  mutate(diff_abs = abs(tot3tp5_orig - tot3tp5_fiche),
         diff_perc = round(100 * (diff_abs / tot3tp5_orig), 2)) %>%
  write_xlsx("data/processed/compar_fiche.xlsx")

final %>%
  select(-matches("district|adm3")) %>%
  write_xlsx("data/processed/cadre_harmonise.xlsx")