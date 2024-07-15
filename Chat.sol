// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

contract Chat{

    struct user{
        string name;
        friend [] friendList;
    }
    
    struct friend{
        address publicKey;
        string name;
    }
    struct message{
        address sender;
        uint256 timestamp;
        string mssg;

    }

    struct allUserStruck{
        string name ;
        address accountAddress;
    }

    allUserStruck [] getAllUsers;

    mapping (address => user) userList;

    mapping(bytes32 => message[]) allMessages;

    //check user existance 
    function checkUserExist(address _publicKey) public view returns(bool){
        return bytes(userList[_publicKey].name).length>0;
    }
    
    //create account
    function createAccount(string calldata _name) external {
        require(!checkUserExist(msg.sender), "User already exist!");
        require(bytes(_name).length>0, "Username cannot be empty!");

        userList[msg.sender].name = _name;
        getAllUsers.push(allUserStruck({name : _name, accountAddress : msg.sender}));
    }

    //get username
    function getUsername(address _publicKey) external view  returns (string memory){
        require(checkUserExist(_publicKey), "user not found!");
        return userList[_publicKey].name;
    }

    //add friends
    function addFriend(address _friendKey, string memory _name) external {
        require(checkUserExist(msg.sender), "create an acconut first!");
        require(checkUserExist(_friendKey), "user not found!");
        require(checkAlreadyFriend(msg.sender, _friendKey), "already friends!");
        _addFriend(msg.sender, _friendKey, _name);
        _addFriend(_friendKey, msg.sender, userList[msg.sender].name);
        
    }

    function _addFriend(address _publicKey1, address _publicKey2, string memory  _name) internal virtual  {
        require(bytes(_name).length>0, "Username cannot be empty!");
        userList[_publicKey1].friendList.push(friend({name: _name, publicKey: _publicKey2}));
    }

    //check if already friends
    function checkAlreadyFriend(address _publicKey1, address _publicKey2) internal view virtual returns (bool){
        if(userList[_publicKey1].friendList.length>userList[_publicKey2].friendList.length){
            address temp = _publicKey1;
             _publicKey1 = _publicKey2;
             _publicKey2 = temp;
        }
        uint256 length = userList[_publicKey1].friendList.length;
        for(uint256 i=0; i<length; i++){
            if(userList[_publicKey1].friendList[i].publicKey==_publicKey2) return true;
        }
        
        return false;
    }

    //get my friends
    function getMyFriendList() external view returns(friend[] memory){
        return userList[msg.sender].friendList;
    }

    //get chat code
    function _getChatCode(address _publicKey1, address _publicKey2) internal view virtual returns(bytes32){
        if(_publicKey1<_publicKey2) return keccak256(abi.encodePacked(_publicKey1, _publicKey2));
        else return keccak256(abi.encodePacked(_publicKey2, _publicKey1));
    }

    //send message
    function sendMessage(address _friendKey, string calldata _mssg) external {
        require(checkUserExist(msg.sender), "create an account first!");
        require(checkUserExist(_friendKey), "user not found!");
        require(checkAlreadyFriend(_friendKey, msg.sender), "You're not friends");

        bytes32 chatCode = _getChatCode(msg.sender, _friendKey);
        message memory newMsg = message(msg.sender, block.timestamp, _mssg);
        allMessages[chatCode].push(newMsg); 
    }

    //read message
    function readMessage(address _friendKey) external view returns (message [] memory){
        require(checkUserExist(msg.sender), "create an acconut first!");
        require(checkUserExist(_friendKey), "user not found!");
        require(checkAlreadyFriend(msg.sender, _friendKey), "already friends!");
        bytes32 chatCode = _getChatCode(_friendKey, msg.sender);
        return allMessages[chatCode];
    }

    //get all users
    function allUsers() public view returns (allUserStruck[] memory){
        return getAllUsers;
    }
}