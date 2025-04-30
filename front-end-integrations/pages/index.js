import Head from 'next/head';
import { useState, useEffect } from "react";
import Link from 'next/link';
import AOS from 'aos';
import 'aos/dist/aos.css';
import axios from 'axios';
import Header from '@/components/header';
import { useRouter } from 'next/router';

export default function Home(){
  useEffect(() => {
    AOS.init();
  }, [])

  // create countdown for dashboard navigation
  const [count, setCount] = useState(60);
  useEffect(() => {
    const countdownInterval = setInterval(() => {
      setCount((prevCount) => prevCount - 1);
    }, 1000);

    // Clear the interval when the component is unmounted
    return () => clearInterval(countdownInterval);
  }, []);

  //navigate to dashboard page
  const [allowAutoNav, setAllowAutoNav] = useState(true);
  const router = useRouter();
  useEffect(() => {
    const autoNav = allowAutoNav && setTimeout(() => {
      router.push("/dashboard");
    }, 60000);

    // Cleanup function to clear the timeout when the component is unmounted or auto navigation is stopped
    return () => clearTimeout(autoNav);
}, [allowAutoNav, router])

  //stop navigation to dashboard page
  const stopNav = () => {
    setAllowAutoNav(false)
  }

  return (
    <>
    <Head>
   <title>RootLend - Unlock Effortless Lending and Borrowing on the Rootstock Ecosystem</title>
   <link rel="shortcut icon" href="/favicon.ico" />
   </Head>
   <div>
   <Header />
   <div className='lg:px-[8%] px-[5%] lg:pt-[5cm] pt-[3cm]' style={{backgroundImage:"url(images/bg12.jpg)", backgroundPositionX:"10%", backgroundRepeat:"no-repeat", transition:"0.3s ease-in-out"}}>


   <div className='lg:mx-[-8%] mx-[-5%]  lg:pb-[30%] pb-[100%] firstsectiondiv'>
   <div className='text-center text-[170%] lg:text-[230%] md:text-[180%] pt-[1.5cm] font-[500]'>Scaling EVM-Compatible Solutions with Rootstock and AI-Driven Automation</div>
   <div className='mt-[1cm] text-center lg:text-[140%] text-[120%] lg:mx-[20%] md:mx-[10%] mx-[5%] p-[0.5cm] lg:px-[2cm] text-[#ccc] bg-[rgba(0,0,0,0.95)]' style={{border:"1px solid #209"}}>
    <div data-aos="fade-in" className='info1' style={{transition:"0.5s ease-in-out"}}>
      Lending: RootLend enables DeFi users to participate in peer-to-peer lending and borrowing using supported tokens through our innovative decentralized lending/borrowing dApp. Lenders can earn attractive interest rewards while enjoying a seamless and intuitive user experience. The platform features AI-assisted loan evaluation for smarter, automated funding decisions, a decentralized chat system, a swap powered by Chainlink oracles, advanced search capabilities, and smooth pagination for easy navigation. Backed by a rigorously audited security algorithm, RootLend ensures your funds remain secure at all times.
    </div>
    <div data-aos="fade-in" className='info2' style={{transition:"0.5s ease-in-out"}}>
      Borrowing: Borrowing on RootLend is simple and hassle-free. Users can initiate a loan request from the Borrow section by providing collateral and agreeing to repay the amount with interest. Lenders can then fund these loan requests promptly. To enhance the user experience, RootLend includes dedicated sections such as "View All Available Loans", "View Loans You Funded", and "View Loans You Created" for easy tracking and management of loan activities.
    </div>
   </div>
   <div className='mt-[1cm] text-center' style={{transition:"0.3s ease-in-out"}}>
    <Link href="/dashboard"><button className='m-[0.2cm] rounded-md bg-[#209] px-[0.3cm] py-[0.2cm] text-[#fff] generalbutton ecobutton' style={{border:"2px solid #209"}}>Explore dApp <img src="images/blockchain.png" width="25" className='ml-[0.2cm]' style={{display:"inline-block"}}/></button></Link>
    <Link href="https://github.com/jerydam/rootlend/blob/main/README.md"><button className='m-[0.2cm] rounded-md bg-[#111] px-[0.3cm] py-[0.2cm] text-[#fff] generalbutton docbutton' style={{border:"2px solid #209"}}>Documentation <img src="images/documentation.png" width="25" className='ml-[0.2cm]' style={{display:"inline-block"}}/></button></Link>
   </div>
   {allowAutoNav ? (<div className='text-center mt-[1cm] text-[#fff]'>You will be automatically navigated to the dashboard in {count} seconds....</div>) : 
   (<div className='text-center mt-[1cm] text-[#fff] font-[500]'>Auto-navigation cancelled....</div>)}
   <div className='text-center'>
    {allowAutoNav ? (<button onClick={(e) => stopNav(e)} className='fa-fade mt-[0.5cm] rounded-md bg-[#fff] px-[0.3cm] py-[0.2cm] text-[#001]' style={{boxShadow:"2px 2px 2px 2px #209", animationDuration:"5s"}}>Cancel auto-navigation</button>) : (<span></span>)}
   </div>
   </div>

   </div>
   </div>
  </>
  );
};

