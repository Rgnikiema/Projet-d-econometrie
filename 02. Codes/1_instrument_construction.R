##Clearing the environment
rm(list=ls())


#Libraries packages usful for the analysis
library("haven")
library("tidyverse")
library("igraph")

#Seting the environment for the analisis
Paths <- c("C:/Users/richm/Dropbox/Projet d'économétrie",
           "C:/Users/frans/Dropbox/Projet d'économétrie",
           "C:/Users/richa/Dropbox/Projet d'économétrie",
           "/Users/rgnikiea/Dropbox/Projet d'économétrie")

names(Paths) <- c("richm", "frans","richa", "rgnikiea")
setwd(Paths[Sys.info()[["user"]]])
Sys.info()[["user"]]

dist_cepii <- read_dta("02. Data/Raw data/lang_dis.dta") 

countries <- unique(dist_cepii$iso_o)

M1_lang <- matrix(nrow = 192, ncol = 192, dimnames = list(countries,
                                                     countries))
for (country_o in countries){
  
  for (country_d in countries){
    
    if (country_o == country_d) {
      
      M1_lang[country_o, country_d] <- 1
      
  } else {
    
    lang <- dist_cepii[dist_cepii$iso_o == country_o & dist_cepii$iso_d ==country_d, "prox1"]$prox1
    M1_lang[country_o, country_d] = lang
    }
  }
}

G_lang <- graph.adjacency(M2_lang, weighted=TRUE) # , mode="directed"

#https://igraph.org/r/html/latest/eigen_centrality.html

centrality_score_lang <- eigen_centrality(G_lang)["vector"] %>%
  data.frame()

iso <- row.names(centrality_score_lang)

data <- eigen_centrality(G_lang)["vector"] %>%
  data.frame(row.names = NULL) %>% mutate(iso=iso)


#Saving the data
save(data,      file = "02. Data/Cleaned data/centrality_data.rda")
write.csv(data,        "02. Data/Cleaned data/centrality_data.csv")
write_dta(data, path = "02. Data/Cleaned data/centrality_data.dta")

