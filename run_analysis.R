##Load dependencies of the script
packages <- c("qdap", "plyr", "knitr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
lapply(packages, library, character.only=TRUE)

##Section 1: Download and Unzip the Project Data
##

##check to see if a project directory exists
##create the directory if it does not exist
if(!file.exists("~/GettingDataCourseProject/")){
  dir.create("~/GettingDataCourseProject")
}

##set working directory to project directory
setwd("~/GettingDataCourseProject/")

##check to see if a project data directory exists
##create the directory if it does not exist
if(!file.exists("./data")){
  dir.create("./data")
}

##download the UCI HAR Dataset if not alread in ./data/
if(!file.exists("./data/UCIHARDataset.zip")){
  dataUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(dataUrl, destfile="./data/UCIHARDataset.zip", method="auto")  
}

##unzip the data downloaded in "UCIHARDataset.zip"
unzip(zipfile="./data/UCIHARDataset.zip", exdir="./data")

##Section 2: Read data into R
##
dataDirectory <- file.path("./data/UCI HAR Dataset/")

##read in data from "test" folder
testSubjects <- read.table(file.path(dataDirectory,"test","subject_test.txt"), header=FALSE)
testFeaturesX <- read.table(file.path(dataDirectory, "test", "X_test.txt"), header=FALSE)
testActivitiesY <- read.table(file.path(dataDirectory, "test", "y_test.txt"), header=FALSE)

##read in data from training ("train") folder
trainingSubjects <- read.table(file.path(dataDirectory,"train","subject_train.txt"), header=FALSE)
trainingFeaturesX <- read.table(file.path(dataDirectory, "train", "X_train.txt"), header=FALSE)
trainingActivitiesY <- read.table(file.path(dataDirectory, "train", "y_train.txt"), header=FALSE)

##Section 3: Merge Data into one Data Set ("mergedProjectData")
##

##combine "Subjects" data and assign column name "subjectId"
mergedSubjectData <- rbind(testSubjects, trainingSubjects)
colnames(mergedSubjectData) <- "subjectId"

##combine "Activity" data and assign column name "activityId"
mergedActivitiesData <- rbind(testActivitiesY, trainingActivitiesY)
names(mergedActivitiesData) <- "activityId"

##combine "Features" data and assign column names
mergedFeaturesData <- rbind(testFeaturesX, trainingFeaturesX)
features <- read.table(file.path(dataDirectory, "features.txt"), header=FALSE)
colnames(mergedFeaturesData) <- features[,2]

##get rid of Feature columns that do not include "mean" or "std"
featuresToKeep <- c("mean", "std")
mergedFeaturesData <- mergedFeaturesData[, which(grepl(paste(featuresToKeep, collapse="|"), colnames(mergedFeaturesData))),]

##combine Subject, Activity and Features data into mergedProjectData
mergedProjectData <- cbind(mergedSubjectData, mergedActivitiesData, mergedFeaturesData)

##Section 4: Tidy up data
##

##Assign descriptive names to Activities in mergedProjectData
##Descriptive Activity names are given in column 2 of "activity_labels.txt" 
activities <- read.table(file.path(dataDirectory, "activity_labels.txt"), header=FALSE)
colnames(activities) <- c("activityId", "activityName")
mergedProjectData <- merge(mergedProjectData, activities, by="activityId", all.x=TRUE)

##Column names have to be made more descriptive
##"-" will be replaced by ""
##"()" will be replaced by ""
##prefix "f" will be replaced by prefix "frequency"
##prefix "t" will be replaced by prefix "time"
##Letters "Acc" will be replaced by Accelerometer
##Letters "BodyBody" will be replaced by Body
##Letters "Gyro" will be replaced by Gyroscope
##Letters "Mag" will be replaced by Magnitude
textToReplace <- c("-","()", "^f", "^t","Acc", "BodyBody", "Gyro", "Mag")
replacementText <- c("","", "frequency", "time","Accelerometer", "Body", "Gyroscope", "Magnitude")
names(mergedProjectData) <- mgsub(textToReplace, replacementText, names(mergedProjectData), fixed=FALSE)

##create tidy data set with average of each feature by subject and activity
tidyData <- aggregate(. ~subjectId + activityName, mergedProjectData, mean)
tidyData <- tidyData[order(tidyData$subjectId, tidyData$activityName),]

##write the tidy data to an external file
write.table(tidyData, file=file.path(dataDirectory, "tidyData.txt"), row.names=FALSE)
