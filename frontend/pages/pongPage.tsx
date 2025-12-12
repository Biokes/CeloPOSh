import Navbar from "@/components/cmm ons/navbar";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { motion } from "framer-motion";
import { toast } from "sonner";


const BoostPack = () => (
    <section className="boostpack ">
        <nav>
            <h5>Inventory</h5>
            <Button className={cn("refresh ribeye")} disabled>refresh</Button>
        </nav>
        <div>
            {
                [
                    { name: 'Multiball mayhem', icon: '🎆', description: 'splits the ball for a burst of chaotic offence', owned: 0, },
                    { name: 'Pat Stretch', icon: '💪', description: 'Increase the length of your pat for clutch saves', owned: 0,},
                    { name: 'Guardian Shield', icon: '🛡️', description: 'Summons an energy barrier that block one goal', owned: 0, }
                ].map((powerUp, index) => (
                        <motion.article key={index}>
                            <nav className="flex gap-1 items-center">
                                <span>{powerUp.icon}</span>
                                <h5>{powerUp.name}</h5>
                            </nav>
                            <p>{powerUp.description}</p>
                            <h6>Owned: {powerUp.owned}</h6>
                        </motion.article>
                    ))
                }
            </div>
            <Button
                className={cn("w-[160px] h-[35px] rounded ribeye text-[1rem]")}
                onClick={() => { 
                    toast.info('Daily crate looting available soon')
                }}
            >Loot Daily crate</Button>
        </section>
)
    
export default function PongPage() {
      const games = [
          { texts: "Quick Match", gameType: "Free", action: () => { } },
          { texts: "Create / Join", gameType: "Free", action: () => {} },
          { texts: "Friendly Stake", gameType: "Stake", action: () => {} },
        { texts: "Compete", gameType: "Stake", action: ()=> {} }
    ];

    
    

    return (
        <main className="w-full">
            <Navbar />
             <div className='pong_hero'>
                <section>
                    {games.map((game, idx) => (
                        <motion.article key={idx}
                            animate={{ scale: [1, 1.05, 1] }}
                            transition={{ duration: 0.3, repeat: Infinity }}
                            whileHover={{ scale: [1.1, 1.3, 1.1] }}
                            onClick={game.action}
                        >
                            <h6 className="text-gradient">{game.texts} <br/> ({game.gameType})</h6>
                        </motion.article>
                    ))}
                </section>
            </div>
            <BoostPack />
        </main>
    )
}