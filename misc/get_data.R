library(rhdx)
library(tidyverse)
library(sf)

set_rhdx_config("prod")
ds <- read_resource("4b2bfec2-2f26-4354-bfe0-801f161c23fb")
ds

download(ds, folder = "./", filename = "test.zip")
ff <- read_sf("NER_adm02_feb2018.shp")
View(ff)
View(df)

ff$adm_02
ff2 <- filter(df, country == "Niger")
x <- iconv(str_to_title(ff$adm_02), to = "ASCII//TRANSLIT")
y <-iconv(str_to_title(ff2$adm2), to = "ASCII//TRANSLIT")

x <- unique(ff$adm_02)
y <- unique(ff2$adm2)

length(x)
length(y)
setdiff(x, y)
setdiff(y, x)
