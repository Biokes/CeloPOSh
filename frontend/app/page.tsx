"use client";
import { motion } from "framer-motion";
import { Zap, Trophy, Users } from "lucide-react";
import { useRouter } from "next/navigation";

function Hero() {
  return (
    <main className='hero'>
      <motion.article
        animate={{ scale: [1, 1.05, 1], rotate: [0, 1, -1, 0] }}
        transition={{ duration: 3, ease: "easeInOut", repeat: Infinity }}
        className="text-center mt-20"
      >
        <h1 className="text-6xl md:text-8xl font-[700] ribeye">
          <span className="text-gradient">Chainskills Arena</span>
        </h1>
        <p className="text-sm md:text-xl text-muted-foreground mb-8 max-w-2xl mx-auto hero_bold">
          <span className="text-gradient">
            Connect, Play competitive games. Win crypto.
          </span>
          <br /> Join the on-chain gaming revolution.
        </p>
        <button className="glass">Get Started</button>
      </motion.article>
    </main>
  )
}
const TopGames = () => {
  const router = useRouter();
  return (
  <section className='w-full px-2 pt-4'>
    <p className='text-gradient ribeye text-[1.5rem] pl-[40px] text-start'>Top Games</p>

    <article className="flex flex-col md:flex-row px-1 w-full md:h-[250px]">
      <aside
        style={{
          backgroundImage: `url(/background1.jpeg)`,
          backgroundSize: 'cover',
          backgroundRepeat: 'no-repeat',
        }}
        className='group relative rounded-lg overflow-hidden h-[150px] sm:h-[250px] md:max-w-[500px] w-full flex flex-row items-end'
      >
        <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

        <motion.button
          onClick={() => {router.push('/pong') }}
          whileHover={{ scale: 1.1 }}
          transition={{ duration: 0.2 }}
          className='relative z-10 h-[30px] rounded-sm bg-black px-2 ml-5 mb-2 text-glow-cyan ribeye transition-all'
        >
          play now
        </motion.button>
      </aside>

      <div className='flex flex-col sm:flex-row w-full'>
        <section className="flex flex-row sm:flex-col w-full py-2 gap-2 md:pl-2 lg:w-full">
          <aside
            style={{
              backgroundImage: `url(/background2.jpeg)`,
              backgroundSize: 'cover',
              backgroundRepeat: 'no-repeat',
            }}
            className='group relative rounded-lg overflow-hidden h-[150px] sm:h-[250px] md:h-full sm:max-w-[300px] lg:max-w-[450px] w-full flex flex-row items-end'
          >
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

            <motion.button
              whileHover={{ scale: 1.1 }}
              transition={{ duration: 0.2 }}
              className='relative z-10 h-[30px] rounded-sm bg-black px-2 ml-5 mb-2 text-glow-cyan ribeye transition-all'
            >
              Coming soon
            </motion.button>
          </aside>

          <aside
            style={{
              backgroundImage: `url(/background1.jpeg)`,
              backgroundSize: 'cover',
              backgroundRepeat: 'no-repeat',
            }}
            className='group relative rounded-lg overflow-hidden h-[150px] sm:h-[250px] md:h-full sm:max-w-[300px] lg:max-w-[450px] w-full flex flex-row items-end'
          >
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/80 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

            <motion.button
              whileHover={{ scale: 1.1 }}
              transition={{ duration: 0.2 }}
              className='relative z-10 h-[30px] rounded-sm bg-black px-2 ml-5 mb-2 text-glow-cyan ribeye transition-all'
            >
              Coming soon
            </motion.button>
          </aside>
        </section>

        <section className="flex flex-row sm:flex-col w-full py-2 gap-2 md:pl-2 lg:w-full">
          <aside
            style={{
              backgroundImage: `url(/background2.jpeg)`,
              backgroundSize: 'cover',
              backgroundRepeat: 'no-repeat',
            }}
            className='group relative rounded-lg overflow-hidden h-[150px] sm:h-[250px] md:h-full sm:max-w-[300px] lg:max-w-[450px] w-full flex flex-row items-end'
          >
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

            <motion.button
              whileHover={{ scale: 1.1 }}
              transition={{ duration: 0.2 }}
              className='relative z-10 h-[30px] rounded-sm bg-black px-2 ml-5 mb-2 text-glow-cyan ribeye transition-all'
            >
              Coming soon
            </motion.button>
          </aside>

          <aside
            style={{
              backgroundImage: `url(/background1.jpeg)`,
              backgroundSize: 'cover',
              backgroundRepeat: 'no-repeat',
            }}
            className='group relative rounded-lg overflow-hidden h-[150px] sm:h-[250px] md:h-full sm:max-w-[300px] lg:max-w-[450px] w-full flex flex-row items-end'
          >
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

            <motion.button
              whileHover={{ scale: 1.1 }}
              transition={{ duration: 0.2 }}
              className='relative z-10 h-[30px] rounded-sm bg-black px-2 ml-5 mb-2 text-glow-cyan ribeye transition-all'
            >
              Coming soon
            </motion.button>
          </aside>
        </section>
      </div>
    </article>
  </section>
  )
}
const FAQ = () => (
  <section className="py-20 px-4 bg-gradient-to-b from-transparent to-card/50">
    <div className="max-w-7xl mx-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="text-center mb-16"
      >
        <h2 className="text-5xl md:text-6xl font-bold mb-6">
          <span className="text-gradient ribeye">Why Chainskills Arena?</span>
        </h2>
      </motion.div>

      <div className="grid md:grid-cols-3 gap-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="glass p-8 rounded-2xl text-center border-gradient-primary border-[1px]"
        >
          <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-primary/20 flex items-center justify-center glow-cyan">
            <Zap className="h-8 w-8 text-primary" />
          </div>
          <h3 className="text-2xl font-bold mb-4">Instant Payouts</h3>
          <p className="text-muted-foreground">
            Win games, earn crypto instantly. No waiting, no middlemen. Your
            winnings are yours immediately.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.1 }}
          className="glass p-8 rounded-2xl text-center border-gradient-primary border-[1px]"
          >
          <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-secondary/20 flex items-center justify-center glow-purple">
            <Trophy className="h-8 w-8 text-secondary" />
          </div>
          <h3 className="text-2xl font-bold mb-4">Skill-Based</h3>
          <p className="text-muted-foreground">
            Pure skill, zero luck. Every game is fair and transparent. The
            best player wins, always.
          </p>
        </motion.div>
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2 }}
          className="glass p-8 rounded-2xl text-center border-gradient-primary border-[1px]"
        >
          <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-accent/20 flex items-center justify-center glow-magenta">
            <Users className="h-8 w-8 text-accent" />
          </div>
          <h3 className="text-2xl font-bold mb-4">Global Community</h3>
          <p className="text-muted-foreground">
            Play against opponents worldwide. Join tournaments, climb
            leaderboards, and become a legend.
          </p>
        </motion.div>
      </div>
    </div>
  </section>
);
export default function Home() {

  return (
    <>
      <Hero />
      <TopGames />
      <FAQ />
    </>
  )
}
