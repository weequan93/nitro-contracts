import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { abi as ArbOwner__abi } from '../../../build/contracts/src/precompiles/ArbOwner.sol/ArbOwner.json'

// npx hardhat test test/e2e/precompile/pricer.ts --network local

describe('Pricer', function () {
  let chainOwner: SignerWithAddress
  const arbOwnerABI = ArbOwner__abi
  const arbOwnerAddress = '0x0000000000000000000000000000000000000070'
  const pricerAddress = '0xd7ba14B43f0530eEB4EA1c279DfC47Bf8F55f766'
  const pricerAddress2 = '0x00000000000000000000000000000000000007EA'
  const pricerAddress3 = '0x00000000000000000000000000000000000007E9'
  const pricerAddress4 = '0xB370ae496175E438DfBee2E1E0748B50AE901860'

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

    tx = await ArbOwner.addPricerTxTo(pricerAddress)
    await tx.wait()

    ok = await ArbOwner.isPricerTxTo(pricerAddress, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true

    tx = await ArbOwner.addPricerTxTo(pricerAddress2)
    await tx.wait()

    ok = await ArbOwner.isPricerTxTo(pricerAddress2, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true

    tx = await ArbOwner.addPricerTxTo(pricerAddress3)
    await tx.wait()

    ok = await ArbOwner.isPricerTxTo(pricerAddress3, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true

    tx = await ArbOwner.addPricerTxTo(pricerAddress4)
    await tx.wait()

    ok = await ArbOwner.isPricerTxTo(pricerAddress4, {
      gasLimit: 500000,
    })
    expect(ok).to.be.true
  })
})
