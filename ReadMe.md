# GetData-013 Course Project ReadMe
Jawad Habib  
Tuesday, April 21, 2015  

This R markdown describes how the run_analysis.R script is implemented.

#Requirements of the Course Project
The Course Project states the following requirements (copied from the project assignment page).

"Here are the data for the project: 
https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 

* You should create one R script called run_analysis.R that does the following. 
* Merges the training and the test sets to create one data set.
* Extracts only the measurements on the mean and standard deviation for each measurement. 
* Uses descriptive activity names to name the activities in the data set
* Appropriately labels the data set with descriptive variable names. 
* From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject."

#Overview of the run_analysis.R Script
The run_analysis script is divided into six sections, Section 0 through Section 5. Each section is intended to perform a specific function as described below.  
* Section 0 - Load dependencies of the script  
* Section 1 - Download and Unzip the Project Data  
* Section 2 - Read data into R  
* Section 3 - Merge Data into one Data Set  
* Section 4 - Tidy up data  
* Section 5 - Output the tidyData to text file  

#Detailed description of the run_analysis script
The following sections provide  detailed description of how the script is implemented.

##Section 0: Load dependencies of the script
The script relies on **qdap** and **plyr** packages. We first check if the packages are installed in the user's environment. If they are not installed, we use the **install.packages** function to install them and then use **lapply** and **library** to load the packages. This step ensures that our script will function as intended on user machines.


```r
packages <- c("qdap", "plyr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
lapply(packages, library, character.only=TRUE)
```

```
## Loading required package: ggplot2
## Loading required package: qdapDictionaries
## Loading required package: qdapRegex
## 
## Attaching package: 'qdapRegex'
## 
## The following object is masked from 'package:ggplot2':
## 
##     %+%
## 
## Loading required package: qdapTools
## Loading required package: RColorBrewer
## 
## Attaching package: 'qdap'
## 
## The following object is masked from 'package:base':
## 
##     Filter
## 
## 
## Attaching package: 'plyr'
## 
## The following object is masked from 'package:qdapTools':
## 
##     id
```

```
## [[1]]
##  [1] "qdap"             "RColorBrewer"     "qdapTools"       
##  [4] "qdapRegex"        "qdapDictionaries" "ggplot2"         
##  [7] "stats"            "graphics"         "grDevices"       
## [10] "utils"            "datasets"         "methods"         
## [13] "base"            
## 
## [[2]]
##  [1] "plyr"             "qdap"             "RColorBrewer"    
##  [4] "qdapTools"        "qdapRegex"        "qdapDictionaries"
##  [7] "ggplot2"          "stats"            "graphics"        
## [10] "grDevices"        "utils"            "datasets"        
## [13] "methods"          "base"
```

##Section 1: Download and Unzip the Project Data
We need to download [the data](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) from an external source. The script first creates the directory where the data will be downloaded and unzipped.

```r
if(!file.exists("./GetData-013-data")){
  dir.create("./GetData-013-data")
}
```

We then download the data if it has not already been downloaded. And then we unzip the data.

```r
if(!file.exists("./GetData-013-data/UCIHARDataset.zip")){
  dataUrl <- "http://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(dataUrl, destfile="./GetData-013-data/UCIHARDataset.zip", method="auto")  
}
unzip(zipfile="./GetData-013-data/UCIHARDataset.zip", exdir="./GetData-013-data")
```

##Section 2: Read data into R
Now that we have our data unzipped, we need to read it into R. We will do this systematically so as to avoid extraneous data manipulation steps.
First, we will read the data from the **test** folder and then from the **train** folder. We need to read data from three files in each folder: *subject_test.txt*, *X_test.txt*, and *y_test.txt*. These three files contain different columns belonging to the same data set. At the end of this step, we will have data from each folder in three data frames, one for each file in each folder; a total of six data frames.


