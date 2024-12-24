import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { abi as DeriwSubAccount__abi } from '../../../build/contracts/src/precompiles/DeriwSubAccount.sol/DeriwSubAccount.json'
import { abi as DeriwSubAccountPublic__abi } from '../../../build/contracts/src/precompiles/DeriwSubAccountPublic.sol/DeriwSubAccountPublic.json'
import { MessageTypes, signTypedData, SignTypedDataVersion, TypedMessage } from "@metamask/eth-sig-util";
import { BigNumber } from 'ethers'
import { TestToken__factory } from '../../../build/types'


// npx hardhat test test/e2e/precompile/subaccountPublic.ts --network local

const domain = [
    { name: "name", type: "string" },
    { name: "version", type: "string" },
    { name: "chainId", type: "uint256" },
    { name: "verifyingContract", type: "address" }
]

const typeMessage = [
    { name: "Timestamp", type: "string" },
    { name: "Operation", type: "string" },
    { name: "Child", type: "address" },
]
const typeMessageRevoke = [
    { name: "Timestamp", type: "string" },
    { name: "Operation", type: "string" },
]

const domainData = {
    name: "DeriwSubAccountSignature",
    version: "1",
    chainId: 42691720113,//Come back and hardcode the ID later
    verifyingContract: "0x00000000000000000000000000000000000007E9"
};

const message = {
    "Timestamp": `0`,
    "Operation": "Grant", // Revoke // Grant
    "Child": "0x8f48163d1932dc2286cc7d1f260e09c6ed07a1e0"
};
const messageRevoke = {
    "Timestamp": `0`,
    "Operation": "Grant", // Revoke // Grant
};

const subaccountAddress = '0x00000000000000000000000000000000000007EA'
const subaccountPublicAddress = '0x00000000000000000000000000000000000007E9'
const usdtAddress = '0xd7ba14B43f0530eEB4EA1c279DfC47Bf8F55f766'
const allowedAddress = '0xB370ae496175E438DfBee2E1E0748B50AE901860'

type domainDataType = typeof domainData
type messageType = typeof message | typeof messageRevoke

const signGrantAction = (domainData: domainDataType, messsage: messageType): TypedMessage<MessageTypes> => {
    const data: TypedMessage<MessageTypes> = {
        types: {
            EIP712Domain: domain,
            Message: typeMessage,
        },
        primaryType: "Message",
        domain: domainData,
        message: messsage
    };
    return data;
}


const signRevokeAction = (domainData: domainDataType, messsage: messageType): TypedMessage<MessageTypes> => {
    const data: TypedMessage<MessageTypes> = {
        types: {
            EIP712Domain: domain,
            Message: typeMessageRevoke,
        },
        primaryType: "Message",
        domain: domainData,
        message: messsage
    };
    return data;
}

describe('SubAccountPublic', function () {

    let parentSigner: SignerWithAddress
    let childSigner: SignerWithAddress

    const subAccountABI = DeriwSubAccount__abi
    const subAccountPublicABI = DeriwSubAccountPublic__abi


    beforeEach(async function () {
        // other of signer... take note
        const [owner, signer2, signer3] = await ethers.getSigners()

        parentSigner = signer2
        childSigner = signer3

        const ownerControl = new ethers.Contract(
            subaccountAddress,
            subAccountABI,
            owner
        )

        let tx = await ownerControl.addAllowedAddress(allowedAddress)
        await tx.wait()
        tx = await ownerControl.setUsdtAddress(usdtAddress)
        await tx.wait()
    })

    it('SubAccountOwner', async function () {

        const childControl = new ethers.Contract(
            subaccountPublicAddress,
            subAccountPublicABI,
            childSigner
        )


        // grant
        let domainData = {
            name: "DeriwSubAccountSignature",
            version: "1",
            chainId: 42691720113,//Come back and hardcode the ID later
            verifyingContract: subaccountPublicAddress
        }
        let timeUnix = Math.floor(Date.now() / 1000);
        let mailData = {
            "Timestamp": `${timeUnix}`,
            "Operation": "Grant", // Revoke // Grant
            "Child": childSigner.address
        }

        let signData = signGrantAction(domainData, mailData)

        const prvtKey = "3f924b934c41a048183b48835acdb533b1d07045a38394b006b238a3fc07ea89"

        const sig = signTypedData(
            {
                privateKey: Buffer.from(prvtKey, 'hex'),
                data: signData,
                version: SignTypedDataVersion.V4
            });

        let tx = await childControl.grantAccountControl("0x" + Buffer.from(JSON.stringify(signData)).toString('hex'), sig, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        await tx.wait()

        let addressChildControl = await childControl.readAccountControl(childSigner.address)
        expect(addressChildControl).to.be.equal(parentSigner.address)

        let respond = await childControl.isValidAccountSession(childSigner.address)

        expect(respond[0]).to.be.true

        return

        // revoke
        domainData = {
            name: "DeriwSubAccountSignature",
            version: "1",
            chainId: 42691720113,//Come back and hardcode the ID later
            verifyingContract: subaccountAddress
        }
        timeUnix = Math.floor(Date.now() / 1000);
        let mailDataRevoke = {
            "Timestamp": `${timeUnix}`,
            "Operation": "Revoke", // Revoke // Grant
        }


        signData = signRevokeAction(domainData, mailDataRevoke)

        const signedData = signTypedData(
            {
                privateKey: Buffer.from(prvtKey, 'hex'),
                data: signData,
                version: SignTypedDataVersion.V4
            });

        tx = await childControl.revokeAccountControl("0x" + Buffer.from(JSON.stringify(signData)).toString('hex'), signedData, { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        await tx.wait()

        addressChildControl = await childControl.readAccountControl(childSigner.address)
        expect(addressChildControl).to.be.equal("0x0000000000000000000000000000000000000000")

        // let isValidSession = await childControl.isValidAccountSession(childSigner.address)
        // expect(isValidSession[0]).to.be.false
    })

    it('SubAccountSender', async function () {
        const childControl = new ethers.Contract(
            usdtAddress,
            TestToken__factory.abi,
            childSigner
        )

        let tx = await childControl.approve(allowedAddress, "1000000000000000000000", { maxFeePerGas: BigNumber.from(0), maxPriorityFeePerGas: BigNumber.from(0) })
        await tx.wait()

    })

})
