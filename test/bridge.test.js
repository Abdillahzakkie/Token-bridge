const { ethers } = require("hardhat");
const { expect } = require("chai");

const toWei = (_amount) => ethers.utils.parseEther(_amount.toString());
const fromWei = (_amount) =>
	parseFloat(ethers.utils.formatEther(_amount.toString()));
// const toHex = (_value) => ethers.utils.hexlify(_value);

describe("Bridge", () => {
	let deployer, moderator, user1, user2, user3;
	beforeEach(async () => {
		[deployer, moderator, user1, user2, user3] = await ethers.getSigners();

		const BridgeA = await ethers.getContractFactory("Bridge");
		const BridgeB = await ethers.getContractFactory("Bridge");

		const ERC20 = await ethers.getContractFactory("MyToken");

		this.tokenA = await ERC20.connect(deployer).deploy();
		this.tokenB = await ERC20.connect(deployer).deploy();

		this.bridgeA = await BridgeA.connect(deployer).deploy();
		this.bridgeB = await BridgeB.connect(deployer).deploy();

		// initialize contracts
		await this.tokenA.connect(deployer).initialize();
		await this.tokenB.connect(deployer).initialize();
		await this.bridgeA.connect(deployer).initialize(moderator.address);
		await this.bridgeB.connect(deployer).initialize(moderator.address);

		// register new chainIds
		await this.bridgeA.connect(moderator).addNewChain(1);
		await this.bridgeA
			.connect(moderator)
			.addNewChain(await this.bridgeA.CHAIN_ID());

		await this.bridgeB.connect(moderator).addNewChain(1);
		await this.bridgeB
			.connect(moderator)
			.addNewChain(await this.bridgeB.CHAIN_ID());
	});

	describe("deployment", () => {
		it("should deploy contracts properly", () => {
			expect(this.tokenA.address).not.null;
			expect(this.tokenA.address).not.undefined;

			expect(this.tokenB.address).not.null;
			expect(this.tokenB.address).not.undefined;

			expect(this.bridgeA.address).not.null;
			expect(this.bridgeA.address).not.undefined;

			expect(this.bridgeB.address).not.null;
			expect(this.bridgeB.address).not.undefined;
		});
	});

	describe("submitMapRequest", () => {
		let _mapDetails = [];

		beforeEach(async () => {
			_mapDetails = Object.values({
				token0: this.tokenA.address,
				token1: this.tokenB.address,
				token0ChainId: 1,
				token1ChainId: await this.bridgeB.CHAIN_ID(),
				email: "zakariyyaopeyemi@gmail.com",
			});
		});

		it("should request token mapping", async () => {
			await expect(this.bridgeA.connect(user1).submitMapRequest(..._mapDetails))
				.to.emit(this.bridgeA, "TokenMapRequest")
				.withArgs(..._mapDetails);
		});
	});
});
