//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract Ownable is Context {
    address private _owner;
    address private _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function owner2() public view virtual returns (address) {
        return _owner2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwner2() {
        require(_msgSender() == _owner2 || owner() == _msgSender(), "Ownable: caller is not the owner2");
        _;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function addOwner2(address owners2) public virtual onlyOwner {
        _owner2 = owners2;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract MFIIncome is Ownable, Pausable {
    //--------------------------- EVENT --------------------------
    /**
    * @dev MFI????????????
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time, bool superUaser);

    /**
    * @dev ????????????????????????
    */
    event SetUserRewardCountEvent(uint256 time, address userAddr);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //MFI??????
    IERC20 public MfiAddress;
    //Mfi???????????????
    uint88 public MFICount;
    //????????????
    address[] public userAddress;
   
    //????????????????????????
    uint88[] public  UserRewards;
 
    struct userCount {
        //?????????????????????
        uint88 UserCanReceiveQuantity;
        //?????????????????????
        uint88 NumberOfUsersNotClaimed;
        //??????????????????
        uint88 Count;
        //?????????????????????
        bool PickUpThisWeek;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) public userData;
    // mapping(address => SuperUserCount) public SuperUserData;


    /**
    * @dev  mif??????
    */
    constructor(IERC20 _mfiAddress)  {
        MfiAddress = _mfiAddress;
    }

    //---------------------------ADMINISTRATOR FUNCTION --------------------------
    /**
    * @dev  ??????MFI??????
    * @param    _mfiAddress     mfi??????
    */
    function SetMfiAddress(IERC20 _mfiAddress) external onlyOwner {
        super._pause();
        MfiAddress = _mfiAddress;
        super._unpause();
    }  

    /**
    * @dev ??????????????????
    * @param    _userAddress    ????????????
    * @return   bool    ??????
    */
   function SetUserRewardCount(address[] memory _userAddress) external onlyOwner2 returns (bool){
        super._pause();
        UpdateUser();
        userAddress = _userAddress;
        for (uint8 i = 0; i < userAddress.length; i++) {
            userData[userAddress[i]].UserCanReceiveQuantity = UserRewards[i];
            userData[userAddress[i]].PickUpThisWeek = false;
        }
        super._unpause();
        emit SetUserRewardCountEvent(block.timestamp,_msgSender());
        return true;
    }

    /**
    * @dev ??????token
    * @param    _userAddr    ????????????
    * @param    _count   ??????
    */
    function borrow(address _userAddr, uint160 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    /**
    * @dev  ??????????????????
    * @param    _userDataArray  ????????????????????????
    */
    function SetUpTheRewardArray(uint88[] memory _userDataArray) external onlyOwner {
        super._pause();
        UserRewards = _userDataArray;
        super._unpause();
    }

    //---------------------------INQUIRE FUNCTION --------------------------
    /**
    * @dev  ??????MFI????????????
    * @param    _users  ????????????
    * @return   ???????????????,???????????????,????????????
    */

     function GetUserInformation(address _users) public view returns (uint88, uint88, uint88, bool){
        //?????????????????????
        uint88 UserCanReceiveQuantity;
        //?????????????????????
        uint88 NumberOfUsersNotClaimed;
        //??????????????????
        uint88 Count;
        //?????????????????????
        bool PickUpThisWeek;
       
        UserCanReceiveQuantity = userData[_users].UserCanReceiveQuantity;
        NumberOfUsersNotClaimed = userData[_users].NumberOfUsersNotClaimed;
        Count = userData[_users].Count;
        PickUpThisWeek = userData[_users].PickUpThisWeek;
        return (UserCanReceiveQuantity, NumberOfUsersNotClaimed, Count, PickUpThisWeek);
        
    }

    /**
    * @dev  ????????????????????????
    * @return   ????????????,????????????
    */
    function GetUserCount() public view returns (uint8, address[] memory){
        return (uint8(userAddress.length), userAddress);
    }


    //--------------------------- USER FUNCTION --------------------------
    /**
    * @dev  ????????????
    * @param    _userAddr  ????????????
    */
    function ReceiveAward(address _userAddr) external whenNotPaused {
        userCount storage userdata = userData[_userAddr];
        uint256  UserCanReceiveQuantity = userdata.UserCanReceiveQuantity;
        uint256  NumberOfUsersNotClaimed = userdata.NumberOfUsersNotClaimed;

        require(UserCanReceiveQuantity > 1000 || NumberOfUsersNotClaimed > 1000, "Without your reward:(");
        uint256 RewardCount;
        if (NumberOfUsersNotClaimed > 1000 && UserCanReceiveQuantity < 1000) {
            RewardCount = NumberOfUsersNotClaimed;
        }
        if (UserCanReceiveQuantity > 1000 && NumberOfUsersNotClaimed < 1000) {
            RewardCount = UserCanReceiveQuantity;
        }
        if (UserCanReceiveQuantity > 1000 && NumberOfUsersNotClaimed > 1000) {
            RewardCount = UserCanReceiveQuantity.add(NumberOfUsersNotClaimed);
        }
        userdata.UserCanReceiveQuantity = 0;
        userdata.NumberOfUsersNotClaimed = 0;
        userdata.Count++;
        userdata.PickUpThisWeek = true;

        MfiAddress.safeTransfer(_userAddr, RewardCount);
    }

    /**
    * @dev   ????????????
    */
    function UpdateUser() private {
        for (uint256 i = 0; i < userAddress.length; i++) {
            judgment(userAddress[i]);
        }
    }


    /**
    * @dev   ??????????????????
    * @param  _useradd  ????????????
    */
    function judgment(address _useradd) private {
        if (userData[_useradd].PickUpThisWeek == false) {
            userData[_useradd].NumberOfUsersNotClaimed += userData[_useradd].UserCanReceiveQuantity;
            userData[_useradd].UserCanReceiveQuantity = 0;
        }
    }

}

