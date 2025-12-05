import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button } from "../ui/button";

export default function Navbar() {
    const navigate = useRouter()

    return (
        <nav className='flex justify-between items-center h-[70px] py-2 px-4 shadow-sm shadow-primary/40'>
            <aside className='w-[70px] h-[70%] cursor-pointer' onClick={() => navigate.push('/')}>
                <Image src="/logo.png" alt="logo" className="w-full h-full object-cover object-contain" />
            </aside>
            <Button className="connectButton">Toggle</Button>
        </nav>
    )
}