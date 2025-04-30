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
} from "@/abiAndContractSettings";
  import { useWeb3ModalProvider, useWeb3ModalAccount } from '@web3modal/ethers/react'
  import { BrowserProvider, Contract, formatUnits, parseUnits } from 'ethers'

export default function BorrowSection({displayComponent, setDisplayComponent, changeBg3}) {
    // wallet connect settings
    const { address, chainId, isConnected } = useWeb3ModalAccount()
    const { walletProvider } = useWeb3ModalProvider()

    const [loading, setLoading] = useState()

 // lets read data for the Borrow section using inbuilt functions and abi related read functions
 const [token, setToken] = useState("RBTC")
 const [userRBTCBalance, setuserRBTCBalance] = useState()
 const [userRTLBalance, setUserRTLBalance] = useState()
 const [userUSDTBalance, setUserUSDTBalance] = useState()
 const [userDAIBalance, setUserDAIBalance] = useState()
 useEffect(()=>{
  const getTheData = async() => {
    if(isConnected){
      //read settings first
      const ethersProvider = new BrowserProvider(walletProvider) 
      const tokenContractReadSettings = new Contract(tokenContractAddress, tokenContractABI, ethersProvider)
      const usdtContractReadSettings = new Contract(usdtContractAddress, usdtContractABI, ethersProvider)
      const daiContractReadSettings = new Contract(daiContractAddress, daiContractABI, ethersProvider)
    try {
      const RBTCbalance = await ethersProvider.getBalance(address)
      const parseRBTCbalance = formatUnits(RBTCbalance, 18);
      setuserRBTCBalance((parseFloat(parseRBTCbalance).toFixed(5)).toString())
      const RTLbalance = await tokenContractReadSettings.balanceOf(address)
      const parseRTLbalance = parseFloat(formatUnits(RTLbalance, 18)).toFixed(5);
      setUserRTLBalance(parseRTLbalance.toString())
      const USDTbalance = await usdtContractReadSettings.balanceOf(address)
      const parseUSDTbalance = parseFloat(formatUnits(USDTbalance, 18)).toFixed(5);
      setUserUSDTBalance(parseUSDTbalance.toString())
      const DAIbalance = await daiContractReadSettings.balanceOf(address)
      const parseDAIbalance = parseFloat(formatUnits(DAIbalance, 18)).toFixed(5);
      setUserDAIBalance(parseDAIbalance.toString())
    } catch (error) {
      console.log(error)
    }
  }
  }
  getTheData();  
 }, [userRBTCBalance, userRTLBalance, userUSDTBalance, userDAIBalance, loading])


     //Now we are going to approve the collateral of the loan
    const [hideApprove, setHideApprove] = useState()
    const approveTheLoanCollateral = async () => {
      if(isConnected){
        setLoading(true)
        const ethersProvider = new BrowserProvider(walletProvider) 
        const signer = await ethersProvider.getSigner()
       const tokenContractWriteSettings = new Contract(tokenContractAddress, tokenContractABI, signer)
       const usdtContractWriteSettings = new Contract(usdtContractAddress, usdtContractABI, signer)
       const daiContractWriteSettings = new Contract(daiContractAddress, daiContractABI, signer)
       try {
        if (collateralAddress == tokenContractAddress){
          const approveLoanCollateral = await tokenContractWriteSettings.approve(lendBorrowContractAddress, parseUnits(collateralAmount, 18))
          setHideApprove(true)
        }
        else if (collateralAddress == usdtContractAddress){
          const approveLoanCollateral = await usdtContractWriteSettings.approve(lendBorrowContractAddress, parseUnits(collateralAmount, 18))
          setHideApprove(true)
        }
           else if (collateralAddress == daiContractAddress){
          const approveLoanCollateral = await daiContractWriteSettings.approve(lendBorrowContractAddress, parseUnits(collateralAmount, 18))
          setHideApprove(true)
        }
         
      } catch (error) {
        console.log(error)
        setLoading(false)
       }
       finally {
        setLoading(false)
       }
      }
    }


    //Now we are going to create the loan
    const [RBTCamountToBorrow, setRBTCamountToBorrow] = useState()
    const [interestRate, setInterestRate] = useState()
    const [duration, setDuration] = useState()
    const [collateralAmount, setCollateralAmount] = useState()
    const [collateralAddress, setCollateralAddress] = useState()
    const [isERC20, setisERC20] = useState(true)
    const createTheLoan = async () => {
      if(isConnected){
        setLoading(true)
        const ethersProvider = new BrowserProvider(walletProvider) 
        const signer = await ethersProvider.getSigner()
        const lendBorrowContractWriteSettings = new Contract(lendBorrowContractAddress, lendBorrowContractABI, signer)
       try {
          const blockNumber = await ethersProvider.getBlockNumber();
          const block = await ethersProvider.getBlock(blockNumber);
          const currentTimestamp = block.timestamp;
          console.log("Current block timestamp:", currentTimestamp);
          const totalDuration = duration.toString() * 3600;
          const fundingDeadline = duration.toString() * 3600
          console.log(totalDuration)
          const createloan = await lendBorrowContractWriteSettings.createLoan(parseUnits(RBTCamountToBorrow, 18), interestRate, totalDuration, parseUnits(collateralAmount, 18), collateralAddress, isERC20, fundingDeadline)
          setHideApprove(false)
          setDisplayComponent("lend")
          changeBg3()
        } catch (error) {
        console.log(error)
        setLoading(false)
       }
       finally {
        setLoading(false)
       }
      }
    }
      
    return (
        <div>
        <div className="font-[500] bg-[#209] px-[0.4cm] py-[0.15cm] rounded-md mb-[0.2cm]" style={{display:"inline-block", boxShadow:"2px 2px 2px 2px #333"}}>Borrow</div>
        <div className="text-[#ccc] text-[90%]">Create a loan request on RootLend through peer-to-peer (P2P) borrowing</div>
        
        <div className="my-[1cm] bg-[#000] p-[0.5cm] rounded-xl lg:mx-[10%] md:mx-[10%]" style={{boxShadow:"2px 2px 2px 2px #00f"}}>
          <div className="mb-[0.5cm] text-center">To borrow RBTC, create a loan request. Another RootLend user will fund your loan. (P2P)</div>
        <div className=" bg-[#111] p-[0.5cm] rounded-xl " style={{boxShadow:"2px 2px 2px 2px #333"}}>
        <form>
         <div className='p-[0.5cm] pb-[1cm] bg-[#eee] rounded-md'>
         <div className='text-[#222] font-[500] clear-both'>
          <span className="float-left">Duration (hr)</span>
          <span className='float-right'>RBTC amount</span>
         </div>
         <div className='mt-[1.5cm] clear-both font-[500]' style={{display:"block"}}>
         <input style={{display:"inline-block"}} className="w-[30%] float-left text-[120%] bg-[#eee] outline-none text-[#000] placeholder-[#000]" type="number" id="duration" name="duration" onChange={(e) => setDuration(e.target.value)} placeholder='0' />
         <input style={{display:"inline-block"}} className="w-[30%] float-right text-[120%] text-right bg-[#eee] outline-none text-[#000] placeholder-[#000]" type="number" id="RBTCamountToBorrow" name="RBTCamountToBorrow" onChange={(e) => setRBTCamountToBorrow(e.target.value)} placeholder='0' />
         </div>
         {RBTCamountToBorrow > 100000 && (<div className="text-[#d7b644] text-center clear-both mt-[0.3cm] text-[90%]">RBTC amount to borrow must not be more than 100,000</div>)}
         {RBTCamountToBorrow < 0.001 && (<div className="text-[#d7b644] text-center clear-both mt-[0.3cm] text-[90%]">RBTC amount to borrow must not be less than 0.001</div>)}
         </div>
        </form>
        </div>
          <div className="mt-[0.5cm]"><img src="images/borrow.png" className="m-[auto]" width="35" /></div>
          <div className="mt-[0.5cm] bg-[#111] p-[0.5cm] rounded-xl " style={{boxShadow:"2px 2px 2px 2px #333"}}>
          <div className='grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-6 p-[0.5cm] pb-[1cm] bg-[#eee] rounded-md'>
         <div className="grid-cols-1">
          <label className="text-[#fff] bg-[#002] rounded-md px-[0.3cm] py-[0.2cm]">Collateral</label> <br />
          <div className="grid-cols-1 px-[0.3cm] text-[#000]">
          <div className="mt-[0.5cm]"><input type="radio" id="RTL" name="collateralAddress" value={tokenContractAddress} onChange={(e) => setCollateralAddress(e.target.value)} /><span className="ml-[0.3cm]">RTL</span></div>
          <div><input type="radio" id="USDT" name="collateralAddress" value={usdtContractAddress} onChange={(e) => setCollateralAddress(e.target.value)} /><span className="ml-[0.3cm]">USDT</span></div>
          <div><input type="radio" id="DAI" name="collateralAddress" value={daiContractAddress} onChange={(e) => setCollateralAddress(e.target.value)} /><span className="ml-[0.3cm]">DAI</span></div>
          </div>
         </div>
         <div className="grid-cols-1">
          <label className="text-[#fff] bg-[#002] rounded-md px-[0.3cm] py-[0.2cm]">Collateral amount</label> <br />
          <input style={{borderBottom:"2px solid #000"}} className="mt-[0.3cm] w-[4cm] px-[0.2cm] py-[0.2cm] bg-[rgba(0,0,0,0)] rounded-md outline-none text-[#000] placeholder-[#333]" type="number" id="collateralAmount" name="collateralAmount" onChange={(e) => setCollateralAmount(e.target.value)} placeholder='Input amount' />
         </div>
         <div className="grid-cols-1">
          <label className="text-[#fff] bg-[#002] rounded-md px-[0.3cm] py-[0.2cm]">Is collateral ERC20?</label> <br />
          <div className="px-[0.3cm] text-[#000]">
          <div className="mt-[0.5cm]"><input type="radio" id="true" name="isERC20" value="true" onChange={(e) => setisERC20(e.target.value)} /><span className="ml-[0.3cm]">yes</span></div>
          <div><input type="radio"id="false" name="isERC20" value="false" onChange={(e) => setisERC20(e.target.value)} /><span className="ml-[0.3cm]">no</span></div>
          </div>
         </div>
         <div className="grid-cols-1">
          <label className="text-[#fff] bg-[#002] rounded-md px-[0.3cm] py-[0.2cm]">Interest rate (%)</label> <br />
          <input style={{borderBottom:"2px solid #000"}} className="mt-[0.3cm] w-[4cm] px-[0.2cm] py-[0.2cm] bg-[rgba(0,0,0,0)] rounded-md outline-none text-[#000] placeholder-[#333]" type="number" id="interestRate" name="interestRate" onChange={(e) => setInterestRate(e.target.value)} placeholder='rate e.g 5%' />
         {interestRate > 20 && (<div className="text-[#d7b644] mt-[0.3cm] text-[90%]">Interest rate must not be more than 20%</div>)}
         {interestRate < 2 && (<div className="text-[#d7b644] mt-[0.3cm] text-[90%]">Interest rate must not be less than 2%</div>)}
         </div>
         </div> 
         </div>
         <div className="mt-[0.5cm] ml-[1cm] text-[#aaa]">Service fee: 2%</div>
        {!hideApprove ? (<button type="submit" className='text-center py-[0.3cm] bg-[#111] font-[500] text-[#fff] w-[100%] mt-[0.5cm] rounded-md generalbutton4 cursor-pointer' onClick={(e) => {e.preventDefault();approveTheLoanCollateral(RBTCamountToBorrow, collateralAddress)}}>Approve</button>) : (<span></span>)}
        <button type="submit" className='text-center py-[0.3cm] bg-[#209] font-[500] text-[#fff] w-[100%] mt-[0.5cm] rounded-md generalbutton cursor-pointer' onClick={(e) => {e.preventDefault();createTheLoan(duration, RBTCamountToBorrow, collateralAddress, collateralAmount, isERC20, interestRate)}}>Create Loan Request</button>
        </div>

    {loading ? 
     (<div className='bg-[rgba(0,0,0,0.8)] text-[#000] text-center w-[100%] h-[100%] top-0 right-0 rounded-xl' style={{position:"fixed", zIndex:"9999"}}>
      <div className='loader mx-[auto] xl:mt-[30%] lg:mt-[40%] md:mt-[60%] mt-[70%]'></div>
      </div>) : (<span></span>)  
     }

        </div>
    )
}