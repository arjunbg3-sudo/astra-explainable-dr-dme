# Astra Explainable DR+DME MATLAB Prototype

This project implements the architecture in the supplied *MATLAB-Based AI Pipeline for Diabetic Retinopathy & DME Screening* report: IQA → retinal structure/lesion analysis → multi-task DR+DME model → explainability/HITL → district workflow simulation.

## Important clinical/engineering status

This is a **research prototype**, not a clinically validated or autonomous diagnostic device. The requested >90% sensitivity and >85% specificity for referable DR are **acceptance targets**, not results that can be honestly claimed before training and independent testing.

The included `run_demo` works without a trained network by using a deterministic heuristic fallback for demonstration. For real performance, train the multi-task network on appropriately licensed/consented data and evaluate on a locked, patient-level independent test set.

## MATLAB requirements

Recommended: MATLAB R2024a or newer.

Toolboxes:
- Image Processing Toolbox
- Computer Vision Toolbox
- Deep Learning Toolbox
- Statistics and Machine Learning Toolbox
- Simulink + SimEvents for the discrete-event model
- Medical Imaging Toolbox (optional)
- MATLAB Report Generator (optional)

## Quick start

1. Open MATLAB in this project folder.
2. Run:
   `setupProject`
3. Run the end-to-end demo:
   `run_demo`
4. The demo writes:
   - `outputs/demo_report.pdf` (or PNG fallback)
   - `outputs/demo_overlay.png`
   - `outputs/demo_result.mat`
   - `outputs/simulation_results.csv`
   - `outputs/simulation_bottleneck.png`

## Real dataset workflow

Create `data/labels.csv` with columns:

`imagePath,drGrade,dme`

where:
- `drGrade` = 0,1,2,3,4
- `dme` = 0/1
- `imagePath` is relative to the project folder or an absolute path.

Then run:

```
M = prepareManifest("data/labels.csv");
trainMultiTaskResNet50(M);
```

The training code uses a shared ResNet-50 encoder with DR and DME heads, class-weighted DR loss, augmentation, and a custom training loop.

## Segmentation

`segmentRetina.m` provides:
- optic-disc localization
- fovea estimate relative to the disc
- vessel map
- candidate microaneurysm/exudate/hemorrhage masks
- neovascularization cue

For benchmark training, use DRIVE/CHASE-DB1 vessel masks and IDRiD lesion annotations. A U-Net training template is included in `training/trainVesselUNet.m`.

## Explainability

`makeGradCAM.m` uses MATLAB's `gradCAM` where the trained network is compatible. A robust image-gradient fallback is also included so the demo does not fail when no trained network is present.

## Simulation

`runDistrictSimulation.m` is a fast MATLAB discrete-event approximation of the PHC → edge inference → referral → specialist queue. It sweeps cameras/technicians/reviewers and reports throughput, utilization, queue/waiting time, and whether 100,000 annual patients can be served.

`buildSimEventsModel.m` attempts to create a corresponding SimEvents block model when SimEvents is installed.

## Validation

`evaluateReferable.m` computes:
- referable DR = grade >= 2
- sensitivity
- specificity
- PPV/NPV
- ROC/AUC
- confusion matrix
- quadratic-weighted kappa

The code never substitutes target values for measured values.
