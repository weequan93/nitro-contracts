import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { abi as DeriwSubAccount__abi } from '../../../build/contracts/src/precompiles/DeriwSubAccount.sol/DeriwSubAccount.json'
import { BigNumber } from 'ethers'

// npx hardhat test test/e2e/precompile/subaccount.ts --network local

describe('SubAccount', function () {
    let chainOwner: SignerWithAddress
    let subAccountOwner: SignerWithAddress  
    
    const allowedAddress = "0xB370ae496175E438DfBee2E1E0748B50AE901860"

    const subAccountABI = DeriwSubAccount__abi
    const subaccountAddress = '0x00000000000000000000000000000000000007EA'
    const usdtAddress = '0xd7ba14B43f0530eEB4EA1c279DfC47Bf8F55f766'

    beforeEach(async function () {
        const [signer, signer2, signer3, signer4] = await ethers.getSigners()

        chainOwner = signer
        subAccountOwner = signer4
    })

    it('SubAccountOwner', async function () {

        const chainOwnerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            chainOwner
        )

        let tx = await chainOwnerControl.addSubAccountOwner(subAccountOwner.address)
        await tx.wait()

        let ok = await chainOwnerControl.isSubAccountOwner(subAccountOwner.address)
        expect(ok).to.be.true

        tx = await chainOwnerControl.removeSubAccountOwner(subAccountOwner.address)
        await tx.wait()

        ok = await chainOwnerControl.isSubAccountOwner(subAccountOwner.address)
        expect(ok).to.be.false

    })

    it('AllowedAddress', async function () {
        const chainOwnerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            chainOwner
        )

        let tx = await chainOwnerControl.addSubAccountOwner(subAccountOwner.address)
        await tx.wait()

        let ok = await chainOwnerControl.isSubAccountOwner(subAccountOwner.address)
        expect(ok).to.be.true

        const subAccountOwnerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            subAccountOwner
        )

        ok = await subAccountOwnerControl.isAllowedAddress(allowedAddress)
        if (ok){
            tx = await subAccountOwnerControl.removeAllowedAddress(allowedAddress, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
            await tx.wait()
        }

       
        ok = await subAccountOwnerControl.isAllowedAddress(allowedAddress)
        expect(ok).to.be.false

        tx = await subAccountOwnerControl.addAllowedAddress(allowedAddress, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        await tx.wait()

        ok = await subAccountOwnerControl.isAllowedAddress(allowedAddress)
        expect(ok).to.be.true

        tx = await subAccountOwnerControl.removeAllowedAddress(allowedAddress, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0)  })
        await tx.wait()

        ok = await subAccountOwnerControl.isAllowedAddress(allowedAddress)
        expect(ok).to.be.false

        tx = await subAccountOwnerControl.addAllowedAddress(allowedAddress, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        await tx.wait()
    })

    it('UsdtAddress', async function () {
        const chainOwnerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            chainOwner
        )

        let tx = await chainOwnerControl.addSubAccountOwner(subAccountOwner.address)
        await tx.wait()

        let ok = await chainOwnerControl.isSubAccountOwner(subAccountOwner.address)
        expect(ok).to.be.true

        const subAccountOwnerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            subAccountOwner
        )


        tx = await subAccountOwnerControl.setUsdtAddress(usdtAddress, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        
        await tx.wait()

        let usdt = await subAccountOwnerControl.getUsdtAddress()
        expect(usdt).to.be.equal(usdtAddress)

    })

})
