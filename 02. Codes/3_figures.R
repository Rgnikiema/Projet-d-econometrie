##Clearing the environment
rm(list=ls())


#Libraries packages usful for the analysis
library("haven")
library("tidyverse")
library("igraph")
library(hrbrthemes) ## theme(s) I like
library(stargazer)
library("Hmisc")

#Seting the environment for the analisis
Paths <- c("C:/Users/richm/Dropbox/Projet d'économétrie",
           "C:/Users/frans/Dropbox/Projet d'économétrie",
           "C:/Users/richa/Dropbox/Projet d'économétrie",
           "/Users/rgnikiea/Dropbox/Projet d'économétrie")

names(Paths) <- c("richm", "frans","richa", "rgnikiea")
setwd(Paths[Sys.info()[["user"]]])
Sys.info()[["user"]]

data <- read_dta("02. Data/Cleaned data/FinalDatabase.dta")

names(data)


ggplot(data) + geom_line(aes(x = year, y = remit_year/1000000000))+
  ylab("Transfert des migrants (Milliards USD)")+
  xlab("Années")

ggsave(filename = "04. Results/Figures/remit_evolution.png")

ggplot(data) + geom_histogram(aes(x = remitofgdp,  y=..density..), colour="black", fill="grey")+
  geom_density(aes(remitofgdp), alpha=1)+
  ylab("Densité")+
  xlab("Transfert des migrants (% PIB)")

ggsave(filename = "04. Results/Figures/dist_remit.png")


ggplot(data) + geom_histogram(aes(x = credit_priv,  y=..density..), colour="black", fill="grey")+
  geom_density(aes(credit_priv), alpha=1)+
  ylab("Densité")+
  xlab("Crédit privé (% PIB)")

ggsave(filename = "04. Results/Figures/dist_credit.png")
