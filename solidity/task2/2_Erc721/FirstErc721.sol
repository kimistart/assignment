//SPDX-License-Identifier:MIT
//by 0xAA
pragma solidity ^0.8.21;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./String.sol";

contract FirstErc721 {
    using Strings for uint;

    string public _name;
    string public _symbol;
    mapping(uint => address) private _owners; //tokenId 到 owner address 的持有人
    mapping(address => uint) private _balances; //address 到 持仓数量
    mapping(uint => address) private _tokenApprovls; //tokenId 到 授权地址
    //owner地址 到 operator地址 的批量映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //ERC721

    event Transfer(address indexed from,address indexed to,uint indexed tokenId);

    event Approval(address indexed owner,address indexed approved,uint indexed tokenId);

    event ApprovalForAll(address indexed owner,address indexed operator,bool indexed approved);

    error ERC721InvalidReceiver(address receiver);

    constructor(string memory name_,string memory symbol_){
        _name = name_;
        _symbol = symbol_;
    }

    //165
    function supportsInterface(bytes4 interfaceId) external pure returns(bool) {
        return 
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    //721
    function balanceOf(address owner) external view returns(uint) {
        require(owner != address(0), "owner=zero address");
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view returns(address owner) {
        owner = _owners[tokenId];
        require(owner != address(0),"token doesn't exist");
    }


    //是否批量授权
    function isApprovedForAll(address owner,address operator) external view returns(bool){
        return _operatorApprovals[owner][operator];
    }

    function setApproveForAll(address operator,bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 实现IERC721的getApproved，利用_tokenApprovals变量查询tokenId的授权地址。
    function getApproved(uint tokenId) external view returns (address) {
        require(_owners[tokenId]!= address(0),"token doesn't exist");
        return _tokenApprovls[tokenId];
    }

    //将tokenId授权给 to 地址。条件：to不是owner，且msg.sender是owner或授权地址。调用_approve函数
    function approve(address to,uint tokenId) public {
       address owner = _owners[tokenId];
       require(msg.sender == owner || _operatorApprovals[owner][msg.sender],"not owner or approved for all");
       _approve(owner,to,tokenId);
    }

    function _approve(address owner,address to,uint tokenId) private {
        _tokenApprovls[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // 实现IERC721的transferFrom，非安全转账，不建议使用。调用_transfer函数
    // 实现IERC721的ownerOf，利用_owners变量查询tokenId的owner。
    // function ownerOf(uint tokenId) public view override returns (address owner) {
    function transferFrom(address from,address to,uint tokenId) external {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner,msg.sender,tokenId),"not owner nor approved");
        _transfer(owner,from,to,tokenId);
    }

    function _isApprovedOrOwner(address owner,address spender,uint tokenId) private view returns (bool) {
        return (spender == owner ||
                _tokenApprovls[tokenId] == spender ||
                _operatorApprovals[owner][spender]);
    }

    /*
     * 转账函数。通过调整_balances和_owner变量将 tokenId 从 from 转账给 to，同时释放Transfer事件。
     * 条件:
     * 1. tokenId 被 from 拥有
     * 2. to 不是0地址
     */
    function _transfer(address owner,address from,address to,uint tokenId) private {
        require(from == owner,"not owner");
        require(to != address(0),"transfer to the zero address");

        _approve(owner,address(0),tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from,to,tokenId);

    }

    /**
     * 安全转账，安全地将 tokenId 代币从 from 转移到 to，会检查合约接收者是否了解 ERC721 协议，以防止代币被永久锁定。
     * 调用了_transfer函数和_checkOnERC721Received函数。条件：
     * from 不能是0地址.
     * to 不能是0地址.
     * tokenId 代币必须存在，并且被 from拥有.
     * 如果 to 是智能合约, 他必须支持 IERC721Receiver-onERC721Received.
     */
     function safeTransferFrom(address from,address to,uint tokenId,bytes memory _data) public {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner, msg.sender, tokenId),"not owner nor approved");
        _safeTransfer(owner,from,to,tokenId,_data);
     }

     function _safeTransfer(address owner,address from,address to,uint tokenId,bytes memory _data) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from,to,tokenId,_data);
     }

     function _checkOnERC721Received(address from,address to,uint tokenId,bytes memory _data) private {
        
     }

    //metadata
    function name() public view  virtual returns (string memory) {
        return _name;
    }

    function symbol() public view  virtual  returns (string memory) {
        return _symbol;
    }

    //通过tokenId查询metadata的链接url
    function tokenURI(uint tokenId) external view returns (string memory) {
        require(_owners[tokenId]!=address(0),"Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length >0 ? string.concat(baseURI,tokenId.toString()):"";
    }

    function _baseURI() internal pure returns (string memory) {
        return "";
    }





}