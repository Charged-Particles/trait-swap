import { ContractTransactionReceipt, ContractTransactionResponse, EventLog, Log } from 'ethers';

export const performTx = async (tx: ContractTransactionResponse, msg: string) => {
  const rc: ContractTransactionReceipt | null = await tx.wait();
  if (rc !== null) {

    if (rc?.logs?.length > 0 && msg.includes('{id}')) {
      const evt: EventLog | Log = rc.logs[0];
      // @ts-ignore
      if (evt?.args?.length == 3) {
        // @ts-ignore
        const data = evt.args[2];
        msg = msg.replace(/\{id}/ig, data);
      }
    }

    // console.log(msg);
  }
};
