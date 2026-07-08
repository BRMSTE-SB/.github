#!/usr/bin/env bash
# BRMSTE FULL FINE-TUNE — Multi-Platform Fine-Tuning Script
# Generated: 2026-07-08 by Computer
# Run from: /Users/sachindabas/Desktop/MAC ADMIN
# ──────────────────────────────────────────────────────────────────────────────
# Doctrine: CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS
# Fine-tuned model = BRMSTE JARVIS persona embedded in weights
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DATASET="$HOME/.brmste-finetune-dataset.jsonl"

# ──────────────────────────────────────────────────────────────────────────────
# OPTION A: Together AI (cheapest — $3/M train tokens on Llama-3-8B)
# ──────────────────────────────────────────────────────────────────────────────
finetune_together() {
  echo "=== Together AI Fine-Tune ==="
  local TOGETHER_KEY="${TOGETHER_API_KEY:-}"
  if [ -z "$TOGETHER_KEY" ]; then
    echo "Get key: https://api.together.xyz → Settings → API Keys"
    return 1
  fi

  # Upload dataset
  echo "Uploading dataset..."
  UPLOAD=$(curl -s -X POST https://api.together.xyz/v1/files \
    -H "Authorization: Bearer $TOGETHER_KEY" \
    -F "file=@$DATASET" \
    -F "purpose=fine-tune")
  FILE_ID=$(echo "$UPLOAD" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "File ID: $FILE_ID"

  # Launch fine-tune job
  JOB=$(curl -s -X POST https://api.together.xyz/v1/fine-tuning/jobs \
    -H "Authorization: Bearer $TOGETHER_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"meta-llama/Meta-Llama-3-8B-Instruct\",
      \"training_file\": \"$FILE_ID\",
      \"n_epochs\": 3,
      \"learning_rate\": 0.0001,
      \"suffix\": \"brmste-jarvis\"
    }")
  echo "Job: $JOB"
  JOB_ID=$(echo "$JOB" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "Job ID: $JOB_ID"
  echo "Monitor: curl -s https://api.together.xyz/v1/fine-tuning/jobs/$JOB_ID -H \"Authorization: Bearer $TOGETHER_KEY\""
}

# ──────────────────────────────────────────────────────────────────────────────
# OPTION B: OpenAI gpt-4o-mini (best quality/cost for BRMSTE persona)
# ──────────────────────────────────────────────────────────────────────────────
finetune_openai() {
  echo "=== OpenAI Fine-Tune (gpt-4o-mini) ==="
  local OPENAI_KEY="${OPENAI_API_KEY:-}"
  if [ -z "$OPENAI_KEY" ] || [ "$OPENAI_KEY" = "OPENAI-API" ]; then
    echo "Get key: https://platform.openai.com/account/api-keys"
    echo "Then: export OPENAI_API_KEY=sk-proj-..."
    return 1
  fi

  # Upload dataset
  echo "Uploading dataset..."
  UPLOAD=$(curl -s https://api.openai.com/v1/files \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -F "purpose=fine-tune" \
    -F "file=@$DATASET")
  FILE_ID=$(echo "$UPLOAD" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "File ID: $FILE_ID"

  # Launch fine-tune
  JOB=$(curl -s https://api.openai.com/v1/fine_tuning/jobs \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"training_file\": \"$FILE_ID\",
      \"model\": \"gpt-4o-mini-2024-07-18\",
      \"suffix\": \"brmste-jarvis\",
      \"hyperparameters\": {
        \"n_epochs\": 3
      }
    }")
  echo "Job: $(echo $JOB | python3 -m json.tool)"
  JOB_ID=$(echo "$JOB" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "Monitor: curl -s https://api.openai.com/v1/fine_tuning/jobs/$JOB_ID -H \"Authorization: Bearer $OPENAI_KEY\""
  echo "After completion wire to CF Worker:"
  echo "  npx wrangler secret put OPENAI_BRMSTE_MODEL --name brmste-mine"
  echo "  # paste: ft:gpt-4o-mini-2024-07-18:brmste-jarvis:..."
}

# ──────────────────────────────────────────────────────────────────────────────
# OPTION C: IBM WatsonX Prompt Tuning (Granite model — on your existing IBM instance)
# ──────────────────────────────────────────────────────────────────────────────
finetune_watsonx() {
  echo "=== IBM WatsonX Prompt Tuning ==="
  # Requires new IBM Cloud API key (old one revoked)
  # https://cloud.ibm.com/iam/apikeys → create brmste-quantum-operator
  local IBM_KEY="${IBM_QUANTUM_API_KEY:-}"
  if [ -z "$IBM_KEY" ]; then
    echo "Generate IBM key: https://cloud.ibm.com/iam/apikeys"
    return 1
  fi

  # Exchange for IAM token
  IAM_TOKEN=$(curl -s -X POST https://iam.cloud.ibm.com/identity/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBM_KEY" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")

  # Upload training data to IBM COS (brmste-coming-soon bucket)
  echo "Upload dataset to IBM COS first:"
  echo "  ibmcloud cos upload --bucket brmste-coming-soon --key brmste-jarvis-finetune.jsonl --file $DATASET"
  echo ""
  echo "Then create WatsonX prompt tuning experiment:"

  cat << WATSONX_JSON
{
  "name": "brmste-jarvis-prompt-tune",
  "description": "BRMSTE JARVIS persona fine-tune on IBM Granite",
  "type": "prompt_tuning",
  "model_id": "ibm/granite-3-8b-instruct",
  "task_id": "generation",
  "training_data_references": [{
    "connection": {
      "id": "ibm-cos-brmste",
      "type": "container"
    },
    "location": {
      "bucket": "brmste-coming-soon",
      "file_name": "brmste-jarvis-finetune.jsonl"
    }
  }],
  "prompt_tuning": {
    "num_epochs": 20,
    "verbalizer": "Input: {{input}} Output:",
    "learning_rate": 0.3,
    "accumulate_steps": 16,
    "init_method": "text"
  }
}
WATSONX_JSON
}

# ──────────────────────────────────────────────────────────────────────────────
# OPTION D: Grok xAI (fine-tuning NOT yet available — API returns 404)
# Monitor: https://docs.x.ai for LoRA fine-tune announcement
# ──────────────────────────────────────────────────────────────────────────────
# XAI_KEY from env or keychain: brmste-xai-api-key
# When available: grok-build-0.1 (code) and grok-4.3 expected to support LoRA
# Dataset is already in OpenAI chat format — compatible when released

# ──────────────────────────────────────────────────────────────────────────────
# WIRE FINE-TUNED MODEL TO CF WORKERS
# ──────────────────────────────────────────────────────────────────────────────
wire_finetuned_model() {
  local MODEL_ID="$1"
  local WORKERS="brmste-mine brmste-786x-voyager brmste-quantum-gi"
  
  echo "=== Wiring fine-tuned model to CF Workers ==="
  for WORKER in $WORKERS; do
    printf "%s" "$MODEL_ID" | npx wrangler secret put BRMSTE_FINETUNE_MODEL --name "$WORKER"
    echo "  ✅ Wired to $WORKER"
  done
  echo ""
  echo "Update worker code to use BRMSTE_FINETUNE_MODEL env var instead of default model"
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────
echo "BRMSTE FULL FINE-TUNE"
echo "Doctrine: CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS"
echo ""
echo "Choose platform:"
echo "  A) Together AI   — cheapest · Llama-3-8B · \$3/M train tokens"
echo "  B) OpenAI        — best quality · gpt-4o-mini · \$8/M train tokens"  
echo "  C) IBM WatsonX   — on your IBM instance · Granite · prompt-tuning"
echo "  D) Grok xAI      — NOT YET AVAILABLE (fine-tuning endpoint returns 404)"
echo ""
read -rp "Choice [A/B/C]: " CHOICE

case "${CHOICE^^}" in
  A) finetune_together ;;
  B) finetune_openai ;;
  C) finetune_watsonx ;;
  *) echo "Invalid choice" ;;
esac
