/*
 * test/api/security/pan.test.ts – Test-Driven Security cho POL-07 (gate G3)
 * PCI DSS v4.0.1 3.5.1 / 3.4.1; GDPR Art. 25, 32; Luật 91/2025/QH15
 * Viết TRƯỚC khi sửa mã: fail trên mã gốc, pass sau khi che số thẻ.
 */
import { describe, it, before } from 'node:test'
import assert from 'node:assert/strict'
import request from 'supertest'
import type { Express } from 'express'
import type { Sequelize } from 'sequelize'
import { createTestApp } from '../helpers/setup'
import { login } from '../helpers/auth'

let app: Express
let sequelize: Sequelize

before(async () => {
  ({ app, sequelize } = await createTestApp())
}, { timeout: 90000 })

void describe('POL-07: PAN phải được che khi trả về và khi lưu', () => {
  void it('POST /api/Cards không trả về, không lưu PAN đầy đủ', async (t) => {
    const { token } = await login(app, { email: 'jim@juice-sh.op', password: 'ncc-1701' })
    const res = await request(app).post('/api/Cards')
      .set('Authorization', `Bearer ${token}`)
      .send({ fullName: 'Jim', cardNum: '4111111111111111', expMonth: 12, expYear: 2090 })

    const [rows] = await sequelize.query('SELECT cardNum FROM Cards ORDER BY id DESC LIMIT 1')

    // In ra TRƯỚC các assert để khi test fail vẫn thấy giá trị (bằng chứng cho báo cáo)
    t.diagnostic(`HTTP status            : ${res.status}`)
    t.diagnostic(`API trả về cardNum     : ${res.body?.data?.cardNum}`)
    t.diagnostic(`CSDL lưu cardNum       : ${(rows as any[])[0]?.cardNum}`)

    assert.equal(res.status, 201)
    assert.match(String(res.body.data.cardNum), /^\*{12}\d{4}$/, 'API trả về PAN đầy đủ')
    assert.match(String((rows as any[])[0].cardNum), /^\*{12}\d{4}$/, 'PAN lưu dạng rõ trong CSDL')
  })
})
