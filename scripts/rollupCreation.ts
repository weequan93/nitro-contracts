import { ethers } from 'hardhat'
import '@nomiclabs/hardhat-ethers'
import { run } from 'hardhat'
import { abi as rollupCreatorAbi } from '../build/contracts/src/rollup/RollupCreator.sol/RollupCreator.json'
import { config, maxDataSize } from './config'
import { BigNumber } from 'ethers'
import { IERC20__factory } from '../build/types'
import { sleep } from './testSetup'

// 1 gwei
const MAX_FER_PER_GAS = BigNumber.from('1000000000')

interface RollupCreatedEvent {
  event: string
  address: string
  args?: {
    rollupAddress: string
    inboxAddress: string
    outbox: string
    rollupEventInbox: string
    challengeManager: string
    adminProxy: string
    sequencerInbox: string
    bridge: string
    validatorUtils: string
    validatorWalletCreator: string
  }
}

export async function createRollup(feeToken?: string) {
  const rollupCreatorAddress = process.env.ROLLUP_CREATOR_ADDRESS

  if (!rollupCreatorAddress) {
    console.error(
      'Please provide ROLLUP_CREATOR_ADDRESS as an environment variable.'
    )
    process.exit(1)
  }

  if (!rollupCreatorAbi) {
    throw new Error(
      'You need to first run <deployment.ts> script to deploy and compile the contracts first'
    )
  }

  const [signer] = await ethers.getSigners()

  const rollupCreator = new ethers.Contract(
    rollupCreatorAddress,
    rollupCreatorAbi,
    signer
  )

  if (!feeToken) {
    feeToken = ethers.constants.AddressZero
  }

  try {
    let vals: boolean[] = []
    for (let i = 0; i < config.validators.length; i++) {
      vals.push(true)
    }

    //// funds for deploying L2 factories

    // 0.13 ETH is enough to deploy L2 factories via retryables. Excess is refunded
    let feeCost = ethers.utils.parseEther('0.5')
    if (feeToken != ethers.constants.AddressZero) {
      // in case fees are paid via fee token, then approve rollup cretor to spend required amount
      await (
        await IERC20__factory.connect(feeToken, signer).approve(
          rollupCreator.address,
          feeCost,
        )
      ).wait()
      feeCost = BigNumber.from(0)
    }

    // Call the createRollup function
    console.log('Calling createRollup to generate a new rollup ...')
    const deployParams = {
      config: config.rollupConfig,
      batchPoster: config.batchPoster,
      validators: config.validators,
      maxDataSize: maxDataSize,
      nativeToken: feeToken,
      deployFactoriesToL2: true,
      maxFeePerGasForRetryables: MAX_FER_PER_GAS,
    }
    const createRollupTx = await rollupCreator.createRollup(
      deployParams,
      {
        gasLimit: 15000000,
      }
      
    )
    const createRollupReceipt = await createRollupTx.wait()
    console.log(createRollupReceipt.transactionHash)

    const rollupCreatedEvent = createRollupReceipt.events?.find(
      (event: RollupCreatedEvent) =>
        event.event === 'RollupCreated' &&
        event.address.toLowerCase() === rollupCreatorAddress.toLowerCase()
    )

    // Checking for RollupCreated event for new rollup address
    if (rollupCreatedEvent) {
      const rollupAddress = rollupCreatedEvent.args?.rollupAddress
      const inboxAddress = rollupCreatedEvent.args?.inboxAddress
      const outbox = rollupCreatedEvent.args?.outbox
      const rollupEventInbox = rollupCreatedEvent.args?.rollupEventInbox
      const challengeManager = rollupCreatedEvent.args?.challengeManager
      const adminProxy = rollupCreatedEvent.args?.adminProxy
      const sequencerInbox = rollupCreatedEvent.args?.sequencerInbox
      const bridge = rollupCreatedEvent.args?.bridge
      const validatorUtils = rollupCreatedEvent.args?.validatorUtils
      const validatorWalletCreator =
        rollupCreatedEvent.args?.validatorWalletCreator
      const upgradeExecutor = rollupCreatedEvent.args?.upgradeExecutor

      console.log("Congratulations! 🎉🎉🎉 All DONE! Here's your addresses:")
      console.log('RollupProxy Contract created at address:', rollupAddress)
      console.log('Wait a minute before starting the contract verification')
      await sleep(1 * 60 * 1000)
      console.log(
        `Attempting to verify Rollup contract at address ${rollupAddress}...`
      )
      try {
        await run('verify:verify', {
          contract: 'src/rollup/RollupProxy.sol:RollupProxy',
          address: rollupAddress,
          constructorArguments: [],
        })
      } catch (error: any) {
        if (error.message.includes('Already Verified')) {
          console.log(`Contract RollupProxy is already verified.`)
        } else {
          console.error(
            `Verification for RollupProxy failed with the following error: ${error.message}`
          )
        }
      }

      if (feeToken != ethers.constants.AddressZero) {
        await (
          await IERC20__factory.connect(feeToken, signer).approve(
            rollupAddress,
            ethers.constants.MaxUint256
          )
        ).wait()
      }

      console.log(`"chainId": "${config.rollupConfig.chainId}",`)
      console.log(`"utils": "${validatorUtils}",`)
      console.log(`"rollup": "${rollupAddress}",`)
      console.log(`"inbox": "${inboxAddress}",`)
      console.log(`"outbox": "${outbox}",`)
      console.log(`"rollupEventInbox": "${rollupEventInbox}",`)
      console.log(`"challengeManager": "${challengeManager}",`)
      console.log(`"adminProxy": "${adminProxy}",`)
      console.log(`"sequencerInbox": "${sequencerInbox}",`)
      console.log(`"bridge": "${bridge}",`)
      console.log(`"upgradeExecutor": "${upgradeExecutor}",`)
      console.log(`"validatorUtils": "${validatorUtils}",`)
      console.log(`"validatorWalletCreator": "${validatorWalletCreator}",`)
      console.log(`"deployedAtBlockNumber": "${createRollupReceipt.blockNumber}"\n`)

      const rollup = {
        "bridge": bridge,
        "inbox": inboxAddress,
        "sequencer-inbox": sequencerInbox,
        "rollup": rollupAddress,
        "validator-utils": validatorUtils,
        "validator-wallet-creator": validatorWalletCreator,
        "deployed-at": createRollupReceipt.blockNumber,
      }
      console.log(JSON.stringify(rollup))
    } else {
      console.error('RollupCreated event not found')
    }
  } catch (error) {
    console.error(
      'Deployment failed:',
      error instanceof Error ? error.message : error
    )
  }
}
