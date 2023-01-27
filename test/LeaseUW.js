const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

describe('LeaseUW', () => {

    let lessee, lessor, inspector
    let rentalUnit, leaseUW
    const unitID = 1

    beforeEach(async () => {
       // Setup accounts
       [lessee, lessor, inspector] = await ethers.getSigners()

       // Deploy Rental Unit
       const RentalUnit = await ethers.getContractFactory('RentalUnit');
       rentalUnit = await RentalUnit.deploy()

       // Mint
       let transaction = await rentalUnit.connect(lessor).mint("https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS")
       await transaction.wait()

       const LeaseUW = await ethers.getContractFactory('LeaseUW')
       leaseUW = await LeaseUW.deploy(
           rentalUnit.address,
           lessor.address,
           inspector.address
       )

       // Approve property
       transaction = await rentalUnit.connect(lessor).approve(leaseUW.address, unitID)
       await transaction.wait()

       // List property
       transaction = await leaseUW.connect(lessor).list(unitID, lessee.address, tokens(1), tokens(5))
       await transaction.wait()
    })

    describe('Deployment', () => {
        it('Returns NFT address', async () => {
            const result = await leaseUW.nftAddress()
            expect(result).to.be.equal(rentalUnit.address)
        })
    
        it('Returns lessor', async () => {
            const result = await leaseUW.lessor()
            expect(result).to.be.equal(lessor.address)
        })
    
        it('Returns inspector', async () => {
            const result = await leaseUW.inspector()
            expect(result).to.be.equal(inspector.address)
        })
    })

    describe('Listing', () => {

        it('Updates as listed', async () => {
            const result = await leaseUW.isListed(1)
            expect(result).to.be.equal(true)
        })

        it('Updates ownership', async () => {
          expect(await rentalUnit.ownerOf(unitID)).to.be.equal(leaseUW.address)  
        })

        it('Returns lessee', async () => {
            const result = await leaseUW.lessee(unitID);
            expect(result).to.be.equal(lessee.address);
        })

        it('Returns deposit', async () => {
            const result = await leaseUW.deposit(unitID);
            expect(result).to.be.equal(tokens(1));
        })

        it('Returns rent', async () => {
            const result = await leaseUW.rent(unitID);
            expect(result).to.be.equal(tokens(5));
        })

    })


    describe('Pay Deposit', () => {
        it('Updates contract balance', async () => {
            const transaction = await leaseUW.connect(lessee).payDeposit(unitID, { value: tokens(1) })
            await transaction.wait()
            const result = await leaseUW.getBalance()
            expect(result).to.be.equal(tokens(1))
        })
    })

    describe('Inspection', () => {
        it('Updates inspection status', async () => {
            const transaction = await leaseUW.connect(inspector).inspect(unitID, true)
            await transaction.wait()
            const result = await leaseUW.inspected(unitID)
            expect(result).to.be.equal(true)
        })
    })

    describe('Approval', () => {
        it('Updates approval status', async () => {
            let transaction = await leaseUW.connect(lessee).approveLease(unitID)
            await transaction.wait()

            transaction = await leaseUW.connect(lessor).approveLease(unitID)
            await transaction.wait()

            expect(await leaseUW.approval(unitID, lessee.address)).to.be.equal(true)
            expect(await leaseUW.approval(unitID, lessor.address)).to.be.equal(true)      
        })
    })

    describe('Lease', async () => {
        beforeEach(async () => {
            let transaction = await leaseUW.connect(lessee).payDeposit(unitID, { value: tokens(1) })
            await transaction.wait()

            transaction = await leaseUW.connect(inspector).inspect(unitID, true)
            await transaction.wait()

            transaction = await leaseUW.connect(lessee).approveLease(unitID)
            await transaction.wait()

            transaction = await leaseUW.connect(lessor).approveLease(unitID)
            await transaction.wait()

            await lessee.sendTransaction({ to: leaseUW.address, value: tokens(5) })

            transaction = await leaseUW.connect(lessor).finalizeLease(unitID)
            await transaction.wait()
        })

        it('Updates balance', async () => {
            expect(await leaseUW.getBalance()).to.be.equal(0)
        })
    })

})
