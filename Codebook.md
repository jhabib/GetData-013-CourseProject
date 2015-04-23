# GetData-013 Course Project Codebook
Jawad Habib  
Wednesday, April 22, 2015  
This Codebook describes how the run_analysis.R script is implemented, and provides descriptions of the variable names (feature names) that were kept for the original data set.

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

#Description of Variables in tidyData.txt
The tidyData data.frame contains 180 observations of 81 variables. These variables represent the per Activity per Subject means of feature-means and feature-standard deviations. How the **mean** and **standard deviation** feature were extracted is described in Section 3 above.

```r
str(tidyData)
```

```
## 'data.frame':	180 obs. of  81 variables:
##  $ subjectId                                      : int  1 1 1 1 1 1 2 2 2 2 ...
##  $ activityName                                   : Factor w/ 6 levels "LAYING","SITTING",..: 1 2 3 4 5 6 1 2 3 4 ...
##  $ timeBodyAccelerometermeanX                     : num  0.222 0.261 0.279 0.277 0.289 ...
##  $ timeBodyAccelerometermeanY                     : num  -0.04051 -0.00131 -0.01614 -0.01738 -0.00992 ...
##  $ timeBodyAccelerometermeanZ                     : num  -0.113 -0.105 -0.111 -0.111 -0.108 ...
##  $ timeBodyAccelerometerstdX                      : num  -0.928 -0.977 -0.996 -0.284 0.03 ...
##  $ timeBodyAccelerometerstdY                      : num  -0.8368 -0.9226 -0.9732 0.1145 -0.0319 ...
##  $ timeBodyAccelerometerstdZ                      : num  -0.826 -0.94 -0.98 -0.26 -0.23 ...
##  $ timeGravityAccelerometermeanX                  : num  -0.249 0.832 0.943 0.935 0.932 ...
##  $ timeGravityAccelerometermeanY                  : num  0.706 0.204 -0.273 -0.282 -0.267 ...
##  $ timeGravityAccelerometermeanZ                  : num  0.4458 0.332 0.0135 -0.0681 -0.0621 ...
##  $ timeGravityAccelerometerstdX                   : num  -0.897 -0.968 -0.994 -0.977 -0.951 ...
##  $ timeGravityAccelerometerstdY                   : num  -0.908 -0.936 -0.981 -0.971 -0.937 ...
##  $ timeGravityAccelerometerstdZ                   : num  -0.852 -0.949 -0.976 -0.948 -0.896 ...
##  $ timeBodyAccelerometerJerkmeanX                 : num  0.0811 0.0775 0.0754 0.074 0.0542 ...
##  $ timeBodyAccelerometerJerkmeanY                 : num  0.003838 -0.000619 0.007976 0.028272 0.02965 ...
##  $ timeBodyAccelerometerJerkmeanZ                 : num  0.01083 -0.00337 -0.00369 -0.00417 -0.01097 ...
##  $ timeBodyAccelerometerJerkstdX                  : num  -0.9585 -0.9864 -0.9946 -0.1136 -0.0123 ...
##  $ timeBodyAccelerometerJerkstdY                  : num  -0.924 -0.981 -0.986 0.067 -0.102 ...
##  $ timeBodyAccelerometerJerkstdZ                  : num  -0.955 -0.988 -0.992 -0.503 -0.346 ...
##  $ timeBodyGyroscopemeanX                         : num  -0.0166 -0.0454 -0.024 -0.0418 -0.0351 ...
##  $ timeBodyGyroscopemeanY                         : num  -0.0645 -0.0919 -0.0594 -0.0695 -0.0909 ...
##  $ timeBodyGyroscopemeanZ                         : num  0.1487 0.0629 0.0748 0.0849 0.0901 ...
##  $ timeBodyGyroscopestdX                          : num  -0.874 -0.977 -0.987 -0.474 -0.458 ...
##  $ timeBodyGyroscopestdY                          : num  -0.9511 -0.9665 -0.9877 -0.0546 -0.1263 ...
##  $ timeBodyGyroscopestdZ                          : num  -0.908 -0.941 -0.981 -0.344 -0.125 ...
##  $ timeBodyGyroscopeJerkmeanX                     : num  -0.1073 -0.0937 -0.0996 -0.09 -0.074 ...
##  $ timeBodyGyroscopeJerkmeanY                     : num  -0.0415 -0.0402 -0.0441 -0.0398 -0.044 ...
##  $ timeBodyGyroscopeJerkmeanZ                     : num  -0.0741 -0.0467 -0.049 -0.0461 -0.027 ...
##  $ timeBodyGyroscopeJerkstdX                      : num  -0.919 -0.992 -0.993 -0.207 -0.487 ...
##  $ timeBodyGyroscopeJerkstdY                      : num  -0.968 -0.99 -0.995 -0.304 -0.239 ...
##  $ timeBodyGyroscopeJerkstdZ                      : num  -0.958 -0.988 -0.992 -0.404 -0.269 ...
##  $ timeBodyAccelerometerMagnitudemean             : num  -0.8419 -0.9485 -0.9843 -0.137 0.0272 ...
##  $ timeBodyAccelerometerMagnitudestd              : num  -0.7951 -0.9271 -0.9819 -0.2197 0.0199 ...
##  $ timeGravityAccelerometerMagnitudemean          : num  -0.8419 -0.9485 -0.9843 -0.137 0.0272 ...
##  $ timeGravityAccelerometerMagnitudestd           : num  -0.7951 -0.9271 -0.9819 -0.2197 0.0199 ...
##  $ timeBodyAccelerometerJerkMagnitudemean         : num  -0.9544 -0.9874 -0.9924 -0.1414 -0.0894 ...
##  $ timeBodyAccelerometerJerkMagnitudestd          : num  -0.9282 -0.9841 -0.9931 -0.0745 -0.0258 ...
##  $ timeBodyGyroscopeMagnitudemean                 : num  -0.8748 -0.9309 -0.9765 -0.161 -0.0757 ...
##  $ timeBodyGyroscopeMagnitudestd                  : num  -0.819 -0.935 -0.979 -0.187 -0.226 ...
##  $ timeBodyGyroscopeJerkMagnitudemean             : num  -0.963 -0.992 -0.995 -0.299 -0.295 ...
##  $ timeBodyGyroscopeJerkMagnitudestd              : num  -0.936 -0.988 -0.995 -0.325 -0.307 ...
##  $ frequencyBodyAccelerometermeanX                : num  -0.9391 -0.9796 -0.9952 -0.2028 0.0382 ...
##  $ frequencyBodyAccelerometermeanY                : num  -0.86707 -0.94408 -0.97707 0.08971 0.00155 ...
##  $ frequencyBodyAccelerometermeanZ                : num  -0.883 -0.959 -0.985 -0.332 -0.226 ...
##  $ frequencyBodyAccelerometerstdX                 : num  -0.9244 -0.9764 -0.996 -0.3191 0.0243 ...
##  $ frequencyBodyAccelerometerstdY                 : num  -0.834 -0.917 -0.972 0.056 -0.113 ...
##  $ frequencyBodyAccelerometerstdZ                 : num  -0.813 -0.934 -0.978 -0.28 -0.298 ...
##  $ frequencyBodyAccelerometermeanFreqX            : num  -0.1588 -0.0495 0.0865 -0.2075 -0.3074 ...
##  $ frequencyBodyAccelerometermeanFreqY            : num  0.0975 0.0759 0.1175 0.1131 0.0632 ...
##  $ frequencyBodyAccelerometermeanFreqZ            : num  0.0894 0.2388 0.2449 0.0497 0.2943 ...
##  $ frequencyBodyAccelerometerJerkmeanX            : num  -0.9571 -0.9866 -0.9946 -0.1705 -0.0277 ...
##  $ frequencyBodyAccelerometerJerkmeanY            : num  -0.9225 -0.9816 -0.9854 -0.0352 -0.1287 ...
##  $ frequencyBodyAccelerometerJerkmeanZ            : num  -0.948 -0.986 -0.991 -0.469 -0.288 ...
##  $ frequencyBodyAccelerometerJerkstdX             : num  -0.9642 -0.9875 -0.9951 -0.1336 -0.0863 ...
##  $ frequencyBodyAccelerometerJerkstdY             : num  -0.932 -0.983 -0.987 0.107 -0.135 ...
##  $ frequencyBodyAccelerometerJerkstdZ             : num  -0.961 -0.988 -0.992 -0.535 -0.402 ...
##  $ frequencyBodyAccelerometerJerkmeanFreqX        : num  0.132 0.257 0.314 -0.209 -0.253 ...
##  $ frequencyBodyAccelerometerJerkmeanFreqY        : num  0.0245 0.0475 0.0392 -0.3862 -0.3376 ...
##  $ frequencyBodyAccelerometerJerkmeanFreqZ        : num  0.02439 0.09239 0.13858 -0.18553 0.00937 ...
##  $ frequencyBodyGyroscopemeanX                    : num  -0.85 -0.976 -0.986 -0.339 -0.352 ...
##  $ frequencyBodyGyroscopemeanY                    : num  -0.9522 -0.9758 -0.989 -0.1031 -0.0557 ...
##  $ frequencyBodyGyroscopemeanZ                    : num  -0.9093 -0.9513 -0.9808 -0.2559 -0.0319 ...
##  $ frequencyBodyGyroscopestdX                     : num  -0.882 -0.978 -0.987 -0.517 -0.495 ...
##  $ frequencyBodyGyroscopestdY                     : num  -0.9512 -0.9623 -0.9871 -0.0335 -0.1814 ...
##  $ frequencyBodyGyroscopestdZ                     : num  -0.917 -0.944 -0.982 -0.437 -0.238 ...
##  $ frequencyBodyGyroscopemeanFreqX                : num  -0.00355 0.18915 -0.12029 0.01478 -0.10045 ...
##  $ frequencyBodyGyroscopemeanFreqY                : num  -0.0915 0.0631 -0.0447 -0.0658 0.0826 ...
##  $ frequencyBodyGyroscopemeanFreqZ                : num  0.010458 -0.029784 0.100608 0.000773 -0.075676 ...
##  $ frequencyBodyAccelerometerMagnitudemean        : num  -0.8618 -0.9478 -0.9854 -0.1286 0.0966 ...
##  $ frequencyBodyAccelerometerMagnitudestd         : num  -0.798 -0.928 -0.982 -0.398 -0.187 ...
##  $ frequencyBodyAccelerometerMagnitudemeanFreq    : num  0.0864 0.2367 0.2846 0.1906 0.1192 ...
##  $ frequencyBodyAccelerometerJerkMagnitudemean    : num  -0.9333 -0.9853 -0.9925 -0.0571 0.0262 ...
##  $ frequencyBodyAccelerometerJerkMagnitudestd     : num  -0.922 -0.982 -0.993 -0.103 -0.104 ...
##  $ frequencyBodyAccelerometerJerkMagnitudemeanFreq: num  0.2664 0.3519 0.4222 0.0938 0.0765 ...
##  $ frequencyBodyGyroscopeMagnitudemean            : num  -0.862 -0.958 -0.985 -0.199 -0.186 ...
##  $ frequencyBodyGyroscopeMagnitudestd             : num  -0.824 -0.932 -0.978 -0.321 -0.398 ...
##  $ frequencyBodyGyroscopeMagnitudemeanFreq        : num  -0.139775 -0.000262 -0.028606 0.268844 0.349614 ...
##  $ frequencyBodyGyroscopeJerkMagnitudemean        : num  -0.942 -0.99 -0.995 -0.319 -0.282 ...
##  $ frequencyBodyGyroscopeJerkMagnitudestd         : num  -0.933 -0.987 -0.995 -0.382 -0.392 ...
##  $ frequencyBodyGyroscopeJerkMagnitudemeanFreq    : num  0.176 0.185 0.334 0.191 0.19 ...
```

