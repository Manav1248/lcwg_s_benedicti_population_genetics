library(tidyverse)

setwd("MODIFY AS NEEDED")
scores <- read.csv("QualityScores_SNPVCF_LowQualSitesFiltered.table", header = TRUE, sep = "\t")

#Below: don't really need to plot DP as it was not filtered during the low-quality
#filtration step. I commented this out but the user may choose to run it if they so please.
#DP
#png("SNPVCF_DP_Density_LowQualSitesFiltered.png", width=1600, height=1200)
#ggplot(scores, aes(x = DP)) + geom_density()
#dev.off()

#QD
png("SNPVCF_QD_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = QD)) + geom_density() + coord_cartesian(xlim = c(0,50), ylim = c(0, 0.15))
dev.off()

#FS
png("SNPVCF_FS_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = FS)) + geom_density() + coord_cartesian(xlim = c(0,50))
dev.off()

#FS Zoomed In
png("SNPVCF_FS_Density_LowQualSitesFiltered_Zoomed_In.png", width=1600, height=1200)
ggplot(scores, aes (x = FS)) + geom_density() + coord_cartesian(xlim = c(0,20), ylim = c(0,4))
dev.off()

#MQ
png("SNPVCF_MQ_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = MQ)) + geom_density() + coord_cartesian(xlim = c(35,65), ylim = c(0,10))
dev.off()

#MQRankSum
png("SNPVCF_MQRankSum_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = MQRankSum)) + geom_density() + coord_cartesian(xlim = c(-15,15), ylim = c(0,10))
dev.off()

#MQRankSum Zoomed In
png("SNPVCF_MQRankSum_Density_LowQualSitesFiltered_Zoomed_In.png", width=1600, height=1200)
ggplot(scores, aes (x = MQRankSum)) + geom_density() + coord_cartesian(xlim = c(-5,5), ylim = c(0,10))
dev.off()

#SOR
png("SNPVCF_SOR_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = SOR)) + geom_density() + coord_cartesian(xlim = c(0,5), ylim = c(0,8))
dev.off()

#SOR Zoomed In
png("SNPVCF_SOR_Density_LowQualSitesFiltered_Zoomed_In.png", width=1600, height=1200)
ggplot(scores, aes (x = SOR)) + geom_density() + coord_cartesian(xlim = c(0,2), ylim = c(0,8))
dev.off()

#ReadPosRankSum
png("SNPVCF_ReadPosRankSum_Density_LowQualSitesFiltered.png", width=1600, height=1200)
ggplot(scores, aes (x = ReadPosRankSum)) + geom_density() + coord_cartesian(xlim = c(-5,5), ylim = c(0,3))
dev.off()

