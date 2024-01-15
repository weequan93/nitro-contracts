import { ethers } from 'hardhat'
import { IERC20__factory } from '../build/types'

async function main(rollup: string="", feeToken?: string) {
  const [signer] = await ethers.getSigners()

  if (!feeToken) {
    feeToken = ethers.constants.AddressZero
  }

  if (feeToken != ethers.constants.AddressZero) {
    await (
      await IERC20__factory.connect(feeToken, signer).approve(
        rollup,
        ethers.constants.MaxUint256
      )
    ).wait()
  }

  console.log("Done")
}

main(process.env.ROLLUP_ADDRESS, process.env.FEE_TOKEN_ADDRESS)
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })
