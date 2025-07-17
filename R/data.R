# script to create dataset used for JWHBS profiles
#---- Setup ----
#### Packages ####
library(phiTools)

#---- Geography ----
rbwm_code <- "E06000040"
se_code <- "E12000008"
eng_code <- "E92000001"

#### Postcodes ####
# RBWM postcodes
rbwm_pcodes <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/References/Geography/ONS Open Geography Portal/NSPL/processed_data/nspl_rbwm_postcodes.Rds"))

#### Lookups ####
# england and wales LSOA to ward to lad
lsoa_ward_lad <- read.csv(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/References/Geography/ONS Open Geography Portal/Lookups/LSOA to Ward to LAD/LSOA_(2021)_to_Electoral_Ward_(2024)_to_LAD_(2024)_Best_Fit_Lookup_in_EW.csv"))

# RBWM lsoas
i <- lsoa_ward_lad$LAD24CD == rbwm_code
rbwm_lsoas <- lsoa_ward_lad$LSOA21CD[i]

# rbwm wards
i <- lsoa_ward_lad$LAD24CD == rbwm_code
rbwm_wards <- unique(lsoa_ward_lad$WD24CD[i])

# England and Wales MSOA to ward to LAD
msoa_ward_lad <- read.csv(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/References/Geography/ONS Open Geography Portal/Lookups/MSOA to Ward to LAD/MSOA_(2021)_to_Ward_(2024)_to_LAD_(2024)_Best_Fit_Lookup_in_EW.csv"))

# RBWM MSOAs
i <- msoa_ward_lad$LAD24CD == rbwm_code
rbwm_msoas <- msoa_ward_lad$MSOA21CD[i]

# 2011 LSOAs to ward
lsoa_ward_lad_2011 <- read.csv(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/References/Geography/ONS Open Geography Portal/Lookups/LSOA to Ward to LAD/LSOA11_WD20_LAD20_EW_LU_v2.csv"))

# RBWM GPs
epraccur <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/NHS Digital/GP and GP practice related data/processed_data/epraccur.Rds"))

rbwm_gp <- merge(x = epraccur, y = rbwm_pcodes, by = "pcdNoSpaces")
rbwm_gp <- rbwm_gp[, c("Organisation Code", "oseast1m", "osnrth1m")]
rbwm_gp_codes <- rbwm_gp$`Organisation Code`

#---- Prerequisite Data ----
# Create empty data frame for ward profile dataset
dataset <- data.frame(IndicatorID = NA, IndicatorName = NA,
                      AreaCode = NA, AreaName = NA, AreaType = NA,
                      Timeperiod = NA, GroupingVariable = NA, Group = NA, 
                      Sex = NA, Age = NA, Count = NA, Denominator = NA,
                      Value = NA, LowerCI95Limit = NA, UpperCI95Limit = NA, 
                      LowerCI99.8Limit = NA, UpperCI99.8Limit = NA,
                      QuantileValue = NA, Compared = NA, Quintile = NA,
                      Colour = NA, oseast1m = NA, osnrth1m = NA)
dataset <- dataset[FALSE, ]

# initialise empty list to story all factor levels per indicator
factor_levels_list <- list()

#### Population estimates ####
# ONS LA pop estimates
pop_la <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/ONS/nomis/Population/Population estimates/Local authority/processed_data/ons_la_pop.Rds"))

# ONS lsoa pop estimates
pop_lsoa <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/ONS/nomis/Population/Population estimates/lsoa/processed data/ons-lsoa-pop.Rds"))

#### Fingertips data ####
fingertips_gp <- data_fingertips_gp()

# merge GP postcode centroid coords
fingertips_gp <- merge(x = fingertips_gp, y = rbwm_gp, by.x = "AreaCode",
                       by.y = "Organisation Code", all.x = TRUE)

fingertips_msoa <- data_fingertips_msoa()

#---- Data by slides ----
#### Population ####
x <- pop_la

# only need RBWM, South East and England
x <- x[x$AreaCode %in% c(rbwm_code, se_code, eng_code), ]

# rename pop to Count and then use count for denominator too
colnames(x)[colnames(x) == "Pop"] <- "Count"
x$Denominator <- x$Count

# add indicator name and ID
x$IndicatorName <- "LA population estimates"
x$IndicatorID <- abbreviate(x$IndicatorName)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deprivation ####
# LSOA deprivation and pop for RBWM LSOAs
x <- data_deprivation_pop(population = pop_lsoa)

# rename domain, decile and pop
colnames(x) <- c("AreaCode", "GroupingVariable", "Group", "Count")
x$Denominator <- x$Count

x$IndicatorName <- "IMD (Deprivation)"
x$IndicatorID <- "IMD"
x$AreaName <- x$AreaCode
x$AreaType <- "LSOA"
x$Sex <- "persons"
x$Age <- "All ages"

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = "IMD", 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### MMR ####
ind_ID <- 92781

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# max time period is only for England atm 2025-06-18
i <- x$Timeperiod <= max(x$Timeperiod[x$AreaCode %in% rbwm_gp_codes])
x <- x[i, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Combined dtap ipv hib ####
ind_ID <- 92782

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# max time period is only for England atm 2025-06-18
i <- x$Timeperiod <= max(x$Timeperiod[x$AreaCode %in% rbwm_gp_codes])
x <- x[i, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Child admissions ####
ind_ID <- 93115

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Injury admissions under 5 ####
ind_ID <- 93114

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Injury admissions under 15 ####
ind_ID <- 93219

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Injury admissions under 15 to 24 ####
ind_ID <- 93224

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Reception obesity ####
ind_ID <- 93105

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Reception overweight ####
ind_ID <- 93106

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Year 6 obesity ####
ind_ID <- 93107

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Year 6 overweight ####
ind_ID <- 93108

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Asthma ####
ind_ID <- 90933

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Life expectancy females ####
ind_ID <- 93283
ind_sex <- "Female"

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID & 
                       fingertips_msoa$Sex == ind_sex, ]

# create rag comparison
x <- create_comp_rag(data = x, low_is_good = FALSE)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Life expectancy males ####
ind_ID <- 93283
ind_sex <- "Male"

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID & 
                       fingertips_msoa$Sex == ind_sex, ]

# create rag comparison
x <- create_comp_rag(data = x, low_is_good = FALSE)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Unemployment ####
ind_ID <- 93097

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Long-term unemployment ####
ind_ID <- 93098

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Learning disability ####
ind_ID <- 200

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Hypertension ####
ind_ID <- 219

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Epilepsy ####
ind_ID <- 224

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Diabetes ####
ind_ID <- 241

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: COPD ####
ind_ID <- 253

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Heart failure ####
ind_ID <- 262

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: CHD ####
ind_ID <- 273

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Cancer ####
ind_ID <- 276

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Atrial Fibrillation ####
ind_ID <- 280

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Mental health ####
ind_ID <- 90581

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Depression ####
ind_ID <- 90646

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Smoking ####
ind_ID <- 91280

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Obesity ####
ind_ID <- 94136

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Cervical screening 25 to 49 ####
ind_ID <- 93725

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Cervical screening 50 to 64 ####
ind_ID <- 93726

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### GP caring responsibility ####
ind_ID <- 352

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create quintiles
x <- create_comp_quintiles(data = x, low_is_good = TRUE)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions ####
ind_ID <- 93227

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions CHD ####
ind_ID <- 93229

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions stroke ####
ind_ID <- 93231

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions heart attack ####
ind_ID <- 93232

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions COPD ####
ind_ID <- 93233

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)
# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency admissions self harm ####
ind_ID <- 93239

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Stroke ####
ind_ID <- 212

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Dementia ####
ind_ID <- 247

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: CKD ####
ind_ID <- 258

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Osteoporosis ####
ind_ID <- 90443

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### QOF: Rheumatoid arthritis ####
ind_ID <- 91269

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Bowel cancer screening ####
ind_ID <- 92600

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Breast cancer screening ####
ind_ID <- 94063

x <- fingertips_gp[fingertips_gp$IndicatorID == ind_ID, ]

# create higher and lower comparison (BOB)
x <- create_comp_bob(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Emergency hospital admissions for hip fracture ####
ind_ID <- 93241

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths from all causes ####
ind_ID <- 93250

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths under 75 ####
ind_ID <- 93252

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths preventable ####
ind_ID <- 93480

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths cancer ####
ind_ID <- 93253

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths cancer under 75 ####
ind_ID <- 93254

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths circulatory disease ####
ind_ID <- 93255

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths circulatory disease under 75 ####
ind_ID <- 93256

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths CHD ####
ind_ID <- 93257

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths Stroke ####
ind_ID <- 93259

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Deaths respiratory ####
ind_ID <- 93260

x <- fingertips_msoa[fingertips_msoa$IndicatorID == ind_ID, ]

# create rag comparison
x <- create_comp_rag(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Fuel poverty ####
x <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/gov.uk/Sub-regional fuel poverty data/processed_data/fuel_poverty_LILEE.Rds"))

# aggregate to ward using lsoa to ward best fit
ward <- merge(x = x, y = lsoa_ward_lad, by.x = "AreaCode", by.y = "LSOA21CD")

ward <- aggregate(cbind(Count, Denominator) ~ WD24CD + WD24NM + Timeperiod,
                  data = ward, FUN = sum)
colnames(ward) <- c("AreaCode", "AreaName", "Timeperiod", "Count", "Denominator")
ward$AreaType <- "Ward"
ward$Value <- ward$Count / ward$Denominator * 100

x <- rbind(x, ward)

# create comparison quintiles
x <- create_comp_quintiles(data = x)

x$IndicatorName <- "Fuel Poverty"
x$IndicatorID <- abbreviate(x$IndicatorName)
ind_ID <- unique(x$IndicatorID)
x$Sex <- "persons"
x$Age <- "All ages"

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Access gardenspace ####
x <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/ONS/Access to gardens and public green space in Great Britain/Gardens/processed_data/private_outdoor_space.Rds"))

# create comparison quintiles
x <- create_comp_quintiles(data = x)

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

x$IndicatorName <- "Access to gardenspace"
x$IndicatorID <- abbreviate(x$IndicatorName, minlength = 10)
ind_id <- unique(x$IndicatorID)
x$Sex <- "persons"
x$Age <- "All ages"

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Access to greenspace ####
x <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/ONS/Access to gardens and public green space in Great Britain/Public greenspace/processed_data/access_to_greenspace.Rds"))

# create ward level aggregate from LSOA best fit lookup
ward <- x[x$AreaType == "LSOA", ]
ward <- merge(x = ward, y = lsoa_ward_lad_2011, by.x = "AreaCode",
              by.y = "LSOA11CD", all.x = TRUE)

ward <- aggregate(cbind(Count, Denominator) ~ WD20CD + WD20NM + Timeperiod,
                  data = ward, FUN = sum)
colnames(ward)[colnames(ward) == "WD20CD"] <- "AreaCode"
colnames(ward)[colnames(ward) == "WD20NM"] <- "AreaName"
ward$AreaType <- "Ward"

ward$Value <- ward$Count / ward$Denominator * 100

x <- rbind(x, ward)

x <- create_comp_quintiles(data = x, low_is_good = FALSE)

x$IndicatorName <- "Access to greenspace"
x$IndicatorID <- abbreviate(x$IndicatorName, minlength = 10)
ind_ID <- unique(x$IndicatorID)
x$Sex <- "persons"
x$Age <- "All ages"

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#### Access to secondary school ####
x <- readRDS(paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/gov.uk/Journey time statistics data tables (JTS)/lower super output area (JTS05)/JTS0503/processed_data/secondary_school_30min_travel.Rds"))

ward <- merge(x = x, y = lsoa_ward_lad, by.x = "AreaCode", by.y = "LSOA21CD", 
              all.x = TRUE)

ward <- aggregate(cbind(Count, Denominator) ~ WD24CD + WD24NM, data = ward,
                  FUN = sum)
colnames(ward) <- c("AreaCode", "AreaName", "Count", "Denominator")
ward$AreaType <- "Ward"

ward$Value <- ward$Count / ward$Denominator * 100

x <- rbind(x, ward)

x$Timeperiod <- 2019

x$Count <- round(x$Count)

x$LowerCI95Limit <- PHEindicatormethods:::wilson_lower(x = x$Count, n = x$Denominator) * 100
x$LowerCI99.8Limit <- NA
x$UpperCI95Limit <- PHEindicatormethods:::wilson_upper(x = x$Count, n = x$Denominator) * 100
x$UpperCI99.8Limit <- NA

x <- create_comp_rag(data = x, low_is_good = FALSE)

x$IndicatorName <- "Access to secondary school"
x$IndicatorID <- abbreviate(x$IndicatorName, minlength = 10)
ind_ID <- unique(x$IndicatorID)
x$Sex <- "persons"
x$Age <- "11-15"

# pull out and store factor levels
factor_levels_list <- store_factor_levels(data = x, indicator_id = ind_ID, 
                                          master_list = factor_levels_list)

# add remaining dummy cols for rbind
x <- add_dummy_cols(data = x, stand_data_frame = dataset)

# bind to master dataframe but maintain column order
x <- x[, names(dataset), drop = FALSE]
dataset <- rbind(x, dataset)

#---- Save dataset ----
# list factor levels with dataset and store in single Rds file
data_bundle <- list(factor_levels = factor_levels_list, dataset = dataset)
saveRDS(data_bundle, paste0("C:/Users/", Sys.getenv("username"), "/OneDrive - Royal Borough of Windsor and Maidenhead/PHI - Data and Analytics/Datasets/Profiles/JHWBS profile/JHWBS_profiles_data_bundle_", Sys.Date()))
