# Model Card — Astra DR+DME Research Prototype

## Intended use
Research, coursework, engineering prototyping, algorithm comparison, and PHC workflow simulation.

## Not intended use
This package is not a medical device and must not be used as the sole basis for diagnosis, treatment, or referral decisions.

## Target
The supplied problem statement defines referable DR as ICDR Level 2+ and sets an acceptance target of >90% sensitivity and >85% specificity. These are evaluation targets, not pre-existing results.

## Required validation
- Patient-level train/validation/test separation
- Independent external test set
- Cross-dataset evaluation
- Confidence calibration
- IQA agreement against human gradability labels
- Lesion/vessel segmentation Dice/IoU
- 5-class quadratic-weighted kappa
- Referable-DR sensitivity/specificity and ROC/AUC
- Human review time and explainability usefulness assessment

## Safety behavior
Images judged ungradable are rejected before automated grading and a recapture message is produced.

## Demo behavior
When no trained model is present, the software uses a deterministic heuristic only to demonstrate the software path. The generated report identifies this mode as `HEURISTIC-DEMO`.
