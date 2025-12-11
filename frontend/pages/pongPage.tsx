import { motion } from "framer-motion";

export default function PongPage() {
      const games = [
          { texts: "Quick Match", gameType: "Free", action: () => { } },
          { texts: "Create / Join", gameType: "Free", action: () => {} },
          { texts: "Friendly Stake", gameType: "Stake", action: () => {} },
        { texts: "Compete", gameType: "Stake", action: ()=> {} }
    ];

    return (
        <main>
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
        </main>
    )
}