# EXP-ActionGoalRecognition
This is the experiment scripts and analyses scripts for the fMRI study *Dissociating Goal from Outcome During Action Observation*. The study aims to find regions in the brain that represent action goals independently of outcomes when people are observing others' actions.

## Experiment
- Contains scripts for running the fRMI experiment
- "trd" folder: one set of 8 trd files for each subject. Thr trd files contain parameters for controlling the trial orders, timing, and the corresponding stimuli to display in each trial
- "res" folder: store the output of the experiment, e.g., participants' keypresses and response times
- "log" folder: store the Matlab console output for each participant

### Instruction
- In Matlab console, run: run_GOAL_OUTCOME(\_subject\_id\_, \_run\_id\_)
  - Example: to start the first run of subject 02, run: run_GOAL_OUTCOME(1, 2)
 
## Analysis
- Contains scripts for 3 parts of the data analysis
- "scripts00_preprocessing": scripts for preprocssing the fMRI scans for each subject
- "scripts01_GLM_categorical": scripts for computing the Generalized Linear Models (GLM) for each subject and the entire group
- "scripts02_MVPA": scripts for multivariate pattern analysis (MVPA decoding) of neural patterns using SVM classifiers

### Instruction
- For each part of the analysis:
  - Go to the corresponding folder
  - Run the scripts in the order specified by the first part of the file names.
    - Example: for preprocessing, run the .m scripts in the following order:
      - prep00_imaToNifti
      - prep01_getSliceTiming
      - prep02_preprocessing_new
      - prep03_moveFiles
      - prep04_computeTSNR
      - prep05_cleanup
- IMPORTANT: for each script, change the value of subvec to the ids of the subjects that you want to analyze. For example, set to `subvec = [2 4 5]` to run the script for subject 02, 04, and 05. 
