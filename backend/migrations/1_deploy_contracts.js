const WineProduction = artifacts.require("WineProduction");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(WineProduction);
  const instance = await WineProduction.deployed();

  const adminAccount = accounts[0];
  
  // GENERIAMO L'HASH (bytes32) RICHIESTO DAL CONTRATTO
  const roleHash = web3.utils.keccak256("ADMIN");

  try {
    // Ora passiamo l'hash, non la stringa
    await instance.assignRole(adminAccount, roleHash, { from: adminAccount });
    
    console.log("---------------------------------------------------");
    console.log("ADMIN assegnato con successo via bytes32!");
    console.log("---------------------------------------------------");
  } catch (e) {
    console.log("Errore:", e.message);
  }
};