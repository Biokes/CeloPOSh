import { PlayerStat } from "@/types"
import { useState } from "react"


const LeadersBoard = () => {
    const [players] = useState<PlayerStat[]>([
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
         {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
         {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
        {
            walletAddress: "123456789009876543123456789",
            avatarURL: "https://laosupdjwdndq.com",
            username: "string",
            ratings: 10,
        },
    ])

    return (
        <div className="leadersBoard">
            <header>Live LeaderBoard</header>
            {
                players.length == 0 ?
                    <span>
                        <h3> No Records currently</h3>
                    </span>
                    :
                    <div className="!justify-start !items-center">
                        {
                            players.map((player, index) => (
                                <li key={index}>
                                    <p>
                                        <span>{index + 1}.</span>
                                        {`${player.walletAddress.substring(0, 7)}...${player.walletAddress.slice(-7)}`}
                                    </p>
                                    <p>{player.ratings} XP</p>
                                </li>
                            ))
                        }
                    </div>
            }
        </div>
    )
}

const HowToPlay = () => (
    <article className="howToPlay">
        <header>
            How to play
        </header>
        <div>
            <p>1. Connect wallet</p>
            <p>2. Select mode of game to play</p>
            <p>3. Claim daily power ups for profie standards</p>
            <p>4. Master your skills and stake your OCT</p>
            <p className='!text-center italic'>...play for fun, earn for fun...</p>
        </div>
    </article>
)

const LiveGames = ({ livegames }: { livegames: string[] }) => (
    <section className='livegames'>
        <header>Live Games</header>
        {
            livegames.length == 0 ?
                <span>
                    <h3> No Live Game currently</h3>
                </span>
                :
                <div>
                    {livegames.map((game, index) => (<article key={index}>{game}</article>))}
                </div>
        }
    </section>
)


export default function BottomCard() {

    return (
        <div className='bottomCard'>
            <LiveGames livegames={[]} />
            <aside>
                <LeadersBoard />
                <HowToPlay />
            </aside>
        </div>
    )
}