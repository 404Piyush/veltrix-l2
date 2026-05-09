#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ENV_FILE=${ENV_FILE:-}
OUT_FILE=${OUT_FILE:-"$ROOT_DIR/configs/deploy-config.sepolia.json"}
TEMPLATE_FILE=${TEMPLATE_FILE:-"$ROOT_DIR/optimism-repo/packages/contracts-bedrock/deploy-config/sepolia-devnet-0.json"}

load_env_file() {
    local path="$1"
    if [ -f "$path" ]; then
        # shellcheck disable=SC1090
        set -a
        . "$path"
        set +a
    fi
}

if [ -n "$ENV_FILE" ]; then
    load_env_file "$ENV_FILE"
else
    load_env_file "$ROOT_DIR/.env"
    load_env_file "$ROOT_DIR/ops/.env"
fi

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command '$1' is not installed."
        exit 1
    fi
}

require_env() {
    local name="$1"
    if [ -z "${!name:-}" ]; then
        echo "Error: required env var '$name' is not set."
        exit 1
    fi
}

address_from_key() {
    cast wallet address --private-key "$1"
}

resolve_address() {
    local explicit_name="$1"
    local key_name="$2"
    local fallback="$3"

    if [ -n "${!explicit_name:-}" ]; then
        printf '%s\n' "${!explicit_name}"
        return
    fi

    if [ -n "${!key_name:-}" ]; then
        address_from_key "${!key_name}"
        return
    fi

    printf '%s\n' "$fallback"
}

require_command cast
require_command jq

require_env L1_RPC_URL

if [ -n "${PRIVATE_KEY:-}" ] && [ -z "${DEPLOYER_PRIVATE_KEY:-}" ]; then
    DEPLOYER_PRIVATE_KEY="$PRIVATE_KEY"
fi
require_env DEPLOYER_PRIVATE_KEY

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: template file not found at $TEMPLATE_FILE."
    exit 1
fi

DEPLOYER_ADDRESS=$(address_from_key "$DEPLOYER_PRIVATE_KEY")
FINAL_SYSTEM_OWNER=${FINAL_SYSTEM_OWNER:-$DEPLOYER_ADDRESS}
SUPERCHAIN_CONFIG_GUARDIAN=${SUPERCHAIN_CONFIG_GUARDIAN:-$FINAL_SYSTEM_OWNER}

L1_CHAIN_ID=${L1_CHAIN_ID:-11155111}
L2_CHAIN_ID=${L2_CHAIN_ID:-845320}
GOVERNANCE_TOKEN_NAME=${GOVERNANCE_TOKEN_NAME:-Veltrix}
GOVERNANCE_TOKEN_SYMBOL=${GOVERNANCE_TOKEN_SYMBOL:-VEL}
GAS_PRICE_ORACLE_BASE_FEE_SCALAR=${GAS_PRICE_ORACLE_BASE_FEE_SCALAR:-1368}
GAS_PRICE_ORACLE_BLOB_BASE_FEE_SCALAR=${GAS_PRICE_ORACLE_BLOB_BASE_FEE_SCALAR:-810949}
L2_GENESIS_ECOTONE_TIME_OFFSET=${L2_GENESIS_ECOTONE_TIME_OFFSET:-0x0}
L2_GENESIS_FJORD_TIME_OFFSET=${L2_GENESIS_FJORD_TIME_OFFSET:-0x0}

START_BLOCK_JSON=$(cast block --json --rpc-url "$L1_RPC_URL" latest)
START_BLOCK_HASH=${L1_STARTING_BLOCK_TAG:-$(printf '%s' "$START_BLOCK_JSON" | jq -r '.hash')}
START_BLOCK_TIMESTAMP_HEX=$(printf '%s' "$START_BLOCK_JSON" | jq -r '.timestamp')
SYSTEM_CONFIG_START_BLOCK=${SYSTEM_CONFIG_START_BLOCK:-0}
L2OO_STARTING_TIMESTAMP=${L2_OUTPUT_ORACLE_STARTING_TIMESTAMP:-$(cast to-dec "$START_BLOCK_TIMESTAMP_HEX")}

SEQUENCER_ADDRESS=$(resolve_address SEQUENCER_ADDRESS SEQUENCER_PRIVATE_KEY "$DEPLOYER_ADDRESS")
BATCHER_ADDRESS=$(resolve_address BATCHER_ADDRESS BATCHER_PRIVATE_KEY "$DEPLOYER_ADDRESS")
PROPOSER_ADDRESS=$(resolve_address PROPOSER_ADDRESS PROPOSER_PRIVATE_KEY "$DEPLOYER_ADDRESS")
CHALLENGER_ADDRESS=$(resolve_address CHALLENGER_ADDRESS CHALLENGER_PRIVATE_KEY "$FINAL_SYSTEM_OWNER")

