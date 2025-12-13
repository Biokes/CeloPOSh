import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PingPongModule", (m) => {
  const counter = m.contract("PingPong");
  return { counter };
});