```r
dataDirectory <- file.path("./GetData-013-data/UCI HAR Dataset/")
#read in data from "test" folder
testSubjects <- read.table(file.path(dataDirectory,"test","subject_test.txt"), header=FALSE)
testFeaturesX <- read.table(file.path(dataDirectory, "test", "X_test.txt"), header=FALSE)
testActivitiesY <- read.table(file.path(dataDirectory, "test", "y_test.txt"), header=FALSE)

#read in data from training ("train") folder
trainingSubjects <- read.table(file.path(dataDirectory,"train","subject_train.txt"), header=FALSE)
trainingFeaturesX <- read.table(file.path(dataDirectory, "train", "X_train.txt"), header=FALSE)
trainingActivitiesY <- read.table(file.path(dataDirectory, "train", "y_train.txt"), header=FALSE)
```

##Section 3: Merge Data into one Data Set
In this section we will create a single data frame from the six data frames that we read in Step 2. We will do this systematically: first we will combine the two subject datasets into one, then we will combine the two activity data sets, and after that we will combine the features data sets. We will also get rid of the feature columns that do **not** represent **mean** or **standard deviation (std)**. Finally, we will combine subjects, activities and features data into a single data frame.


```r
#combine "Subjects" data and assign column name "subjectId"
mergedSubjectData <- rbind(testSubjects, trainingSubjects)
colnames(mergedSubjectData) <- "subjectId"

#combine "Activity" data and assign column name "activityId"
mergedActivitiesData <- rbind(testActivitiesY, trainingActivitiesY)
names(mergedActivitiesData) <- "activityId"

#combine "Features" data and assign column names
mergedFeaturesData <- rbind(testFeaturesX, trainingFeaturesX)
features <- read.table(file.path(dataDirectory, "features.txt"), header=FALSE)
colnames(mergedFeaturesData) <- features[,2]

#get rid of Feature columns that do not include "mean" or "std"
featuresToKeep <- c("mean", "std")
mergedFeaturesData <- mergedFeaturesData[, which(grepl(paste(featuresToKeep, collapse="|"), colnames(mergedFeaturesData))),]

#combine Subject, Activity and Features data into mergedProjectData
mergedProjectData <- cbind(mergedSubjectData, mergedActivitiesData, mergedFeaturesData)
```

##Section 4: Tidy up data
Now we will get to work on cleaning up our combined data. We will need to do a few things to meet the requirements of our Course Project.  
* Assign descriptive activity names to our activities. For this, we will use the activity names given in activity_labels.txt.  
* Make the feature Column names more descriptive and clean, as follows:  
** "-" will be replaced by ""  
** "()" will be replaced by ""  
** prefix "f" will be replaced by prefix "frequency" 
** prefix "t" will be replaced by prefix "time"  
** Alphabets "Acc" will be replaced by Accelerometer  
** Alphabets "BodyBody" will be replaced by Body  
** Alphabets "Gyro" will be replaced by Gyroscope  
** Alphabets "Mag" will be replaced by Magnitude  
* Our merged data has several observations for each feature, for each activity performed by each subject. We will use these to calculate the __mean__ of each activity performed by each subject.  
Once we are done cleaning up, we will create a tidy data frame called **tidyData**.


```r
#assign descriptive names to Activities in mergedProjectData
#descriptive activity names are given in column 2 of "activity_labels.txt" 
activities <- read.table(file.path(dataDirectory, "activity_labels.txt"), header=FALSE)
colnames(activities) <- c("activityId", "activityName")
mergedProjectData <- merge(mergedProjectData, activities, by="activityId", all.x=TRUE)

#drop the activityId column from the data frame because it is now redundant
mergedProjectData$activityId <- NULL

#column names have to be made more descriptive
textToReplace <- c("-","\\()", "^f", "^t","Acc", "BodyBody", "Gyro", "Mag")
replacementText <- c("","", "frequency", "time","Accelerometer", "Body", "Gyroscope", "Magnitude")
names(mergedProjectData) <- mgsub(textToReplace, replacementText, names(mergedProjectData), fixed=FALSE)

#create tidy data set with average of each feature by subject and activity
tidyData <- aggregate(. ~subjectId + activityName, mergedProjectData, mean)
tidyData <- tidyData[order(tidyData$subjectId, tidyData$activityName),]
```

##Section 5: Output the tidyData to text file
Finally, after all that work, we will create the tidyData.txt file that is required by our Course Project.

```r
#write the tidy data to an external file
write.table(tidyData, file=file.path(dataDirectory, "tidyData.txt"), row.names=FALSE)
```

