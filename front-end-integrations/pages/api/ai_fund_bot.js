import { ethers } from "ethers";
import {
  lendBorrowContractABI,
  lendBorrowContractAddress,
} from "@/abiAndContractSettings";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const contract = new ethers.Contract(lendBorrowContractAddress, lendBorrowContractABI, signer);

  try {
    const loans = await contract.getAllLoans();

    for (const loan of loans) {
      const interest = parseFloat(loan.interest); 
      const amountInRBTC = parseFloat(ethers.formatEther(loan.amount));

      if (interest >= 12 && amountInRBTC < 0.002) {
        const tx = await contract.aiFundLoan(loan.id, { value: loan.amount });
        console.log(`Loan ${loan.id} funded: ${tx.hash}`);
      } else {
        console.log(`Loan ${loan.id} skipped: interest=${interest}, amount=${amountInRBTC}`);
      }
    }

    return res.status(200).json({ message: "Checked all loans and funded eligible ones." });
  } catch (error) {
    console.error("Funding error:", error);
    return res.status(500).json({ error: "Loan funding process failed" });
  }
}

