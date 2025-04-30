import { useState, useEffect } from "react";
import { 
    tokenContractAddress,
    tokenContractABI,
    lendBorrowContractABI,
    lendBorrowContractAddress,
    usdtContractAddress,
    usdtContractABI,
    daiContractAddress,
    daiContractABI, 
    swapContractAddress,
    swapContractABI
  } from "@/abiAndContractSettings";
import { useWeb3ModalProvider, useWeb3ModalAccount } from '@web3modal/ethers/react'
import { BrowserProvider, Contract, formatUnits } from 'ethers'
import BTCChart from "./btcchart";

export default function MetricsSection() {
           // wallet connect settings
           const { address, chainId, isConnected } = useWeb3ModalAccount()
           const { walletProvider } = useWeb3ModalProvider()

          // lets read data for the Protocol Metrics section using inbuilt functions and abi related read functions
           const [totalTokenSupply, settotalTokenSupply] = useState()
           const [tokenPrice, setTokenPrice] = useState()
           const [numberOfLoans, setnumberOfLoans] = useState()
           const [maxLoanAmount, setmaxLoanAmount] = useState()
           const [minLoanAmount, setminLoanAmount] = useState()
    
           useEffect(()=>{
            const getProtocolData = async() => {
                if(isConnected){
                //read settings first
                const ethersProvider = new BrowserProvider(walletProvider) 
                const tokenContractReadSettings = new Contract(tokenContractAddress, tokenContractABI, ethersProvider)
                const usdtContractReadSettings = new Contract(usdtContractAddress, usdtContractABI, ethersProvider)
                const daiContractReadSettings = new Contract(daiContractAddress, daiContractABI, ethersProvider)
                const lendBorrowContractReadSettings = new Contract(lendBorrowContractAddress, lendBorrowContractABI, ethersProvider)
              try {
                const getTotalTokenSupply = await tokenContractReadSettings.totalSupply()
                console.log(getTotalTokenSupply.toString() * 10**-18)
                settotalTokenSupply(getTotalTokenSupply.toString() * 10**-18)
                setTokenPrice(parseFloat(0.5).toFixed(10))
                const getNumberOfLoans = await lendBorrowContractReadSettings.loanCount()
                console.log(getNumberOfLoans.toString())
                setnumberOfLoans(getNumberOfLoans.toString())
                const getMaxLoanAmount = await lendBorrowContractReadSettings.MAX_LOAN_AMOUNT()
                console.log(getMaxLoanAmount.toString() * 10**-18)
                setmaxLoanAmount(getMaxLoanAmount.toString() * 10**-18)
                const getMinLoanAmount = await lendBorrowContractReadSettings.MIN_LOAN_AMOUNT()
                console.log(getMinLoanAmount.toString() * 10**-18)
                setminLoanAmount(getMinLoanAmount.toString() * 10**-18)
              } catch (error) {
                console.log(error)
              }
            }
            }
            getProtocolData();  
           }, [isConnected, address])

    return (
        <div>
        <div className="font-[500] bg-[#209] px-[0.4cm] py-[0.15cm] rounded-md mb-[0.2cm]" style={{display:"inline-block", boxShadow:"2px 2px 2px 2px #333"}}>RootLend Metrics</div>
        <div className="text-[#ccc] text-[90%]">Real-time RootLend platform status</div>

        <div className="text-center mt-[0.7cm] bg-[#000] p-[0.5cm] rounded-xl" style={{boxShadow:"2px 2px 2px 2px #333"}}>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">RTL Total Supply</div>
                {totalTokenSupply ? (<div className="text-[#aaa] lg:w-[100%] md:w-[100%] w-[7cm] overflow-auto">{Intl.NumberFormat().format(parseFloat(totalTokenSupply).toFixed(10))} RTL</div>) : (<span>0</span>)}
            </div>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">RTL Price</div>
                {tokenPrice ? (<div className="text-[#aaa]">≈ ${tokenPrice}</div>) : (<span>0</span>)}
            </div>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">Protocol Blockchain</div>
                <div className="text-[#aaa]">Rootstock Testnet</div>
            </div>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">Number of Loans</div>
                {numberOfLoans > 0 ? (<div className="text-[#aaa]">{Intl.NumberFormat().format(numberOfLoans)}</div>) : (<span>0</span>)}
            </div>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">Max Loan Amount</div>
                {maxLoanAmount ? (<div className="text-[#aaa]">{Intl.NumberFormat().format(maxLoanAmount)} RBTC</div>) : (<span>0</span>)}
            </div>
            <div className="text-center m-[0.4cm]" style={{display:"inline-block"}}>
                <div className="font-[500] text-[110%]">Min Loan Amount</div>
                {minLoanAmount ? (<div className="text-[#aaa]">{Intl.NumberFormat().format(minLoanAmount)} RBTC</div>) : (<span>0</span>)}
            </div>
        </div>

        <div className="mt-[0.5cm] bg-[#000] p-[0.5cm] rounded-xl" style={{boxShadow:"2px 2px 2px 2px #333"}}>
            <div className="grid lg:grid-cols-2 grid-cols-1 gap-4">
            <div className="grid-cols-1">
            <div className="m-[0.4cm]">
             <div className="font-[500] text-[#fff] bg-[#00f] px-[0.4cm] py-[0.1cm] rounded-md mb-[0.2cm]" style={{display:"inline-block"}}>RTL Contract Address</div>
             <div className="text-[#aaa]" style={{overflow:"auto"}}>{tokenContractAddress}</div>
            </div>
            </div>
            <div className="grid-cols-1">
            <div className="m-[0.4cm]">
             <div className="font-[500] text-[#fff] bg-[#00f] px-[0.4cm] py-[0.1cm] rounded-md mb-[0.2cm]" style={{display:"inline-block"}}>P2P Lend/Borrow Contract Address</div>
             <div className="text-[#aaa]" style={{overflow:"auto"}}>{lendBorrowContractAddress}</div>
            </div>
            </div>
            <div className="grid-cols-1">
            <div className="m-[0.4cm]">
             <div className="font-[500] text-[#fff] bg-[#00f] px-[0.4cm] py-[0.1cm] rounded-md mb-[0.2cm]" style={{display:"inline-block"}}>USDT Contract Address</div>
             <div className="text-[#aaa]" style={{overflow:"auto"}}>{usdtContractAddress}</div>
            </div>
            </div>
            <div className="grid-cols-1">
            <div className="m-[0.4cm]">
             <div className="font-[500] text-[#fff] bg-[#00f] px-[0.4cm] py-[0.1cm] rounded-md mb-[0.2cm]" style={{display:"inline-block"}}>DAI Contract Address</div>
             <div className="text-[#aaa]" style={{overflow:"auto"}}>{daiContractAddress}</div>
            </div>
            </div>
            <div className="grid-cols-1">
            <div className="m-[0.4cm]">
             <div className="font-[500] text-[#fff] bg-[#00f] px-[0.4cm] py-[0.1cm] rounded-md mb-[0.2cm]" style={{display:"inline-block"}}>Swap Contract Address</div>
             <div className="text-[#aaa]" style={{overflow:"auto"}}>{swapContractAddress}</div>
            </div>
            </div>
            </div>
        </div>

        <div className="mt-[0.5cm]">
          <BTCChart />
        </div>

        </div>
    )
}