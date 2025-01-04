// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Governance.sol";
import "./BondingCurveWithDAO.sol";

/**
 * @title BondingCurveFactory
 * @dev This contract is responsible for deploying and managing bonding curve contracts.
 * It supports both admin-controlled and DAO-based governance modes.
 */
contract BondingCurveFactory is ReentrancyGuard {
    // State variables
    address public admin; // Address of the factory admin
    bool public useDAO; // Toggle to determine if DAO governance is active
    Governance public governance; // Shared governance contract
    uint256 public protocolFee; // Global protocol fee in basis points (e.g., 200 = 2%)
    address public protocolFeeRecipient; // Address to receive protocol fees

    // Mappings to track deployed bonding curves
    mapping(address => address[]) public deployedBondingCurves; // Maps deployer to their bonding curve contracts
    address[] public allBondingCurves; // List of all bonding curve contracts deployed

    // Events
    event BondingCurveDeployed(
        address indexed deployer,
        address indexed bondingCurveAddress,
        uint256 initialFee
    );
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);
    event ProtocolFeeRecipientUpdated(address oldRecipient, address newRecipient);
    event GovernanceToggled(bool useDAO);
    event EmergencyModeTriggered();

    /**
     * @dev Constructor to initialize the factory.
     * @param _protocolFee Initial protocol fee in basis points.
     * @param _protocolFeeRecipient Address to receive protocol fees.
     * @param _daoToken Address of the governance token used for the shared governance.
     * @param _initialQuorum Initial DAO quorum in basis points (e.g., 5000 = 50%).
     */
    constructor(
        uint256 _protocolFee,
        address _protocolFeeRecipient,
        address _daoToken,
        uint256 _initialQuorum
    ) {
        require(_protocolFee <= 1000, "Fee exceeds max limit"); // Maximum fee is 10%
        require(_protocolFeeRecipient != address(0), "Invalid fee recipient");

        admin = msg.sender;
        protocolFee = _protocolFee;
        protocolFeeRecipient = _protocolFeeRecipient;

        // Initialize the shared governance contract
        governance = new Governance(_daoToken, _initialQuorum);
    }

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not the admin");
        _;
    }

    modifier onlyDAO() {
        require(useDAO, "DAO governance not active");
        _;
    }

    /**
     * @dev Toggles governance between admin and DAO.
     *      Once DAO governance is active, admin control is disabled.
     */
    function toggleGovernance() external onlyAdmin {
        require(!useDAO, "DAO already active");
        useDAO = true;
        emit GovernanceToggled(true);
    }

    /**
     * @dev Deploys a new Bonding Curve contract.
     * @param _uniswapRouter Address of the Uniswap V2 router.
     * @param _liquidityToken Address of the liquidity token to pair with (e.g., WETH).
     * @param _governanceToken Address of the governance token for DAO voting in the bonding curve.
     * @param _targetLiquidity Threshold reserve balance to trigger liquidity addition.
     * @param _daoQuorum Initial quorum for the Bonding Curve's DAO (e.g., 5000 = 50%).
     * @param _lockedLiquidity Boolean indicating whether liquidity should be locked.
     * @return Address of the newly deployed bonding curve contract.
     */
    function deployBondingCurve(
        address _uniswapRouter,
        address _liquidityToken,
        address _governanceToken,
        uint256 _targetLiquidity,
        uint256 _daoQuorum,
        bool _lockedLiquidity
    ) external returns (address) {
        require(_uniswapRouter != address(0), "Invalid Uniswap router");
        require(_liquidityToken != address(0), "Invalid liquidity token");
        require(_governanceToken != address(0), "Invalid governance token");
        require(_daoQuorum > 0 && _daoQuorum <= 10000, "Invalid DAO quorum");

        // Deploy the Bonding Curve contract
        BondingCurveWithDAO bondingCurve = new BondingCurveWithDAO(
            _uniswapRouter,
            _liquidityToken,
            address(governance),
            _targetLiquidity,
            _daoQuorum,
            _lockedLiquidity
        );

        // Track the deployment
        deployedBondingCurves[msg.sender].push(address(bondingCurve));
        allBondingCurves.push(address(bondingCurve));

        emit BondingCurveDeployed(msg.sender, address(bondingCurve), protocolFee);
        return address(bondingCurve);
    }

    /**
     * @dev Updates the global protocol fee. Only callable by DAO governance.
     * @param _newFee New protocol fee in basis points (max 10%).
     */
    function updateProtocolFee(uint256 _newFee) external onlyDAO {
        require(_newFee <= 1000, "Fee exceeds max limit"); // Maximum fee is 10%
        emit ProtocolFeeUpdated(protocolFee, _newFee);
        protocolFee = _newFee;
    }

    /**
     * @dev Updates the protocol fee recipient address. Only callable by DAO governance.
     * @param _newRecipient New recipient address for protocol fees.
     */
    function updateProtocolFeeRecipient(address _newRecipient) external onlyDAO nonReentrant {
        require(_newRecipient != address(0), "Invalid recipient address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @dev Triggers emergency mode in the shared Governance contract. Only callable by the admin.
     */
    function triggerEmergencyMode() external onlyAdmin {
        governance.triggerEmergency();
        emit EmergencyModeTriggered();
    }

    /**
     * @dev Returns all bonding curve contracts deployed by a specific address.
     * @param deployer Address of the deployer.
     * @return Array of bonding curve addresses deployed by the given address.
     */
    function getDeployedBondingCurves(address deployer) external view returns (address[] memory) {
        return deployedBondingCurves[deployer];
    }

    /**
     * @dev Returns all bonding curve contracts deployed through the factory.
     * @return Array of all bonding curve addresses deployed.
     */
    function getAllBondingCurves() external view returns (address[] memory) {
        return allBondingCurves;
    }
}