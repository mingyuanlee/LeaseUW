//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    // External functions are the type of functions that are part of the contract but can only
    //  be used externally and called outside the contract by the other contracts. 
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract LeaseUW {
    // This is the NFT smart contract address
    address public nftAddress;
    address payable public lessor;
    address public inspector;

    modifier onlyLessee(uint256 _nftID) {
        require(msg.sender == lessee[_nftID], "Only lessee can call this method");
        _;
    }

    modifier onlyLessor() {
        require(msg.sender == lessor, "Only lessor can call this method");
        _;
    }
    
    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    // Is the rental unit list on the blockchain?
    mapping(uint256 => bool) public isListed;
    // The first month rent amount
    mapping(uint256 => uint256) public rent;
    // The deposit amount and if the deposit is made by lessee
    mapping(uint256 => uint256) public deposit;
    mapping(uint256 => bool) public depositPaid;
    // The rental unit and its lessee
    mapping(uint256 => address) public lessee;
    // Is the lease inspected?
    mapping(uint256 => bool) public inspected;
    // For each rental unit, record if the lessor or lessee approves
    mapping(uint256 => mapping(address => bool)) public approval;

    constructor(
        address _nftAddress, 
        address payable _lessor,
        address _inspector
    ) {
        nftAddress = _nftAddress;
        lessor = _lessor;
        inspector = _inspector;
    }

    // 1. List the NFT on the blockchain
    // 2. _nftID is the NFT token ID
    function list(
        uint256 _nftID, 
        address _lessee, 
        uint256 _deposit,
        uint256 _rent
    ) public payable onlyLessor {
        // Transfer NFT from lessor to contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);
    
        isListed[_nftID] = true;
        deposit[_nftID] = _deposit;
        rent[_nftID] = _rent;
        lessee[_nftID] = _lessee;
    
    }

    function approveLease(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    function payDeposit(uint256 _nftID) public payable onlyLessee(_nftID) {
        require(msg.value == deposit[_nftID]);
        depositPaid[_nftID] = true;
    }

    function inspect(uint256 _nftID, bool _passed) public onlyInspector {
        inspected[_nftID] = _passed;
    }

    // Cancel Lease (handle deposit)
    // Idea: We can also set a time period within which the lessee can get the refund
    function cancelLease(uint256 _nftID) public {
        // refund to lessee
        payable(lessee[_nftID]).transfer(address(this).balance);
    }

    // For this contract to receive money
    receive() external payable {}

    // Get the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Finalize Lease
    // 1. The lessee should pay deposit
    // 2. The lease needs to be inspected
    // 3. The lessor and lessee should approve the lease
    // 4. The rent should be paid
    // 5. Transfer NFT to lessee
    // 6. Transfer rent to lessor
    function finalizeLease(uint256 _nftID) public {
        require(depositPaid[_nftID]);
        require(inspected[_nftID]);
        require(approval[_nftID][lessee[_nftID]]);
        require(approval[_nftID][lessor]);
        require(address(this).balance >= rent[_nftID] + deposit[_nftID]);

        isListed[_nftID] = false;

        (bool success, ) = payable(lessor).call{value: address(this).balance}("");
        
        require(success);

        IERC721(nftAddress).transferFrom(address(this), lessee[_nftID], _nftID);
    }

}
