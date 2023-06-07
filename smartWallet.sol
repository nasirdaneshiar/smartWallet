pragma solidity 0.8.16;

contract Consumer {
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract smartWallet {

    address payable public owner;
    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGaurdianVotedBool;
    uint guardiansResetCount;
    uint public constant confirmationsFromGaurdiansForReset = 3;



    constructor(){
        owner = payable(msg.sender);
    }

    function setGaurdian(address _gaurdian, bool isGaurdian) public {
        require(msg.sender == owner,"you are not the owner, aborting");
        guardians[_gaurdian] = isGaurdian;
    }


    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender],"you are not guardian, aborting");
        require(nextOwnerGaurdianVotedBool[_newOwner][msg.sender],"You already voted , aborting");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;

        }

        guardiansResetCount++;

        if(guardiansResetCount>= confirmationsFromGaurdiansForReset){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }

    }

    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner,"you are not the owner, aborting");

        allowance[_for] = _amount;

        if(_amount > 0){
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public payable returns(bytes memory){
        //require(msg.sender ==  owner, "You are not the owner,aborting");
        if(msg.sender != owner){
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
            require(isAllowedToSend[msg.sender],"You are not allowed to send anything from this smart contract ");
            allowance[msg.sender] -= msg.value;
        }
        (bool success,bytes memory returnData)=_to.call{value:_amount}(_payload);
        return returnData;
    }

    receive() external payable {}

}
