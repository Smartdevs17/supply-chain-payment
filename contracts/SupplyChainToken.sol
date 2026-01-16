// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SupplyChainToken
 * @dev Platform utility token with staking and reward distribution
 */
contract SupplyChainToken is ERC20, Ownable {
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardDebt;
    }

    // Token configuration
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18; // 1 million tokens
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10**18; // 10 million tokens
    
    // Staking configuration
    uint256 public rewardRate = 10; // 10% annual reward rate
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public totalStaked;
    
    // Mappings
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public rewards;
    
    // Events
    event TokensMinted(address indexed to, uint256 amount, uint256 timestamp);
    event TokensBurned(address indexed from, uint256 amount, uint256 timestamp);
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event RewardRateUpdated(uint256 newRate, uint256 timestamp);

    constructor() ERC20("SupplyChain Token", "SCT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Mint new tokens (owner only)
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");
        
        _mint(_to, _amount);
        
        emit TokensMinted(_to, _amount, block.timestamp);
    }

    /**
     * @dev Burn tokens
     */
    function burn(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        _burn(msg.sender, _amount);
        
        emit TokensBurned(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Stake tokens
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        // Calculate and save pending rewards before updating stake
        if (stakes[msg.sender].amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            rewards[msg.sender] += pendingReward;
        }
        
        // Transfer tokens to contract
        _transfer(msg.sender, address(this), _amount);
        
        // Update stake info
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].rewardDebt = 0;
        
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Unstake tokens
     */
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].amount >= _amount, "Insufficient staked amount");
        
        // Calculate and save pending rewards
        uint256 pendingReward = calculateReward(msg.sender);
        rewards[msg.sender] += pendingReward;
        
        // Update stake info
        stakes[msg.sender].amount -= _amount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].rewardDebt = 0;
        
        totalStaked -= _amount;
        
        // Transfer tokens back to user
        _transfer(address(this), msg.sender, _amount);
        
        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Claim staking rewards
     */
    function claimRewards() external {
        uint256 pendingReward = calculateReward(msg.sender);
        uint256 totalReward = rewards[msg.sender] + pendingReward;
        
        require(totalReward > 0, "No rewards to claim");
        require(totalSupply() + totalReward <= MAX_SUPPLY, "Exceeds max supply");
        
        // Reset rewards and update stake time
        rewards[msg.sender] = 0;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].rewardDebt = 0;
        
        // Mint reward tokens
        _mint(msg.sender, totalReward);
        
        emit RewardClaimed(msg.sender, totalReward, block.timestamp);
    }

    /**
     * @dev Calculate pending rewards for a user
     */
    function calculateReward(address _user) public view returns (uint256) {
        StakeInfo memory userStake = stakes[_user];
        
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        uint256 reward = (userStake.amount * rewardRate * stakingDuration) / (SECONDS_PER_YEAR * 100);
        
        return reward;
    }

    /**
     * @dev Get total pending rewards (saved + pending)
     */
    function getPendingRewards(address _user) external view returns (uint256) {
        return rewards[_user] + calculateReward(_user);
    }

    /**
     * @dev Get stake info for a user
     */
    function getStakeInfo(address _user) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 pendingRewards
    ) {
        StakeInfo memory userStake = stakes[_user];
        return (
            userStake.amount,
            userStake.startTime,
            rewards[_user] + calculateReward(_user)
        );
    }

    /**
     * @dev Update reward rate (owner only)
     */
    function updateRewardRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0 && _newRate <= 100, "Invalid rate (1-100)");
        
        rewardRate = _newRate;
        
        emit RewardRateUpdated(_newRate, block.timestamp);
    }

    /**
     * @dev Distribute rewards to multiple users (owner only)
     */
    function distributeRewards(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        require(_users.length == _amounts.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Invalid address");
            require(totalSupply() + _amounts[i] <= MAX_SUPPLY, "Exceeds max supply");
            
            _mint(_users[i], _amounts[i]);
            emit TokensMinted(_users[i], _amounts[i], block.timestamp);
        }
    }

    /**
     * @dev Get total staked tokens
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    /**
     * @dev Get current reward rate
     */
    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }
}
