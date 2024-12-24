import { MessageTypes, signTypedData, SignTypedDataVersion, TypedMessage } from "@metamask/eth-sig-util";




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

//Create data structs

const domainData = {
    name: "DeriwSubAccountSignature",
    version: "1",
    chainId: 55990773937,//Come back and hardcode the ID later
    verifyingContract: "0x00000000000000000000000000000000000007E9"
};

const timeUnix = Math.floor(Date.now() / 1000);

// child
const Message = {
    "Timestamp": `${timeUnix}`,
    "Operation": "Grant", // Revoke // Grant
    "Child": "0x8f48163d1932dc2286cc7d1f260e09c6ed07a1e0"
};



//Put them together in one data structure

const data: TypedMessage<MessageTypes> = {
    types: {
        EIP712Domain: domain,
        Message: typeMessage,
    },
    primaryType: "Message",
    domain: domainData,
    message: Message
};

// parent 0x94a6713cbf5f589ab51570d0b4cd219792421af2
const prvtKey = "3f924b934c41a048183b48835acdb533b1d07045a38394b006b238a3fc07ea89"

const sig = signTypedData(
    {
        privateKey: Buffer.from(prvtKey, 'hex'),
        data: data,
        version: SignTypedDataVersion.V4
    });

console.log("data", Buffer.from(JSON.stringify(data)).toString('hex') )
console.log("sig", sig)

const typeMessageRevoke = [
    { name: "Timestamp", type: "string" },
    { name: "Operation", type: "string" },
]


// child
const MessageRevoke = {
    "Timestamp": `${timeUnix}`,
    "Operation": "Revoke", // Revoke // Grant
};



//Put them together in one data structure

const dataRevoke: TypedMessage<MessageTypes> = {
    types: {
        EIP712Domain: domain,
        Message: typeMessageRevoke,
    },
    primaryType: "Message",
    domain: domainData,
    message: MessageRevoke
};


const signRevoke = signTypedData(
    {
        privateKey: Buffer.from(prvtKey, 'hex'),
        data: dataRevoke,
        version: SignTypedDataVersion.V4
    });

console.log("data", Buffer.from(JSON.stringify(dataRevoke)).toString('hex'))
console.log("sig", signRevoke)