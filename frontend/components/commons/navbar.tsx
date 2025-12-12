import Image from "next/image";
import { useRouter } from "next/navigation";
import {   AppKitConnectButton } from "@reown/appkit/react";

export default function Navbar() {
    const navigate = useRouter()

    
    return (
        <nav className='navbar'>
            <aside onClick={() => navigate.push('/')}>
                <Image src="/logo.png" alt="logo" height={70} width={70} />
            </aside>
            <AppKitConnectButton className="connect_btn"/>
        </nav>
    )
}