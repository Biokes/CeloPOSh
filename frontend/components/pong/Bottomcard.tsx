    const livegames =[]

const LiveGames = () => (
        <section className='livegames'>
            <header>Live Games</header>
            {
                livegames.length == 0 ?
                    <span>
                        <h3> No Live Game currently</h3>
                    </span>
                    :
                    <div>
                        { livegames.map((game, index) => (<article key={index}>{game}</article> ))}
                    </div>
            }
        </section>
    )


export default function BottomCard() {

    return  (
        <div className='bottomCard'>
            <LiveGames />
            <aside>
                <LeadersBoard />
                <HowToPlay />
            </aside>
        </div>
    )
}