BATCH_INBOX_ADDRESS=${BATCH_INBOX_ADDRESS:-$(printf '0xff%038x' "$L2_CHAIN_ID")}

mkdir -p "$(dirname "$OUT_FILE")"

jq \
    --arg l1StartingBlockTag "$START_BLOCK_HASH" \
    --argjson l1ChainID "$L1_CHAIN_ID" \
    --argjson l2ChainID "$L2_CHAIN_ID" \
    --arg p2pSequencerAddress "$SEQUENCER_ADDRESS" \
    --arg batchInboxAddress "$BATCH_INBOX_ADDRESS" \
    --arg batchSenderAddress "$BATCHER_ADDRESS" \
    --argjson l2OutputOracleStartingTimestamp "$L2OO_STARTING_TIMESTAMP" \
    --arg l2OutputOracleProposer "$PROPOSER_ADDRESS" \
    --arg l2OutputOracleChallenger "$CHALLENGER_ADDRESS" \
    --arg proxyAdminOwner "$FINAL_SYSTEM_OWNER" \
    --arg finalSystemOwner "$FINAL_SYSTEM_OWNER" \
    --arg superchainConfigGuardian "$SUPERCHAIN_CONFIG_GUARDIAN" \
    --arg baseFeeVaultRecipient "$FINAL_SYSTEM_OWNER" \
    --arg l1FeeVaultRecipient "$FINAL_SYSTEM_OWNER" \
    --arg sequencerFeeVaultRecipient "$FINAL_SYSTEM_OWNER" \
    --arg governanceTokenOwner "$FINAL_SYSTEM_OWNER" \
    --arg governanceTokenName "$GOVERNANCE_TOKEN_NAME" \
    --arg governanceTokenSymbol "$GOVERNANCE_TOKEN_SYMBOL" \
    --argjson systemConfigStartBlock "$SYSTEM_CONFIG_START_BLOCK" \
    --argjson gasPriceOracleBaseFeeScalar "$GAS_PRICE_ORACLE_BASE_FEE_SCALAR" \
    --argjson gasPriceOracleBlobBaseFeeScalar "$GAS_PRICE_ORACLE_BLOB_BASE_FEE_SCALAR" \
    --arg l2GenesisEcotoneTimeOffset "$L2_GENESIS_ECOTONE_TIME_OFFSET" \
    --arg l2GenesisFjordTimeOffset "$L2_GENESIS_FJORD_TIME_OFFSET" \
    '
    .l1StartingBlockTag = $l1StartingBlockTag |
    .l1ChainID = $l1ChainID |
    .l2ChainID = $l2ChainID |
    .p2pSequencerAddress = $p2pSequencerAddress |
    .batchInboxAddress = $batchInboxAddress |
    .batchSenderAddress = $batchSenderAddress |
    .l2OutputOracleStartingTimestamp = $l2OutputOracleStartingTimestamp |
    .l2OutputOracleProposer = $l2OutputOracleProposer |
    .l2OutputOracleChallenger = $l2OutputOracleChallenger |
    .proxyAdminOwner = $proxyAdminOwner |
    .finalSystemOwner = $finalSystemOwner |
    .superchainConfigGuardian = $superchainConfigGuardian |
    .baseFeeVaultRecipient = $baseFeeVaultRecipient |
    .l1FeeVaultRecipient = $l1FeeVaultRecipient |
    .sequencerFeeVaultRecipient = $sequencerFeeVaultRecipient |
    .governanceTokenOwner = $governanceTokenOwner |
    .governanceTokenName = $governanceTokenName |
    .governanceTokenSymbol = $governanceTokenSymbol |
    .systemConfigStartBlock = $systemConfigStartBlock |
    .gasPriceOracleBaseFeeScalar = $gasPriceOracleBaseFeeScalar |
    .gasPriceOracleBlobBaseFeeScalar = $gasPriceOracleBlobBaseFeeScalar |
    .l2GenesisEcotoneTimeOffset = $l2GenesisEcotoneTimeOffset |
    .l2GenesisFjordTimeOffset = $l2GenesisFjordTimeOffset
    ' \
    "$TEMPLATE_FILE" > "$OUT_FILE"

echo "Wrote $OUT_FILE"
echo "  l1ChainID=$L1_CHAIN_ID"
echo "  l2ChainID=$L2_CHAIN_ID"
echo "  l1StartingBlockTag=$START_BLOCK_HASH"
echo "  finalSystemOwner=$FINAL_SYSTEM_OWNER"
echo "  sequencerAddress=$SEQUENCER_ADDRESS"
echo "  batcherAddress=$BATCHER_ADDRESS"
echo "  proposerAddress=$PROPOSER_ADDRESS"
echo "  challengerAddress=$CHALLENGER_ADDRESS"