##Descriptive Names of Variables in tidyData
Following list shows the variables in tidyData and provides a description of each variable. All variables, except for subjectId and activityName, are per Subject per Activity means of observations.
The features selected for this database come from the accelerometer and gyroscope 3-axial raw signals tAcc-XYZ and tGyro-XYZ. These time domain signals (prefix 't' to denote time) were captured at a constant rate of 50 Hz. Then they were filtered using a median filter and a 3rd order low pass Butterworth filter with a corner frequency of 20 Hz to remove noise. Similarly, the acceleration signal was then separated into body and gravity acceleration signals (tBodyAcc-XYZ and tGravityAcc-XYZ) using another low pass Butterworth filter with a corner frequency of 0.3 Hz.

 [1] "subjectId"                                      
 unique identifier of each Subject
 
 [2] "activityName"                                   
 name of activity performed by each subhect e.g. Walking, Laying
 
 [3] "timeBodyAccelerometermeanX"                     
 [4] "timeBodyAccelerometermeanY"                     
 [5] "timeBodyAccelerometermeanZ"                     
 mean of time domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes
 
 [6] "timeBodyAccelerometerstdX"                      
 [7] "timeBodyAccelerometerstdY"                      
 [8] "timeBodyAccelerometerstdZ"                    
 standard deviation of time domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes
 
 [9] "timeGravityAccelerometermeanX"                  
