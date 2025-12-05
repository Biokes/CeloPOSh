import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button } from "../ui/button";

export default function Navbar() {
    const navigate = useRouter()

    return (
        <nav className='navbar'>
            <aside onClick={() => navigate.push('/')}>
                <Image src="/logo.png" alt="logo" height={70} width={70} />
            </aside>
            <Button className="connectButton">Toggle</Button>
        </nav>
    )
}