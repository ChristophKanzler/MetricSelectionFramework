# Description
MATLAB source code for the paper:

A data-driven framework for the selection and validation of digital health metrics: use-case in neurological sensorimotor impairments. Christoph M. Kanzler, Mike D. Rinderknecht, Anne Schwarz, Ilse Lamers, Cynthia Gagnon, Jeremia Held, Peter Feys, Andreas R. Luft, Roger Gassert, Olivier Lambercy. bioRxiv 544601; doi: https://doi.org/10.1101/544601

This code will simulate data for multiple digital health metrics for a reference (e.g., neurologically intact) and a target (e.g., neurologocially impaired) population. Based on these data, the proposed multi-step metric selection framework will be applied and all evaluation criteria and plots from the paper will be generated.

This approach is expected to be applicable for any 1D, discrete digital health metric for that data for a reference (e.g., neurologically intact) and target (e.g,. neurologically impaired) population is available. Also, one of these populations should have test-retest data available as well.

The framework allows the selection of robust metrics that have highest potential for repeatedly assessing impairments based on discriminant validity, test-retest reliability, measurement error, learning effects, and inter-metric correlations.

## Requirements
This code requires MATLAB and the following toolboxes.
* Statistics and Machine Learning Toolbox
* Financial Toolbox

# Usage
To run the analysis with the default simulated data, simply run `main.m`. The framework can also be used for feature selection using another data-set. 

## Using a custom data-set
To run the feature selection on your data, you should make sure it meets the following requirements.
* For each subject, the data-set should include a test and a re-test measurement of all the features you want to perform selection on.
* Single measurements of a feature should consist of scalars.
* If you want to perform confound correction using a linear mixed-effect model, the variables used to fit the model should be included in the data-set.
* Your data should contain a group of healthy subject, used as reference, and the set of impaired patients.
The resulting data-set should consist of two separate MATLAB tables, one for the healthy and one for the patients. Assume you want to run feature selection on a set of N features with names f<sub>1</sub>x
f<sub>1</sub>, f<sub>2</sub>, ..., f<sub>N</sub>, and perform confound correction with M effects with names e<sub>1</sub>, e<sub>2</sub>, ..., e<sub>M</sub>. Both tables should have the same structure, depicted in the following scheme. 

   | Unique ID     | e<sub>1</sub> | ... | e<sub>M</sub> | f<sub>1</sub> | f<sub>1</sub>_retest | ... | f<sub>N</sub> | f<sub>N</sub>_retest |
   | ------------- | ------------- | --- | ------------- | ------------- | -------------------- | --- | ------------ | ---------- |
   | 1             | ...           | ... | ...           | ...           | ...                  | ... | ...          | ...        |
   | 2             | ...           | ... | ...           | ...           | ...                  | ... | ...          | ...        |
   | ...           | ...           | ... | ...           | ...           | ...                  | ... | ...          | ...        |

You can then save these tables in two separate `.mat` files. <b>Please make sure to add the _restest suffix on the column names of the re-test measurements of each feature!</b>

The procedure to use the code with your data is then the following.
1) Set the `use_simulated_data` boolean to `false` (line 43)
2) Change lines 44 and 45 to load the correct `.mat` files containing the tables for the healthy and patients group, respectively.
3) Modify the `metrics` array (line 48) to include the name of all the metrics you want to run the selection on (f<sub>1</sub>, f<sub>2</sub>, ..., f<sub>N</sub>).
4) Populate the `effects` array (line 51) with the effects you want to run the confound compensation with (e<sub>1</sub>, e<sub>2</sub>, ..., e<sub>M</sub>).

## Example output
The tool outputs the results both on the MATLAB standard output or by displaying figures. In the following, we go through a run of the framework using the default simulated data. You can advance to the next step by clicking with the mouse on displayed figures.

### Postprocessing, metric selection and validation steps 1 and 2
Here, the confounds are modeled and compensated. Further, the data is normalized using the data from the healthy population as reference. Then, the steps 1 and 2 of the metric selection and validation are executed. This is done once for each feature, and for each of them the confound correction result and ROC curve are displayed. In the MATLAB standard output, the other criteria described in the paper are shown.

![Confound-correction](/images/compensation.png "Confound correction") ![ROC](/images/roc.png "ROC") 

### Metric selection and validation step 3
The partial inter-correlations of the features are displayed in an heatmap.

![inter-correlations](/images/partialcorr.png "Partial inter-correlations")

### Further metric validation step 1
At this stage, factor analysis is performed. To select the appropriate number of factors `k`, one has to look at the scree plot and pick `k`according to a criteria (e.g. the elbow criteria). `k` can be modified at line 67, and the scree plot can be displayed at this stage by setting `show_scree_plot` to `true` (line 63). The results of the factor analysis are printed to the MATLAB standard output.

### Further metric validation step 2
Finally, a plot for sub-population analysis is displayed (see Figure 4 in the paper for more information).
![sub-population](/images/final_plot.png "Sub-population analysis")