[10] "timeGravityAccelerometermeanY"                  
[11] "timeGravityAccelerometermeanZ"                  
mean of time domain accelerometer signal for Gravity acceleration along X-, Y-, and Z-axes

[12] "timeGravityAccelerometerstdX"                   
[13] "timeGravityAccelerometerstdY"                   
[14] "timeGravityAccelerometerstdZ"                   
standard deviation of time domain accelerometer signal for Gravity acceleration along X-, Y- and Z-axes.

###the body linear acceleration and angular velocity were derived in time to obtain Jerk signals.
[15] "timeBodyAccelerometerJerkmeanX"                 
[16] "timeBodyAccelerometerJerkmeanY"                 
[17] "timeBodyAccelerometerJerkmeanZ"  
mean of time domain accelerometer signal for Body Jerk along X-, Y-, and Z-axes. 

[18] "timeBodyAccelerometerJerkstdX"                  
[19] "timeBodyAccelerometerJerkstdY"                  
[20] "timeBodyAccelerometerJerkstdZ"  
standard deviation of time domain accelerometer signal for Body Jerk along X-, Y-, and Z-axes. 

[21] "timeBodyGyroscopemeanX"                         
[22] "timeBodyGyroscopemeanY"                         
[23] "timeBodyGyroscopemeanZ"  
mean of time domain gyroscope signal for Body acceleration along X-, Y-, and Z-axes

[24] "timeBodyGyroscopestdX"                          
[25] "timeBodyGyroscopestdY"                          
[26] "timeBodyGyroscopestdZ"  
standard deviation of time domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes

[27] "timeBodyGyroscopeJerkmeanX"                     
[28] "timeBodyGyroscopeJerkmeanY"                     
[29] "timeBodyGyroscopeJerkmeanZ"  
mean of time domain gyroscope signal for Body Jerk along X-, Y-, and Z-axes

[30] "timeBodyGyroscopeJerkstdX"                      
[31] "timeBodyGyroscopeJerkstdY"                      
[32] "timeBodyGyroscopeJerkstdZ"  
standard deviation of time domain gyroscope signal for Body Jerk along X-, Y-, and Z-axes

