import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { abi as ArbOwner__abi } from '../../build/contracts/src/precompiles/ArbOwner.sol/ArbOwner.json'

// npx hardhat test test/e2e/pricer.ts --network local

describe('Pricer', function () {
  let chainOwner: SignerWithAddress
  const arbOwnerABI = ArbOwner__abi
  const arbOwnerAddress = '0x0000000000000000000000000000000000000070'

  beforeEach(async function () {
    const [signer] = await ethers.getSigners()
    chainOwner = signer
  })

  it('PricerTxFrom', async function () {
    const ArbOwner = new ethers.Contract(
      arbOwnerAddress,
      arbOwnerABI,
      chainOwner
    )

    let tx = await ArbOwner.addPricerTxFrom(chainOwner.address)
    await tx.wait()

    let ok = await ArbOwner.isPricerTxFrom(chainOwner.address, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true

    tx = await ArbOwner.removePricerTxFrom(chainOwner.address)
    await tx.wait()

    ok = await ArbOwner.isPricerTxFrom(chainOwner.address, { gasLimit: 500000 })
    expect(ok).to.be.false
  })

  it('PricerTxTo', async function () {
    const ArbOwner = new ethers.Contract(
      arbOwnerAddress,
      arbOwnerABI,
      chainOwner
    )

    let tx = await ArbOwner.addPricerTxTo(chainOwner.address)
    await tx.wait()

    let ok = await ArbOwner.isPricerTxTo(chainOwner.address, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true

    tx = await ArbOwner.removePricerTxTo(chainOwner.address)
    await tx.wait()

    ok = await ArbOwner.isPricerTxTo(chainOwner.address, { gasLimit: 500000 })
    expect(ok).to.be.false
  })
})
