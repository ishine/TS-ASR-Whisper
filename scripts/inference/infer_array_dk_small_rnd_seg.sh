#!/usr/bin/bash
#$ -N CHIME_infer
#$ -q long.q
#$ -l ram_free=40G,mem_free=40G
#$ -l scratch=1
#$ -t 1-13:1
#$ -l gpu=1,gpu_ram=8G
#$ -o /mnt/matylda5/ipoloka/challenges/NOTSOFAR1-Challenge/outputs/$JOB_NAME_$JOB_ID_$TASK_ID.out
#$ -e /mnt/matylda5/ipoloka/challenges/NOTSOFAR1-Challenge/outputs/$JOB_NAME_$JOB_ID_$TASK_ID.err

# As Karel said don't be an idiot and use the same number of GPUs as requested
export N_GPUS=1

# Enable opening multiple files
ulimit -n 4096

# Enable to save bigger files
ulimit -f unlimited

# Enable more threads per process by increasing virtual memory (https://stackoverflow.com/questions/344203/maximum-number-of-threads-per-process-in-linux)
ulimit -v unlimited


# Setup the environment
unset PYTHONPATH
unset PYTHONHOME
source /mnt/matylda5/ipoloka/miniconda3/bin/activate /mnt/matylda5/ipoloka/miniconda3/envs/notsofar

SRC_ROOT="/mnt/matylda5/ipoloka/challenges/NOTSOFAR1-Challenge"
EXPERIMENT="whisper_small_from_scratch_v2_dec_only"
EXPERIMENT_PATH="/mnt/scratch/tmp/ipoloka/experiments/${EXPERIMENT}"

export PATH="/mnt/matylda5/ipoloka/utils/SCTK/bin:$PATH"
export PYTHONPATH="/mnt/matylda5/ipoloka/challenges/NOTSOFAR1-Challenge:$PYTHONPATH"
export PYTHONPATH="/mnt/matylda5/ipoloka/chime/notsofar/CHIME2024/inference:$PYTHONPATH"
export WANDB_PROJECT="whisper_finetune"
export WANDB_ENTITY="butspeechfit"
export WANDB_RUN_ID="${EXPERIMENT}"
export HF_HOME="/mnt/scratch/tmp/ipoloka/hf_cache"

# Get start index by multiplying the task id by the 10
start_index=$((($SGE_TASK_ID - 1) * 10))
end_index=$((($SGE_TASK_ID) * 10))

# Those defined in https://huggingface.co/docs/transformers/main_classes/trainer#transformers.Seq2SeqTrainingArguments + custom
args=(
--output_dir "/mnt/matylda5/ipoloka/challenges/NOTSOFAR1-Challenge/outputs/dk_small_rnd_seg"
--whisper_model="openai/whisper-small.en"
--per_device_eval_batch_size=1
--generation_num_beams=1
--decoding_ctc_weight=0
--per_device_eval_batch_size=16
--generation_max_length=225
#--init_from="/mnt/scratch/tmp/ipoloka/experiments/timestamps_WhisperCTC_10e_0.3ctc_lr2e5_fixed_longer_warmup/checkpoint-2757/model.safetensors"
--init_from="/mnt/scratch/tmp/xkleme15/asr/chime/checkpoints/wh_small_rand_seg/checkpoint-8000"
#--use_gt_diar
--start_decoding_index=$start_index
--end_decoding_index=$end_index
--use_soft_diar_labels
#--condition_on_prev
)

"${SRC_ROOT}/sge_tools/python" "${SRC_ROOT}/src/inference/infer.py" "${args[@]}"