###magnitude of these three-dimensional signals were calculated using the Euclidean norm
[33] "timeBodyAccelerometerMagnitudemean"             
[34] "timeBodyAccelerometerMagnitudestd"  
magnitude of mean and standard deviation of time domain accelerometer signal for Body.

[35] "timeGravityAccelerometerMagnitudemean"          
[36] "timeGravityAccelerometerMagnitudestd"    
magnitude of mean and standard deviation of time domain accelerometer signal for Gravity.

[37] "timeBodyAccelerometerJerkMagnitudemean"         
[38] "timeBodyAccelerometerJerkMagnitudestd"  
magnitude of mean and standard deviation of time domain accelerometer signal for Jerk.

[39] "timeBodyGyroscopeMagnitudemean"                 
[40] "timeBodyGyroscopeMagnitudestd"  
magnitude of mean and standard deviation of time domain gryoscope signal for Body.

[41] "timeBodyGyroscopeJerkMagnitudemean"             
[42] "timeBodyGyroscopeJerkMagnitudestd"  
magnitude of mean and standard deviation of time domain gryoscope signal for Body.

###a Fast Fourier Transform (FFT) was applied to some of these signals producing frequency domain signals.
[43] "frequencyBodyAccelerometermeanX"                
[44] "frequencyBodyAccelerometermeanY"                
[45] "frequencyBodyAccelerometermeanZ"  
mean of frequency domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes
 
[46] "frequencyBodyAccelerometerstdX"                 
[47] "frequencyBodyAccelerometerstdY"                 
[48] "frequencyBodyAccelerometerstdZ"                 
standard deviation of frequency domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes

[49] "frequencyBodyAccelerometermeanFreqX"            
[50] "frequencyBodyAccelerometermeanFreqY"            
[51] "frequencyBodyAccelerometermeanFreqZ"            
mean of mean-frequency for frequency domain accelerometer signal for Body acceleration along X-, Y-, and Z-axes. weighted average of the frequency components to obtain a mean frequency


[52] "frequencyBodyAccelerometerJerkmeanX"            
[53] "frequencyBodyAccelerometerJerkmeanY"            
[54] "frequencyBodyAccelerometerJerkmeanZ"            
mean of frequency domain accelerometer signal for Body Jerk along X-, Y-, and Z-axes. 

[55] "frequencyBodyAccelerometerJerkstdX"             
[56] "frequencyBodyAccelerometerJerkstdY"             
[57] "frequencyBodyAccelerometerJerkstdZ"             
standard deviation of frequency domain accelerometer signal for Body Jerk along X-, Y-, and Z-axes. 

[58] "frequencyBodyAccelerometerJerkmeanFreqX"        
[59] "frequencyBodyAccelerometerJerkmeanFreqY"        
[60] "frequencyBodyAccelerometerJerkmeanFreqZ"        
mean of mean-frequency for frequency domain accelerometer signal for Body Jerk along X-, Y-, and Z-axes.

[61] "frequencyBodyGyroscopemeanX"                    
[62] "frequencyBodyGyroscopemeanY"                    
[63] "frequencyBodyGyroscopemeanZ"                    
mean of frequency domain gryoscope signal for Body acceleration along X-, Y-, and Z-axes

[64] "frequencyBodyGyroscopestdX"                     
[65] "frequencyBodyGyroscopestdY"                     
[66] "frequencyBodyGyroscopestdZ"                     
standard deviation of frequency domain gyroscope signal for Body acceleration along X-, Y-, and Z-axes

[67] "frequencyBodyGyroscopemeanFreqX"                
[68] "frequencyBodyGyroscopemeanFreqY"                
[69] "frequencyBodyGyroscopemeanFreqZ"                
mean of mean-frequency for frequency domain gryoscope signal for Body along X-, Y-, and Z-axes.

[70] "frequencyBodyAccelerometerMagnitudemean"        
[71] "frequencyBodyAccelerometerMagnitudestd"         
[72] "frequencyBodyAccelerometerMagnitudemeanFreq"  
magnitude of the mean, standard deviation and weighted mean (meanFreq) of frequency domain accelerometer signal for Body.

[73] "frequencyBodyAccelerometerJerkMagnitudemean"    
[74] "frequencyBodyAccelerometerJerkMagnitudestd"     
[75] "frequencyBodyAccelerometerJerkMagnitudemeanFreq"  
magnitude of the mean, standard deviation and weighted mean (meanFreq) of frequency domain accelerometer signal for Body Jerk.

[76] "frequencyBodyGyroscopeMagnitudemean"            
[77] "frequencyBodyGyroscopeMagnitudestd"             
[78] "frequencyBodyGyroscopeMagnitudemeanFreq"        
magnitude of the mean, standard deviation and weighted mean (meanFreq) of frequency domain gyroscope signal for Body.

[79] "frequencyBodyGyroscopeJerkMagnitudemean"        
[80] "frequencyBodyGyroscopeJerkMagnitudestd"         
[81] "frequencyBodyGyroscopeJerkMagnitudemeanFreq"  
magnitude of the mean, standard deviation and weighted mean (meanFreq) of frequency domain gyroscope signal for Body Jerk.

