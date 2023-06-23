import { BigNumber, Wallet } from 'ethers'
import { arrayify, keccak256 } from 'ethers/lib/utils'
import { ethers } from 'hardhat'

let counter = 0

// create non-random account, so gas calculations are deterministic
export function createAccountOwner (c?:number): Wallet {
  const privateKey = keccak256(Buffer.from(arrayify(BigNumber.from(c||++counter))))
  return new ethers.Wallet(privateKey, ethers.provider)
  // return new ethers.Wallet('0x'.padEnd(66, privkeyBase), ethers.provider);
}

export function createOwnerAddress (c?:number): string {
    return createAccountOwner(c).address
  }

export function createOwner (c?:number): Wallet {
    return createAccountOwner(c)
  }

  export async function isDeployed (addr: string): Promise<boolean> {
    const code = await ethers.provider.getCode(addr)
    return code.length > 2
  }