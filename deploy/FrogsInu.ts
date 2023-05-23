
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const accounts = await hre.getNamedAccounts();
    const deployer = accounts.admin;

    const args = [
        "0x10ed43c718714eb63d5aa57b78b54704e256024e", // pancake swap
        "0xd159c4d00660e6BAd7f06e30CDF3570903f2bbC2",
    ];
    const {address} = await hre.deployments.deploy("FrogsInu", {
        from: deployer,
        args: args,
        log: true,
    });

    await hre.run("verify:verify", {
        address: address,
        constructorArguments: args
    });
};

func.tags = ["FrogsInu"];

export default func;
