/*
 * lib/cardMasking.ts – POL-07 / PCI DSS 3.5.1: kiểm tra số thẻ rồi che TRƯỚC KHI lưu
 */
import { type Request, type Response, type NextFunction } from 'express'

/** Thuật toán Luhn: loại số thẻ gõ sai hoặc bịa */
const luhn = (n: string) => [...n].reverse().reduce((s, d, i) => {
  let x = Number(d)
  if (i % 2) { x *= 2; if (x > 9) x -= 9 }
  return s + x
}, 0) % 10 === 0

/** Giữ 4 số cuối, thay 12 số đầu bằng dấu * */
export const maskPan = (pan: string) => '*'.repeat(12) + pan.slice(-4)

export function maskCardNumber () {
  return (req: Request, res: Response, next: NextFunction) => {
    const pan = String(req.body?.cardNum ?? '').replace(/\D/g, '')
    if (pan.length !== 16 || !luhn(pan)) {
      res.status(400).json({ status: 'error', message: 'Invalid card number' })
      return
    }
    req.body.cardNum = maskPan(pan)
    next()
  }
}