#Summary of tidyData
tidyData is summarized below.

```r
summary(tidyData)
```

```
##    subjectId                activityName timeBodyAccelerometermeanX
##  Min.   : 1.0   LAYING            :30    Min.   :0.2216            
##  1st Qu.: 8.0   SITTING           :30    1st Qu.:0.2712            
##  Median :15.5   STANDING          :30    Median :0.2770            
##  Mean   :15.5   WALKING           :30    Mean   :0.2743            
##  3rd Qu.:23.0   WALKING_DOWNSTAIRS:30    3rd Qu.:0.2800            
##  Max.   :30.0   WALKING_UPSTAIRS  :30    Max.   :0.3015            
##  timeBodyAccelerometermeanY timeBodyAccelerometermeanZ
##  Min.   :-0.040514          Min.   :-0.15251          
##  1st Qu.:-0.020022          1st Qu.:-0.11207          
##  Median :-0.017262          Median :-0.10819          
##  Mean   :-0.017876          Mean   :-0.10916          
##  3rd Qu.:-0.014936          3rd Qu.:-0.10443          
##  Max.   :-0.001308          Max.   :-0.07538          
##  timeBodyAccelerometerstdX timeBodyAccelerometerstdY
##  Min.   :-0.9961           Min.   :-0.99024         
##  1st Qu.:-0.9799           1st Qu.:-0.94205         
##  Median :-0.7526           Median :-0.50897         
##  Mean   :-0.5577           Mean   :-0.46046         
##  3rd Qu.:-0.1984           3rd Qu.:-0.03077         
##  Max.   : 0.6269           Max.   : 0.61694         
##  timeBodyAccelerometerstdZ timeGravityAccelerometermeanX
##  Min.   :-0.9877           Min.   :-0.6800              
##  1st Qu.:-0.9498           1st Qu.: 0.8376              
##  Median :-0.6518           Median : 0.9208              
##  Mean   :-0.5756           Mean   : 0.6975              
##  3rd Qu.:-0.2306           3rd Qu.: 0.9425              
##  Max.   : 0.6090           Max.   : 0.9745              
##  timeGravityAccelerometermeanY timeGravityAccelerometermeanZ
##  Min.   :-0.47989              Min.   :-0.49509             
##  1st Qu.:-0.23319              1st Qu.:-0.11726             
##  Median :-0.12782              Median : 0.02384             
##  Mean   :-0.01621              Mean   : 0.07413             
##  3rd Qu.: 0.08773              3rd Qu.: 0.14946             
##  Max.   : 0.95659              Max.   : 0.95787             
##  timeGravityAccelerometerstdX timeGravityAccelerometerstdY
##  Min.   :-0.9968              Min.   :-0.9942             
##  1st Qu.:-0.9825              1st Qu.:-0.9711             
##  Median :-0.9695              Median :-0.9590             
##  Mean   :-0.9638              Mean   :-0.9524             
##  3rd Qu.:-0.9509              3rd Qu.:-0.9370             
##  Max.   :-0.8296              Max.   :-0.6436             
##  timeGravityAccelerometerstdZ timeBodyAccelerometerJerkmeanX
##  Min.   :-0.9910              Min.   :0.04269               
##  1st Qu.:-0.9605              1st Qu.:0.07396               
##  Median :-0.9450              Median :0.07640               
##  Mean   :-0.9364              Mean   :0.07947               
##  3rd Qu.:-0.9180              3rd Qu.:0.08330               
##  Max.   :-0.6102              Max.   :0.13019               
##  timeBodyAccelerometerJerkmeanY timeBodyAccelerometerJerkmeanZ
##  Min.   :-0.0386872             Min.   :-0.067458             
##  1st Qu.: 0.0004664             1st Qu.:-0.010601             
##  Median : 0.0094698             Median :-0.003861             
##  Mean   : 0.0075652             Mean   :-0.004953             
##  3rd Qu.: 0.0134008             3rd Qu.: 0.001958             
##  Max.   : 0.0568186             Max.   : 0.038053             
##  timeBodyAccelerometerJerkstdX timeBodyAccelerometerJerkstdY
##  Min.   :-0.9946               Min.   :-0.9895              
##  1st Qu.:-0.9832               1st Qu.:-0.9724              
##  Median :-0.8104               Median :-0.7756              
##  Mean   :-0.5949               Mean   :-0.5654              
##  3rd Qu.:-0.2233               3rd Qu.:-0.1483              
##  Max.   : 0.5443               Max.   : 0.3553              
##  timeBodyAccelerometerJerkstdZ timeBodyGyroscopemeanX
##  Min.   :-0.99329              Min.   :-0.20578      
##  1st Qu.:-0.98266              1st Qu.:-0.04712      
##  Median :-0.88366              Median :-0.02871      
##  Mean   :-0.73596              Mean   :-0.03244      
##  3rd Qu.:-0.51212              3rd Qu.:-0.01676      
##  Max.   : 0.03102              Max.   : 0.19270      
##  timeBodyGyroscopemeanY timeBodyGyroscopemeanZ timeBodyGyroscopestdX
##  Min.   :-0.20421       Min.   :-0.07245       Min.   :-0.9943      
##  1st Qu.:-0.08955       1st Qu.: 0.07475       1st Qu.:-0.9735      
##  Median :-0.07318       Median : 0.08512       Median :-0.7890      
##  Mean   :-0.07426       Mean   : 0.08744       Mean   :-0.6916      
##  3rd Qu.:-0.06113       3rd Qu.: 0.10177       3rd Qu.:-0.4414      
##  Max.   : 0.02747       Max.   : 0.17910       Max.   : 0.2677      
##  timeBodyGyroscopestdY timeBodyGyroscopestdZ timeBodyGyroscopeJerkmeanX
##  Min.   :-0.9942       Min.   :-0.9855       Min.   :-0.15721          
##  1st Qu.:-0.9629       1st Qu.:-0.9609       1st Qu.:-0.10322          
##  Median :-0.8017       Median :-0.8010       Median :-0.09868          
##  Mean   :-0.6533       Mean   :-0.6164       Mean   :-0.09606          
##  3rd Qu.:-0.4196       3rd Qu.:-0.3106       3rd Qu.:-0.09110          
##  Max.   : 0.4765       Max.   : 0.5649       Max.   :-0.02209          
##  timeBodyGyroscopeJerkmeanY timeBodyGyroscopeJerkmeanZ
##  Min.   :-0.07681           Min.   :-0.092500         
##  1st Qu.:-0.04552           1st Qu.:-0.061725         
##  Median :-0.04112           Median :-0.053430         
##  Mean   :-0.04269           Mean   :-0.054802         
##  3rd Qu.:-0.03842           3rd Qu.:-0.048985         
##  Max.   :-0.01320           Max.   :-0.006941         
##  timeBodyGyroscopeJerkstdX timeBodyGyroscopeJerkstdY
##  Min.   :-0.9965           Min.   :-0.9971          
##  1st Qu.:-0.9800           1st Qu.:-0.9832          
##  Median :-0.8396           Median :-0.8942          
##  Mean   :-0.7036           Mean   :-0.7636          
##  3rd Qu.:-0.4629           3rd Qu.:-0.5861          
##  Max.   : 0.1791           Max.   : 0.2959          
##  timeBodyGyroscopeJerkstdZ timeBodyAccelerometerMagnitudemean
##  Min.   :-0.9954           Min.   :-0.9865                   
##  1st Qu.:-0.9848           1st Qu.:-0.9573                   
##  Median :-0.8610           Median :-0.4829                   
##  Mean   :-0.7096           Mean   :-0.4973                   
##  3rd Qu.:-0.4741           3rd Qu.:-0.0919                   
##  Max.   : 0.1932           Max.   : 0.6446                   
##  timeBodyAccelerometerMagnitudestd timeGravityAccelerometerMagnitudemean
##  Min.   :-0.9865                   Min.   :-0.9865                      
##  1st Qu.:-0.9430                   1st Qu.:-0.9573                      
##  Median :-0.6074                   Median :-0.4829                      
##  Mean   :-0.5439                   Mean   :-0.4973                      
##  3rd Qu.:-0.2090                   3rd Qu.:-0.0919                      
##  Max.   : 0.4284                   Max.   : 0.6446                      
##  timeGravityAccelerometerMagnitudestd
##  Min.   :-0.9865                     
##  1st Qu.:-0.9430                     
##  Median :-0.6074                     
##  Mean   :-0.5439                     
##  3rd Qu.:-0.2090                     
##  Max.   : 0.4284                     
##  timeBodyAccelerometerJerkMagnitudemean
##  Min.   :-0.9928                       
##  1st Qu.:-0.9807                       
##  Median :-0.8168                       
##  Mean   :-0.6079                       
##  3rd Qu.:-0.2456                       
##  Max.   : 0.4345                       
##  timeBodyAccelerometerJerkMagnitudestd timeBodyGyroscopeMagnitudemean
##  Min.   :-0.9946                       Min.   :-0.9807               
##  1st Qu.:-0.9765                       1st Qu.:-0.9461               
##  Median :-0.8014                       Median :-0.6551               
##  Mean   :-0.5842                       Mean   :-0.5652               
##  3rd Qu.:-0.2173                       3rd Qu.:-0.2159               
##  Max.   : 0.4506                       Max.   : 0.4180               
##  timeBodyGyroscopeMagnitudestd timeBodyGyroscopeJerkMagnitudemean
##  Min.   :-0.9814               Min.   :-0.99732                  
##  1st Qu.:-0.9476               1st Qu.:-0.98515                  
##  Median :-0.7420               Median :-0.86479                  
##  Mean   :-0.6304               Mean   :-0.73637                  
##  3rd Qu.:-0.3602               3rd Qu.:-0.51186                  
##  Max.   : 0.3000               Max.   : 0.08758                  
##  timeBodyGyroscopeJerkMagnitudestd frequencyBodyAccelerometermeanX
##  Min.   :-0.9977                   Min.   :-0.9952                
##  1st Qu.:-0.9805                   1st Qu.:-0.9787                
##  Median :-0.8809                   Median :-0.7691                
##  Mean   :-0.7550                   Mean   :-0.5758                
##  3rd Qu.:-0.5767                   3rd Qu.:-0.2174                
##  Max.   : 0.2502                   Max.   : 0.5370                
##  frequencyBodyAccelerometermeanY frequencyBodyAccelerometermeanZ
##  Min.   :-0.98903                Min.   :-0.9895                
##  1st Qu.:-0.95361                1st Qu.:-0.9619                
##  Median :-0.59498                Median :-0.7236                
##  Mean   :-0.48873                Mean   :-0.6297                
##  3rd Qu.:-0.06341                3rd Qu.:-0.3183                
##  Max.   : 0.52419                Max.   : 0.2807                
##  frequencyBodyAccelerometerstdX frequencyBodyAccelerometerstdY
##  Min.   :-0.9966                Min.   :-0.99068              
##  1st Qu.:-0.9820                1st Qu.:-0.94042              
##  Median :-0.7470                Median :-0.51338              
##  Mean   :-0.5522                Mean   :-0.48148              
##  3rd Qu.:-0.1966                3rd Qu.:-0.07913              
##  Max.   : 0.6585                Max.   : 0.56019              
##  frequencyBodyAccelerometerstdZ frequencyBodyAccelerometermeanFreqX
##  Min.   :-0.9872                Min.   :-0.63591                   
##  1st Qu.:-0.9459                1st Qu.:-0.39165                   
##  Median :-0.6441                Median :-0.25731                   
##  Mean   :-0.5824                Mean   :-0.23227                   
##  3rd Qu.:-0.2655                3rd Qu.:-0.06105                   
##  Max.   : 0.6871                Max.   : 0.15912                   
##  frequencyBodyAccelerometermeanFreqY frequencyBodyAccelerometermeanFreqZ
##  Min.   :-0.379518                   Min.   :-0.52011                   
##  1st Qu.:-0.081314                   1st Qu.:-0.03629                   
##  Median : 0.007855                   Median : 0.06582                   
##  Mean   : 0.011529                   Mean   : 0.04372                   
##  3rd Qu.: 0.086281                   3rd Qu.: 0.17542                   
##  Max.   : 0.466528                   Max.   : 0.40253                   
##  frequencyBodyAccelerometerJerkmeanX frequencyBodyAccelerometerJerkmeanY
##  Min.   :-0.9946                     Min.   :-0.9894                    
##  1st Qu.:-0.9828                     1st Qu.:-0.9725                    
##  Median :-0.8126                     Median :-0.7817                    
##  Mean   :-0.6139                     Mean   :-0.5882                    
##  3rd Qu.:-0.2820                     3rd Qu.:-0.1963                    
##  Max.   : 0.4743                     Max.   : 0.2767                    
##  frequencyBodyAccelerometerJerkmeanZ frequencyBodyAccelerometerJerkstdX
##  Min.   :-0.9920                     Min.   :-0.9951                   
##  1st Qu.:-0.9796                     1st Qu.:-0.9847                   
##  Median :-0.8707                     Median :-0.8254                   
##  Mean   :-0.7144                     Mean   :-0.6121                   
##  3rd Qu.:-0.4697                     3rd Qu.:-0.2475                   
##  Max.   : 0.1578                     Max.   : 0.4768                   
##  frequencyBodyAccelerometerJerkstdY frequencyBodyAccelerometerJerkstdZ
##  Min.   :-0.9905                    Min.   :-0.993108                 
##  1st Qu.:-0.9737                    1st Qu.:-0.983747                 
##  Median :-0.7852                    Median :-0.895121                 
##  Mean   :-0.5707                    Mean   :-0.756489                 
##  3rd Qu.:-0.1685                    3rd Qu.:-0.543787                 
##  Max.   : 0.3498                    Max.   :-0.006236                 
##  frequencyBodyAccelerometerJerkmeanFreqX
##  Min.   :-0.57604                       
##  1st Qu.:-0.28966                       
##  Median :-0.06091                       
##  Mean   :-0.06910                       
##  3rd Qu.: 0.17660                       
##  Max.   : 0.33145                       
##  frequencyBodyAccelerometerJerkmeanFreqY
##  Min.   :-0.60197                       
##  1st Qu.:-0.39751                       
##  Median :-0.23209                       
##  Mean   :-0.22810                       
##  3rd Qu.:-0.04721                       
##  Max.   : 0.19568                       
##  frequencyBodyAccelerometerJerkmeanFreqZ frequencyBodyGyroscopemeanX
##  Min.   :-0.62756                        Min.   :-0.9931            
##  1st Qu.:-0.30867                        1st Qu.:-0.9697            
##  Median :-0.09187                        Median :-0.7300            
##  Mean   :-0.13760                        Mean   :-0.6367            
##  3rd Qu.: 0.03858                        3rd Qu.:-0.3387            
##  Max.   : 0.23011                        Max.   : 0.4750            
##  frequencyBodyGyroscopemeanY frequencyBodyGyroscopemeanZ
##  Min.   :-0.9940             Min.   :-0.9860            
##  1st Qu.:-0.9700             1st Qu.:-0.9624            
##  Median :-0.8141             Median :-0.7909            
##  Mean   :-0.6767             Mean   :-0.6044            
##  3rd Qu.:-0.4458             3rd Qu.:-0.2635            
##  Max.   : 0.3288             Max.   : 0.4924            
##  frequencyBodyGyroscopestdX frequencyBodyGyroscopestdY
##  Min.   :-0.9947            Min.   :-0.9944           
##  1st Qu.:-0.9750            1st Qu.:-0.9602           
##  Median :-0.8086            Median :-0.7964           
##  Mean   :-0.7110            Mean   :-0.6454           
##  3rd Qu.:-0.4813            3rd Qu.:-0.4154           
##  Max.   : 0.1966            Max.   : 0.6462           
##  frequencyBodyGyroscopestdZ frequencyBodyGyroscopemeanFreqX
##  Min.   :-0.9867            Min.   :-0.395770              
##  1st Qu.:-0.9643            1st Qu.:-0.213363              
##  Median :-0.8224            Median :-0.115527              
##  Mean   :-0.6577            Mean   :-0.104551              
##  3rd Qu.:-0.3916            3rd Qu.: 0.002655              
##  Max.   : 0.5225            Max.   : 0.249209              
##  frequencyBodyGyroscopemeanFreqY frequencyBodyGyroscopemeanFreqZ
##  Min.   :-0.66681                Min.   :-0.50749               
##  1st Qu.:-0.29433                1st Qu.:-0.15481               
##  Median :-0.15794                Median :-0.05081               
##  Mean   :-0.16741                Mean   :-0.05718               
##  3rd Qu.:-0.04269                3rd Qu.: 0.04152               
##  Max.   : 0.27314                Max.   : 0.37707               
##  frequencyBodyAccelerometerMagnitudemean
##  Min.   :-0.9868                        
##  1st Qu.:-0.9560                        
##  Median :-0.6703                        
##  Mean   :-0.5365                        
##  3rd Qu.:-0.1622                        
##  Max.   : 0.5866                        
##  frequencyBodyAccelerometerMagnitudestd
##  Min.   :-0.9876                       
##  1st Qu.:-0.9452                       
##  Median :-0.6513                       
##  Mean   :-0.6210                       
##  3rd Qu.:-0.3654                       
##  Max.   : 0.1787                       
##  frequencyBodyAccelerometerMagnitudemeanFreq
##  Min.   :-0.31234                           
##  1st Qu.:-0.01475                           
##  Median : 0.08132                           
##  Mean   : 0.07613                           
##  3rd Qu.: 0.17436                           
##  Max.   : 0.43585                           
##  frequencyBodyAccelerometerJerkMagnitudemean
##  Min.   :-0.9940                            
##  1st Qu.:-0.9770                            
##  Median :-0.7940                            
##  Mean   :-0.5756                            
##  3rd Qu.:-0.1872                            
##  Max.   : 0.5384                            
##  frequencyBodyAccelerometerJerkMagnitudestd
##  Min.   :-0.9944                           
##  1st Qu.:-0.9752                           
##  Median :-0.8126                           
##  Mean   :-0.5992                           
##  3rd Qu.:-0.2668                           
##  Max.   : 0.3163                           
##  frequencyBodyAccelerometerJerkMagnitudemeanFreq
##  Min.   :-0.12521                               
##  1st Qu.: 0.04527                               
##  Median : 0.17198                               
##  Mean   : 0.16255                               
##  3rd Qu.: 0.27593                               
##  Max.   : 0.48809                               
##  frequencyBodyGyroscopeMagnitudemean frequencyBodyGyroscopeMagnitudestd
##  Min.   :-0.9865                     Min.   :-0.9815                   
##  1st Qu.:-0.9616                     1st Qu.:-0.9488                   
##  Median :-0.7657                     Median :-0.7727                   
##  Mean   :-0.6671                     Mean   :-0.6723                   
##  3rd Qu.:-0.4087                     3rd Qu.:-0.4277                   
##  Max.   : 0.2040                     Max.   : 0.2367                   
##  frequencyBodyGyroscopeMagnitudemeanFreq
##  Min.   :-0.45664                       
##  1st Qu.:-0.16951                       
##  Median :-0.05352                       
##  Mean   :-0.03603                       
##  3rd Qu.: 0.08228                       
##  Max.   : 0.40952                       
##  frequencyBodyGyroscopeJerkMagnitudemean
##  Min.   :-0.9976                        
##  1st Qu.:-0.9813                        
##  Median :-0.8779                        
##  Mean   :-0.7564                        
##  3rd Qu.:-0.5831                        
##  Max.   : 0.1466                        
##  frequencyBodyGyroscopeJerkMagnitudestd
##  Min.   :-0.9976                       
##  1st Qu.:-0.9802                       
##  Median :-0.8941                       
##  Mean   :-0.7715                       
##  3rd Qu.:-0.6081                       
##  Max.   : 0.2878                       
##  frequencyBodyGyroscopeJerkMagnitudemeanFreq
##  Min.   :-0.18292                           
##  1st Qu.: 0.05423                           
##  Median : 0.11156                           
##  Mean   : 0.12592                           
##  3rd Qu.: 0.20805                           
##  Max.   : 0.42630
```
