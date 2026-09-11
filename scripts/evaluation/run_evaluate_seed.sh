#!/bin/bash
#SBATCH --job-name=eval_seed
#SBATCH --account=project_2018481
#SBATCH --partition=gpumedium
#SBATCH --gres=gpu:gh200:1
#SBATCH --time=00:30:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --output=logs/slurm-eval-seed-%x-%j.out

# Runs src.evaluate on one seed's checkpoint, for the CNN+LSTM-vs-R3D-18
# calibration check. Reuses the exact hyperparameters from the
# original scripts/evaluation/run_evaluate_{cnn_lstm,r3d}.sh, just swapping
# in a different seed's checkpoint/run_name.
#
# Usage:
#   sbatch --export=ALL,MODEL=cnn_lstm,SEED=1 scripts/evaluation/run_evaluate_seed.sh
#   sbatch --export=ALL,MODEL=r3d,SEED=1      scripts/evaluation/run_evaluate_seed.sh

if [ -z "$MODEL" ] || [ -z "$SEED" ]; then
    echo "ERROR: \$MODEL and \$SEED must both be set."
    echo "Usage: sbatch --export=ALL,MODEL=cnn_lstm,SEED=1 $0"
    exit 1
fi

module --force purge

export ECHO_DATA_ROOT=/scratch/project_2018481/echonet
export ECHO_PROJECT_ROOT=/scratch/project_2018481/thesis_project6
export PYTHONPATH=$ECHO_PROJECT_ROOT
export APPTAINER_CACHEDIR=$TMPDIR

SIF=$ECHO_PROJECT_ROOT/containers/pytorch_2.10_cuda13_roihu.sif

cd $ECHO_PROJECT_ROOT

case "$MODEL" in
    baseline)
        CHECKPOINT=checkpoints/baseline_64f_112px_clipp1_pretrained_seed${SEED}_best.pt
        NUM_FRAMES=64; IMG_SIZE=112; BATCH_SIZE=8; CLIP_PERIOD=1
        ;;
    cnn_lstm)
        CHECKPOINT=checkpoints/cnn_lstm_64f_112px_clipp1_pretrained_seed${SEED}_best.pt
        NUM_FRAMES=64; IMG_SIZE=112; BATCH_SIZE=8; CLIP_PERIOD=1
        ;;
    r3d)
        CHECKPOINT=checkpoints/r3d_64f_112px_clipp1_pretrained_seed${SEED}_best.pt
        NUM_FRAMES=64; IMG_SIZE=112; BATCH_SIZE=8; CLIP_PERIOD=1
        ;;
    swin3d)
        CHECKPOINT=checkpoints/swin3d_32f_224px_clipp2_pretrained_seed${SEED}_best.pt
        NUM_FRAMES=32; IMG_SIZE=224; BATCH_SIZE=2; CLIP_PERIOD=2
        ;;
    *)
        echo "ERROR: unsupported MODEL=$MODEL (expected baseline, cnn_lstm, r3d, or swin3d)"
        exit 1
        ;;
esac

if [ "$MODEL" == "swin3d" ]; then
    RUN_NAME=${MODEL}_32f_224px_clipp2_pretrained_seed${SEED}_best
else
    RUN_NAME=${MODEL}_64f_112px_clipp1_pretrained_seed${SEED}_best
fi

apptainer exec --nv --bind /scratch/project_2018481:/scratch/project_2018481 \
    $SIF \
    python3 -m src.evaluate --model $MODEL \
        --checkpoint $CHECKPOINT \
        --num_frames $NUM_FRAMES --img_size $IMG_SIZE \
        --temporal_sampling clip --clip_period $CLIP_PERIOD \
        --batch_size $BATCH_SIZE \
        --split test --out_dir results/evaluation \
        --run_name $RUN_NAME