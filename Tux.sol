pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TuxNixNFT is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {

    //To increment the id of the NFTs
    using Counters for Counters.Counter;

    //To concatenate the URL of an NFT
    using Strings for uint256;

    //Id of the next NFT to mint
    Counters.Counter private _nftIdCounter;

    //Number of NFTs in the collection
    uint public constant MAX_SUPPLY = 5;
    //Maximum number of NFTs an address can mint
    uint public max_mint_allowed = 3;
    //Price of one NFT in sale
    uint public priceSale = 0.0003 ether;

    //URI of the NFTs when revealed
    string public baseURI;
    //URI of the NFTs when not revealed
    string public notRevealedURI;
    //The extension of the file containing the Metadatas of the NFTs
    string public baseExtension = ".json";

    //Are the NFTs revealed yet ?
    bool public revealed = false;

    //Is the contract paused ?
    bool public paused = false;

    //The different stages of selling the collection
    enum Steps {
        Before,
        Sale,
        SoldOut,
        Reveal
    }

    Steps public sellingStep;
    
    //Owner of the smart contract
    address private _owner;

    //Keep a track of the number of tokens per address
    mapping(address => uint) nftsPerWallet;

    //Addresses of all the members of the team
    //address public _teamAddress = ;
    //address public _teamAddress = ;
    address public _teamAddress = 0x03cBd54271fF88D0970f1FAB2e3dE5420b1982B2;
    
    /**
    * @notice Allows to whithdraw found on the contract
    **/
    function withdraw() external onlyOwner {
            //payable(_teamAddress).transfer(address(this).balance *  5 /100);
            //payable(_teamAddress).transfer(address(this).balance * 3 / 100);
            payable(_teamAddress).transfer(address(this).balance);
    }

    //Constructor of the collection
    constructor(string memory _theBaseURI, string memory _notRevealedURI) ERC721("TUX*NIX", "TNIX") {
        _nftIdCounter.increment();
        transferOwnership(msg.sender);
        sellingStep = Steps.Before;
        baseURI = _theBaseURI;
        notRevealedURI = _notRevealedURI;
    }

    /** 
    * @notice Set pause to true or false
    *
    * @param _paused True or false if you want the contract to be paused or not
    **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /** 
    * @notice Change the number of NFTs that an address can mint
    *
    * @param _maxMintAllowed The number of NFTs that an address can mint
    **/
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }

    /**
    * @notice Change the price of one NFT for the sale
    *
    * @param _priceSale The new price of one NFT for the sale
    **/
    function changePriceSale(uint _priceSale) external onlyOwner {
        priceSale = _priceSale;
    }

    /**
    * @notice Change the base URI
    *
    * @param _newBaseURI The new base URI
    **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
    * @notice Change the not revealed URI
    *
    * @param _notRevealedURI The new not revealed URI
    **/
    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    /**
    * @notice Allows to set the revealed variable to true
    **/
    function reveal() external onlyOwner{
        revealed = true;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    * @notice Allows to change the base extension of the metadatas files
    *
    * @param _baseExtension the new extension of the metadatas files
    **/
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    /** 
    * @notice Allows to change the sellinStep to Sale
    **/
    function setUpSale() external onlyOwner {
        sellingStep = Steps.Sale;
    }

    /**
    * @notice Allows to mint NFTs
    *
    * @param _ammount The ammount of NFTs the user wants to mint
    **/
    function saleMint(uint256 _ammount) external payable nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceSale;
        //If everything has been bought
        require(sellingStep != Steps.SoldOut, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.Sale, "Sorry, sale has not started yet.");
        //Did the user then enought Ethers to buy ammount NFTs ?
        require(msg.value >= price * _ammount, "Not enought funds.");
        //The user can only mint max 3 NFTs
        require(_ammount <= max_mint_allowed, "You can't mint more than 3 tokens");
        //If the user try to mint any non-existent token
        require(numberNftSold + _ammount <= MAX_SUPPLY, "Sale is almost done and we don't have enought NFTs left.");
        //Add the ammount of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _ammount;
        //If this account minted the last NFTs available
        if(numberNftSold + _ammount == MAX_SUPPLY) {
            sellingStep = Steps.SoldOut;   
        }
        //Minting all the account NFTs
        for(uint i = 1 ; i <= _ammount ; i++) {
            _safeMint(msg.sender, numberNftSold + i);
        }
    }

    /**
    * @notice Allows to gift one NFT to an address
    *
    * @param _account The account of the happy new owner of one NFT
    **/
    function gift(address _account) external onlyOwner {
        uint supply = totalSupply();
        require(supply + 1 <= MAX_SUPPLY, "Sold out");
        _safeMint(_account, supply + 1);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        if(revealed == false) {
            return notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }

}