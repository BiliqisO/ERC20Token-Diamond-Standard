// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";
import "../contracts/facets/ERC20Facet.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC20Facet erc20Facet;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            "BiliBabyToken",
            "BBT"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(erc20Facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC20Facet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testName() public {
        assertEq(ERC20Facet(address(diamond)).name(), "BiliBabyToken");
    }

    function testMint() public {
        ERC20Facet(address(diamond)).mint();
        assertEq(ERC20Facet(address(diamond)).totalSupply(), 1_000_000_000e18);
    }

    function testFailMint() public {
        vm.prank(address(1));
        ERC20Facet(address(diamond)).mint();
        assertEq(ERC20Facet(address(diamond)).totalSupply(), 1_000_000_000e18);
    }

    function testTransfer() public {
        ERC20Facet(address(diamond)).mint();
        ERC20Facet(address(diamond)).transfer(address(1), 2000000);
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(1)), 2000000);
    }

    function testFailTransfer() public {
        ERC20Facet(address(diamond)).transfer(address(1), 2000000);
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(1)), 2000000);
    }

    function testAllowance() public {
        ERC20Facet(address(diamond)).mint();
        ERC20Facet(address(diamond)).approve(address(1), 100000);
        assertEq(
            ERC20Facet(address(diamond)).allowance(address(this), address(1)),
            100000
        );
    }

    function testTransferFrom() public {
        ERC20Facet(address(diamond)).mint();
        ERC20Facet(address(diamond)).approve(address(1), 100000);
        vm.prank(address(1));
        ERC20Facet(address(diamond)).transferFrom(
            address(this),
            address(2),
            100000
        );
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(1)), 0);
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(2)), 100000);
    }

    function testFailTransferFrom() public {
        ERC20Facet(address(diamond)).mint();
        ERC20Facet(address(diamond)).approve(address(1), 100000);
        ERC20Facet(address(diamond)).transferFrom(
            address(this),
            address(2),
            100000
        );
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(1)), 0);
        assertEq(ERC20Facet(address(diamond)).balanceOf(address(2)), 100000);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
