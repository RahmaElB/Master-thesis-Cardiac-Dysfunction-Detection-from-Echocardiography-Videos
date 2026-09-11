#!/bin/bash
# Submits 9 additional seeds x 4 models = 36 jobs, on top of the existing
# seed=42 (Phase 1 original run), seed=123, seed=2024 already completed.
# Total after this: 12 seeds per model
#
# Usage:
#   cd $ECHO_PROJECT_ROOT
#   bash scripts/robustness_seeds/submit_new_seeds.sh
#
# You can also submit a subset, e.g. only baseline:
#   MODELS=baseline bash scripts/robustness_seeds/submit_new_seeds.sh

NEW_SEEDS=(1 2 3 4 5 6 7 8 9)
MODELS=${MODELS:-"baseline cnn_lstm r3d swin3d"}

declare -A SCRIPT_FOR_MODEL=(
    [baseline]="scripts/robustness_seeds/run_baseline_multiseed.sh"
    [cnn_lstm]="scripts/robustness_seeds/run_cnn_lstm_multiseed.sh"
    [r3d]="scripts/robustness_seeds/run_r3d_multiseed.sh"
    [swin3d]="scripts/robustness_seeds/run_swin3d_multiseed.sh"
)

for model in $MODELS; do
    script=${SCRIPT_FOR_MODEL[$model]}
    if [ -z "$script" ]; then
        echo "Unknown model: $model"
        continue
    fi
    for seed in "${NEW_SEEDS[@]}"; do
        echo "Submitting $model seed=$seed ($script)"
        sbatch --export=ALL,SEED=$seed "$script"
    done
done

echo ""
echo "Submitted 9 seeds x $(echo $MODELS | wc -w) model(s)."
echo "Check status with: squeue -u \$USER"